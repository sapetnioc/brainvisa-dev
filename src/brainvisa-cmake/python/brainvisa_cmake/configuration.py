# -*- coding: utf-8 -*-

"""Handling of bv_maker configuration (bv_maker.cfg)."""

import glob
from optparse import OptionParser
import os
import shlex
from socket import gethostname  # for use in eval()'d expressions
import sys
import traceback

import six
from six.moves import reload_module

import brainvisa_cmake.brainvisa_projects as brainvisa_projects
import brainvisa_cmake.components_definition
from brainvisa_cmake.environment import normalize_path
from brainvisa_cmake.environment import replace_vars
from brainvisa_cmake.environment import VarReplacementType
from brainvisa_cmake.utils import global_installer_variables
from brainvisa_cmake.version import version as brainvisa_cmake_version


default_subprocess_timeout = 3600 * 6  # default subprocess timeout is 6 hours


def check_filter_condition(filters):
    # for now, use python eval()
    expression = ' '.join(filters)
    # replace %(var)s vars
    vars = global_installer_variables()
    expression = expression % vars
    try:
        res = bool(eval(expression))
    except Exception:
        traceback.print_exc()
        raise
    return res


class GlobalConfiguration(object):

    def __init__(self, argv):
        usage = '''%prog [options] [ command [command options] ]...

This program is for the management of source retrieval, configuration and compilation of BrainVISA projects.

In order to work, the commands svn and svnadmin must be installed on your system. On some Linux systems they are in two separate packages (e.g. subversion and subversion-tools).

Commands:

* info: Just output info about configured components.
* sources: Create or updated selected sources directories from Subversion
  repository.
* status: Display a summary of the status of all source repositories.
* configure: Create and configure selected build directories with CMake.
* build: compile all selected build directories.
* doc: Generate documentation (sphinx, doxygen, docbook, epydoc).
* testref: Execute tests in a special mode to generate machine-specific
  reference files (this is needed by some tests).
* test: Execute tests using ctest.
* pack: Generate binary packages.
* install_pack: Install binary packages.
* testref_pack: Create the machine-specific reference files for tests in
  installed binary package.
* test_pack: Run tests in installed binary packages.
* publish_pack: Publish binary packages.

To get help for a specific command, use -h option of the command. Example: "%prog build -h".

To get help on how to configure and write a bv_maker configuration file, see:

http://brainvisa.info/brainvisa-cmake/compile_existing.html

config file syntax:

http://brainvisa.info/brainvisa-cmake/configuration.html

and more generally:

http://brainvisa.info/brainvisa-cmake/
'''
        defaultConfigurationFile = os.environ.get('BRAINVISA_BVMAKER_CFG')
        if defaultConfigurationFile is None:
            defaultConfigurationFile = os.path.join(
                os.environ['USERPROFILE' if sys.platform.startswith('win')
                           else 'HOME'], '.brainvisa', 'bv_maker.cfg')
        parser = OptionParser(usage=usage)

        parser.add_option('-d', '--directory', dest='directories',
                          help='Restrict actions to a selected directory. May be used several times to process several directories.',
                          metavar='DIR', action='append', default=[])
        parser.add_option('-c', '--config', dest='configuration_file',
                          help='specify configuration file. Default ="' +
                          defaultConfigurationFile + '"',
                          metavar='CONFIG', default=None)
        parser.add_option('-s', '--sources', dest='sources_directories',
                          help='directory containing sources',
                          metavar='DIR', action='append', default=[])
        parser.add_option('-b', '--build', dest='build_directory',
                          help='build directory',
                          metavar='DIR', default=None)
        parser.add_option('--username', dest='username',
                          help='specify user login to use with the svn server',
                          metavar='USERNAME', default='')
        parser.add_option('-e', '--email', action='store_true',
                          help='Use email notification (if configured in the '
                          'general section of the configuration file)')
        parser.add_option('--def', '--only-if-default', action='store_true',
                          dest='in_config', default=False,
                          help='apply only steps which are defined as default '
                          'steps in the bv_maker.cfg config file. Equivalent '
                          'to passing --only-if-default to every substep '
                          'which supports it.')
        parser.add_option(
            '-v', '--verbose', dest='verbose', action='store_true',
            help='show as much information as possible')
        parser.add_option(
            '--version', dest='version', action='store_true',
            help='show bv_maker (brainvisa-cmake) version number')

        (options, args) = parser.parse_args(argv)
        if args:
            raise ValueError('Invalid option: %s' % args[0])

        if options.version:
            print('bv_maker version:', brainvisa_cmake_version)
            sys.exit(0)

        packages = []

        self.sourcesDirectories = {}
        self.buildDirectories = {}
        self.packageDirectories = {}
        self.publicationDirectories = {}
        self.general_section = GeneralSection(self)

        self.directories = options.directories

        for i in ('configuration_file', 'username', 'verbose'):
            setattr(self, i, getattr(options, i))

        bd = None  # build directory supplied on the command-line
        if options.build_directory:
            if not options.configuration_file:
                cf = os.path.join(options.build_directory, 'bv_maker.cfg')
                if os.path.exists(cf):
                    options.configuration_file = cf
                else:
                    options.configuration_file = defaultConfigurationFile
            os.environ['BV_MAKER_BUILD'] = options.build_directory
            reload_module(brainvisa_cmake.components_definition)
            reload_module(brainvisa_projects)

            from brainvisa_cmake import build
            bd = build.BuildDirectory(options.build_directory, self)

            for sd in options.sources_directories:
                if os.path.exists(os.path.join(sd, 'project_info.cmake')) \
                    or glob.glob(os.path.join(sd, 'python', '*', 'info.py')) \
                    or glob.glob(os.path.join(sd, '*', 'info.py')):
                    bd.addConfigurationLine('directory ' + sd)
                else:
                    bd.addConfigurationLine('brainvisa all * ' + sd)
        elif not options.configuration_file:
            options.configuration_file = defaultConfigurationFile

        if options.configuration_file \
                and os.path.exists(options.configuration_file):
            with open(options.configuration_file, 'rb') as f:
                self.parse_config_file(f, options, extra_build_dir=bd)

        if options.verbose:
            print('variables initialized')

        # store options and args
        self.options = options
        self.args = args


    def parse_config_file(self, f, options, extra_build_dir=None):
        """Read configuration from an file object (opened in binary mode)."""
        from brainvisa_cmake import build
        from brainvisa_cmake import sources
        lineCount = 0
        currentDirectoryObject = None

        source_dirs = []
        build_dirs = [extra_build_dir] if extra_build_dir else []
        package_dirs = []
        publication_dirs = []

        condition_stack = []

        for line in f:
            lineCount += 1
            line = line.strip()
            try:
                line = line.decode()
            except UnicodeError:
                line = line.decode('utf-8')
            # skip comments
            if not line or line[0] == '#' or line.startswith('//'):
                continue
            try:
                if line[0] == '[':
                    if line[-1] != ']':
                        raise SyntaxError()
                    l = line[1:-1].split(None, 1)
                    if len(l) != 2 and l[0] not in ('if', 'endif', 'else',
                                                    'general'):
                        raise SyntaxError()

                    if l[0] == 'if' \
                            and currentDirectoryObject is not None \
                            and len(l) >= 2:
                        if len(condition_stack) != 0 \
                                and condition_stack[-1] is False:
                            # if an upstream condition is already false,
                            # all the subtree is false (but we still have
                            # to parse it to count if/endif/else
                            # occurrences in it)
                            condition_stack.append(False)
                        else:
                            try:
                                condition_stack.append(
                                    check_filter_condition(l[1:]))
                            except Exception:
                                print('error in condition, line %d:'
                                      % lineCount, file=sys.stderr)
                                print(line, file=sys.stderr)
                                raise
                    elif l[0] == 'endif' and len(l) == 1:
                        if len(condition_stack) > 0:
                            # ends the filtered section
                            condition_stack.pop()
                        else:
                            SyntaxError('[endif] clause is not preceded '
                                        'by [if] clause.')
                    elif l[0] == 'else' and len(l) == 1:
                        if len(condition_stack) > 0:
                            # inverts the filtered section, only if its
                            # parent condition is True
                            if len(condition_stack) == 1 \
                                    or condition_stack[-2]:
                                condition_stack[-1] \
                                    = not condition_stack[-1]
                        else:
                            SyntaxError('[else] clause is not preceded by '
                                        '[if] clause.')
                    elif len(condition_stack) == 0 \
                        or False not in condition_stack:
                        if self.verbose:
                            print('  processing line %s:' % str(lineCount),
                                  repr(line))
                            sys.stdout.flush()

                        if l[0] == 'source':
                            currentDirectoryObject = sources.SourceDirectory(
                                l[1].strip(),
                                self)
                            source_dirs.append(currentDirectoryObject)
                        elif l[0] == 'build':
                            currentDirectoryObject = build.BuildDirectory(
                                l[1].strip(),
                                self)
                            build_dirs.append(currentDirectoryObject)
                        elif l[0] == 'virtualenv':
                            currentDirectoryObject = build.VirtualenvDirectory(
                                l[1].strip(),
                                self)
                            build_dirs.append(currentDirectoryObject)
                        elif l[0] == 'package':
                            from brainvisa_cmake import installer
                            currentDirectoryObject = installer.PackageDirectory(
                                l[1].strip(),
                                self)
                            package_dirs.append(currentDirectoryObject)
                        elif l[0] == 'package_publication':
                            from brainvisa_cmake import installer
                            currentDirectoryObject = installer.PublicationDirectory(
                                l[1].strip(),
                                self)
                            publication_dirs.append(currentDirectoryObject)
                        elif l[0] == 'general' and len(l) == 1:
                            currentDirectoryObject = self.general_section
                        else:
                            raise SyntaxError()

                elif len(condition_stack) == 0 \
                    or False not in condition_stack:
                    if currentDirectoryObject is None:
                        raise SyntaxError()
                    if self.verbose:
                        print('  processing line %s:' % str(lineCount),
                              repr(line))
                        sys.stdout.flush()

                    currentDirectoryObject.addConfigurationLine(line)
            except SyntaxError as e:
                # FIXME: SyntaxError should be reserved for Python syntax
                # errors, use a custom exception instead
                msg = str(e)
                if msg == '':
                    msg = 'Syntax error'
                raise SyntaxError('%s in ' % msg + repr(
                    options.configuration_file) + ' on line '
                    + str(lineCount))

        if len(condition_stack) > 0:
            RuntimeError('some [if] clause remain unclosed by [endif].')

        if options.verbose:
            print('configuration file %s parsed'
                % repr(options.configuration_file))

        for r, sections in ((None, [self.general_section]), \
                            ('sourcesDirectories', source_dirs), \
                            ('buildDirectories', build_dirs), \
                            ('packageDirectories', package_dirs), \
                            ('publicationDirectories', publication_dirs)):
            for s in sections:
                # Variable initialization is done after parsing of sections
                # because it may depend on the complete parsing of other
                # sections
                if not hasattr(s, '_initialized') or not s._initialized:
                    s.init_vars()

                    registry = getattr(self, r, None) if r else None
                    if registry is not None:
                        # Register section
                        registry[s.directory] = s

                    if isinstance(s, sources.SourceDirectory):
                        # Parses source configuration
                        s.parseSourceConfiguration()

                if options.verbose:
                    print(getattr(s, 'directory', 'general'), 'options:')
                    for o in s._validOptions:
                        print(' ', o, '=', getattr(s, o, None))


