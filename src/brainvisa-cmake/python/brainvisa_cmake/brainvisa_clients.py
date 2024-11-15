# -*- coding: utf-8 -*-

import sys
import posixpath
from subprocess                         import Popen, PIPE, STDOUT

from six.moves.urllib.parse import urlparse, urlunparse

from brainvisa_cmake.version_number     import VersionNumber, \
                                               VersionFormat, \
                                               version_format_unconstrained

def system( command,
            simulate = False,
            verbose = False ):
    """Execute a system command.
        If the code returned by the executed command is not 0, 
        a SystemError is raised.
    
    @type command: list
    @param command: The list that contains a command and its parameters.
    
    @type verbose: bool
    @param verbose: Specify that the command must be printed to standard output.
                    [Default: False].
                    
    @type simulate: bool
    @param simulate: Specify that the command must not be executed
                    [Default: False].
    
    @rtype: string
    @return: The standard output of the command.
    """
  
    if verbose:
        print(' '.join( ('"' + i + '"' for i in command) ))
      
    if simulate :
        return command
        
    else :
        cmd = Popen( command,
                     stdout = PIPE,
                     stderr = STDOUT )
        output = cmd.stdout.read()
        cmd.wait()
        if cmd.returncode != 0:
            if verbose:
                print(output)
                sys.stdout.flush()
            raise SystemError( 'System command exited with error code '
                                + repr( cmd.returncode ) + ': ' 
                                + ' '.join( ('"' + i + '"' for i in command) ) )
    
        return output
  
def normurl( url ):
    """Normalizes URL in order that URLs that point 
        to the same resource will return the same string.
    
    @type url: string
    @param url: The URL to normalize
    
    @return: A normalized URL, i.e. without '..' or '.' elements.
    """

    parsed = urlparse(url)
    return urlunparse(
                ( parsed.scheme,
                  parsed.netloc,
                  posixpath.normpath(parsed.path),
                  parsed.params,
                  parsed.query,
                  parsed.fragment ) )
  
def find_remote_project_info( client,
                              url ):
    """Find a project_info.cmake or the info.py file
        in subdirectories of the specified url.
        Files are searched using the patterns :
        1) <url>/project_info.cmake
        2) <url>/python/*/info.py
        3) <url>/*/info.py
        4) <url>/info.py
    
    @type client: Client
    @param client: The Client instance to get access to files.
    
    @type url: string
    @param url: The url to search project_info.cmake or info.py
    
    @rtype: string
    @return: The url of the found file containing project information
    """
    
    project_info_patterns = ( posixpath.join( url,
                                              'project_info.cmake' ),
                              posixpath.join( url,
                                              'python',
                                              '*',
                                              'info.py' ),
                              posixpath.join( url,
                                              '*',
                                              'info.py' ),
                              posixpath.join( url,
                                              'info.py' ))
    # Searches for project_info.cmake and info.py file
    for pattern in project_info_patterns:
            project_info_url = client.vcs_glob( pattern )
            
            if project_info_url:
                return project_info_url[0]
  
    return None
  
def read_remote_project_info( client,
                              url,
                              version_format = version_format_unconstrained ):
    """Search a project_info.cmake or a info.py file
        in subdirectories of the specified url and parses its content.
        Files are searched using the patterns :
        1) <url>/project_info.cmake
        2) <url>/python/*/info.py
        3) <url>/*/info.py
    
    @type client: Client
    @param client: The Client instance to get access to files.
    
    @type url: string
    @param url: The url to search project_info.cmake or info.py
    
    @type version_format: VersionFormat
    @param version_format: The format to use to return version.
    
    @rtype: list
    @return: a list that contains project name, component name and version
    """
    import os, tempfile
    from brainvisa_cmake.brainvisa_projects import parse_project_info_cmake, \
                                                   parse_project_info_python
    project_info_url = find_remote_project_info( client, url )

    if project_info_url is not None:
    
        fd, path = tempfile.mkstemp()
        os.close(fd)
        os.unlink(path)
        project_info = None
    
        if project_info_url.endswith( '.cmake' ):
            # Read the content of project_info.cmake file
            client.vcs_export( project_info_url, path )
            project_info = parse_project_info_cmake(
                                path,
                                version_format
                           )
            os.unlink( path )
        
        elif project_info_url.endswith( '.py' ):
            # Read the content of info.py file
            client.vcs_export( project_info_url, path )
            project_info = parse_project_info_python(
                                path,
                                version_format
                           )
            os.unlink( path )
        
        else:
            raise RuntimeError( 'Url ' + project_info_url + ' has unknown '
                                + 'extension for project info file.'  )
        return project_info
    
    else:
        return None
