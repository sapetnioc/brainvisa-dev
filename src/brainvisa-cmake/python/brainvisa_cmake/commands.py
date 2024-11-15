# -*- coding: utf-8 -*-

"""Support code for sub-commands of bv_maker."""

import datetime
import json
import io
from optparse import OptionParser
import os
import platform
import re
from smtplib import SMTP
from socket import gethostname
import sys
import tempfile
import time
import traceback

import six

from brainvisa_cmake.environment import normalize_path
from brainvisa_cmake.utils import installer_format_date
from brainvisa_cmake.utils import installer_format_time
from brainvisa_cmake.utils import installer_parse_date
from brainvisa_cmake.utils import installer_parse_time
from brainvisa_cmake.utils import global_installer_datetime


IGNORED_STEP = 'ignored'


class StepCommand(object):

    def __init__(self, argv, configuration):
        # Initialize python variables that can override directories
        # python variables
        super(StepCommand, self).__init__()
        self.configuration = configuration
        self.python_vars = {}

    def process(self, step, directories_list, method, *meth_args,
                **meth_kwargs):
        for o in directories_list:
            # Update directory python variables by those coming from the command
            # line (package date and version)
            o.update_python_vars(self.python_vars)
            # Python variables update need to reprocess environment variables
            o.reset_environ()

            # Get the new directory value
            d = o.directory
            normalize_path_needed = 'directory' in \
                getattr(o, '_path_variables', set())

            # Resolve directories pattern using configuration directory
            # variables
            conf_dirs = [normalize_path(o.replace_vars(c)) \
                         if normalize_path_needed else o.replace_vars(c) \
                         for c in self.configuration.directories] \
                        if self.configuration.directories else []

            if (not conf_dirs or d in conf_dirs) and o.conditional_build():
                if (not self.options.in_config
                    and not self.configuration.options.in_config) \
                        or step in o.default_steps:
                    if o.has_satisfied_dependencies(step):
                        self.redirect_stdout(d, o, step)
                        logs = None

                        build_info_file = build_info = None
                        if 'CONDA_PREFIX' in os.environ:
                            build_info_file = os.path.join(os.path.dirname(o.directory), 'conf', 'build_info.json')
                            if os.path.exists(build_info_file):
                                with open(build_info_file) as f:
                                    build_info = json.load(f)
                                    write = False
                                    if step == 'configure':
                                        build_info['brainvisa-cmake'] = {
                                            'configure': {'start': datetime.datetime.now().isoformat()},
                                            'build': {},
                                            'doc': {},
                                        }
                                        write = True
                                    elif step in ('build', 'doc'):
                                        build_info['brainvisa-cmake'][step] = {'start': datetime.datetime.now().isoformat()}
                                        write = True
                                    if write:
                                        with open(build_info_file, 'w') as f:
                                            json.dump(build_info, f, indent=4)

                        try:
                            logs = getattr(o, method)(*meth_args,
                                                      **meth_kwargs)
                            if not logs:
                                o.status[step] = 'succeeded' # mark as done
                        except KeyboardInterrupt:
                            # record failure
                            o.status[step] = 'interrupted'
                            o.stop_time[step] = time.localtime()
                            # user interruptions should stop all.
                            raise
                        except Exception:
                            traceback.print_exc()
                            # record failure
                            o.status[step] = 'failed'
                        if logs:
                            if logs == IGNORED_STEP:
                                # step did nothing and should be ignored
                                o.status[step] = 'not run'
                                self.release_stdout(o)
                                continue
                            o.stop_time[step] = time.localtime()
                            o.status[step] = 'succeeded'
                            for label, item in six.iteritems(logs):
                                log = item['log_file']
                                exc = item['exception']
                                full_step = '%s:%s' % (step, label)
                                o.start_time[full_step] = item['start_time']
                                o.stop_time[full_step] = item['stop_time']
                                if exc is None:
                                    o.status[full_step] = 'succeeded'
                                elif isinstance(exc, KeyboardInterrupt):
                                    o.status[full_step] = 'interrupted'
                                    if o.status[step] != 'failed':
                                        o.status[step] = 'interrupted'
                                else:
                                    o.status[full_step] = 'failed'
                                    o.status[step] = 'failed'
                                self.release_notify_log(d, o, step, label, log,
                                                        exc)
                        else:
                            self.release_notify_stdout(d, o, step)

                        if build_info and step in ('configure', 'build', 'doc'):
                            build_info['brainvisa-cmake'][step]['stop'] = datetime.datetime.now().isoformat()
                            build_info['brainvisa-cmake'][step]['status'] = o.status[step]
                            with open(build_info_file, 'w') as f:
                                json.dump(build_info, f, indent=4)
                    else:
                        print('Skipping', step, 'of', d,
                              'because it depends on a step that failed.')
            elif self.configuration.verbose:
                print('Skipping', step, 'of', d,
                      'because it is not in the selected directories.')


    def redirect_stdout(self, d, o, step):
        o.start_time[step] = time.localtime()
        if self.configuration.general_section is None:
            return
        if ((self.configuration.general_section.email_notification_by_default. \
                upper() != 'ON' and not self.configuration.options.email) \
                or (self.configuration.general_section.failure_email == ''
                    and self.configuration.general_section.success_email == ''
                    and self.configuration.general_section.failure_email_by_project
                        == {})):
            return
        if o.stdout_file or o.stderr_file:
            # Line buffering is used (buffering=1) because the output from
            # bv_maker needs to be interspersed correctly with the output of
            # external commands called through subprocess.
            if o.stdout_file:
                self.tmp_stdout = open(o.stdout_file, 'w', buffering=1)
                if o.stderr_file:
                    self.tmp_stderr = open(o.stderr_file, 'w', buffering=1)
                else:
                    self.tmp_stderr = self.tmp_stdout
            else:
                self.tmp_stdout = open(o.stderr_file, 'w', buffering=1)
                self.tmp_stderr = self.tmp_stdout
        else:
            tmp_stdout = tempfile.mkstemp(prefix='buildout_')
            os.close(tmp_stdout[0])
            print('redirecting outputs to temporary file:', tmp_stdout[1])
            sys.stdout.flush()
            sys.stderr.flush()
            self.tmp_stdout = open(tmp_stdout[1], 'w', buffering=1)
            self.tmp_stderr = self.tmp_stdout
        self.orig_stdout = os.dup(sys.stdout.fileno())
        self.orig_stderr = os.dup(sys.stderr.fileno())
        os.dup2(self.tmp_stdout.fileno(), 1)
        os.dup2(self.tmp_stderr.fileno(), 2)

    def release_notify_stdout(self, d, o, step):
        o.stop_time[step] = time.localtime()
        fix_stdout = False
        if hasattr(self, 'orig_stdout'):
            fix_stdout = True
            os.dup2(self.orig_stdout, 1)
            os.dup2(self.orig_stderr, 2)
            self.tmp_stdout.close()
            if self.tmp_stderr is not self.tmp_stdout:
                self.tmp_stderr.close()
        self.notify_log(d, o, step)
        if fix_stdout:
            del self.orig_stderr
            del self.orig_stdout
            if not o.stdout_file:
                os.unlink(self.tmp_stdout.name)
            # tmp_stderr is never removed: either it is specified as a
            # persistant file or it is tmp_stdout.
            del self.tmp_stdout
            del self.tmp_stderr

    def release_stdout(self, o):
        if not hasattr(self, 'orig_stdout'):
            return
        os.dup2(self.orig_stdout, 1)
        os.dup2(self.orig_stderr, 2)
        self.tmp_stdout.close()
        if self.tmp_stderr is not self.tmp_stdout:
            self.tmp_stderr.close()
        del self.orig_stderr
        del self.orig_stdout
        if not o.stdout_file:
            os.unlink(self.tmp_stdout.name)
        # tmp_stderr is never removed: either it is specified as a persistant
        # file or it is tmp_stdout.
        del self.tmp_stdout
        del self.tmp_stderr

    def release_notify_log(self, d, o, step, label, log, exc):
        self.release_stdout(o)
        self.tmp_stdout = open(log)
        self.tmp_stdout.close()
        self.tmp_stderr = self.tmp_stdout
        full_step = '%s:%s' % (step, label)
        if exc is None:
            o.status[full_step] = 'succeeded'
        elif isinstance(exc, KeyboardInterrupt):
            o.status[full_step] = 'interrupted'
        else:
            o.status[full_step] = 'failed'
        self.notify_log(d, o, full_step)
        del self.tmp_stdout
        os.unlink(log)

    def notify_log(self, d, o, step):
        status =  o.status.get(step, 'not run')
        # global log file notification
        self.log_in_global_log_file(d, o, step, status)
        # email notification
        email = ''
        if self.configuration.general_section.email_notification_by_default.upper() \
                == 'ON' or self.configuration.options.email:
            if status in ('failed', 'interrupted'):
                email = self.configuration.general_section.failure_email
                if self.configuration.general_section.failure_email_by_project:
                    project = step.split(':')[-1]
                    if project in  self.configuration.general_section. \
                            failure_email_by_project:
                        email = self.configuration.general_section. \
                            failure_email_by_project[project]
            elif status == 'succeeded':
                email = self.configuration.general_section.success_email
        if email:
            try:
                self.send_log_email(email, d, o, step, status)
            except Exception as e:
                print('WARNING: notification email could not be sent:',
                      e.message)
                traceback.print_exc()
        # console notification
        if email and status in ('failed', 'interrupted'):
            # original stdout has been changed, we need to print again
            print(self.message_header(d, o, step, status))
            print(self.log_message_content())

    def message_header(self, d, o, step, status):
        real_dir = o.replace_vars(d)
        dlen = max((len(step), len(status), len(real_dir)))
        if hasattr(o, 'get_environ'):
            env = o.get_environ()
        else:
            env = os.environ
        start_time = '%04d/%02d/%02d %02d:%02d' % o.start_time[step][:5]
        stop_time = '%04d/%02d/%02d %02d:%02d' % o.stop_time[step][:5]
        message = '''\
=========================================
== directory: %s%s ==
== step:      %s%s ==
== status:    %s%s ==
== started:   %s%s ==
== stopped:   %s%s ==
=========================================

--- environment: ---
''' % (real_dir, ' ' * (dlen - len(real_dir)),
            step, ' ' * (dlen - len(step)),
            status, ' ' * (dlen - len(status)),
            start_time, ' ' * (dlen - len(start_time)),
            stop_time, ' ' * (dlen - len(stop_time)))
        message += '\n'.join(['%s=%s' % (var, env[var])
                              for var in sorted(env.keys())])
        message += '\n------------------------------------------\n\n'

        return message

    def send_log_email(self, email, d, o, step, status):
        if self.configuration.general_section.from_email == '':
            from_address = '%s-%s@intra.cea.fr' \
                % (os.getenv('USER'), gethostname())
        else:
            from_address = self.configuration.general_section.from_email
        if self.configuration.general_section.reply_to_email == '':
            reply_to_address = 'appli@saxifrage.saclay.cea.fr'
        else:
            reply_to_address = self.configuration.general_section.reply_to_email
        to_address = email

        # header
        machine = gethostname()
        osname = platform.platform()
        Status = status[0].upper() + status[1:]
        message = '''MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Reply-To: %s
Subject: %s - %s %s on %s (%s)

%s - build started %s, stopped %s on %s (%s)

''' % (reply_to_address, Status, step,
            '%04d/%02d/%02d' % o.start_time[step][:3],
            machine, osname, Status,
            '%04d/%02d/%02d %02d:%02d' % o.start_time[step][:5],
            '%04d/%02d/%02d %02d:%02d' % o.stop_time[step][:5], machine,
            osname)

        message += self.message_header(d, o, step, status)
        message += self.log_message_content()

        # Normalize all end-of-lines to use CRLF as required in Internet
        # messages (taken from smtplib).
        message = re.sub(r'(?:\r\n|\n|\r(?!\n))', '\r\n', message)

        if self.configuration.general_section.smtp_server != '':
            smtp_server = self.configuration.general_section.smtp_server
        else:
            smtp_server = 'mx.intra.cea.fr'
        server = SMTP(smtp_server)
        server.sendmail(from_address, to_address, message.encode('utf-8'))
        server.quit()

    def log_message_content(self):
        if self.tmp_stderr is not self.tmp_stdout:
            message = '====== standard output ======\n\n'
        else:
            message = '====== output ======\n\n'
        # Read message from file
        with io.open(self.tmp_stdout.name, mode='rt', errors='replace',
                     newline='') as file:
            message += file.read()
        if self.tmp_stderr is not self.tmp_stdout:
            message += '====== standard error ======\n\n'
            with io.open(self.tmp_stderr.name, mode='rt', errors='replace',
                         newline='') as file:
                message += file.read()
        return message

    def log_in_global_log_file(self, d, o, step, status):
        # print('log_in_global_log_file', step, status)
        if status == 'not run':
            return # don't log non-running steps
        log_file = None
        if self.configuration.general_section \
                and self.configuration.general_section.global_status_file:
            log_file = self.configuration.general_section.global_status_file
        if not log_file:
            return

        status = status.upper()
        if status == 'SUCCEEDED':
            status = 'OK' # we used OK, so let's go on
        machine = gethostname()
        osname = platform.platform()

        message = '%s step %s: %s' % (status, step, d)
        start = o.start_time.get(step)
        if start:
            message += ', started: %04d/%02d/%02d %02d:%02d' \
                % start[:5]
        stop = o.stop_time.get(step)
        if stop:
            message += ', stopped: %04d/%02d/%02d %02d:%02d' \
                % stop[:5]
        with open(log_file, 'a') as f:
            f.write('%s on %s (%s)\n' % (message, machine, osname))


class InfoCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] info [options]

    Display information about configuration, sources directories and build directories.'''
        parser = OptionParser(usage=usage)
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, and '
                          '"configure build" for build sections')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(InfoCommand, self).__init__(argv, configuration)
        self.options = options
        self.args = args

    def __call__(self):
        print('Configuration file:', self.configuration.configuration_file)
        dirs = dict(self.configuration.sourcesDirectories)
        dirs.update(self.configuration.buildDirectories)
        dirs.update(self.configuration.packageDirectories)
        dirs.update(self.configuration.publicationDirectories)
        self.process('info', list(dirs.values()), 'info')


class SourcesCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] sources [options]

    Create or updated selected sources directories from Subversion repository.'''
        parser = OptionParser(usage=usage)
        parser.add_option('--no-cleanup', dest='cleanup', action='store_false',
                          default=True,
                          help='don\'t cleanup svn sources')
        parser.add_option('--no-svn', dest='svn', action='store_false',
                          default=True,
                          help='don\'t update of svn sources')
        parser.add_option('--no-git', dest='git', action='store_false',
                          default=True,
                          help='don\'t update git sources')
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, and '
                          '"configure build" for build sections')
        parser.add_option('--ignore-git-failure', dest='ignore_git_failure',
                          action='store_true', default=False,
                          help='ignore git update failures, useful when '
                          'working on a feature branch')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(SourcesCommand, self).__init__(argv, configuration)
        self.options = options
        self.args = args

    def __call__(self):
        self.process('sources', list(self.configuration.sourcesDirectories.values()),
                     'process', self.options, self.args)


class SourceStatusCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] status [options]

    Display a summary of the status of all source repositories.'''
        parser = OptionParser(usage=usage)
        parser.add_option('--svn', dest='svn', action='store_true',
                          default=False,
                          help="display the status of svn sources")
        parser.add_option('--no-git', dest='git', action='store_false',
                          default=True,
                          help="don't display the status of git sources")
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, and '
                          '"configure build" for build sections')
        parser.add_option('--git-command', dest='extra_git_commands',
                          default=[], action='append',
                          help="run one or more extra commands in every Git "
                               "repository. The commmands are interpreted in "
                               "a shell so that you can pass arguments.")
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(SourceStatusCommand, self).__init__(argv, configuration)
        self.options = options
        self.args = args

    def __call__(self):
        self.process('status',
                     list(self.configuration.sourcesDirectories.values()),
                     'source_status', self.options, self.args)


class ConfigureCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] configure [options]

    Create or updated selected build directories.'''
        parser = OptionParser(usage=usage)
        parser.add_option('-c', '--clean', dest='clean', action='store_true',
                          default=False,
                          help='clean build tree (using bv_clean_build_tree '
                          '-d) before configuring')
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, and '
                          '"configure build" for build sections')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(ConfigureCommand, self).__init__(argv, configuration)
        self.options = options
        self.args = args

    def __call__(self):
        self.process('configure', list(self.configuration.buildDirectories.values()),
                     'configure', self.options, self.args)

class BuildCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] configure [options]

    Compile selected build directories.'''
        parser = OptionParser(usage=usage)
        parser.add_option('-c', '--clean', dest='clean', action='store_true',
                          default=False,
                          help='clean build tree (using '
                          'bv_clean_build_tree -b) before building')
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, and '
                          '"configure build" for build sections')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(BuildCommand, self).__init__(argv, configuration)
        self.options = options
        self.args = args

    def __call__(self):
        self.process('build', list(self.configuration.buildDirectories.values()),
                     'build', self.options, self.args)


class DocCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] doc [options]

    Generate documentation (docbook, epydoc, doxygen).'''
        parser = OptionParser(usage=usage)
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, and '
                          '"configure build" for build sections')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(DocCommand, self).__init__(argv, configuration)
        self.options = options
        self.args = args

    def __call__(self):
        self.process('doc', list(self.configuration.buildDirectories.values()), 'doc')


class TestCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] test

    Executes ctest.'''
        parser = OptionParser(usage=usage)
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, and '
                          '"configure build" for build sections')
        parser.add_option('-t', '--ctest_options',
                          default=None,
                          help='options passed to ctest (ex: "-VV -R carto*"). '
                          'Same as the configuration option ctest_options but '
                          'specified at runtime. The commandline option here '
                          'overrides the bv_maker.cfg options.')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(TestCommand, self).__init__(argv, configuration)
        self.options = options
        self.args = args

    def __call__(self):
        self.process('test', list(self.configuration.buildDirectories.values()), 'test',
                     self.options, self.args)


class TestrefCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] testref

    Executes tests in the testref mode (used to generate reference files).'''
        parser = OptionParser(usage=usage)
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, and '
                          '"configure build" for build sections')
        parser.add_option('-m', '--make_options',
                          default=None,
                          help='options passed to make (ex: "-j8") during test '
                          'reference generation. '
                          'Same as the configuration option make_options but '
                          'specified at runtime. The commandline option here '
                          'overrides the bv_maker.cfg options.')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(TestrefCommand, self).__init__(argv, configuration)
        self.options = options
        self.args = args

    def __call__(self):
        self.process('testref', list(self.configuration.buildDirectories.values()), 'testref',
                     self.options, self.args)


class PackCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] pack [options]

    Make installer package for the selected build directory.'''
        parser = OptionParser(usage=usage)
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, '
                          '"configure build" for build sections.')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(PackCommand, self).__init__(argv, configuration)
        self.python_vars = dict(global_installer_datetime())
        self.options = options
        self.args = args

    def __call__(self):
        # First, we need to order packages to manage dependencies between
        # them (especially for offline installer that refer to data package,
        # because in this case, it is necessary to update data package
        # repository before software package has been packaged)
        def __getPackageDirectoriesByDepth():
            def __getDepth(package_dir):
                data_dir = package_dir.get_data_dir()
                if not data_dir:
                    return 0
                else:
                    return __getDepth(data_dir) + 1

            dirs=[]
            for o in self.configuration.packageDirectories.values():
                dirs.append((__getDepth(o), o))

            #print([(o, d.directory) for o, d in sorted(dirs)])
            return [d for o, d in sorted(dirs, key=lambda x: x[0])]

        self.process('pack', __getPackageDirectoriesByDepth(),
                     'package', self.options, self.args)


class InstallPackCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] install_pack [options]

    Install a binary package for the selected build directory.'''
        parser = OptionParser(usage=usage)
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, '
                          '"configure build" for build sections.')
        parser.add_option('--package-date', dest='package_date',
                          default=None,
                          help='sets the date of the pack to install. '
                          'This is only useful if a %(date)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        parser.add_option('--package-time', dest='package_time',
                          default=None,
                          help='sets the time of the pack to install. '
                          'This is only useful if a %(time)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        parser.add_option('--package-version', dest='package_version',
                          default=None,
                          help='sets the version of the pack to install. '
                          'This is only useful if a %(version)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        parser.add_option('--prefix', dest='prefix',
                          default=None,
                          help='sets the prefix directory to install the pack.')
        parser.add_option('--local', dest='local',
                          action='store_true',
                          default=False,
                          help='True if the installation must be done ' \
                               'locally. Default is False.')
        parser.add_option('--offline', dest='offline',
                          action='store_true',
                          default=False,
                          help='True if the installation must be done using ' \
                               'offline installer. Default is False.')
        parser.add_option('--debug', dest='debug',
                          action='store_true',
                          default=False,
                          help='True if the installation must be done in debug ' \
                               'mode (i.e. generated files must not be deleted). ' \
                               'Default is False.')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(InstallPackCommand, self).__init__(argv, configuration)

        date = installer_format_date(installer_parse_date(options.package_date)) \
               if options.package_date else global_installer_datetime()['date']
        time = installer_format_time(installer_parse_time(options.package_time)) \
               if options.package_time else global_installer_datetime()['time']
        self.python_vars = {'date': date,
                            'time': time}
        if options.package_version:
            self.python_vars.update({'version': options.package_version})

        self.options = options
        self.args = args

    def __call__(self):
        self.process('install_pack', list(self.configuration.packageDirectories.values()),
                     'install_package', self.options, self.args)


class TestPackCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] test_pack [options]

    Test in installed package for the selected build directory.'''
        parser = OptionParser(usage=usage)
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, '
                          '"configure build" for build sections.')
        parser.add_option('-t', '--ctest_options',
                          default=None,
                          help='options passed to ctest (ex: "-VV -R carto*"). '
                          'Same as the configuration option ctest_options but '
                          'specified at runtime. The commandline option here '
                          'overrides the bv_maker.cfg options.')
        parser.add_option('--package-date', dest='package_date',
                          default=None,
                          help='sets the date of the pack to install. '
                          'This is only useful if a %(date)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        parser.add_option('--package-time', dest='package_time',
                          default=None,
                          help='sets the time of the pack to install. '
                          'This is only useful if a %(time)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        parser.add_option('--package-version', dest='package_version',
                          default=None,
                          help='sets the version of the pack to install. '
                          'This is only useful if a %(version)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(TestPackCommand, self).__init__(argv, configuration)

        date = installer_format_date(installer_parse_date(options.package_date)) \
               if options.package_date else global_installer_datetime()['date']
        time = installer_format_time(installer_parse_time(options.package_time)) \
               if options.package_time else global_installer_datetime()['time']
        self.python_vars = {'date': date,
                            'time': time}
        if options.package_version:
            self.python_vars.update({'version': options.package_version})

        self.options = options
        self.args = args

    def __call__(self):
        self.process('test_pack', list(self.configuration.packageDirectories.values()),
                     'test_package', self.options, self.args)


class TestrefPackCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] testref_pack [options]

    Create test reference files in installed package for the selected build directory.'''
        parser = OptionParser(usage=usage)
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, '
                          '"configure build" for build sections.')
        parser.add_option('-m', '--make_options',
                          default=None,
                          help='options passed to make (ex: "-j8") during test '
                          'reference generation. '
                          'Same as the configuration option make_options but '
                          'specified at runtime. The commandline option here '
                          'overrides the bv_maker.cfg options.')
        parser.add_option('--package-date', dest='package_date',
                          default=None,
                          help='sets the date of the pack to install. '
                          'This is only useful if a %(date)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        parser.add_option('--package-time', dest='package_time',
                          default=None,
                          help='sets the time of the pack to install. '
                          'This is only useful if a %(time)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        parser.add_option('--package-version', dest='package_version',
                          default=None,
                          help='sets the version of the pack to install. '
                          'This is only useful if a %(version)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(TestrefPackCommand, self).__init__(argv, configuration)

        date = installer_format_date(installer_parse_date(options.package_date)) \
               if options.package_date else global_installer_datetime()['date']
        time = installer_format_time(installer_parse_time(options.package_time)) \
               if options.package_time else global_installer_datetime()['time']
        self.python_vars = {'date': date,
                            'time': time}
        if options.package_version:
            self.python_vars.update({'version': options.package_version})

        self.options = options
        self.args = args

    def __call__(self):
        self.process('testref_pack', list(self.configuration.packageDirectories.values()),
                     'testref_package', self.options, self.args)


class PublishPackCommand(StepCommand):

    def __init__(self, argv, configuration):
        usage = '''%prog [global options] publish [options]

    Run command to publish package for the selected publication directory.'''
        parser = OptionParser(usage=usage)
        parser.add_option('--only-if-default', dest='in_config',
                          action='store_true',
                          default=False,
                          help='only perform this step if it is a default '
                          'step, or specified in the "default_steps" option '
                          'of bv_maker.cfg config file. Default steps are '
                          'normally "sources" for source sections, '
                          '"configure build" for build sections.')
        parser.add_option('-m', '--make_options',
                          default=None,
                          help='options passed to make (ex: "-j8") during test '
                          'reference generation. '
                          'Same as the configuration option make_options but '
                          'specified at runtime. The commandline option here '
                          'overrides the bv_maker.cfg options.')
        parser.add_option('--package-date', dest='package_date',
                          default=None,
                          help='sets the date of the pack to install. '
                          'This is only useful if a %(date)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        parser.add_option('--package-time', dest='package_time',
                          default=None,
                          help='sets the time of the pack to install. '
                          'This is only useful if a %(time)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        parser.add_option('--package-version', dest='package_version',
                          default=None,
                          help='sets the version of the pack to install. '
                          'This is only useful if a %(version)s pattern '
                          'has been used in the package directory sections '
                          'of bv_maker.cfg.')
        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        super(PublishPackCommand, self).__init__(argv, configuration)

        date = installer_format_date(installer_parse_date(options.package_date)) \
               if options.package_date else global_installer_datetime()['date']
        time = installer_format_time(installer_parse_time(options.package_time)) \
               if options.package_time else global_installer_datetime()['time']
        self.python_vars = {'date': date,
                            'time': time}
        if options.package_version:
            self.python_vars.update({'version': options.package_version})

        self.options = options
        self.args = args

    def __call__(self):
        self.process('publish_pack', list(self.configuration.publicationDirectories.values()),
                     'publish_package', self.options, self.args)


COMMANDS = {
    'info': InfoCommand,
    'sources': SourcesCommand,
    'status': SourceStatusCommand,
    'configure': ConfigureCommand,
    'build': BuildCommand,
    'doc': DocCommand,
    'test': TestCommand,
    'testref': TestrefCommand,
    'pack': PackCommand,
    'install_pack': InstallPackCommand,
    'test_pack': TestPackCommand,
    'testref_pack': TestrefPackCommand,
    'publish_pack': PublishPackCommand,
}