class ConfigVariableParser(object):

    _validOptions = set()
    _validAdditiveOptions = set()
    _path_variables = set()
    _variables_with_replacements = set()
    _variables_with_env_only_replacements = set()
    _variables_with_python_only_replacements = set()

    def __new__(cls, *args):
        # Initialize the class properties
        for prop in cls._validOptions.union(cls._validAdditiveOptions):
            cls.property_init(prop)

        return super(ConfigVariableParser, cls).__new__(cls)

    def __init__(self, *args):
        super(ConfigVariableParser, self).__init__(*args)

        self._property_info = {}
        self._property_recursivity = {}
        for prop in self._validOptions.union(self._validAdditiveOptions):
            self._property_info[prop] = \
                (self.get_replacement_type(prop),
                 self.is_path(prop))

    @classmethod
    def property_init(cls, name, doc = None):
        from functools import partial

        # Declare option as a property
        setattr(cls, name,
                property(partial(getattr(cls, '_property_get'), name),
                         partial(getattr(cls, '_property_set'), name),
                         partial(getattr(cls, '_property_del'), name),
                         doc if doc else 'property ' + name))

    @staticmethod
    def _property_has(name, config_parser):
        return name in config_parser._property_info

    @staticmethod
    def _property_set(name, config_parser, value):
        setattr(config_parser, '_' + name, value)
        #print('val_type is', type(v), 'for value:', value)

    @staticmethod
    def _property_get_origin(name, config_parser):
        getattr(config_parser, '_' + name)

    @staticmethod
    def _property_get(name, config_parser):
        info = config_parser._property_info.get(name, None)
        if info is None:
            raise RuntimeError('Property %s is not declared' % name)

        repl_type, is_path = info

        def from_config_object(value):
            # Recursively replaces configuration patterns
            # using ConfigValue object
            if isinstance(value, (list, tuple, set)):
                value = type(value)([from_config_object(v) for v in value])

            elif isinstance(value, dict):
                value = dict([(k, from_config_object(v)) \
                              for k, v in six.iteritems(value)])

            elif isinstance(value, six.string_types):
                env_vars = config_parser.get_environ()
                python_vars = config_parser.get_python_vars()
                value = replace_vars(value, repl_type, python_vars, env_vars)
                if is_path and value:
                    value = normalize_path(value)

            return value

        value = getattr(config_parser, '_' + name)
        config_parser._property_recursivity[name] = True
        value = from_config_object(value)
        del config_parser._property_recursivity[name]

        #print('_property_get', name, value, type(value), repl_type, is_path);sys.stdout.flush()
        return value

    @staticmethod
    def _property_del(name, config_parser):
        delattr(config_parser, '_' + name)

    def property_append(self, name, value):
        old_value = getattr(self, '_' + name)
        prop_type = type(old_value)

        if prop_type in (dict, set):
            old_value.update(value)
        else:
            old_value += value

        setattr(self, name, old_value)

    def property_remove(self, name, value):
        old_value = getattr(self, '_' + name)
        prop_type = type(old_value)
        if prop_type is dict:
            for k in value:
                if k in old_value:
                    del old_value[k]
        elif prop_type is set:
            old_value.difference_update(value)
        elif prop_type is list:
            old_value = [x for x in old_value if x not in value]
            setattr(self, name, old_value)
        else:
            try:
                old_value -= value
            except Exception:
                raise SyntaxError()

    def get_valid_options(self):
        return self._validOptions

    def addConfigurationLine(self, line):
        i = line.find('=')
        if i > 0:
            oper = '' # assign (=) operator by default
            if i > 1 and line[i-1] in ('-', '+'): # operators -=, +=
                oper = line[i-1]
                option = line[:i-1].strip()
                if option not in self._validAdditiveOptions:
                    raise SyntaxError('Option %s does not allow additive '
                                      'assignation (+=, -=)' % option)
            else:
                option = line[:i].strip()
            value = line[i + 1:].strip()
            if option not in self._validOptions:
                raise SyntaxError('Invalid option: %s' % option)

            var_type = str
            if hasattr(self, option):
                var_type = type(getattr(self, option))
                if var_type in (list, tuple):
                    value = shlex.split(value)
                elif var_type is dict:
                    if value.startswith('{') and value.endswith('}'):
                        try:
                            value = eval(value)
                        except Exception:
                            raise SyntaxError()
                    else:
                        try:
                            value = eval('{' + value + '}')
                        except Exception:
                            # try simpler syntax without quotes
                            try:
                                value = [x.strip() for x in value.split(',')]
                                value = dict([(x[:x.find(':')],
                                               x[x.find(':') + 1:].strip())
                                    for x in value])
                            except Exception:
                                raise SyntaxError()

            if oper == '':
                setattr(self, option, value)

            elif oper == '+':
                self.property_append(option, value)

            elif oper == '-':
                self.property_remove(option, value)

            self.validate_option(option)
            return True # parsed
        return False # not parsed

    def validate_option(self, option):
        # by default nothing more is done
        pass

    def is_path(self, var):
        return var in getattr(self, '_path_variables', set())

    def allows_env_replacements(self, var):
        return (self.is_path(var) \
                and var not in getattr(self,
                                   '_variables_with_python_only_replacements',
                                   set())) \
            or var in getattr(self,
                              '_variables_with_env_only_replacements',
                              set()) \
            or var in getattr(self,
                              '_variables_with_replacements',
                              set())

    def allows_python_replacements(self, var):
        return (self.is_path(var) \
                and var not in getattr(self,
                                   '_variables_with_env_only_replacements',
                                   set())) \
            or var in getattr(self,
                              '_variables_with_python_only_replacements',
                              set()) \
            or var in getattr(self,
                              '_variables_with_replacements',
                              set())

    def allows_replacements(self, var):
        return self.allows_python_replacements(var) \
           and self.allows_env_replacements(var)

    def get_replacement_type(self, var):
        if self.allows_replacements(var):
            return VarReplacementType.ALL

        elif self.allows_env_replacements(var):
            return VarReplacementType.ENV

        elif self.allows_python_replacements(var):
            return VarReplacementType.PYTHON

        else:
            return VarReplacementType.NO

    def init_vars(self):
        self.__init_python_vars()
        self.__init_environ()

    def __init_python_vars(self):
        self._python_vars = dict(global_installer_variables())

    def __init_environ(self):
        self._env_vars = dict(os.environ)

        if not self._property_recursivity.get('env'):
            # Automatically add the env property of the directory
            # to the environment variables if it exists
            if hasattr(self, 'env'):
                # Add env property content
                self.update_environ(getattr(self, 'env', {}))

    def reset_environ(self):
        self.__init_environ()

    def update_python_vars(self, vars):
        '''Update python variable cache for the section'''
        self._python_vars.update(vars)

    def update_environ(self, vars):
        '''Update environment variable cache for the section'''
        self._env_vars.update(vars)

    def get_python_vars(self):
        return getattr(self, '_python_vars', {})

    def get_environ(self, env = None):
        env_vars = getattr(self, '_env_vars', None)
        if not env_vars:
            return os.environ
            #raise RuntimeError('Environment is not initialized')

        new_env = dict(self._env_vars)
        if env:
            new_env.update(env)
        return new_env

    def replace_vars(self, value, replacement_type=VarReplacementType.ALL):
        return replace_vars(value, replacement_type,
                            self.get_python_vars(),
                            self.get_environ())

    def replace_vars_if_allowed(self, var, value, env=None):
        if self.allows_replacements(var):
            return replace_vars(value, VarReplacementType.ALL,
                                self.get_python_vars(),
                                self.get_environ())

        elif self.allows_env_replacements(var):
            # Replaces only environment variables
           return replace_vars(value, VarReplacementType.ENV,
                               env_vars = self.get_environ())
        elif self.allows_python_replacements(var):
            # Replaces only environment variables
           return replace_vars(value, VarReplacementType.PYTHON,
                               python_vars = self.get_python_vars())
        else:
            return value


