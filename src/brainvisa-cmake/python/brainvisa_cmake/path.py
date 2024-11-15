# -*- coding: utf-8 -*-

import re
import sys
import six

from abc import abstractmethod


# To keep brainvisa-cmake independent from other projects (soma-base)
# we need to duplicate the singleton module.
from brainvisa_cmake.singleton import Singleton
       
#-------------------------------------------------------------------------------
# Path conversion
#-------------------------------------------------------------------------------
class PathSystemSyntax(object):
    def __init__(self):
        raise RuntimeError('PathSystemSyntax is not instanciable')
        
    @classmethod
    def check(cls, path):
        return True
    
class UriPathSystemSyntax(PathSystemSyntax):
    sep = '/'
    alt_sep = []
    possible_sep = [sep] + alt_sep
    scheme = 'file://'
    syntax = re.compile('^(file://([a-zA-Z0-9_%/:]+))$')

    @classmethod
    def check(cls, path):
        return cls.syntax.match(path)
    
class WindowsPathSystemSyntax(PathSystemSyntax):
    sep = '\\'
    alt_sep = ['/']
    possible_sep = [sep] + alt_sep
    syntax = re.compile(r'^(([a-zA-Z]:)?([a-zA-Z0-9_%\\/]+))$')

    @classmethod
    def check(cls, path):
        return cls.syntax.match(path)
    
class WindowsAltPathSystemSyntax(WindowsPathSystemSyntax):
    sep = '/'
    alt_sep = ['\\']
    possible_sep = [sep] + alt_sep
    
class LinuxPathSystemSyntax(PathSystemSyntax):
    sep = '/'
    possible_sep = ['/']
    syntax = re.compile(r'^([:a-zA-Z0-9_%\\/]+)$')

    @classmethod
    def check(cls, path):
        return cls.syntax.match(path)

class PathSystems(object):
    r'''
    Supported path systems are:
    - uri (i.e. path with uri syntax, for example file:///dir/file)
    - linux (i.e. linux path syntax, /dir/file)
    - windows (i.e. windows standard path syntax, c:\dir\file)
    - windows_alt (i.e. windows alternative path syntax, c:/dir/file)
    - msys (i.e. msys path syntax, /c/dir/file)
    '''

    def __init__(self):
        self.__registered_systems = dict()
        self.__register_default_systems()
        
    def register(self, system, syntax):
        self.__registered_systems[system] = syntax
        
    def __register_default_systems(self):
        for s in (('uri', UriPathSystemSyntax), \
                  ('linux', LinuxPathSystemSyntax), \
                  ('windows', WindowsPathSystemSyntax), \
                  ('windows_alt', WindowsAltPathSystemSyntax), \
                  ('msys', WindowsAltPathSystemSyntax)):
            self.register(s)

class DefaultPathConverterRegistry(Singleton, dict):
    pass

def get_host_path_system():
    import os
    
    if sys.platform.startswith('win'):
        if os.environ.get('TERM') == 'msys':
            return 'msys'
        
        return 'windows' 
        
    else:
        return 'linux'
    
class Path(str):
    default_system = get_host_path_system()
        
    def __new__(cls, obj, system = None, 
                converters_registry=DefaultPathConverterRegistry()):

        t = type(obj)
        if t is Path:
            o = str(obj)
            s = obj.__system

        elif isinstance(obj, six.string_types):
            if not isinstance(obj, str): # unicode
                o = obj.encode()
            else:
                o = obj
            s = None
        
        elif t in (list, tuple):
            if len(obj) > 0:
                o = obj[0]
                if len(obj) > 1:
                    s = obj[1]
                else:
                    s = None
            else:
                raise IndexError('%s must have a length greater than 0' 
                                 % t.title())

        elif t is dict:
            o = obj.get('path')
            s = obj.get('system')

        else:
            raise IndexError('incompatible type for Path')

        if not isinstance(o, six.string_types):
            raise TypeError('Object of type %s is not convertible to Path' % t)
            
        if system is not None and s is not None and s != system:
           # Try to convert path to the new system
           c = converters_registry.get((s, system))
           if c:
               o = c.convert(o)
               s = system
           
           else:
               raise RuntimeError('No path converter registered to convert ' 
                                  '%s path to %s path' % (s, system))
           
        elif s is None and system is not None:
            s = system
            
        # Build new object
        cls = str.__new__(cls, o)
        cls.__system = s if s is not None else Path.default_system
        cls.__converters_registry = converters_registry \
            if converters_registry is not None \
            else DefaultPathConverterRegistry()
                
        return cls
        
    def __repr__(self):
        return str((str(self), self.__system))
    
    def __eq__(self, path):
        return (repr(self) == repr(path))
    
    def __ne__(self, path):
        return (not self.__eq__(path))

    def get_system(self):
        return self.__system
   
    def to_system(self, system):
        return Path(self, system)
    
