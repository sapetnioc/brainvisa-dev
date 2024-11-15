# -*- coding: utf-8 -*-

import glob, os, re
from fnmatch import fnmatchcase
import toml
import sys

SVN_URL = 'https://bioproj.extra.cea.fr/neurosvn'
BRAINVISA_SVN_URL = SVN_URL + '/brainvisa'

from brainvisa_cmake.components_definition import (
    components_definition, packages_definition)
from brainvisa_cmake.version_number import (VersionNumber,
                                            version_format_unconstrained)


def execfile(filename, globals=None, locals=None):
    with open(filename, 'rb') as f:
        file_contents = f.read()
    exec(compile(file_contents, filename, 'exec'), globals, locals)


class ProjectsSet:
    def __init__(self, components_definition=components_definition,
                 packages_definition=packages_definition,
                 ordered_projects=[],
                 components_per_group={},
                 components_per_project={},
                 project_per_component={},
                 url_per_component={},
                 info_per_component={},
                 attributes_per_component={}):
        self.components_definition = components_definition
        self.packages_definition = packages_definition
        self.ordered_projects = ordered_projects
        self.components_per_group = components_per_group
        self.components_per_project = components_per_project
        self.project_per_component = project_per_component
        self.url_per_component = url_per_component
        self.info_per_component = info_per_component
        self.attributes_per_component = attributes_per_component
        self.build_lists()

    def build_lists(self):
        all_components = set()
        for project, components in self.components_definition:
            self.ordered_projects.append(project)
            for component, component_info in components['components']:
                all_components.add(component)
                self.url_per_component[component] \
                    = component_info['branches']
                self.info_per_component[component] = component_info
                self.components_per_project.setdefault(
                    project, []).append(component)
                self.project_per_component[component] = project

                # Add a package for each component
                component_package = {
                   'components': [component],
                }
                for k in ('about', 'packages', 'requirements'):
                    v = component_info.get(k)
                    if v is not None:
                        component_package[k] = v
                self.packages_definition[component] = component_package

        # Recursively resolve packages dependencies and adds 'all_packages'
        # item to packages defined in self.packages_definition that contains
        # all packages that are included by a package.
        # Also adds a 'dependent_packages' item containing all packages
        # that include the package.
        for package, package_dict in self.packages_definition.items():
            all_packages = set()
            stack = list(package_dict.get('packages', []))
            while stack:
                p = stack.pop()
                if p == package:
                    raise ValueError(f'Circular dependency detected in packages definition for {package}')
                if p not in all_packages:
                    all_packages.add(p)
                    stack.extend(
                        i for i in self.packages_definition[p].get(
                            'packages', []) if i not in all_packages)
            package_dict['all_packages'] = all_packages
            for p in all_packages:
                self.packages_definition[p].setdefault(
                  'dependent_packages', set()).add(package)

        # Set an 'all_components' item in each package definition that contain
        # components included in the package and all dependent packages.
        for package, package_dict in self.packages_definition.items():
            for p in {package} | package_dict.get('dependent_packages', set()):
                for c in package_dict.get('components', []):
                    self.packages_definition[p].setdefault(
                        'all_components',
                        set()).update(package_dict.get('components', []))

        # Define self.components_per_group for all packages and alias using
        # 'all_components' item.
        self.components_per_group['all'] = all_components
        for package, package_dict in self.packages_definition.items():
            aliases = package_dict.get('alias', [])
            if isinstance(aliases, str):
                aliases = [aliases]
            for p in [package] + aliases:
                self.components_per_group[p] = package_dict['all_components']

    def add_sources_list(self, components_sources):
        for component, versions in components_sources.items():
            project = self.project_per_component.get(component)
            if not project:
                project = component
                project_exists = (project in self.components_per_project)
                self.project_per_component[component] = project
                self.components_per_project.setdefault(
                    project, []).append(component)
                if not project_exists:
                    self.ordered_projects.append(project)
                # the new component doesn't belong to any group.
            component_info = self.info_per_component.setdefault(component, {})
            component_url = self.url_per_component.setdefault(component, {})
            for version, version_info in versions.items():
                component_url[version] = (None, version_info[0])
            component_info['branches'] = component_url
            component_info.setdefault('groups', list())

    def find_components(self, componentsPattern):
        """Gets all the Brainvisa components that match the given pattern.

        Parameters
        ----------
        componentsPattern: string
            The pattern can be:
            * the name of a group of projects (standard, opensource...)
            * the name of a project (soma, axon, anatomist...)
            * the name of a component (soma-base, anatomist-gpl...)
            * a fnmatch pattern matching a Brainvisa component in any project
              (soma-*, old-connectomist-*, ...)
            * fnmatch patterns matching a project and a component
              <project_pattern>:<component_pattern> (anatomist:*, connectomist:old-connectomist-*,...)

        Returns
        -------
        components: list
            the list of components that match the pattern
        """
        components = self.components_per_group.get(componentsPattern)
        if components is None:
            components = self.components_per_project.get(componentsPattern)
            if components is None:
                if componentsPattern in self.project_per_component:
                    components = [componentsPattern]
                else:
                    l = componentsPattern.split(':')
                    if len(l) > 2:
                        raise SyntaxError('%s is not a valid component pattern'
                                          % repr(componentsPattern))
                    if len(l) == 1:
                        projectPattern = '*'
                        componentPattern = l[0]
                    else:
                        projectPattern, componentPattern = l
                    components = []
                    for project, projectComponents \
                            in self.components_per_project.items():
                        if fnmatchcase(project, projectPattern):
                            for component in projectComponents:
                                if fnmatchcase(component, componentPattern):
                                    components.append(component)
        return components