class GeneralSection(ConfigVariableParser):
    _variables_with_replacements = \
        set(('directory_id_by_default',
             'subprocess_timeout'))
    _variables_with_env_only_replacements = set(('casa_environment', 'env'))
    _validAdditiveOptions = set(('env', ))
    _path_variables = set(('global_status_file', ))
    _validOptions = set(('failure_email', 'success_email', 'smtp_server',
                         'from_email', 'reply_to_email',
                         'email_notification_by_default',
                         'failure_email_by_project',
                         'casa_environment'))
    _validOptions.update(_variables_with_replacements)
    _validOptions.update(_path_variables)
    _validOptions.update(_variables_with_env_only_replacements)

    def __init__(self, configuration):
        super(GeneralSection, self).__init__()

        self.configuration = configuration
        self.configurationLines = []
        self.failure_email = ''
        self.failure_email_by_project = {}
        self.success_email = ''
        self.smtp_server = ''
        self.from_email = ''
        self.reply_to_email = ''
        self.global_status_file = None
        self.email_notification_by_default = 'OFF'
        self.casa_environment = ''
        self.subprocess_timeout = default_subprocess_timeout
        self.directory_id_by_default = ''
        self.env = {}

    def addConfigurationLine(self, line):
        if ConfigVariableParser.addConfigurationLine(self, line):
            pass
        else:
            raise SyntaxError()

    def validate_option(self, option):
        if option == 'env':
            # env variables are set immediately
            self.init_vars()

    def init_vars(self):
        super(GeneralSection, self).init_vars()
        # actually add env vars to os.environ
        for var, value in six.iteritems(self._env_vars):
            if var not in os.environ or os.environ[var] != value:
                os.environ[var] = value