def autoinitsingleton(*args, **kwargs):
    
    def __update_class(cls):        
        if issubclass(cls, Singleton):
            def __init_singleton__(self, *args, **kwargs):
                super(cls, self).__init__(*args, **kwargs)
            
            cls.__init_singleton__ = __init_singleton__

            # instanciate singleton class to register
            cls(*args, **kwargs)
            
            #print('@autoinitsingleton, cls:', cls, 'registered')

        return cls
    
    return __update_class

def get_path_converter(source_system, target_system,
                       converters = DefaultPathConverterRegistry()):
    '''
        Get registered path converter for converting path from 
        source system to target system
    '''
    c = converters.get((source_system, target_system))
    if not c:
        raise RuntimeError('No %s to %s path converter registered. Please'
                           'register one before using it.' \
                           % (source_system, target_system))
    return c
    
class PathConverter(object):
    '''
        Path converter base class.
        A path converter allow to convert path from one system to another
    '''
    def __init__(self, source_system, target_system, 
                 registry = DefaultPathConverterRegistry()):
        self.__source_system = source_system
        self.__target_system = target_system
        self.__converters_registry = registry
        
        self.__converters_registry.setdefault((source_system, target_system), self)
    
    @abstractmethod
    def convert(self, source_path):
        raise RuntimeError("Convert method is an abstract method and must be",
                           "implemented in PathConverter subclasses")

class DefaultPathConverter(PathConverter):
    '''
        Default path converter.
    '''
    def convert(self, source_path):
        return source_path

def to_uri(path):
    file_scheme = 'file://'
    has_file_scheme = path.startswith(file_scheme)

    if not has_file_scheme:
        # Add file scheme
        path = file_scheme + path
    
    return path

def from_uri(path):
    file_scheme = 'file://'
    has_file_scheme = path.startswith(file_scheme)

    if has_file_scheme:
        # Remove file scheme
        path = path[7:]
    
    return path

#-------------------------------------------------------------------------------
# Linux path converters
#-------------------------------------------------------------------------------
@autoinitsingleton('linux', 'uri')
class LinuxToUriPathConverter(Singleton, PathConverter):
    '''
        Linux path to uri converter.
    '''
    def convert(self, source_path):
        return to_uri(source_path)

@autoinitsingleton('linux', 'msys')
class LinuxToMsysPathConverter(Singleton, PathConverter):
    '''
        Linux path to msys converter.
    '''
    def convert(self, source_path):
        return get_path_converter(
                    'windows', 
                    'msys').convert(
                        get_path_converter(
                            'linux', 
                            'windows').convert(source_path))

@autoinitsingleton('linux', 'windows_alt')
class LinuxToWindowsAltPathConverter(Singleton, PathConverter):
    '''
        Linux path to windows alternative converter.
    '''
    def convert(self, source_path):
        return get_path_converter(
                    'windows', 
                    'windows_alt').convert(
                        get_path_converter(
                            'linux', 
                            'windows').convert(source_path))

#-------------------------------------------------------------------------------
# Msys path converters
#-------------------------------------------------------------------------------
@autoinitsingleton('msys', 'linux')
class MsysToLinuxPathConverter(Singleton, PathConverter):
    '''
        Msys path to linux path converter.
    '''
    def convert(self, source_path):
        return get_path_converter(
                    'windows_alt', 
                    'linux').convert(
                        get_path_converter(
                            'msys', 
                            'windows_alt').convert(source_path))
                        
@autoinitsingleton('msys', 'uri')
class MsysToUriPathConverter(Singleton, PathConverter):
    '''
        Msys path to uri path converter.
    '''
    def convert(self, source_path):
        return get_path_converter(
                    'windows_alt', 
                    'uri').convert(
                        get_path_converter(
                            'msys', 
                            'windows_alt').convert(source_path))

@autoinitsingleton('msys', 'windows')
class MsysToWindowsPathConverter(Singleton, PathConverter):
    '''
        Msys path to windows path converter.
    '''
    def convert(self, source_path):
        return get_path_converter(
                    'windows_alt', 
                    'windows').convert(
                        get_path_converter(
                            'msys', 
                            'windows_alt').convert(source_path))
                        
@autoinitsingleton('msys', 'windows_alt')
class MsysToWindowsAltPathConverter(Singleton, PathConverter):
    '''
        Msys path to windows alternative path converter.
    '''
    def convert(self, source_path):
        if len(source_path) > 2 \
            and source_path[0] == WindowsAltPathSystemSyntax.sep \
            and source_path[1].isalpha() \
            and source_path[2] == WindowsAltPathSystemSyntax.sep:
            return source_path[1] + ':' + source_path[2:]
        else:
            return source_path

#-------------------------------------------------------------------------------
# Uri path converters
#-------------------------------------------------------------------------------
@autoinitsingleton('uri', 'linux')
class UriToLinuxPathConverter(Singleton, PathConverter):
    '''
        Uri to linux path converter.
    '''
    def convert(self, source_path):
        return from_uri(source_path)
    