# these global variables are regrouped in the project_set instance.
# they are still here for backward compatibility. Please use the
# project_set variable instead.

ordered_projects = []  # Keeping the order of project is important because this
                       # is the way configuration dependencies are handled
components_per_group = {}
components_per_project = {}
project_per_component = {}
url_per_component = {}
info_per_component = {}
attributes_per_component = {}

projects_set = ProjectsSet(
    components_definition, packages_definition, ordered_projects,
    components_per_group,
    components_per_project, project_per_component, url_per_component,
    info_per_component, attributes_per_component)


def parse_project_info_cmake(
    path,
    version_format=version_format_unconstrained
):
    """Parses a project_info.cmake file

    @type path: string
    @param path: The path of the project_info.cmake file

    @rtype: tuple
    @return: A tuple that contains project name, component name and version
    """
    project = None
    component = None
    version = VersionNumber(
                  '1.0.0',
                  format=version_format
              )
    build_model = None

    p = re.compile(r'\s*set\(\s*([^ \t]*)\s*(.*[^ \t])\s*\)')
    with open(path, 'rb') as f:
        for line in f:
            try:
                line = line.decode()
            except UnicodeError:
                line = line.decode('utf-8') # in case the default encoding is ascii
            match = p.match(line)
            if match:
                variable, value = match.groups()
                if variable == 'BRAINVISA_PACKAGE_NAME':
                    component = value
                elif variable == 'BRAINVISA_PACKAGE_MAIN_PROJECT':
                    project = value
                elif variable == 'BRAINVISA_PACKAGE_VERSION_MAJOR' and len(version) > 0:
                    version[ 0 ] = value
                elif variable == 'BRAINVISA_PACKAGE_VERSION_MINOR' and len(version) > 1:
                    version[ 1 ] = value
                elif variable == 'BRAINVISA_PACKAGE_VERSION_PATCH' and len(version) > 2:
                    version[ 2 ] = value
                elif variable == 'BRAINVISA_BUILD_MODEL':
                    build_model = value

    return (project, component, version, build_model)


def parse_project_info_python(
    path,
    version_format=version_format_unconstrained
):
    """Parses an info.py file

    @type path: string
    @param path: The path of the info.py file

    @rtype: tuple
    @return: A tuple that contains project name, component name and version
    """

    d = {}
    version = VersionNumber(
                  '1.0.0',
                  format=version_format
              )
    with open(path) as f:
        exec(compile(f.read(), path, 'exec'), d, d)

    for var in ('NAME', 'version_major', 'version_minor', 'version_micro'):
        if var not in d:
            raise KeyError('Variable %s missing in info file %s' % (var, path))

    project = component = d['NAME']
    if len(version) > 0:
        version[0] = d['version_major']

        if len(version) > 1:
            version[1] = d['version_minor']

            if len(version) > 2:
                version[2] = d['version_micro']

    build_model = d.get('brainvisa_build_model')

    return (project, component, version, build_model)