class DirectorySection(object):

    def __init__(self):
        super(DirectorySection, self).__init__()
        self.status = {}
        self.start_time = {}
        self.stop_time = {}
        self.depend_on_sections = {}
        self.deps_set = False
        self.build_condition = None
        self.stdout_file = None
        self.stderr_file = None

    def has_failed(self, step):
        return self.status.get(step, 'not run') \
            in ('failed', 'interrupted', 'unmet dependency')

    def has_succeeded(self, step):
        return not self.status.get(step, 'not run') == 'succeeded'

    def get_status(self, step):
        return self.status.get(step, 'not run')

    def has_satisfied_dependencies(self, step):
        if not self.deps_set:
            self.set_dependencies()
            self.deps_set = True

        for dep_sec in self.depend_on_sections.get(step, []):
            dep, dep_step = dep_sec[:2]
            if len(dep_sec) >= 3: # function to test dependency
                if not dep_sec[2](self, dep, dep_step):
                    self.status[step] = 'unmet dependency'
                    return False
            else:
                if dep.has_failed(dep_step):
                    self.status[step] = 'unmet dependency'
                    return False
        return True

    def set_dependencies(self):
        pass

    def conditional_build(self):
        '''Tells if the current directory has actually to be built.
        If a condition option is False, it will not.
        '''
        if not self.build_condition:
            return True
        cond = True
        try:
            cond = eval(self.build_condition)
        except Exception as e:
            print('Directory', self.directory,
                  ': error in parsing build_condition option:',
                  file=sys.stderr)
            print(self.build_condition, file=sys.stderr)
            print('(Condition is evaluated as python expression). Error:',
                  sys.stderr)
            print(e, file=sys.stderr)
            raise
        return cond

    def process_configuration_lines(self):
        pass
