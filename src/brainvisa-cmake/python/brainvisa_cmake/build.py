# -*- coding: utf-8 -*-

"""Handling of build-directory configuration."""

import datetime
from fnmatch import fnmatchcase
import glob
import json
import os
import pathlib
import shlex
import shutil
import subprocess
import sys
import tempfile
import time

import brainvisa_cmake.brainvisa_projects as brainvisa_projects
import brainvisa_cmake.configuration
from brainvisa_cmake.environment import environmentPathVariablesSubstitution
from brainvisa_cmake.path import DefaultPathConverterRegistry
from brainvisa_cmake.path import get_host_path_system
from brainvisa_cmake.path import Path
from brainvisa_cmake.path import SystemPathConverter
import brainvisa_cmake.sources
from brainvisa_cmake.subprocess import system
from brainvisa_cmake.subprocess import system_output_on_error
from brainvisa_cmake.version import version as brainvisa_cmake_version
from brainvisa_cmake.version_number import VersionNumber
from brainvisa_cmake.version_number import version_format_short


if os.path.exists(sys.argv[0]):
    this_script = sys.argv[0]
else:
    this_script = None
    for p in os.environ.get('PATH', '').split(os.pathsep) + [os.curdir]:
        s = os.path.join(p, sys.argv[0])
        if os.path.exists(s):
            this_script = s
            break
if this_script:
    this_script = os.path.abspath(this_script)
    python_modules = os.path.join(
        os.path.dirname(os.path.dirname(this_script)), 'python')
    if os.path.isdir(python_modules):
        sys.path.insert(0, python_modules)

if this_script:
    cmake_root = os.path.join(os.path.dirname(this_script),
                              '..', 'share', 'brainvisa-cmake-%s' %
                              str(VersionNumber(
                                    brainvisa_cmake_version,
                                    version_format_short)),
                              'cmake')


class ComponentsConfigParser(brainvisa_cmake.configuration.DirectorySection):

    def __init__(self, directory, configuration):
        super(ComponentsConfigParser, self).__init__()
        self.configuration = configuration
        self.directory = directory
        self.configurationLines = []
        self.projects = set()
        self.components = {}
        self._configuration_lines_processed = False

    def process_configuration_lines(self):
        if not self._configuration_lines_processed:
            if self.configuration.verbose:
                print('Processing build directory %s' % self.directory)
            for line in self.configurationLines:
                if '=' in line:
                    continue
                first, rest = line.split(None, 1)
                if first in ('directory', '+'):
                    directory = environmentPathVariablesSubstitution(
                            rest.strip(), env=self.get_environ())
                    pinfo = brainvisa_projects.read_project_info(
                        directory,
                        # version_format=version_format_short
                    )
                    if pinfo:
                        project, component, version, build_model = pinfo
                        if self.configuration.verbose:
                            print('    adding component %s version %s from %s'
                                  % (component, version, directory))
                        self.components[component] = (
                            directory, version, '.'.join(str(i) for i in version._version_numbers[:2]), build_model)
                    else:
                        print('WARNING: directory %s will be ignored because project_info.cmake, python/*/info.py or */info.py cannot be found' % directory)
                elif first in ('brainvisa_exclude', '-'):
                    component_def = rest.split(None, 1)
                    componentPattern, versionPattern = (
                        component_def + ['*'])[:2]
                    components \
                        = brainvisa_projects.find_components(componentPattern)
                    if len(components) == 0 \
                            and component_def[0] in self.components:
                        components = [component_def[0]]
                    for component in components:
                        dir_version = self.components.get(component)
                        if dir_version:
                            dir, selected_version, component_version, \
                               build_model = dir_version
                            if fnmatchcase(str(selected_version),
                                           versionPattern):
                                if self.configuration.verbose:
                                    print('    removing component %s from %s'
                                          % (component, dir))
                                del self.components[component]
                elif first == 'brainvisa' \
                        or (first
                            in brainvisa_projects.project_per_component) \
                        or (first in brainvisa_projects.components_per_group) \
                        or (first
                            in brainvisa_projects.components_per_project) \
                        or '*' in first:
                    if first == 'brainvisa':
                        l = rest.split(None, 2)
                        componentPattern, versionPattern, sourceDirectory = l
                    else:
                        l = rest.split(None, 1)
                        componentPattern = first
                        versionPattern, sourceDirectory = l
                    sourceDirectory = environmentPathVariablesSubstitution(
                            sourceDirectory, env=self.get_environ())
                    components_sources_json = os.path.join(sourceDirectory,
                            'components_sources.json')
                    if 'PIXI_PROJECT_ROOT' in os.environ and not os.path.exists(components_sources_json):
                        components_sources = {}
                        for component in os.listdir(sourceDirectory):
                            components_sources[component] = {"current": [component, None]}
                    else:
                        with open(components_sources_json) as f:
                            components_sources = json.load(f)
                    projects_set = brainvisa_projects.ProjectsSet()
                    projects_set.add_sources_list(components_sources)
                    possible_components = set(
                        projects_set.find_components(componentPattern))
                    for component in possible_components:
                        for version, directory_model \
                                in components_sources.get(component, {}).items():
                            if isinstance(directory_model, list):
                                directory, build_model = directory_model
                            else:
                                directory = directory_model
                                build_model = None
                            directory = os.path.join(
                                sourceDirectory, directory)
                            if fnmatchcase(version, versionPattern):
                                pinfo = brainvisa_projects.read_project_info(
                                    directory,
                                    # version_format=version_format_short
                                )
                                if pinfo:
                                    project, component, component_version, \
                                        build_model = pinfo
                                    if self.configuration.verbose:
                                        print('    adding component %s version %s from %s' \
                                            % (component, component_version, directory))
                                    self.components[component] = (
                                        directory, component_version, '.'.join(str(i) for i in component_version._version_numbers[:2]), build_model)
                                else:
                                    print('WARNING: directory %s will be ignored because project_info.cmake, python/*/info.py or */info.py cannot be found'
                                          % directory)
                elif first == 'pip':
                    if '=' in rest:
                        module, version = rest.split(None, 1)
                    else:
                        module = rest
                        version = None
                    installed_json = os.path.join(
                        self.directory, 'bv_maker_install.json')
                    if os.path.exists(installed_json):
                        with open(installed_json) as f:
                            installed = json.load(f)
                    else:
                        installed = {}
                    pip_installed = installed.setdefault('pip', {})
                    if module not in pip_installed:
                        command = [os.path.join(
                            self.directory, 'bin', 'pip'), 'install',
                            ('%s==%s' % (module, version) if version
                             else module)]
                        print('Running:', ' '.join(command))
                        subprocess.check_call(command)
                        pip_installed[module] = version
                        with open(installed_json, 'w') as f:
                            json.dump(installed, f)
                else:
                    SyntaxError()
            projects = set(brainvisa_projects.project_per_component.get(i, i)
                           for i in self.components)
            self.projects = [i for i in brainvisa_projects.ordered_projects
                             if i in projects]
            self.projects.extend(projects - set(self.projects))
            self._configuration_lines_processed = True
            if self.configuration.verbose:
                print('Build directory %s parsing done.' % self.directory)


