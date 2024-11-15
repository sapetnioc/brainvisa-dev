# -*- coding: utf-8 -*-

"""Code related to the BrainVISA installer and packaging.

Note that the installer was used for releases 4.6 and 4.7. Is is not used
anymore since BrainVISA 5.0.
"""

import glob
from optparse import OptionParser
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import six

from brainvisa_cmake import build
from brainvisa_cmake.commands import IGNORED_STEP
import brainvisa_cmake.configuration
from brainvisa_cmake.environment import environmentPathVariablesSubstitution
from brainvisa_cmake.environment import normalize_path
from brainvisa_cmake.subprocess import subprocess32
from brainvisa_cmake.subprocess import system_output_on_error
from brainvisa_cmake.utils import global_installer_datetime


def get_matching_dirs(directories, pattern):
    dirs = []
    for d in directories:
        if normalize_path(
            d.replace_vars(pattern)) == d.directory:
            dirs.append(d)

    return dirs



class PackageDirectory(build.ComponentsConfigParser,
                       brainvisa_cmake.configuration.ConfigVariableParser):

    _path_variables = set(('directory',
                           'build_directory',
                           'installer_filename',
                           'offline_installer_filename',
                           'data_repos_dir', 'test_install_dir',
                           'stdout_file', 'stderr_file', 'test_ref_data_dir',
                           'test_run_data_dir', 'remote_installer_filename',
                           'remote_offline_installer_filename',
                           'remote_repos_dir', 'remote_data_repos_dir',
                           'remote_test_install_dir',
                           'remote_test_ref_data_dir',
                           'remote_test_run_data_dir'))
    _variables_with_replacements = set(('package_repository_subdir',
                                        'pack_version', 'directory_id',
                                        'packaging_options',
                                        'make_options', 'ctest_options',
                                        'installer_options'))
    _variables_with_env_only_replacements = set(('env',
                                                 'test_ref_data_dir',
                                                 'test_run_data_dir',
                                                 'remote_test_ref_data_dir',
                                                 'remote_test_run_data_dir'))
    _validAdditiveOptions = set(('packaging_options', 'default_steps',
                                 'make_options', 'ctest_options', 'env',
                                 'installer_options'))
    _validOptions = set(('build_condition',
                         'remote_test_host_cmd',
                         'init_components_from_build_dir',
                         'keep_n_older_repos'))
    _validOptions.update(_variables_with_replacements)
    _validOptions.update(_variables_with_env_only_replacements)
    _validOptions.update(_path_variables)
    _validOptions.update(_validAdditiveOptions)

    def __init__(self, directory, configuration):
        super(PackageDirectory, self).__init__(directory, configuration)
        self.build_directory = ''
        self.package_repository_subdir = 'packages'
        self.packaging_options = []
        self.installer_filename = None
        self.installer_options = ''
        self.offline_installer_filename = None
        self.data_repos_dir = ''
        self.test_install_dir = ''
        self.init_components_from_build_dir = 'ON'
        self.pack_version = None
        self.pathvars = None
        self.default_steps = []
        self.keep_n_older_repos = 1
        self.ctest_options = []
        self.make_options = []
        self.directory_id = ''
        self.env = {}
        self.test_ref_data_dir = ''
        self.test_run_data_dir = tempfile.gettempdir()
        self.remote_installer_filename = None
        self.remote_offline_installer_filename = None
        self.remote_repos_dir = None
        self.remote_data_repos_dir = None
        self.remote_test_install_dir = None
        self.remote_test_host_cmd = None
        self.remote_test_ref_data_dir = None
        self.remote_test_run_data_dir = None

    def addConfigurationLine(self, line):
        # Supported lines in bv_maker.cfg for [ pack ... ]:
        if brainvisa_cmake.configuration.ConfigVariableParser.addConfigurationLine(self, line):
            pass
        else:
            line = os.path.expandvars(line)
            if line[0] == '+':
                if '*' in line:
                    raise SyntaxError()
        self.configurationLines.append(line)

    #def validate_option(self, option):
        #if option in ('init_components_from_build_dir', 'build_directory'):
            #if self.build_directory not in ('', None):
                #if self.init_components_from_build_dir.upper() == 'ON':
                    #build_dir = self.get_build_dir()
                    #build_dir.process_configuration_lines()
                    #self.components = dict(build_dir.components)
                #else:
                    #self.components = {}

    #def get_matching_build_dirs(self):
        #build_dirs = []
        #for o in self.configuration.buildDirectories.values():
            #if normalize_path(
                #o.replace_vars(self._build_directory)) == o.directory:
                #build_dirs.append(o)

        #return build_dirs

    def get_build_dir(self):
        if not hasattr(self, 'build_dir'):
            #build_dirs = self.get_matching_build_dirs()
            build_dirs = get_matching_dirs(self.configuration.buildDirectories.values(),
                              self._build_directory)
            if len(build_dirs) == 0:
                raise RuntimeError(
                    'Package directory: referenced build directory "%s" does '
                    'not exist' % self.build_directory)
            elif len(build_dirs) > 1:
                raise RuntimeError(
                    'Package directory: referenced build directory "%s" '
                    'must match a unique build directory. Matches %d '
                    'directories %s' % (self.build_directory, len(build_dirs),
                                        str(build_dirs)))
            else:
                self.build_dir = build_dirs[0]

        return self.build_dir

    def get_data_dir(self):
        if not hasattr(self, 'data_dir'):
            data_dirs = get_matching_dirs(self.configuration.packageDirectories.values(),
                              self._data_repos_dir)
            if len(data_dirs) == 0:
                self.data_dir = None

            elif len(data_dirs) > 1:
                raise RuntimeError(
                    'Package directory: referenced data directory "%s" '
                    'must match a unique package directory. Matches %d '
                    'directories %s' % (self.data_repos_dir, len(data_dirs),
                                        str(data_dirs)))
            else:
                self.data_dir = data_dirs[0]

        return self.data_dir

    def set_dependencies(self):
        build_section = self.get_build_dir()

        if build_section is not None:
            build_section = [(build_section, 'build'),
                             (build_section, 'doc'),
                             (build_section, 'test')]
        else:
            build_section = []
        self.depend_on_sections = {
            'pack': build_section,
            'install_pack': [(self, 'pack')],
            'test_pack': [(self, 'install_pack')],
            'testref_pack': [(self, 'install_pack')],
        }

    def process_configuration_lines(self):
        if not self._configuration_lines_processed:
            build_dir = self.get_build_dir()

            if self.init_components_from_build_dir.upper() == 'ON':
                build_dir.process_configuration_lines()
                # make sure to do an actual copy of build dir projects/components
                self.projects = list(build_dir.projects)
                self.components = dict(build_dir.components)
            super(PackageDirectory, self).process_configuration_lines()

    def info(self):
        self.process_configuration_lines()
        print('Base package directory: "' + self._directory + '"')
        print('  Real base package directory:', self.directory)
        print('  Real final package repository:', os.path.join(self.directory, self.package_repository_subdir))
        print('  Real temporary package repository:',
              os.path.join(self.directory, self.package_repository_subdir) + '_tmp')
        print('  Build directory:', self.build_directory)
        for component, directory_version_model \
                in six.iteritems(self.components):
            directory, selected_version, version, build_model \
                = directory_version_model
            print('  %s (%s) <- %s' % (component, version, directory))

    def get_pack_version(self):
        if self.pack_version:
            version = self.pack_version
        else:
            version = '1.0.0'

            if not self._property_recursivity.get('build_directory'):
                build_dir = self.get_build_dir()
                v = build_dir.get_version()
                if v:
                    version = v
        return version

    def __init_python_vars(self):
        online = 'online'
        offline = 'offline'

        if not self._property_recursivity.get('build_directory'):
            build_dir = self.get_build_dir()
            self.update_python_vars(build_dir.get_python_vars())

        if not self._property_recursivity.get('packaging_options'):
            # Add i2bm and public vars
            i2bm_str = 'public'
            public = ''

            if '--i2bm' in self.packaging_options:
                i2bm_str = 'i2bm'
                public = '-i2bm'
            self.update_python_vars({'i2bm': i2bm_str,
                                     'public': public})

        if not self._property_recursivity.get('pack_version'):
            # Add version var
            self.update_python_vars({'version': self.get_pack_version()})

        # Add online var and local variables
        self.update_python_vars({'online': online,
                                 'offline': offline})

    def installer_variables(self):
        return self.get_python_vars()

    def installer_cmdline(self):
        components = list(self.components.keys())
        projects = list(self.projects)
        pack_options = self.packaging_options
        installer_filename = self.installer_filename
        #if not installer_filename:
            #installer_filename = os.path.join(
                #os.path.dirname(self.directory),
                #'brainvisa-installer/brainvisa_installer-'
                #'%(version)s-%(os)s-%(online)s%(public)s')

        offline_installer_filename = self.offline_installer_filename
        #directory = self.replace_vars(self.directory)
        directory = os.path.join(self.directory, self.package_repository_subdir)

        exe_suffix = ''
        if sys.platform == 'win32':
            exe_suffix = '.exe'

        # if bv_build_installer is in the build tree, use it
        bvi = os.path.join(self.build_directory, 'bin',
                           'bv_build_installer.py')
        if not os.path.exists(bvi):
            # otherwise use the path
            bvi = shutil.which('bv_build_installer.py')
        cmd = [sys.executable, bvi, '-r', directory]
        if installer_filename:
            cmd += ['-i', installer_filename]
            if not offline_installer_filename:
                cmd.append('--online-only')
        if offline_installer_filename:
            from brainvisa.installer import version as bvi_ver
            if [int(x) for x in bvi_ver.version.split('.')] >= [1, 2]:
                cmd += ['-j', offline_installer_filename]

                data_dir = self.get_data_dir()
                if data_dir and data_dir.directory:
                    # Add data directory as an additional repository to allow
                    # binarycreator to find data packages to embed in the
                    # offline installer
                    cmd += ['-f', os.path.join(
                        data_dir.directory,
                        data_dir.package_repository_subdir)]
            else:
                print('warning: bv installer version too old to handle '
                      'offline + online installers at the same time.')
            if not installer_filename:
                cmd.append('--offline-only')
        if not installer_filename and not offline_installer_filename:
            cmd.append('--repository-only')
        cmd += pack_options + ['-p'] + projects + ['-n'] + components
        return cmd

    def make_install_script(self, install_dir, repos_dir, data_repos_dir,
                            temp_dir=None):

        fd, script_fname = tempfile.mkstemp(prefix='install_script',
                                            dir=temp_dir)
        os.close(fd)

        install_dir = self.build_dir.to_target_path(install_dir)

        if not repos_dir.startswith('file://'):
            repos_dir = self.build_dir.to_target_path(repos_dir) \
                        .to_system('uri')

        if data_repos_dir:
            if not data_repos_dir.startswith('file://'):
                data_repos_dir = self.build_dir.to_target_path(data_repos_dir) \
                                 .to_system('uri')

            data_repos_dir_url = ', "%s"' % data_repos_dir
        else:
            data_repos_dir_url = ""



        with open(script_fname, 'w') as f:
            f.write('''var install_dir = "%s";
var repositories = ["%s"%s];

function Controller()
{
    print("controller instanciated");

    installer.currentPageChanged.connect(OnCurrentPageChangedCallback);
    installer.installationStarted.connect(OnInstallationStartedCallback);
    installer.installationFinished.connect(OnInstallationFinishedCallback);
    installer.installationInterrupted.connect(OnInstallationInterruptedCallback);

    installer.autoRejectMessageBoxes;

    installer.setMessageBoxAutomaticAnswer("OverwriteTargetDirectory",
                                           QMessageBox.Yes);

    installer.setMessageBoxAutomaticAnswer("installationError",
                                           QMessageBox.OK);

    installer.setMessageBoxAutomaticAnswer("installationErrorWithRetry",
                                           QMessageBox.Cancel);

    installer.setMessageBoxAutomaticAnswer("AuthorizationError",
                                           QMessageBox.Abort);

    installer.setMessageBoxAutomaticAnswer("OperationDoesNotExistError",
                                           QMessageBox.Abort);

    installer.setMessageBoxAutomaticAnswer("isAutoDependOnError",
                                           QMessageBox.OK);

    installer.setMessageBoxAutomaticAnswer("isDefaultError",
                                           QMessageBox.OK);

    installer.setMessageBoxAutomaticAnswer("isDefaultError",
                                           QMessageBox.OK);

    installer.setMessageBoxAutomaticAnswer("DownloadError",
                                           QMessageBox.Cancel);

    installer.setMessageBoxAutomaticAnswer("archiveDownloadError",
                                           QMessageBox.Cancel);

    installer.setMessageBoxAutomaticAnswer("WriteError",
                                           QMessageBox.OK);

    installer.setMessageBoxAutomaticAnswer("ElevationError",
                                           QMessageBox.OK);

    installer.setMessageBoxAutomaticAnswer("unknown",
                                           QMessageBox.OK);

    installer.setMessageBoxAutomaticAnswer("Error",
                                           QMessageBox.OK);

    installer.setMessageBoxAutomaticAnswer("stopProcessesForUpdates",
                                           QMessageBox.Ignore);

    installer.setMessageBoxAutomaticAnswer("Installer_Needs_To_Be_Local_Error",
                                           QMessageBox.OK);

    installer.setMessageBoxAutomaticAnswer("TargetDirectoryInUse",
                                           QMessageBox.No);

    installer.setMessageBoxAutomaticAnswer("WrongTargetDirectory",
                                           QMessageBox.OK);

    installer.setMessageBoxAutomaticAnswer("AlreadyRunning",
                                           QMessageBox.OK);

    //installer.setMessageBoxAutomaticAnswer("cancelInstallation",
    //                                       QMessageBox.Yes);
}

OnInstallationStartedCallback = function()
{
    print("installation started");
}

OnInstallationFinishedCallback = function()
{
    print("installation ended");
    // This is necessary for windows
    gui.clickButton(buttons.NextButton);
}

OnInstallationInterruptedCallback = function()
{
    print("installation interrupted");
}

OnCurrentPageChangedCallback = function(page)
{
    print("page changed");
}

Controller.prototype.IntroductionPageCallback = function()
{
    print("introduction page");
    installer.setTemporaryRepositories(repositories, true);
    gui.clickButton(buttons.NextButton)
}

Controller.prototype.TargetDirectoryPageCallback = function()
{
    print("target directory page");
    var widget = gui.currentPageWidget(); // get the current wizard page
    widget.TargetDirectoryLineEdit.setText(install_dir);
    print("install directory: " + widget.TargetDirectoryLineEdit.text)
    print("message: " + widget.MessageLabel.text)
    if (widget.WarningLabel)
    {
        print("warning: " + widget.WarningLabel.text)
    }
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ComponentSelectionPageCallback = function()
{
    print("component selection page");
    var widget = gui.currentPageWidget();
    widget.selectAll();
    gui.clickButton(buttons.NextButton);
    //installer.setAutomatedPageSwitchEnabled(true);
}

Controller.prototype.LicenseAgreementPageCallback = function()
{
    print("licence agreement page");
    var widget = gui.currentPageWidget();
    widget.AcceptLicenseRadioButton.setChecked(true);
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.StartMenuDirectoryPageCallback = function()
{
    print("start menu directory page");
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ReadyForInstallationPageCallback = function()
{
    print("ready for installation page");
    gui.clickButton(buttons.CommitButton);
}

Controller.prototype.PerformInstallationPageCallback = function()
{
    print("perform installation page");
    gui.clickButton(buttons.CommitButton);
}

Controller.prototype.FinishedPageCallback = function()
{
    print("finished page");
    gui.clickButton(buttons.FinishButton);
}

''' % (install_dir, repos_dir, data_repos_dir_url))
        return script_fname

    def package(self, options, args):
        #self.test_config(options, args)
        self.process_configuration_lines()

        timeout = self.configuration.general_section.subprocess_timeout
        timeout = getattr(options, 'subprocess_timeout', timeout)

        #directory = self.replace_vars(self.directory)
        directory = os.path.join(self.directory, self.package_repository_subdir)
        print('Building package:', directory)
        print('    from build dir:', self.build_dir.directory)
        self.cleanup_package_dir()
        cmd = self.installer_cmdline()
        print('running:', "'" + "' '".join(cmd) + "'")


        if subprocess32:
            subprocess32.check_call(cmd, cwd=self.build_dir.directory,
                                    env=self.get_environ(),
                                    timeout=timeout)
        else:
            subprocess.check_call(cmd, cwd=self.build_dir.directory,
                                  env=self.get_environ())

    @staticmethod
    def rm_with_empty_dirs(path):
        if os.path.isdir(path):
            shutil.rmtree(path)
        else:
            os.unlink(path)
        d = os.path.dirname(path)
        while d and len(os.listdir(d)) == 0:
            try:
                os.rmdir(d)
            except OSError:
                break
            d = os.path.dirname(d)

    @staticmethod
    def rm_with_empty_dirs_nofail(path):
        try:
            PackageDirectory.rm_with_empty_dirs(path)
        except OSError:
            pass # oh well...

    def cleanup_package_dir(self):
        #directory = self.replace_vars(self.directory)
        directory = os.path.join(self.directory, self.package_repository_subdir)
        dirs = [directory, directory + '_tmp']
        pack_options = self.packaging_options
        if '--skip-repos' not in pack_options \
                and '--skip-existing' not in pack_options:
            for d in dirs:
                if os.path.isdir(d):
                    shutil.rmtree(d)
        if os.path.isdir(directory):
            report_file = os.path.join(directory, 'tests_report.txt')
            if os.path.exists(report_file):
                os.unlink(report_file)
        # erase older repositories
        if '%(date)s' in os.path.join(self._directory,
                                      self._package_repository_subdir):
            real_vars = dict(self.installer_variables())
            real_vars.update(global_installer_datetime())
            vars = dict(real_vars) # copy vars
            vars['date'] = '*'
            my_dir = environmentPathVariablesSubstitution(
                os.path.join(self._directory,
                             self._package_repository_subdir),
                env=self.get_environ()) % real_vars
            dir_pattern = environmentPathVariablesSubstitution(
                self._directory, env=self.get_environ()) % vars
            older_dirs = [d for d in glob.glob(dir_pattern) if d != my_dir]
            older_tmp_dirs = [d for d in glob.glob(dir_pattern + '_tmp')
                              if d != my_dir + '_tmp']
            # check in older repos if they were OK
            repos_to_remove = set()
            for d in older_dirs:
                report_file = os.path.join(d, 'tests_report.txt')
                if os.path.exists(report_file):
                    with open(report_file) as f:
                        report = f.readlines()
                    if report[-1].strip() != 'Tests_result: OK':
                        repos_to_remove.add(d)
                        print('removing older failed repos:', d)
            older_dirs = [d for d in older_dirs if d not in repos_to_remove]
            to_remove = set()
            for d in older_tmp_dirs:
                if not d[:-4] in older_dirs:
                    print('temp repos', d, 'has no real repos')
                    self.rm_with_empty_dirs_nofail(d)
                    to_remove.add(d)
            older_tmp_dirs = sorted([d for d in older_tmp_dirs
                                     if d not in to_remove])
            older_dirs = sorted(older_dirs)
            keep_n_older_repos = int(self.keep_n_older_repos)
            if len(older_dirs) > keep_n_older_repos:
                repos_to_remove.update(
                    older_dirs[:len(older_dirs) - keep_n_older_repos])
            # remove older repos and installs
            vars['date'] = '%(date)s' # keep date pattern as is
            pattern = environmentPathVariablesSubstitution(
                self._directory, env=self.get_environ()) % vars
            pattern = re.escape(pattern)
            # this replace restores the pattern '%(date)s' modified
            # by re.escape()
            pattern = pattern.replace(re.escape('%(date)s'), '%(date)s')
            pattern = re.compile(pattern % {'date': '(.+)'})
            for d in repos_to_remove:
                print('removing:', d)
                self.rm_with_empty_dirs_nofail(d)
                if d + '_tmp' in older_tmp_dirs:
                    print('removing:', d + '_tmp')
                    self.rm_with_empty_dirs_nofail(d + '_tmp')
                infos_file = os.path.join(os.path.dirname(d),
                                          'packages_infos.html')
                if os.path.exists(infos_file):
                    self.rm_with_empty_dirs_nofail(infos_file)
                m = pattern.match(d)
                r_date = m.group(1)
                vars['date'] = r_date
                # find associated installer
                if self.installer_filename:
                    installer = environmentPathVariablesSubstitution(
                        self._installer_filename,
                        env=self.get_environ()) % vars
                    if os.path.exists(installer):
                        print('removing:', installer)
                        self.rm_with_empty_dirs_nofail(installer)
                    if os.path.exists(installer + '.md5'):
                        self.rm_with_empty_dirs_nofail(installer + '.md5')
                    # check for lock file leaved after installer crash
                    lockfile = glob.glob(os.path.join(
                        os.path.dirname(installer), 'lock*.lock'))
                    for lock in lockfile:
                        self.rm_with_empty_dirs_nofail(lock)
                    # on Mac, remove .dmg files and .app directory
                    if sys.platform == 'darwin':
                        if os.path.exists(installer + '.dmg'):
                            self.rm_with_empty_dirs_nofail(installer + '.dmg')
                        if os.path.exists(installer + '.dmg.md5'):
                            self.rm_with_empty_dirs_nofail(
                                installer + '.dmg.md5')
                        if os.path.exists(installer + '.app'):
                            self.rm_with_empty_dirs_nofail(installer + '.app')
                # find associated install
                if self.test_install_dir:
                    install_dir = environmentPathVariablesSubstitution(
                        self._test_install_dir,
                        env=self.get_environ()) % vars
                    if os.path.exists(install_dir):
                        print('removing', install_dir)
                        self.rm_with_empty_dirs_nofail(install_dir)
                    # and tmp dir
                    tmp_dir = os.path.join(os.path.dirname(install_dir), 'tmp')
                    # remove it if empty
                    if os.path.isdir(tmp_dir) \
                            and len(os.listdir(tmp_dir)) == 0:
                        print('removing:', tmp_dir)
                        self.rm_with_empty_dirs_nofail(tmp_dir)


    def install_package(self, options, args):
        #self.test_config(options, args)
        self.process_configuration_lines()

        timeout = self.configuration.general_section.subprocess_timeout
        timeout = getattr(options, 'subprocess_timeout', timeout)

        #directory = self.replace_vars(self.directory)
        directory = os.path.join(self.directory, self.package_repository_subdir)

        if not self.test_install_dir:
            return IGNORED_STEP

        remote_test_install = True if self.remote_test_host_cmd \
                                      and not options.local \
                                      else False

        # Test install directory
        if options.prefix:
            test_install_dir = options.prefix
            remote_test_install_dir = options.prefix
        else:
            test_install_dir = self.test_install_dir
            if remote_test_install and self.remote_test_install_dir:
                remote_test_install_dir = self.remote_test_install_dir
            else:
                remote_test_install_dir = test_install_dir

        # Temporary directory
        tmp_dir = os.path.join(os.path.dirname(test_install_dir), 'tmp')

        # Repository directory
        repos_dir = directory
        if remote_test_install and self.remote_repos_dir:
            remote_repos_dir = self.remote_repos_dir
        else:
            remote_repos_dir = repos_dir

        # Data repository directory
        data_dir = self.get_data_dir()
        if data_dir and data_dir.directory:
            data_repos_dir = os.path.join(
                data_dir.directory,
                data_dir.package_repository_subdir)
            data_repos_dir = self.replace_vars(data_repos_dir)

        else:
            data_repos_dir = ''

        if remote_test_install and self.remote_data_repos_dir:
            remote_data_repos_dir = self.remote_data_repos_dir
            if data_dir is not None:
                remote_data_repos_dir = \
                    os.path.join(remote_data_repos_dir,
                                 data_dir.package_repository_subdir)
        elif data_repos_dir:
            remote_data_repos_dir = data_repos_dir
        else:
            remote_data_repos_dir = None

        use_online_installer = not options.offline \
            and self.installer_filename is not None

        if not use_online_installer \
           and self.offline_installer_filename is not None:
            installer_filename = self.offline_installer_filename
        else:
            installer_filename = self.installer_filename

        if remote_test_install:
            if not use_online_installer \
               and self.remote_offline_installer_filename is not None:
                remote_installer_filename = self.remote_offline_installer_filename
            elif self.remote_installer_filename is not None:
                remote_installer_filename = self.remote_installer_filename
            else:
                remote_installer_filename = installer_filename

        else:
            remote_installer_filename = installer_filename

        print('Installing package:', directory)
        print('    with installer:', remote_installer_filename)
        if(data_repos_dir):
            print('    using data package:', data_repos_dir)
        print('    from build dir:', self.build_dir.directory)
        print('    to:', test_install_dir)
        if remote_test_install:
            print('    remote:', self.remote_test_host_cmd)

        if os.path.isdir(test_install_dir):
            print('removing previous test installation...')
            shutil.rmtree(test_install_dir)

        #if os.path.isdir(tmp_dir):
            #print('removing previous temporary directory...')
            #shutil.rmtree(tmp_dir)

        if not os.path.exists(test_install_dir):
            print('creating test directory...')
            os.makedirs(test_install_dir)

        if not os.path.exists(tmp_dir):
            print('creating temporary directory...')
            os.makedirs(tmp_dir)

        if use_online_installer \
            and (not os.path.isdir(repos_dir) \
                 or (data_repos_dir is not None \
                 and not os.path.isdir(data_repos_dir))):
            # For offline package installation these directories are not
            # necessary
            raise RuntimeError('Some repositories are missing (%s, %s). ' \
                'Installation may fail.' % (repos_dir, data_repos_dir))

        install_script = self.make_install_script(
            remote_test_install_dir,
            remote_repos_dir,
            remote_data_repos_dir,
            temp_dir=tmp_dir)

        cmd = []
        if remote_test_install:
            cmd = shlex.split(self.remote_test_host_cmd)

        if sys.platform == 'darwin':
            # on Mac, the installer is a .app
            remote_installer_filename += '.app/Contents/MacOS/%s' \
                % os.path.basename(remote_installer_filename)
        cmd += [remote_installer_filename] \
               + shlex.split(self.installer_options) \
               + ['--script', self.build_dir.to_target_path(install_script)]
        try:
            print('installing...')
            # the ssh command needs to be converted to a string, some options
            # do not pass when check_call() is used with a list.
            cmd = '"' + '" "'.join([x.replace('"', '\"') for x in cmd]) + '"'
            print(cmd)
            # setup QT_QPA_PLATFORM=minimal envar to avoid need for
            # GUI/X server. Note that if remote_test_host_cmd is used (ssh or
            # other), it will need to re-export this variable in the remote
            # context to be taken into account.
            env = dict(self.get_environ())
            env['QT_QPA_PLATFORM'] = 'minimal'

            if subprocess32:
                subprocess32.check_call(cmd, shell=True, env=env, timeout=timeout)
            else:
                subprocess.check_call(cmd, shell=True, env=env)

            print('done.')
        finally:
            if not options.debug:
                os.unlink(install_script)

    def init_vars(self):
        super(PackageDirectory, self).init_vars()

        self.__init_python_vars()
        self.__init_environ()

    def __init_environ(self):
        env = {}
        # binaries are in bin/real-bin/ (used by some python tests commands)
        env['BRAINVISA_REAL_BIN'] = '/real-bin'

        if not self._property_recursivity.get('remote_test_host_cmd'):
            if self.remote_test_host_cmd \
                and (not self._property_recursivity.get(
                    'remote_test_install_dir')) \
                and self.remote_test_install_dir:
                install_dir = self.remote_test_install_dir
                env['BRAINVISA_PACKAGE_INSTALL_PREFIX'] = install_dir
            elif (not self._property_recursivity.get('test_install_dir')) \
                and self.test_install_dir:
                install_dir = self.test_install_dir
                env['BRAINVISA_PACKAGE_INSTALL_PREFIX'] = install_dir

            if (not self._property_recursivity.get('build_directory')):
                build_dir = self.configuration.buildDirectories.get(
                    self.build_directory)

                if build_dir:
                    if self.remote_test_host_cmd \
                        and (not self._property_recursivity.get(
                            'remote_test_run_data_dir')) \
                        and self.remote_test_run_data_dir:
                        # Add directories to env
                        env["BRAINVISA_TEST_RUN_DATA_DIR"] = \
                            build_dir.to_target_path(self.remote_test_run_data_dir)
                    elif (not self._property_recursivity.get(
                            'test_run_data_dir')) \
                         and self.test_run_data_dir:
                        # Add directories to env
                        env["BRAINVISA_TEST_RUN_DATA_DIR"] = \
                            build_dir.to_target_path(self.test_run_data_dir)

                    if self.remote_test_host_cmd \
                        and (not self._property_recursivity.get(
                            'remote_test_ref_data_dir')) \
                        and self.remote_test_ref_data_dir:
                        # Add directories to env
                        env["BRAINVISA_TEST_REF_DATA_DIR"] = \
                            build_dir.to_target_path(self.remote_test_ref_data_dir)
                    elif (not self._property_recursivity.get(
                            'test_ref_data_dir')) \
                        and self.test_ref_data_dir:
                        # Add directories to env
                        env["BRAINVISA_TEST_REF_DATA_DIR"] = \
                            build_dir.to_target_path(self.test_ref_data_dir)

            if self.remote_test_host_cmd:
                # temporarily change os.environ since expand_shell uses
                # os.path.expandvars(), which use os.environ variables
                cur_env = os.environ
                os.environ = dict(os.environ)
                os.environ.update(env)
                env['BRAINVISA_TEST_REMOTE_COMMAND'] \
                    = self.expand_shell(self.remote_test_host_cmd)
                os.environ = cur_env

        self.update_environ(env)

        return env

    def reset_environ(self):
        super(PackageDirectory, self).reset_environ()
        self.__init_environ()

    def test_package(self, options, args):
        #self.test_config(options, args)
        self.process_configuration_lines()

        timeout = self.configuration.general_section.subprocess_timeout
        timeout = getattr(options, 'subprocess_timeout', timeout)

        if not self.test_install_dir:
            return IGNORED_STEP
        if not self.test_ref_data_dir:
            print("Warning: test_ref_data_dir is not defined; tests may fail.")
        # Create test_run_data_dir and test_ref_data_dir
        if self.test_run_data_dir \
                and not os.path.exists(self.test_run_data_dir):
            os.makedirs(self.test_run_data_dir)
        if self.test_ref_data_dir \
                and not os.path.exists(self.test_ref_data_dir):
            os.makedirs(self.test_ref_data_dir)
        print('Testing package:', self.directory)
        print('    from build dir:', self.build_dir.directory)
        install_dir = self.test_install_dir
        # Add directories to env
        new_env = self.get_environ(dict(os.environ))
        repos_dir = self.replace_vars(
            os.path.join(self.directory,
                         self.package_repository_subdir))
        report_file = os.path.join(repos_dir, 'tests_report.txt')
        if options.ctest_options is not None:
            ctoptions = shlex.split(options.ctest_options)
        else:
            ctoptions = self.ctest_options
        test_res = build.run_and_log_tests(cwd=self.build_dir.directory,
                                           env=new_env, options=ctoptions,
                                           projects=self.projects,
                                           timeout=timeout)
        if test_res:
            status = 'OK'
            for item in six.itervalues(test_res):
                if item['exception'] is not None:
                    status = 'FAILED'
            if os.path.isdir(repos_dir):
                with open(report_file, 'w') as f:
                    f.write('Tests_result: %s\n' % status)
        elif os.path.isdir(repos_dir):
            with open(report_file, 'w') as f:
                f.write('Tests_result: OK\n')
        return test_res

    def testref_package(self, options, args):
        #self.test_config(options, args)
        self.process_configuration_lines()

        timeout = self.configuration.general_section.subprocess_timeout
        timeout = getattr(options, 'subprocess_timeout', timeout)

        if not self.test_install_dir:
            return IGNORED_STEP
        if not self.test_ref_data_dir:
            print("Warning: test_ref_data_dir should be defined to create "
                  "reference files.")
        # Create test_ref_data_dir
        if self.test_ref_data_dir \
                and not os.path.exists(self.test_ref_data_dir):
            os.makedirs(self.test_ref_data_dir)
        if options.make_options is not None:
            ctoptions = shlex.split(options.make_options)
        else:
            ctoptions = self.make_options
        print('Creating test reference files for package:', self.directory)
        print('    from build dir:', self.build_dir.directory)
        install_dir = self.test_install_dir
        # Add directories to env
        new_env = self.get_environ(dict(os.environ))
        test_res = build.run_and_log_testref(cwd=self.build_dir.directory,
                                             env=new_env, options=ctoptions,
                                             timeout=timeout)
        return test_res

    def expand_shell(self, line):
        ''' Allow shell commands expressions $(command arg) in string
        '''
        patt = re.compile(r'\$\(([^\)]+)\)')
        expressions = patt.split(os.path.expandvars(line))
        new_line = expressions.pop(0)
        while expressions:
            expr = expressions.pop(0)
            text = subprocess.check_output(expr, shell=True).strip()
            new_line += text
            new_line += expressions.pop(0)
        return ' '.join(shlex.split(new_line))