def parse_project_info_toml(
    path,
    version_format=version_format_unconstrained
):
    """Parses a pyproject.toml file

    @type path: string
    @param path: The path of the pyproject.toml file

    @rtype: tuple
    @return: A tuple that contains project name, component name and version
    """
    project = None
    component = None
    version = VersionNumber(
                  '1.0.0',
                  format=version_format
              )
    build_model = None
    with open(path) as f:
        pyproject = toml.load(f)
    project = component = pyproject['project']['name']
    # populse-db changed its name from populse_db. This trick
    # is the only way found to make brainvisa-cmake compatible
    # with both old and new name.
    if component == 'populse_db':
        project = component = 'populse-db'
    try:
        v = pyproject['project']['version']
        v = ''.join([x for x in v if x in '0123456789.'])
        v = v.split('.', 3)
        if len(version) > 0:
            version[0] = v[0]

        if len(version) > 1:
            version[1] = v[1]

            if len(version) > 2:
                version[2] = v[2]
    except AttributeError:
        print('Error reading config for', project, path, file=sys.stderr)
        raise
    except KeyError:
        print('Error reading config version for', project, path,
              file=sys.stderr)
        version[0] = 0
        version[1] = 0
        version[2] = 0

    build_model = 'pure_python'

    return (project, component, version, build_model)


def project_info_to_cmake(path):
    """Return a string containing a CMake compatible list of pairs of variable name
        and value."""
    info = read_project_info(path)
    if not info:
        raise Exception(f'cannot find project info in {path}')
    project, component, version, build_model = info
    return (f"BRAINVISA_PACKAGE_NAME;{component};"
            f"BRAINVISA_PACKAGE_MAIN_PROJECT;{project};"
            f"BRAINVISA_PACKAGE_VERSION_MAJOR;{version[0]};"
            f"BRAINVISA_PACKAGE_VERSION_MINOR;{version[1]};"
            f"BRAINVISA_PACKAGE_VERSION_PATCH;{version[2]};"
            f"BRAINVISA_BUILD_MODEL;{build_model}")


def find_project_info(directory):
    """Find the project_info.cmake or the info.py file
      contained in a directory.
      Files are searched using the patterns :
      1) <directory>/pyproject.toml
      2) <directory>/project_info.cmake
      3) <directory>/cmake/project_info.cmake
      4) <directory>/python/*/info.py
      5) <directory>/*/info.py
      6) <directory>/info.py

    @type directory: string
    @param directory: The directory to search project_info.cmake or info.py

    @rtype: string
    @return: The path of the found file containing project information
            or None when no file was found
    """
    project_info_python_patterns = (
        os.path.join(directory, 'pyproject.toml'),
        os.path.join(directory, 'project_info.cmake'),
        os.path.join(directory, 'cmake', 'project_info.cmake'),
        os.path.join(directory, 'python', '*', 'info.py'),
        os.path.join(directory, '*', 'info.py'),
        os.path.join(directory, 'info.py'))

    # Searches for project_info.cmake and info.py file
    for pattern in project_info_python_patterns:
        project_info_python_path = glob.glob(pattern)

        if project_info_python_path:
            return project_info_python_path[0]

    return None


def read_project_info(directory,
                      version_format=version_format_unconstrained):
    """Find the project_info.cmake or the info.py file
      contained in a directory and parses its content.
      Files are searched using the patterns :
      1) <directory>/pyproject.toml
      2) <directory>/project_info.cmake
      3) <directory>/cmake/project_info.cmake
      4) <directory>/python/*/info.py
      5) <directory>/*/info.py
      6) <directory>/info.py

    @type directory: string
    @param directory: The directory to search project_info.cmake or info.py

    @type version_format: VersionFormat
    @param version_format: The version format to use to parse version.

    @rtype: tuple
    @return: A tuple that contains project name, component name and version
    """
    project_info = None
    project_info_path = find_project_info(directory)

    if project_info_path is not None:

        if project_info_path.endswith('.toml'):
            project_info = parse_project_info_toml(
                              project_info_path,
                              version_format=version_format
                          )

        elif project_info_path.endswith('.cmake'):
            project_info = parse_project_info_cmake(
                              project_info_path,
                              version_format=version_format
                          )

        elif project_info_path.endswith('.py'):
            try:
                project_info = parse_project_info_python(
                                  project_info_path,
                                  version_format=version_format
                              )
            except ImportError:
                print('File %s cannot be imported, project is skipped.'
                      % project_info_path, file=sys.stderr)
                return None

        else:
            raise RuntimeError('File ' + project_info_path + ' has unknown '
                               + 'extension for project info file.')

        return project_info

    else:
        return None