class BuildDirectory(ComponentsConfigParser,
                     brainvisa_cmake.configuration.ConfigVariableParser):

    _path_variables = set(('directory',
                           'stdout_file', 'stderr_file',
                           'test_ref_data_dir', 'test_run_data_dir'))
    _variables_with_replacements = set(('make_options', 'cmake_options',
                                        'ctest_options', 'directory_id',
                                        'doc_timeout'))
    _variables_with_env_only_replacements = set(('cross_compiling_prefix',
                                          'cross_compiling_target_system',
                                          'cross_compiling_to_target_path_cmd',
                                          'env',
                                          'test_ref_data_dir',
                                          'test_run_data_dir'))
    _validAdditiveOptions = set(('make_options', 'cmake_options', 'env',
                                 'default_steps', 'ctest_options'))
    _validOptions = set((
        'build_type',
        'packaging_thirdparty',  # obsolete but kept for compatibility
        'build_condition',
        'clean_config',
        'clean_build',
    ))
    _validOptions.update(_validAdditiveOptions)
    _validOptions.update(_variables_with_replacements)
    _validOptions.update(_variables_with_env_only_replacements)
    _validOptions.update(_path_variables)

    sitecustomize_content = '''import os, site
site.addsitedir(os.path.dirname(__file__))
'''

    def __init__(self, directory, configuration):
        super(BuildDirectory, self).__init__(directory, configuration)
        # self.configurationDirectories = []
        self.build_type = ''
        self.make_options = []
        self.cmake_options = []
        self.packaging_thirdparty = ''  # obsolete but kept for compatibility
        self.cross_compiling_prefix = ''
        self.cross_compiling_target_system = ''
        self.cross_compiling_to_target_path_cmd = ''
        self.clean_commands = True
        self.default_steps = ['configure', 'build']
        self.clean_config = 'OFF'
        self.clean_build = 'OFF'
        self.ctest_options = []
        self.directory_id = ''
        self.env = {}
        self.test_ref_data_dir = ''
        self.test_run_data_dir = tempfile.gettempdir()
        self.doc_timeout = None

    def addConfigurationLine(self, line):
        # Supported lines in bv_maker.cfg for [ build ... ]:
        #    default_steps [info] [configure] [build] [doc] [test]
        #    directory <directory>
        #    brainvisa <component_pattern> <version_pattern> <source_directory>
        #    brainvisa_exclude <component_pattern> [<version_pattern>]
        #    + <directory>
        #    - <component_pattern> [<version_pattern>]
        #    <component_pattern> <version_pattern> <source_directory>
        if brainvisa_cmake.configuration.ConfigVariableParser.addConfigurationLine(self, line):
            pass
        else:
            line = os.path.expandvars(line)
            if line[0] == '+':
                if '*' in line:
                    raise SyntaxError()
        self.configurationLines.append(line)

    def set_dependencies(self):
        self.depend_on_sections = {
            'configure': [(d, 'sources', brainvisa_cmake.sources.SourceDirectory.dep_condition)
                          for d in
                          self.configuration.sourcesDirectories.values()],
            'build': [(self, 'configure')],
            'doc': [(self, 'build')],
            'test': [(self, 'build')],
            'testref': [(self, 'build')],
        }

    def target_system(self):
        if self.cross_compiling_target_system:
            return self.cross_compiling_target_system
        elif self.cross_compiling_prefix:
            if 'mingw' in self.cross_compiling_prefix:
                # Try to split target prefix
                cross_compiling_info = self.cross_compiling_prefix.split('-')

                if len(cross_compiling_info) == 3 \
                   and cross_compiling_info[0] == 'x86_64':
                       return 'win64'

                return 'win32'
            else:
                raise RuntimeError('Unable to determine target cross '
                                   'compilation system. Please set '
                                   'cross_compiling_target_system option in '
                                   ' build section of your configuration file.')
        else:
            # Target system is the host system
            return sys.platform

    def to_target_path(self, path):
        '''
            Get target system path from path
        '''
        host_path_system = get_host_path_system()
        if not isinstance(path, Path):
            path = Path(path, host_path_system)

        target_path_system = get_target_path_system(self.target_system())
        if host_path_system != target_path_system:
            if not DefaultPathConverterRegistry().get((host_path_system,
                                                       target_path_system)):
                if self.cross_compiling_to_target_path_cmd:
                    # Register host to target conversion command
                    cmd = shlex.split(self.cross_compiling_to_target_path_cmd)
                elif host_path_system == 'linux' \
                    and target_path_system == 'windows':
                    # Default cross compilation try to use winepath command
                    # to convert pathes
                    cmd = ['winepath', '-w']
                else:
                    raise RuntimeError('No known conversion between %s and %s '
                                       'path systems. Please set '
                                       '\'cross_compiling_to_target_path_cmd\' '
                                       'using an available command to do the '
                                       'conversion'
                                       % (host_path_system, target_path_system))

                SystemPathConverter(host_path_system,
                                    target_path_system,
                                    cmd)

            if target_path_system == 'windows':
                # If target path system is windows,
                # we prefer to use the windows alternative with slashes
                target_path_system = 'windows_alt'

            return path.to_system(target_path_system)

        else:
            return path

    def configure(self, options, args):
        self.process_configuration_lines()

        timeout = self.configuration.general_section.subprocess_timeout
        timeout = getattr(options, 'subprocess_timeout', timeout)
        if timeout is not None:
            timeout = float(timeout)

        # Order of projects and components is important for dependencies
        sortedProjects = [p for p in brainvisa_projects.ordered_projects
                          if p in self.projects]
        sortedComponents = []
        components = set(self.components)
        for project in sortedProjects:
            for component \
                    in brainvisa_projects.components_per_project[project]:
                if component in components:
                    sortedComponents.append(component)
                    components.remove(component)
        sortedComponents.extend(components)

        if not os.path.exists(self.directory):
            os.makedirs(self.directory)

        if options.clean or self.clean_config.upper == 'ON':
            my_path = os.path.dirname(sys.argv[0])
            bv_clean = os.path.join(my_path, 'bv_clean_build_tree')
            print('cleaning build tree', self.directory)
            # clean and remove empty dirs. Don't use -b option here
            # because configuration has to be done first.
            subprocess.call([sys.executable, bv_clean, '-d', self.directory],
                            env=self.get_environ())

        # Create a sitecustomize Python package that imports all modules it
        # contains during Python startup. This is mainly used to modify
        # sys.path to include pure Python components source (see module
        # brainvisa_cmake.build_models.pure_python). This package is used only
        # in build directory, it is not installed in packages (to date there is
        # one exception to this in axon component, see Axon's CMakeLists.txt).
        if 'CONDA_PREFIX' in os.environ:
            python_version = f'{sys.version_info.major}.{sys.version_info.minor}'
            python_directory = f'lib/python{python_version}/site-packages'
        else:
            python_directory = 'python'
        sitecustomize_dir = os.path.join(
            self.directory, python_directory, 'sitecustomize')
        if not os.path.exists(sitecustomize_dir):
            os.makedirs(sitecustomize_dir)
        with open(os.path.join(sitecustomize_dir, '__init__.py'), 'w') as f:
            f.write(self.sitecustomize_content)
        # Remove existing sitecustomize.py (was generated by older Axon)
        for i in glob.glob(sitecustomize_dir + '.py*'):
            os.remove(i)

        if not os.path.exists(self.directory):
            os.makedirs(self.directory)

        bin = pathlib.Path(self.directory) / 'bin'
        bin.mkdir(exist_ok=True)
        
        brainvisa_cmake_root = None
        src = os.environ.get('CASA_SRC')
        if src:
            brainvisa_cmake_root = pathlib.Path(__file__).parent.parent.parent
            if not brainvisa_cmake_root.exists() \
                    or not str(brainvisa_cmake_root).startswith(str(src)):
                src = pathlib.Path(src)
                for i in [src / 'brainvisa-cmake'] + [p for p in (src / 'development' / 'brainvisa-cmake').glob('*')]:
                    if i.exists() and i.is_dir():
                        brainvisa_cmake_root = i
                        break
        if not brainvisa_cmake_root:
            brainvisa_cmake_root = pathlib.Path(__file__).parent.parent.parent

        for f in ('bv_env', 'bv_env.sh', 'bv_unenv', 'bv_unenv.sh'):
            path = bin / f
            path.unlink(missing_ok=True)
            path.symlink_to(os.path.relpath(brainvisa_cmake_root / 'bin' / f, bin))

        cross_compiling_directories = {}
        for k, s in self.configuration.sourcesDirectories.items():
            if s.cross_compiling_dirs is not None:
                if len(self.cross_compiling_prefix) > 0:
                    cross_compiling_dir = \
                        s.cross_compiling_dirs.get(
                            self.cross_compiling_prefix)

                    if cross_compiling_dir is not None:
                        cross_compiling_directories[s.directory] = cross_compiling_dir

        self.buildModelPerComponent = {}
        for component in sortedComponents:
            # find build model
            build_model = self.components[component][3]
            if build_model is None:
                build_model = brainvisa_projects.info_per_component.get(
                    component, {}).get('build_model')
            if build_model is not None:
                build_model_class = getattr(__import__(
                    'brainvisa_cmake.build_models',
                    fromlist=['pure_python'], level=0),
                    build_model)
                build_model = build_model_class(
                    component, self.components[component][0], self,
                    cross_compiling_directories, options=options, args=args)
                self.buildModelPerComponent[component] = build_model

        cmakeFile = os.path.join(self.directory, 'bv_maker.cmake')
        with open(cmakeFile, 'w') as out:
            print('cmake_policy( SET CMP0074 NEW )', file=out)
            print(f'set( BRAINVISA_SOURCES_brainvisa-cmake "{brainvisa_cmake_root}" )',
                  file=out)
            print('set( CMAKE_PREFIX_PATH "${BRAINVISA_SOURCES_brainvisa-cmake}" ${CMAKE_PREFIX_PATH} )',
                  file=out)
            print('set( BRAINVISA_PROJECTS', ' '.join(
                sortedProjects), 'CACHE STRING "BrainVISA Projects list" FORCE )',
                file=out)
            print('set( _BRAINVISA_PROJECTS', ' '.join(
                sortedProjects), 'CACHE STRING "BrainVISA Projects list" FORCE )',
                file=out)
            print('set( BRAINVISA_COMPONENTS',
                  ' '.join(sortedComponents),
                  'CACHE STRING "BrainVISA components list" FORCE )',
                  file=out)
            print('set( _BRAINVISA_COMPONENTS',
                  ' '.join(sortedComponents),
                  'CACHE STRING "BrainVISA components list" FORCE )',
                  file=out)
            print(file=out)
            for component, directory_version_model in self.components.items():
                directory, selected_version, version, build_model = directory_version_model
                if component in self.buildModelPerComponent:
                    print('set( BRAINVISA_SOURCES_' + component + ' "' \
                        + cmake_path(self.directory ) + '/build_files/' \
                        + component + '_src' \
                        + '" CACHE STRING "Sources directory for component ' \
                        + component + '" FORCE )',
                        file=out)
                else:
                    print('set( BRAINVISA_SOURCES_' + component + ' "' \
                        + cmake_path(directory) \
                        + '" CACHE STRING "Sources directory for component ' \
                        + component + '" FORCE )',
                        file=out)
                print('set( ' + component + '_DIR "' \
                    + cmake_path(self.directory ) + '/share/' + component + \
                    '-' + version + \
                    '/cmake" CACHE STRING "Directory used for find_package( ' + \
                    component + \
                    ' )" FORCE )',
                    file=out)
                print('set( ' + component + '_VERSION "' + version + '" )',
                      file=out)
            print('set(PYTHON_INSTALL_DIRECTORY python)', file=out)
            print('if( DEFINED PIXI )',file=out)
            print('    include( "${PIXI}/src/brainvisa-cmake/cmake/conda.cmake" )',
                  file=out)
            print('endif()', file=out)

        cmakeLists = os.path.join(self.directory, 'CMakeLists.txt')
        with open(cmakeLists, 'w') as out:
            print(f'''
cmake_minimum_required( VERSION 3.20 )
set( CMAKE_PREFIX_PATH "${{CMAKE_BINARY_DIR}}" ${{CMAKE_PREFIX_PATH}} )
project( "Brainvisa" )
include( "{brainvisa_cmake_root}/cmake/brainvisa-compilation.cmake" )
''', file=out)

        components_info = {}
        for component, directory_version_model in self.components.items():
                directory, version, version_str, build_model = directory_version_model
                components_info[component] = dict(
                    version=str(version),
                    directory=directory,
                    build_model=build_model or 'cmake',
                )
        with open(os.path.join(self.directory, 'components_info.json'), 'w') as out:
            json.dump(components_info, out, indent=4)

        exe_suffix = ''
        if sys.platform == 'win32':
            command_base = ['cmake', '-G', 'MSYS Makefiles']
            exe_suffix = '.exe'
        else:
            command_base = ['cmake']

        command_options = list(self.cmake_options)
        command_options += ['-DCMAKE_BUILD_TYPE:STRING=' + self.build_type]
        if self.packaging_thirdparty.upper() == 'ON':
            print('ERROR: the packaging_thirdparty option is no longer '
                  'supported, it will be ignored.')

        config_dir = cmake_path(self.directory)

        for component, build_model \
                in self.buildModelPerComponent.items():
            build_model.configure()

        # set bv_maker path, so that cmake finds its modules
        os.environ['PATH'] = os.path.dirname(this_script) + os.pathsep \
            + os.getenv('PATH')

        # cross compilation options
        cross_compiling_prefix = self.cross_compiling_prefix.strip()
        if len(cross_compiling_prefix) > 0:
            cross_compiling_prefix_path = os.path.join( cmake_root,
                                                        'toolchains',
                                                        cross_compiling_prefix )
            cross_compiling_options = ['-DBRAINVISA_CMAKE_OPTIONS:STRING=' \
                                       'CMAKE_CROSSCOMPILING;COMPILER_PREFIX;' \
                                       'CMAKE_TOOLCHAIN_FILE', \
                                       '-DCOMPILER_PREFIX:STRING=%s' % \
                                       self.cross_compiling_prefix.strip(), \
                                       '-DCMAKE_CROSSCOMPILING:BOOL=ON']
            cross_compiling_toolchain_path = os.path.join(
                                                cross_compiling_prefix_path,
                                                'toolchain.cmake' )

            cross_compiling_init_cache_path = os.path.join(
                                                cross_compiling_prefix_path,
                                                'init-cache.cmake' )
            #print("=== cross_compiling_prefix:", cross_compiling_prefix, "===")
            #print("=== cross_compiling_prefix_path:", cross_compiling_prefix_path, "===")
            #print("=== cross_compiling_toolchain_path:", cross_compiling_toolchain_path, "===")
            #print("=== cross_compiling_init_cache_path:", cross_compiling_init_cache_path, "===")
            if os.path.exists( cross_compiling_toolchain_path ):
                cross_compiling_options += ['-DCMAKE_TOOLCHAIN_FILE:PATH=%s' % \
                                            cmake_path(
                                              cross_compiling_toolchain_path),]

            if os.path.exists( cross_compiling_init_cache_path ):
                cross_compiling_options += ['-C',
                                            cmake_path(
                                              cross_compiling_init_cache_path),]
            #print('cross compiling using toolchain:', cross_compiling_prefix)
            #print('  with options:', *cross_compiling_options)
        else:
            cross_compiling_options = []

        # special case: if bv-cmake is part of the build directory, run cmake
        # in 2 passes: once to reinstall bv-cmake from sources, and a second
        # time to actually configure all projects using the newly installed
        # bv-cmake.
        if 'brainvisa-cmake' in self.components:
            print('=== bootstraping brainvisa-cmake project ===')
            bvcmake_dir = os.path.join(self.directory, 'brainvisa-cmake')
            if not os.path.exists(bvcmake_dir):
                os.makedirs(bvcmake_dir)
            # pass it Qt version if we have any info
            bvcmake_options = []
            qt_opt = [x for x in self.cmake_options
                      if x.startswith('DESIRED_QT_VERSION')]
            if qt_opt:
                qt_opt = qt_opt[0].split('=')[1].strip()
                bvcmake_options.append('-DDESIRED_QT_VERSION=%s' %qt_opt)
            elif os.path.exists(os.path.join(self.directory, 'CMakeCache.txt')):
                with open(os.path.join(self.directory, 'CMakeCache.txt')) as f:
                    for l in f.readlines():
                        if l.startswith('DESIRED_QT_VERSION:'):
                            qt_opt = l.split('=')[1].strip()
                            bvcmake_options.append(
                                '-DDESIRED_QT_VERSION=%s' %qt_opt)
            system(cwd=bvcmake_dir,
                   *(command_base
                     + [self.components['brainvisa-cmake'][0],
                        '-DBRAINVISA_CMAKE_BUILD_TYPE=brainvisa-cmake-only',
                        '-DCMAKE_INSTALL_PREFIX=%s' % self.directory]
                     + bvcmake_options),
                     env=self.get_environ(),
                     timeout=timeout)
            system(cwd=bvcmake_dir, *['make', 'install'],
                   env=self.get_environ(),
                   timeout=timeout)
            print('=== now configuring all other projects ===')
            # run with this local bv-cmake environment
            system(cwd=self.directory,
                   *(command_base
                     + command_options
                     + cross_compiling_options
                     + ["-DBRAINVISA_CMAKE_BUILD_TYPE=no-brainvisa-cmake"]
                     + [config_dir]),
                   env=self.get_environ(),
                   timeout=timeout)
        else:
            # run cmake in a regular way
            system(cwd=self.directory, *( command_base
                                        + command_options
                                        + cross_compiling_options
                                        + [config_dir]),
                   env=self.get_environ(),
                   timeout=timeout)


        # After a first configuration, the global version file of the build
        # directory has been generated, and package directories variables,
        # must be updated
        for p in list(self.configuration.packageDirectories.values()) \
               + list(self.configuration.publicationDirectories.values()):
            if p.get_build_dir() is self:
                version = self.get_version()
                if version:
                    p.update_python_vars({'version': version})

    def build(self, options, args):
        self.process_configuration_lines()

        # It is crucial that we do not run 'make' with spurious
        # libraries in LD_LIBRARY_PATH, because 'make' has no safeguard
        # against it.
        check_ld_library_path_error(fatal=False)

        timeout = self.configuration.general_section.subprocess_timeout
        timeout = getattr(options, 'subprocess_timeout', timeout)
        if timeout is not None:
            timeout = float(timeout)

        if options.clean or self.clean_build.upper() == 'ON':
            if self.clean_commands:
                clean_opts = ['-b']
            else:
                clean_opts = []
            my_path = os.path.dirname(sys.argv[0])
            bv_clean = os.path.join(my_path, 'bv_clean_build_tree')
            print('cleaning build tree', self.directory)
            # don't remove empty dirs here since configure may have created
            # directories which will be used during build
            subprocess.call(
                [sys.executable, bv_clean] + clean_opts + [self.directory],
                env=self.get_environ())

        print('Building directory:', self.directory)
        system(cwd=self.directory, *(['make'] + self.make_options),
               env=self.get_environ(),
               timeout=timeout)

        # make / update run scripts/symlinks from a container
        if os.environ.get('CASA_SYSTEM'):
            try:
                casa_distro = 'casa_distro'
                casa_distro = shutil.which(casa_distro)
                if not casa_distro:
                    casa_distro = shutil.which(
                        'casa_container')
                if casa_distro:
                    casa_distro = os.path.dirname(os.path.dirname(
                        os.path.realpath(casa_distro)))
                    script = os.path.join(
                        casa_distro, 'share', 'scripts',
                        'casa_build_host_links')
                    if os.path.exists(script):
                        print('updating run scripts for casa-distro')
                        env = dict(os.environ)
                        if 'PYTHONPATH' in env:
                            pypath = ':'.join(
                                [os.path.join(casa_distro, 'python'),
                                 env['PYTHONPATH']])
                            env['PYTHONPATH'] = pypath
                        else:
                            env['PYTHONPATH'] = os.path.join(casa_distro,
                                                             'python')
                        subprocess.call([sys.executable, script], env=env)
            except Exception as e:
                print(e)
                pass

    def doc(self):
        self.process_configuration_lines()

        print('Building docs in directory:', self.directory)
        timeout = self.doc_timeout
        if timeout is None:
            timeout = self.configuration.general_section.subprocess_timeout
        if timeout is not None:
            timeout = float(timeout)
        system(cwd=self.directory, *
               (['make'] + self.make_options + ['doc']),
               env=self.get_environ(),
               timeout=timeout)

    def init_vars(self):
        super(BuildDirectory, self).init_vars()

        self.__init_python_vars()
        self.__init_environ()

    def __init_python_vars(self):
        if not self._property_recursivity.get('directory'):
            build_system = self.target_system()
            self.update_python_vars({'os': build_system})

    def __init_environ(self):
        env = {}

        # During environment initialization, we need skip property
        # mechanims
        if (not self._property_recursivity.get('test_run_data_dir')) \
           and self.test_run_data_dir:
            # Add directories to env
            env["BRAINVISA_TEST_RUN_DATA_DIR"] = self.to_target_path(
                self.test_run_data_dir)
        if (not self._property_recursivity.get('test_ref_data_dir')) \
           and self.test_ref_data_dir:
            # Add directories to env
            env["BRAINVISA_TEST_REF_DATA_DIR"] = self.to_target_path(
                self.test_ref_data_dir)

        self.update_environ(env)

    def reset_environ(self):
        super(BuildDirectory, self).reset_environ()
        self.__init_environ()

    def test(self, options, args):
        self.process_configuration_lines()

        timeout = self.configuration.general_section.subprocess_timeout
        timeout = getattr(options, 'subprocess_timeout', timeout)
        if timeout is not None:
            timeout = float(timeout)

        if options.ctest_options is not None:
            ctoptions = shlex.split(options.ctest_options)
        else:
            ctoptions = self.ctest_options
        print('Testing directory:', self.directory)
        if not self.test_ref_data_dir:
            print("Warning: test_ref_data_dir is not defined; tests may fail.")
        env = self.get_environ()
        # Create test_run_data_dir and test_ref_data_dir
        if self.test_run_data_dir:
            if not os.path.exists(self.test_run_data_dir):
                os.makedirs(self.test_run_data_dir)
        if self.test_ref_data_dir:
            if not os.path.exists(self.test_ref_data_dir):
                os.makedirs(self.test_ref_data_dir)
        return run_and_log_tests(cwd=self.directory, options=ctoptions,
                                 env=env,
                                 timeout=timeout)

    def testref(self, options, args):
        self.process_configuration_lines()

        timeout = self.configuration.general_section.subprocess_timeout
        timeout = getattr(options, 'subprocess_timeout', timeout)
        if timeout is not None:
            timeout = float(timeout)

        if options.make_options is not None:
            ctoptions = shlex.split(options.make_options)
        else:
            ctoptions = self.make_options
        print('Creating test reference data for directory:', self.directory)
        if not self.test_ref_data_dir:
            print("Warning: test_ref_data_dir should be defined to create "
                  "reference files.")
        env = self.get_environ()
        # Create test_ref_data_dir
        if self.test_ref_data_dir:
            if not os.path.exists(self.test_ref_data_dir):
                os.makedirs(self.test_ref_data_dir)
        return run_and_log_testref(cwd=self.directory, options=ctoptions,
                                   env=env,
                                   timeout=timeout)

    def info(self):
        self.process_configuration_lines()
        print('Build directory: "' + self.directory + '"')
        for component, directory_version_model \
                in self.components.items():
            directory, selected_version, version, build_model \
                = directory_version_model
            print('  %s (%s) <- %s' % (component, version, directory))

    def get_version(self):
        bvconf = os.path.join(self.directory,
                              'python', 'brainvisa', 'config.py')
        fullVersion = None

        if os.path.exists(bvconf):
            ver = {}
            try:
                with open(bvconf) as f:
                    code = compile(f.read(), bvconf, 'exec')
                    exec(code, ver, ver)
                fullVersion = ver.get('fullVersion', fullVersion)
            except ImportError:
                pass

        return fullVersion


