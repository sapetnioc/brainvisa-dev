# -*- coding: utf-8 -*-

"""Miscellaneous utilities with no dependencies on other bv_maker modules."""

import datetime
import json
import os
import platform
from socket import gethostname
import sys
import time

from brainvisa_cmake.brainvisa_projects import find_project_info


_installer_datetime = None
_installer_variables = None


def installer_parse_date(value):
    return datetime.datetime.strptime(value, '%Y_%m_%d').timetuple()[:3]


def installer_parse_time(value):
    return datetime.datetime.strptime(value, '%H:%M:%S').timetuple()[3:6]


def installer_format_date(date):
    return '%04d_%02d_%02d' % date


def installer_format_time(time):
    return '%02d:%02d:%02d' % time


def global_installer_datetime():
    global _installer_datetime
    if _installer_datetime is not None:
        return _installer_datetime

    plt = time.localtime()
    p_date = installer_format_date(plt[:3])
    p_time = installer_format_time(plt[3:6])

    _installer_datetime = {'date': p_date, 'time': p_time}

    return _installer_datetime


def get_standard_arch(arch = platform.architecture()[0]):
    return 64 if arch in ['64', '64bit', 'x86_64'] else 32


def get_host_system_name():
    systems = {'darwin' : 'osx',
               'windows': 'win'}
    system = platform.system()
    osname = system.lower()
    osname = systems.get(osname, osname)

    if osname in ('linux', 'win'):
        # Append architecture
        arch = platform.architecture()[0]
        osname += str(get_standard_arch(arch))

    return osname


def get_host_libc_version():
    # determine libc version - using ctypes and calling C
    # gnu_get_libc_version() function
    # Note: plaform.libc_ver() is completely bogus.
    import ctypes
    libc = ctypes.cdll.LoadLibrary("libc.so.6")
    gnu_get_libc_version = libc.gnu_get_libc_version
    gnu_get_libc_version.restype = ctypes.c_char_p

    ver = gnu_get_libc_version()
    if sys.version_info[0] >= 3:
        # in python3, ver is a bytes, not a str
        ver = ver.decode()
    return ver.split('.')


def get_pack_host_system_name():
    '''
        Get system name to use for packaging.
        Because linux compatibility for packs depends on libc version, the
        libc version is integrated to the system name.
        On Mac, the version of OSX is also appended.
    '''
    pack_system = get_host_system_name()
    if pack_system.startswith('linux'):
        libc_version = get_host_libc_version()
        pack_system += '-glibc-'+ '.'.join(libc_version[:2])
    elif pack_system.startswith('osx'):
        pack_system += '-' + '.'.join(platform.mac_ver()[0].split('.')[:2])

    return pack_system


def global_installer_variables():
    global _installer_variables
    if _installer_variables is not None:
        return _installer_variables

    pack_host_system = get_pack_host_system_name()

    _installer_variables = {'os': pack_host_system,
                            'hostname': gethostname().split('.')[0]}
    return _installer_variables

def get_components_info():
    '''
    Return a dictionary with one item for each component defined during
    the last configuration. The values are dictionaries containing the 
    following information:
        'version' : the complete version string of the component
        'src' : the path of the directory containing component sources
        'build_model' : the build model of the component ('cmake' or 'pure_python')
    
    None is returned if no information had been found.
    '''
    casa_build = os.environ.get('CASA_BUILD')
    if casa_build:
        path = os.path.join(casa_build, 'components_info.json')
        if os.path.exists(path):
            with open(path) as i:
                components_info = json.load(i)
            for component_info in components_info.values():
                path = find_project_info(component_info['directory'])
                if path and path.endswith('.py'):
                    d = {}
                    with open(path) as f:
                        exec(compile(f.read(), path, 'exec'), d, d)
                    depends = d.get('REQUIRES')
                    if depends:
                        component_info['depends'] = depends
                    alternative_depends = d.get('EXTRA_REQUIRES')
                    if alternative_depends:
                        component_info['alternative_depends'] = alternative_depends
            return components_info
    return None