@autoinitsingleton('uri', 'msys')
class UriToMsysPathConverter(Singleton, PathConverter):
    '''
        Uri path to msys path converter.
    '''
    def convert(self, source_path):
        return get_path_converter(
                    'windows_alt', 
                    'msys').convert(
                        get_path_converter(
                            'uri', 
                            'windows_alt').convert(source_path))

@autoinitsingleton('uri', 'windows')
class UriToWindowsPathConverter(Singleton, PathConverter):
    '''
        Uri to windows path converter.
    '''
    def convert(self, source_path):
        return get_path_converter(
                    'windows_alt', 
                    'windows').convert(
                        get_path_converter(
                            'uri', 
                            'windows_alt').convert(source_path))
    
@autoinitsingleton('uri', 'windows_alt')
class UriToWindowsAltPathConverter(Singleton, PathConverter):
    '''
        Uri to windows alternative path converter.
    '''
    def convert(self, source_path):
        return from_uri(source_path)[1:]

#-------------------------------------------------------------------------------
# Windows path converters
#-------------------------------------------------------------------------------
@autoinitsingleton('windows', 'msys')
class WindowsToMsysPathConverter(Singleton, PathConverter):
    '''
        Windows path to msys path converter.
    '''
    def convert(self, source_path):
        return get_path_converter(
                    'windows_alt', 
                    'msys').convert(
                        get_path_converter(
                            'windows', 
                            'windows_alt').convert(source_path))
    
@autoinitsingleton('windows', 'uri')
class WindowsToUriPathConverter(Singleton, PathConverter):
    '''
        Windows to uri path converter.
    '''
    def convert(self, source_path):
        return get_path_converter(
                    'windows_alt', 
                    'uri').convert(
                        get_path_converter(
                            'windows', 
                            'windows_alt').convert(source_path))

@autoinitsingleton('windows', 'windows_alt')
class WindowsToWindowsAltPathConverter(Singleton, PathConverter):
    '''
        Windows path to windows alternative path converter.
    '''
    def convert(self, source_path):
        return source_path.replace(WindowsPathSystemSyntax.sep, 
                                   WindowsAltPathSystemSyntax.sep)
    
#-------------------------------------------------------------------------------
# Windows alternative path converters
#-------------------------------------------------------------------------------
@autoinitsingleton('windows_alt', 'linux')
class WindowsAltToLinuxPathConverter(Singleton, PathConverter):
    '''
        Windows alternative  to linux path converter.
    '''
    def convert(self, source_path):
        return get_path_converter(
                    'windows', 
                    'linux').convert(
                        get_path_converter(
                            'windows_alt', 
                            'windows').convert(source_path))
                        
@autoinitsingleton('windows_alt', 'msys')
class WindowsAltToMsysPathConverter(Singleton, PathConverter):
    '''
        Windows alternative path to msys path converter.
    '''
    def convert(self, source_path):
        if len(source_path) > 2 \
            and source_path[1:3] == ':' + WindowsAltPathSystemSyntax.sep:
            return WindowsAltPathSystemSyntax.sep + source_path[0] \
                   + source_path[2:]
        else:
            return source_path
        
@autoinitsingleton('windows_alt', 'uri')
class WindowsAltToUriPathConverter(Singleton, PathConverter):
    '''
        Windows alternative path to uri converter.
    '''
    def convert(self, source_path):
        return to_uri(WindowsAltPathSystemSyntax.sep + source_path)

@autoinitsingleton('windows_alt', 'windows')
class WindowsAltToWindowsPathConverter(Singleton, PathConverter):
    '''
        Windows alternative path to windows path converter.
    '''
    def convert(self, source_path):
        return source_path.replace(WindowsAltPathSystemSyntax.sep, 
                                   WindowsPathSystemSyntax.sep)

class SystemPathConverter(PathConverter):
    '''
        Path converter based on system command calls.
    '''
    def __init__(self, source_system, target_system, command, 
                 registry = DefaultPathConverterRegistry()):
        super(SystemPathConverter, self).__init__(source_system, 
                                                  target_system,
                                                  registry = registry)
        self.__command = command
    
    def convert(self, source_path):
        return self.__system_check_output(self.__command + [source_path]).strip()
    
    @classmethod
    def __system_check_output(cls, *args, **kwargs):
        import subprocess
        try:
            # backport of subprocess of python 3
            import subprocess32
        except ImportError:
            subprocess32 = None
        #print(' '.join([str(x) for x in args]))
        if subprocess32 is not None:
            output = subprocess32.check_output(*args, **kwargs)
        else:
            if 'timeout' in kwargs:
                # timeout not supported in python2.subprocess
                kwargs = dict(kwargs)
                del kwargs['timeout']
            output = subprocess.check_output(*args, **kwargs)
        
        return output