class VirtualenvDirectory(BuildDirectory):

    '''
    It does the samething with the BuildDirectory
    with additional virtualenv init.
    '''

    def __init__(self, directory, configuration):
        super(VirtualenvDirectory, self).__init__(directory, configuration)
        self.clean_commands = False

    def configure(self, options, args):
        self.virtualenv_command(self.directory)
        super(VirtualenvDirectory, self).configure(options, args)

    def which(self, program):
        def is_exe(fpath):
            return os.path.exists(fpath) and os.access(fpath, os.X_OK)

        def ext_candidates(fpath):
            yield fpath
            for ext in os.environ.get("PATHEXT", "").split(os.pathsep):
                yield fpath + ext
        fpath, fname = os.path.split(program)
        if fpath:
            if is_exe(program):
                return program
        else:
            for path in os.environ["PATH"].split(os.pathsep):
                exe_file = os.path.join(path, program)
                for candidate in ext_candidates(exe_file):
                    if is_exe(candidate):
                        return candidate
        return None

    def virtualenv_command(self, env_path):

        timeout = self.configuration.general_section.subprocess_timeout
        if timeout is not None:
            timeout = float(timeout)

        if not self.which("virtualenv"):
            raise ValueError("Cannot find virtual. Please install virtualenv.")
        active_path = os.path.join(env_path, "bin", "activate")
        if not os.path.isfile(active_path):
            cmd = ["virtualenv",  "--system-site-packages"]
            cmd.append(env_path)
            system(*cmd,
                   env=self.get_environ(),
                   timeout=timeout)
        else:
            print("No need to virtualenv init '%s' since it is already initialized." \
                % env_path)
        pass