def update_project_info(project_info_path, version):
    if not isinstance(version, VersionNumber):
        version = VersionNumber(version)

    if project_info_path is None or not os.path.exists(project_info_path):
        return False

    project_info_content = open(project_info_path, 'rb').read()
    try:
        project_info_content = project_info_content.decode()
    except UnicodeError:
        # in case the default encoding is ascii
        project_info_content = project_info_content.decode('utf-8')

    # Set version in project info file
    # It needs to have a version with at least 3
    # numbers
    if len(version) < 3:
        version.resize(3)

    if project_info_path.endswith('.cmake'):
        pattern = re.compile(
            r'BRAINVISA_PACKAGE_VERSION_MAJOR.+'
            r'BRAINVISA_PACKAGE_VERSION_PATCH \d+',
            re.DOTALL
        )

        project_info_content_new = pattern.sub(
            'BRAINVISA_PACKAGE_VERSION_MAJOR '
            + str(version[0]) + ' )\n'
            + 'set( BRAINVISA_PACKAGE_VERSION_MINOR '
            + str(version[1]) + ' )\n'
            + 'set( BRAINVISA_PACKAGE_VERSION_PATCH '
            + str(version[2]),
            project_info_content
        )

    elif project_info_path.endswith('.py'):
        pattern = re.compile(
            r'version_major.+\nversion_micro\s*=\s*\d+',
            re.DOTALL
        )

        project_info_content_new = pattern.sub(
            'version_major = ' + str(version[0]) + '\n'
            + 'version_minor = ' + str(version[1]) + '\n'
            + 'version_micro = ' + str(version[2]),
            project_info_content
        )

    if project_info_content != project_info_content_new:
        #print(project_info_content_new)
        # Write new project info content to file
        # and commit local changes to the branch
        f = open(project_info_path, "w")
        f.write(project_info_content_new)
        f.close()

        return True

    return False


def parse_versioning_client_info(client_info):
    """Parses versioning client information for BrainVISA projects.
      The versioning client information is described using the format
      <client_type> <url> [<client_parameters>]

      i.e: svn https://bioproj.extra.cea.fr/neurosvn/brainvisa/aims/aims-gpl/branches/4.4
      or git https://github.com/neurospin/soma-workflow.git master

    @type client_info: string
    @param client_info: The informations concerning the client
    """
    splitted_client_info = client_info.split(' ')
    client_type, url = splitted_client_info[0:2]
    client_params = splitted_client_info[2:]
    return (client_type, url, client_params)


def find_components(componentsPattern):
    """Gets all the Brainvisa components that match the given pattern.

    This global function works on the global projects_set projects. See the
    ProjectsSet class and its find_components method.

    Parameters
    ----------
    componentsPattern: string
        The pattern can be:
        * the name of a group of projects (standard, opensource...)
        * the name of a project (soma, axon, anatomist...)
        * the name of a component (soma-base, anatomist-gpl...)
        * a fnmatch pattern matching a Brainvisa component in any project
          (soma-*, old-connectomist-*, ...)
        * fnmatch patterns matching a project and a component
          <project_pattern>:<component_pattern> (anatomist:*, connectomist:old-connectomist-*,...)

    Returns
    -------
    components: list
        the list of components that match the pattern
    """
    return projects_set.find_components(componentsPattern)

if __name__ == "__main__":
    # Create a Grphviz graph for brainvisa-cmake components
    from brainvisa_cmake.utils import get_components_info

    components_info = get_components_info()
    distro = sys.argv[1]
    distro_info = packages_definition[distro]
    packages = {distro} | distro_info["all_packages"]
    print(f'digraph "{distro}" {{')
    print(f'  node [shape=box]  ')
    for package in packages:
        node_attributes = {}
        component_info = components_info.get(package)
        if component_info:
            node_attributes["style"] = "filled"
            node_attributes["color"] = "green"
        attrs = " ".join(f'{k}="{v}"' for k, v in node_attributes.items())
        print(f'  "{package}" [{attrs}]')
        for dependency in packages_definition.get(package, {}).get("packages", []):
           print(f"  \"{package}\" -> \"{dependency}\"")
    print("}")
