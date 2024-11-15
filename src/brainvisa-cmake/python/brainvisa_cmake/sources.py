# -*- coding: utf-8 -*-

"""Handling of source-directory configuration."""

from fnmatch import fnmatchcase
import json
import os

import six

import brainvisa_cmake.brainvisa_projects as brainvisa_projects
import brainvisa_cmake.configuration
from brainvisa_cmake.git import GitRepository
from brainvisa_cmake.git import GitUpdateError
from brainvisa_cmake.git import print_git_status_summary
from brainvisa_cmake.subprocess import system
from brainvisa_cmake.version_number import version_format_short


class SourceDirectory(brainvisa_cmake.configuration.DirectorySection,
                      brainvisa_cmake.configuration.ConfigVariableParser):

    _variables_with_replacements = set(('directory_id',  'cross_compiling_dirs'))
    _path_variables = set(('directory',))
    _validAdditiveOptions = set(('default_steps', 'cross_compiling_dirs'))
    _validOptions = set(('revision_control',
                         'build_condition',
                         'stdout_file', 
                         'stderr_file',
                         'update_git_remotes',
                         'default_source_dir',
                         'ignore_git_failure'))
    _validOptions.update(_variables_with_replacements)
    _validOptions.update(_path_variables)
    _validOptions.update(_validAdditiveOptions)
        
    def __init__(self, directory, configuration):
        super(SourceDirectory, self).__init__()
        self.configuration = configuration
        self.directory = directory
        self.configurationLines = []
        self.sourceConfigurationLines = []
        self.svnComponents = []
        self.gitComponents = []
        self.default_steps = ['sources']
        self.revision_control = 'ON'
        self.update_git_remotes = 'ON'
        self.directory_id = ''
        # cross_compiling_dirs contains toolchain substitutions for source
        # directories. This is used when execution needs different path to
        # access sources (i.e.: in windows cross compilation, for pure python
        # components, it is necessary to access source directory through
        # network share, instead of NFS mount point.
        self.cross_compiling_dirs = {}
        self.ignore_git_failure = False
        if self.configuration.verbose:
            print('Processing source directory %s' % self.directory)
        self._git_only_failed = False

    def addConfigurationLine(self, line):
        # Supported lines in bv_maker.cfg for [ source ... ]:
        #    default_steps [info] [sources]
        #    git <url> <git_tag> [<dest_directory> [<bv_version>]]
        #    svn <url> [<dest_directory> [<bv_version>]]
        #    brainvisa <component_pattern> <version_pattern>
        #    brainvisa_exclude <component_pattern> [<version_pattern>]
        #    + soma/soma-base/trunk [<dest_directory>] [<bv_version>]]
        #    + https://svn.url [<dest_directory>] [<bv_version>]]
        #    + <component_pattern> <version_pattern>
        #    - <component_pattern> [<version_pattern>]
        if brainvisa_cmake.configuration.ConfigVariableParser.addConfigurationLine(self, line):
            pass
        else:
            self.sourceConfigurationLines.append(line)
            
    def parseSourceConfiguration(self):
        for l in self.sourceConfigurationLines:
            self.parseSourceConfigurationLine(l)

    def parseSourceConfigurationLine(self, line, virtual=False, 
                                     component_version = None):
        line = os.path.expandvars(line)
        l = line.split()
        sign = l[0]
        if sign == 'git':
            if len(l) < 3 or len(l) > 5:
                raise SyntaxError()
            sign, url, git_tag, dest_directory, bv_version = (
                l + [None, None])[:5]
            git_tag_type, git_tag = (['branch'] \
                + git_tag.split(':',1))[-2:]
            if dest_directory is None:
                dest_directory = url.rsplit('/', 1)[-1]
            # git_tag is the git branch (master, integration...)
            # bv_version is the bv branch name (bug_fix, trunk)
            if self.configuration.verbose:
                print('    adding repository: git', url, git_tag)
                print('                   in:', \
                    os.path.join(self.directory, dest_directory))
                if component_version:
                    print('                  for: %s version %s' \
                        % component_version)
            self.gitComponents.append(
                (component_version, url, git_tag, dest_directory,
                    bv_version))
        else:
            if len(l) < 2 or len(l) > 4:
                raise SyntaxError()
            sign, componentPattern, versionPattern, bv_version = (
                l + [None, None])[:4]
            if sign == 'svn' or (sign == '+' and '/' in componentPattern):
                if '*' in componentPattern:
                    raise SyntaxError()
                if componentPattern.startswith('http') \
                        or componentPattern.startswith('file'):
                    url = componentPattern
                    dest_directory = versionPattern
                else:
                    url = brainvisa_projects.SVN_URL + '/' \
                        + componentPattern
                    dest_directory = versionPattern
                    if dest_directory is None:
                        dest_directory = componentPattern
                if dest_directory is None:
                    raise SyntaxError()
                if self.configuration.verbose:
                    print('    adding repository: svn', url,
                            component_version)
                    print('                   in:', \
                        os.path.join(self.directory, dest_directory))
                    if component_version:
                        print('                  for: %s version %s' \
                            % component_version)

                self.svnComponents.append(
                    (component_version, url, dest_directory, bv_version))
            elif sign in ('brainvisa', '+'):
                if versionPattern is None:
                    raise SyntaxError()
                for component in brainvisa_projects.find_components(
                    componentPattern):
                    project = brainvisa_projects.project_per_component[
                        component]
                    for version, repo_dir in six.iteritems(
                        brainvisa_projects.url_per_component[component]):
                        repo, dir = repo_dir
                        if fnmatchcase(version, versionPattern):
                            default_source_dir = getattr(self, 'default_source_dir', None)
                            if default_source_dir:
                                dir = default_source_dir.format(project=project,
                                                                component=component,
                                                                branch=version)
                            self.parseSourceConfigurationLine(
                                '%s %s %s' % (repo, dir, version), 
                                virtual=True, 
                                component_version=(component, version))
                            break
                    else:
                        repo_dir = brainvisa_projects.url_per_component[component].get('trunk')
                        if 'CONDA_PREFIX' in os.environ and repo_dir:
                            repo, dir = repo_dir
                            url = repo.split()[1]
                            default_source_dir = getattr(self, 'default_source_dir', None)
                            if default_source_dir:
                                dir = default_source_dir.format(project=project,
                                                                component=component,
                                                                branch=versionPattern)
                            self.parseSourceConfigurationLine(
                                f'git {url} {versionPattern} {dir}',
                                virtual=True, 
                                component_version=(component, versionPattern))
            elif sign in ('-', 'brainvisa_exclude'):
                if '/' in componentPattern:
                    raise SyntaxError()
                else:
                    if versionPattern is None:
                        versionPattern = '*'
                    for component in brainvisa_projects.find_components(
                        componentPattern):
                        for version, repo_dir in six.iteritems(
                            brainvisa_projects.url_per_component[
                                component]):
                            if fnmatchcase(version, versionPattern):
                                # Remove unwanted svn components
                                count = 0
                                for component_version \
                                    in [i[0] for i in self.svnComponents]:
                                    if component_version:
                                        c, v = component_version
                                        if c == component and v == version:
                                            if self.configuration.verbose:
                                                component_version, url, \
                                                dest_directory, bv_version = \
                                                self.svnComponents[count]
                                                print('    removing repository:',
                                                      'svn', url)
                                                print('                     in:',
                                                      os.path.join(
                                                          self.directory, 
                                                          dest_directory))
                                                print('                    for: %s version %s' % component_version)
                                            del self.svnComponents[count]
                                            count -= 1
                                    count += 1
                                # Remove unwanted git components
                                count = 0
                                for component_version in [i[0] for i in self.gitComponents]:
                                    if component_version:
                                        c, v = component_version
                                        if c == component and v == version:
                                            if self.configuration.verbose:
                                                component_version, url, git_tag, dest_directory, bv_version = self.gitComponents[
                                                    count]
                                                print('    removing repository: git', url, git_tag)
                                                print('                     in:', os.path.join(self.directory, dest_directory))
                                                print('                    for: %s version %s' % component_version)
                                            del self.gitComponents[count]
                                            count -= 1
                                    count += 1
            else:
                raise SyntaxError('Line cannot begin with "%s"' % sign)

        # Sort components according to their destination directory
        self.gitComponents = sorted(self.gitComponents, key=lambda t: t[3])
        self.svnComponents = sorted(self.svnComponents, key=lambda t: t[2])

        if not virtual:
            self.configurationLines.append(line)

    def process(self, options, args):
        self._git_only_failed = False
        if options.ignore_git_failure:
            self.ignore_git_failure = True
        if not os.path.exists(self.directory):
            os.makedirs(self.directory)
        with open(os.path.join(self.directory, 'bv_maker.cfg'),
                  'w') as clientFile:
            print('\n'.join(self.configurationLines), file=clientFile)

        if len(self.svnComponents) == 0 or not options.svn:
            svn = False
        else:
            svn  = True
        repositoryDirectory = os.path.join(self.directory, '.repository')
        checkout = False
        use_rcs = self.revision_control.upper() in ('', 'ON')
        if use_rcs and svn and not os.path.exists(repositoryDirectory):
            os.makedirs(repositoryDirectory)
            # Because of a bug in svnadmin on MacOS, I cannot use an absolute name for the directory to create.
            # When I try "svnadmin create /neurospin/brainvisa/cmake_mac/", I have the following error:
            # svnadmin: '/neurospin/brainvisa/cmake_mac' is a subdirectory of an existing repository rooted at '/neurospin'
            # But it works if I do "cd /neurospin/brainvisa && vnadmin create
            # cmake_mac"
            cwd, dir = os.path.split(repositoryDirectory)
            system('svnadmin', 'create', dir, cwd=cwd)

            if len(os.path.splitdrive(repositoryDirectory)[0]) > 0:
                # This is for windows absolute pathes
                repositoryDirectory = '/' + \
                    repositoryDirectory.replace(os.path.sep, "/")

            self.svncommand(
                'checkout',  'file://' + repositoryDirectory, self.directory)
            checkout = True

        source_directories = []

        # Update SVN repositories

        # Go to the sources directory
        externalsFileName = os.path.join(self.directory, 'bv_maker.externals')
        with open(externalsFileName, 'w') as externalsFile:
            for component_version, url, dest_directory, bv_version in set(self.svnComponents):
                print(dest_directory, url, file=externalsFile)
                source_directories.append((dest_directory, bv_version))

        if use_rcs and svn:
            if options.cleanup:
                self.svncommand('cleanup', self.directory, cwd=self.directory)
            self.svncommand('propset', 'svn:externals',
                            '--file', externalsFileName, self.directory,
                            cwd=self.directory)
            self.svncommand('commit', '-m', '', self.directory,
                            cwd=self.directory)
            self.svncommand('update', self.directory, cwd=self.directory)

        # update Git Repositories

        git_status_list = []
        git_update_failure = False
        for component_version, url, git_tag, dest_directory, bv_version \
                in self.gitComponents:
            if dest_directory is None:
                dest_directory = url.rsplit('/', 1)[-1]
                if dest_directory.endswith('.git'):
                    dest_directory = dest_directory[:-4]
            if use_rcs and options.git:
                gr = GitRepository(self.directory, dest_directory,
                                   remote_url=url, remote_ref=git_tag)
                try:
                    gr.update_or_clone(source_dir=self)
                except GitUpdateError as exc:
                    update_message = u'✗ ' + six.ensure_text(str(exc))
                    git_update_failure = True
                else:
                    update_message = u'✓'
                status_dict = gr.get_status_dict()
                status_dict['update_message'] = update_message
                git_status_list.append(status_dict)
                source_directories.append((dest_directory, bv_version))

        print_git_status_summary(self.directory, git_status_list)

        components_sources = {}
        for dest_path, bv_version in source_directories:
            pinfo = brainvisa_projects.read_project_info(
                os.path.join(self.directory, dest_path),
                version_format=version_format_short
            )
            if pinfo:
                project, component, version, build_model = pinfo
                version = str(version)
                components_sources.setdefault(component, {})[
                    bv_version or version] = (dest_path, build_model)
            else:
                print('WARNING: directory %s will be ignored because project_info.cmake, python/*/info.py or */info.py cannot be found or used' % os.path.join(self.directory, dest_path))
        with open(os.path.join(self.directory, 'components_sources.json'),
                  'w') as f:
            json.dump(components_sources, f, indent=2)
        if git_update_failure:
            self._git_only_failed = True
            raise RuntimeError('Error updating one or more Git repositories')

    def source_status(self, options, args):
        repositoryDirectory = os.path.join(self.directory, '.repository')
        use_rcs = self.revision_control.upper() in ('', 'ON')

        # Display status of SVN repositories

        # Go to the sources directory
        if use_rcs and options.svn and len(self.svnComponents) != 0:
            self.svncommand('status', self.directory, cwd=self.directory)

        # Display status of Git Repositories

        git_status_list = []
        for _, url, git_tag, dest_directory, _ in self.gitComponents:
            if dest_directory is None:
                dest_directory = url.rsplit('/', 1)[-1]
                if dest_directory.endswith('.git'):
                    dest_directory = dest_directory[:-4]
            dest_path = os.path.join(self.directory, dest_directory)
            if use_rcs and options.git:
                gr = GitRepository(self.directory, dest_directory,
                                   remote_url=url, remote_ref=git_tag)
                gr.print_short_status(
                    extra_git_commands=options.extra_git_commands,
                )
                status_dict = gr.get_status_dict()
                git_status_list.append(status_dict)

        print_git_status_summary(self.directory, git_status_list)

    def svncommand(self, *svnargs, **subprocess_kwargs):
        cmd = ['svn', svnargs[0]]
        if self.configuration.username:
            cmd += ['--username', self.configuration.username]
            if self.configuration.username == 'brainvisa':
                cmd += ['--password', 'Soma2009']
        cmd.extend(svnargs[1:])
        system(*cmd, **subprocess_kwargs)

    def info(self):
        print('Source directory: "' + self.directory + '"')
        for component_version, url, dest_directory, bv_version in self.svnComponents:
            print('  %s <- svn %s' % (dest_directory, url))
            if component_version:
                component, version = component_version
                print('    component %s (%s)' % (component, version))
        for component_version, url, git_tag, dest_directory, bv_version in self.gitComponents:
            print('  %s <- git %s' % (dest_directory, url))
            if component_version:
                component, version = component_version
                print('    component %s (%s)' % (component, version))

    @staticmethod
    def dep_condition(dest_section, src_section, step):
        # this function is used for step condition testing. It is overloaded
        # just in case the option ignore_git_failure is set: then next
        # steps are still enabled, while this source step has failed.
        if not src_section.has_failed(step):
            return True
        if src_section.status.get(step, 'not run') == 'failed' \
                and src_section.ignore_git_failure \
                and src_section._git_only_failed:
            return True
        return False