def get_target_path_system(platform):
    if platform.startswith('win'):
        # We prefer alternative windows path i.e. pathes separated
        # with slaches instead of back slaches
        return 'windows'

    else:
        return 'linux'


def cmake_path(path):
    if sys.platform == 'win32':
        return Path(path, 'windows').to_system('windows_alt')
    else:
        return path


def copy_brainvisa_cmake(installDir):
    global this_script
    sourceDir = os.path.dirname(os.path.dirname(this_script))
    samefile = getattr(os.path, 'samefile', None)
    if samefile:
        samefile = samefile(sourceDir, installDir)
    else:
        samefile = sourceDir == installDir
    if samefile:
        return
    import brainvisa_cmake
    with open(os.path.join(os.path.dirname(brainvisa_cmake.__file__),
                           'installed_files.txt')) as installed_f:
        for f in installed_f:
            p, f = os.path.split(f.strip())
            d = os.path.join(installDir, p)
            if not os.path.exists(d):
                os.makedirs(d)
            shutil.copy(os.path.join(sourceDir, p, f), d)


def check_ld_library_path_error(fatal):
    # This code is a safeguard: libraries that are dynamically mounted by
    # Singularity should never be used by the linker, see
    # https://github.com/brainvisa/casa-distro/issues/113
    if '/.singularity.d/libs' in (os.environ.get('LD_LIBRARY_PATH', '')
                                  .split(os.pathsep)):
        try:
            libs_list = os.listdir('/.singularity.d/libs')
        except OSError:
            libs_list = []
        if libs_list:
            if fatal:
                sys.stderr.write('''\
    ERROR: The LD_LIBRARY_PATH environment variable contains
    '/.singularity.d/libs', which probably means that you are running
    bv_maker/cmake from within Singularity with binding of the NVidia
    drivers. This has been found to result in broken builds, see
    <https://github.com/brainvisa/casa-distro/issues/113>.

    Please remember to always run configuration and compilation work
    (bv_maker, cmake, or make) without the NVidia driver binding, by
    starting your container:

      - either with 'bv bv_maker',
      - or, by passing the 'opengl=container' option to 'casa_distro run'.
    ''')
                sys.exit(1)
            else:
                # remove the singularity paths during configure/build
                lpath = os.environ.get('LD_LIBRARY_PATH', '').split(os.pathsep)
                lpath.remove('/.singularity.d/libs')
                lpath = os.pathsep.join(lpath)
                os.environ['LD_LIBRARY_PATH'] = lpath