class PublicationDirectory(brainvisa_cmake.configuration.DirectorySection,
                           brainvisa_cmake.configuration.ConfigVariableParser):

    _path_variables = set(('package_directory',
                           'stdout_file', 'stderr_file'))
    _variables_with_replacements = set(('directory', 'directory_id',
                                        'publication_commands'))
    _variables_with_env_only_replacements = set(('env',))
    _validAdditiveOptions = set(('publication_commands', ))
    _validOptions = set(('build_condition', ))
    _validOptions.update(_variables_with_replacements)
    _validOptions.update(_variables_with_env_only_replacements)
    _validOptions.update(_path_variables)
    _validOptions.update(_validAdditiveOptions)

    def __init__(self, directory, configuration):
        super(PublicationDirectory, self).__init__()

        self.configuration = configuration
        self.directory = directory
        self.package_directory = ''
        self.pathvars = None
        self.default_steps = []
        self.publication_commands = []
        self.directory_id = ''
        self.env = {}

    def init_vars(self):
        super(PublicationDirectory, self).init_vars()

        self.__init_python_vars()

    def __init_python_vars(self):
        package_dir = self.get_package_dir()

        # Add same python variables than pack section
        self.update_python_vars(package_dir.get_python_vars())

    def get_package_dir(self):
        if not hasattr(self, 'package_dir'):
            package_dirs = get_matching_dirs(
                self.configuration.packageDirectories.values(),
                self.package_directory)
            if len(package_dirs) == 0:
                raise RuntimeError(
                    'Package directory: referenced package directory "%s" does '
                    'not exist' % self.package_directory)
            elif len(package_dirs) > 1:
                raise RuntimeError(
                    'Package directory: referenced package directory "%s" '
                    'must match a unique package directory. Matches %d '
                    'directories %s' % (self.package_directory,
                                        len(package_dirs),
                                        str(package_dirs)))
            else:
                self.package_dir = package_dirs[0]

        return self.package_dir

    def get_build_dir(self):
        return self.get_package_dir().get_build_dir()

    def set_dependencies(self):
        pack_section = self.get_package_dir()

        if pack_section is not None:
            pack_section = [(pack_section, 'pack')]
        else:
            pack_section = []

        self.depend_on_sections = {
            'publish': pack_section,
        }

    #def test_config(self, options, args):
        #package_dir = self.get_package_dir()
        #build_dir = package_dir.get_build_dir()

    def info(self):
        print('Publication package directory: "' + self._directory + '"')
        print('  Real publication package directory:', self.directory)
        print('  Package directory:', self.package_directory)
        print('  Build directory:', self.get_package_dir().build_directory)

    def publish_package(self, options, args):
        #self.test_config(options, args)
        self.process_configuration_lines()

        timeout = self.configuration.general_section.subprocess_timeout
        timeout = getattr(options, 'subprocess_timeout', timeout)

        package_dir = self.get_package_dir()
        if not package_dir:
            return IGNORED_STEP

        print('Running commands for package publication',
              self.package_directory, '=>', self.directory)

        # These values can only be added to python variables when they are
        # completely solved from the command
        self.update_python_vars({'package_directory': self.package_directory,
                                 'publication_directory': self.directory})

        if not self.publication_commands:
            # Default publication command
            self.publication_commands = [
                'cmake -E copy_directory '
                '"%(package_directory)s/brainvisa-installer" '
                '"%(package_directory)s/packages" '
                '"%(package_directory)s/packages_tmp" '
                '"%(publication_directory)s"']

        env = self.get_environ()
        for c in self.publication_commands:
            command = shlex.split(c)
            system_output_on_error(command, env = env, timeout=timeout)