def run_and_log_tests(cwd=None, env=None, options=None, projects=None, timeout=None):
    # get test labels to assign them to projects
    test_labels = system_output_on_error(
        ['ctest', '--print-labels'] + options, echo=False, cwd=cwd)
    lines = test_labels.strip().split('\n')
    if 'All Labels:' in lines:
        labels_index = lines.index('All Labels:')
        labels = [line.strip() for line in lines[labels_index+1:]]
    elif 'No Labels Exist' in lines:
        labels = [] # no tests
    else:
        raise RuntimeError(
            'ctest --print-labels produced an unexpected output:\n'
            + '\n'.join(lines))
    logs = {}

    if timeout is None:
        timeout = brainvisa_cmake.configuration.default_subprocess_timeout
    if timeout is not None:
        timeout = float(timeout)

    for label in labels:
        if projects is not None and label not in projects:
            # skip this test, it's not part of the packaging/build config
            continue
        logfile = tempfile.mkstemp(prefix='bv_test_%s' % label, suffix='.log')
        os.close(logfile[0])
        start_time = time.localtime()
        try:
            system(cwd=cwd,
                   env=env,
                   timeout = timeout,
                  *(['ctest', '-L', '^%s$' % label, '--output-on-failure',
                     '-O', logfile[1]] + options))
        except Exception as e:
            logitem = {}
            logitem['log_file'] = logfile[1]
            logitem['exception'] = e
            logitem['start_time'] = start_time
            logitem['stop_time'] = time.localtime()
            logs[label] = logitem
        else:
            logitem = {}
            logitem['log_file'] = logfile[1]
            logitem['exception'] = None
            logitem['start_time'] = start_time
            logitem['stop_time'] = time.localtime()
            logs[label] = logitem
            #os.unlink(logfile[1])
        # FIXME DEBUG
        with open(logfile[1], 'a') as f:
            print('-------------------------------------', file=f)
            print('projects to test: %s' % repr(projects), file=f)
            print('labels to test: %s' % repr(labels), file=f)
            print('current label: %s' % label, file=f)
    return logs


def run_and_log_testref(cwd=None, env=None, options=None, timeout=None,
                        print_output=True):
    logs = {}

    if timeout is None:
        timeout = brainvisa_cmake.configuration.default_subprocess_timeout
    if timeout is not None:
        timeout = float(timeout)

    logfile = tempfile.mkstemp(prefix='bv_testref', suffix='.log')
    os.close(logfile[0])
    start_time = time.localtime()
    try:
        output = system_output_on_error(['make'] + options + ['testref'],
                                        cwd=cwd, env=env,
                                        timeout=timeout)
    except Exception as e:
        if hasattr(e, 'output'):
            with open(logfile[1], 'w') as f:
                f.write(str(e.output))
            if print_output:
                print(e.output)
        logitem = {}
        logitem['log_file'] = logfile[1]
        logitem['exception'] = e
        logitem['start_time'] = start_time
        logitem['stop_time'] = time.localtime()
        logs['testref'] = logitem
    else:
        with open(logfile[1], 'w') as f:
            f.write(output)
        logitem = {}
        logitem['log_file'] = logfile[1]
        logitem['exception'] = None
        logitem['start_time'] = start_time
        logitem['stop_time'] = time.localtime()
        logs['testref'] = logitem
        #os.unlink(logfile[1])
        if print_output:
            print(output)
    return logs
