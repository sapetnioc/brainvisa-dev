# -*- coding: utf-8 -*-

import os
import string
import re
import types
import fnmatch
import posixpath
import lxml.objectify
import tempfile

import six
from six.moves.urllib.parse import urlparse, urlunparse, urlsplit, urlunsplit

from brainvisa_cmake.brainvisa_clients import system, normurl
from brainvisa_cmake.brainvisa_projects     import parse_project_info_cmake, \
    parse_project_info_python
from brainvisa_cmake.brainvisa_client_components import BranchType, \
                                                        VersionControlComponent
from brainvisa_cmake.version_number import VersionNumber, \
                                            version_format_release
# Glob special char
svn_glob_regexp = re.compile(r'[\[\]\*\?]')
svn_revision_regexp = re.compile(r'<\s*logentry\s+revision\s*=\s*"(\d+)"\s*>')

def svn_get_latest_revision(svn_url):
    """Get the latest revision done in a Subversion directory given its URL

    @type url: string
    @param url: The url of the Subversion directory

    @rtype: string or None
    @return: the revision number (as a string) or None if it cannot be retrieved.
    """

    xml = system(['svn', 'log', '--limit', '1', '--xml', svn_url])
    match = svn_revision_regexp.search(xml)
    if match:
        return match.group(1)


def svn_cat(url,
        simulate=False,
        verbose=False):
    """Get text content of the specified url.

    @type url: string
    @param url: The url to check

    @rtype: string
    @return: The content of the specified url
    """
    try:
        cmd = ['svn', 'cat', url]

        return system(cmd,
                        simulate=simulate,
                        verbose=verbose)

    except SystemError as e:
        raise RuntimeError('SVN error: Unable to cat from ' + url)


def svn_checkout(url,
            path,
            depth=None,
            ignore_externals=False,
            simulate=False,
            verbose=False):
    """Checkout the content of the specified url to a path.

    @type url: string
    @param url: The url of the directory to check out

    @type path: string
    @param path: The destination path

    @type depth: string
    @param depth: Optional depth to limit checkout.
                    Valid values are empty/files/immediates/infinity.
                    [Default: None].

    @type depth: bool
    @param depth: Specify that externals svn references must be ignored.
                    [Default: False].

    @rtype: string
    @return: The standard output of the 'svn checkout' command
    """
    try:

        cmd = ['svn', 'checkout', url, path]

        if depth is not None:
            if depth not in ('empty',
                                'files',
                                'immediates',
                                'infinity'):
                raise RuntimeError('SVN error: Depth ' + depth
                                + ' is not a valid value for checkout')

        cmd += ['--depth', depth]

        if ignore_externals:
            cmd += ['--ignore-externals']

        return system(cmd,
                        simulate=simulate,
                        verbose=verbose)

    except SystemError as e:
        raise RuntimeError('SVN error: Unable to export from '
                        + url + ' to ' + path)


def svn_commit(path,
            message='',
            simulate=False,
            verbose=False):
    """Commit the changes of the specified local path
        to the repository.

    @type path: string
    @param path: The path to commit
    
    @type url: string
    @param url: The destination to commit to
    
    @type message: string
    @param message: The message to commit

    @rtype: string
    @return: The standard output of the 'svn commit' command
    """
    try:
        cmd = ['svn', 'commit', path, '-m', message]

        return system(cmd,
                        simulate=simulate,
                        verbose=verbose)

    except SystemError as e:
        raise RuntimeError('SVN error: Unable to commit changes from ' + path)


def svn_copy(source,
            dest,
            parents=False,
            message='',
            simulate=False,
            verbose=False):
    """Copy the source url to the destination url keeping the history.

    @type source: string
    @param source: The source url to copy from

    @type dest: string
    @param dest: The destination url to copy to

    @type parents: bool
    @param parents: Specify that intermediates directory should be created
                    if they do not exists [Default: False]

    @type message: string
    @param message: The message to log changes in history

    @rtype: string
    @return: The standard output of the 'svn copy' command
    """
    cmd = ['svn', 'copy', source, dest, '-m', message]
    if parents:
        cmd.append('--parents')

    return system(cmd,
                    simulate=simulate,
                    verbose=verbose)


def svn_delete(url,
               message='',
               simulate=False,
               verbose=False):
    """Remove file or directory from repository.

    @type ulr: string
    @param source: The url to delete

    @type message: string
    @param message: The message to log changes in history

    @rtype: string
    @return: The standard output of the 'svn delete' command
    """
    cmd = ['svn', 'delete', url, '-m', message]

    return system(cmd,
                    simulate=simulate,
                    verbose=verbose)


def svn_exists(url):
    """Check that the url exists

    @type url: string
    @param url: The url to check

    @rtype: bool
    @return: True if the url exists, False otherwise
    """
    try:
        svn_info(url)
        return True

    except RuntimeError as e:
        return False


def svn_export(url,
              path,
              simulate=False,
              verbose=False):
    """Export the content of the specified url to a path.

    @type url: string
    @param url: The url to check out

    @type path: string
    @param path: The destination path

    @rtype: string
    @return: The standard output of the 'svn export' command
    """
    try:

        cmd = ['svn', 'export', url, path]

        return system(cmd,
                        simulate=simulate,
                        verbose=verbose)

    except SystemError as e:
        raise RuntimeError('SVN error: Unable to export from '
                        + url + ' to ' + path)


def svn_info(url,
        xml=True,
        simulate=False,
        verbose=False):
    """Retrieve information for the url

    @type url: string
    @param url: The url to get info for

    @type xml: bool
    @param xml: specify that the command must return xml message.
                [Default: True].

    @rtype: string
    @return: The standard output of the 'svn info' command
    """
    try:
        cmd = ['svn', 'info', url]

        if xml:
            cmd.append('--xml')

        return system(cmd,
                        simulate=simulate,
                        verbose=verbose)

    except SystemError as e:
        raise RuntimeError('SVN error: Unable to get info for ' + url)


def svn_list(url,
        xml=True,
        simulate=False,
        verbose=False):
    """List content of a specified url if it is a directory

    @type url: string
    @param url: The url to get list from

    @type xml: bool
    @param xml: specify that the command must return xml message.
                [Default: True].

    @rtype: string
    @return: The standard output of the 'svn list' command
    """
    try:
        cmd = ['svn', 'list', url]

        if xml:
            cmd.append('--xml')

        return system(cmd,
                        simulate=simulate,
                        verbose=verbose)

    except SystemError as e:
        raise RuntimeError('SVN error: Unable to list content of ' + url)

def svn_merge( source,
            dest,
            revision_range = None,
            accept = None,
            record_only = False,
            simulate = False,
            verbose = False ):
    """List content of a specified url if it is a directory
    
    @type source: string
    @param source: The source to merge history from
    
    @type dest: string
    @param dest: The destination to merge history to
    
    @type revision_range: tuple
    @param revision_range: specify the revision range to merge. When value is
                           None, revision range is set to 0:HEAD.
                           [Default = None]
    
    @type accept: string
    @param accept: specify the revision range to merge. [Default = None]
    
    @rtype: string
    @return: The standard output of the 'svn list' command
    """
    try:
      cmd = [ 'svn', 'merge', source, dest ]
      
      if revision_range is not None:
        if len(revision_range) != 2:
          raise RuntimeError( 'SVN error: Revision range list must contains 2 '
                            + 'revisions, not ' + str(len(revision_range)) )
      else:
        revision_range = ( 0, 'HEAD' )
        
      cmd += [ '-r', ':'.join( str(r) for r in revision_range ) ]
        
      if accept is not None:
        accept_values = ( 'postpone',
                          'base',
                          'mine-conflict',
                          'theirs-conflict',
                          'mine-full',
                          'theirs-full',
                          'edit',
                          'launch' )
                           
        if accept not in accept_values:
          raise RuntimeError( 'SVN error: Action for automatic conflict '
                            + 'resolution of merge command is not valid.'
                            + 'It must be one of the following:'
                            + (os.linesep + '- ').join( accept_values ) )
        cmd += [ '--accept', accept ]
      
      if record_only:
        cmd.append( '--record-only' )
        
      return system( cmd,
                     simulate = simulate,
                     verbose = verbose )
      
    except SystemError as e:
      raise RuntimeError( 'SVN error: Unable to merge ' + source
                        + ' and ' + dest )
    

def svn_mkdir( url,
             parents = False,
             simulate = False,
             verbose = False ):
    """Make a svn directory at the specified url.
    
    @type url: string
    @param url: The url of the directory to create
    
    @type parents: bool
    @param parents: Specify that intermediates directory should be created
                    if they do not exists [Default: False]
                    
    @rtype: string
    @return: The standard output of the 'svn mkdir' command
    """
    try:
      cmd = [ 'svn', 'mkdir', url ]
      if parents:
        cmd.append( '--parents' )
      
      return system( cmd,
                     simulate = simulate,
                     verbose = verbose )
      
    except SystemError as e:
      raise RuntimeError( 'SVN error: Unable to mkdir at ' + url )

def svn_move( source,
            dest,
            parents = False,
            message = '',
            simulate = False,
            verbose = False ):
    """Move the source url to the destination url keeping the history.
    
    @type source: string
    @param source: The source url to move from
    
    @type dest: string
    @param dest: The destination url to move to
    
    @type parents: bool
    @param parents: Specify that intermediates directory should be created
                    if they do not exists [Default: False]
    
    @type message: string
    @param message: The message to log changes in history

    @rtype: string
    @return: The standard output of the 'svn move' command
    """
    cmd = [ 'svn', 'move', source, dest, '-m', message ]
    if parents:
      cmd.append( '--parents' )

    return system( cmd,
                   simulate = simulate,
                   verbose = verbose )

def svn_rename( source,
                dest,
                message = '',
                simulate = False,
                verbose = False ):
    """Rename the source url to the destination url keeping the history.
    
    @type source: string
    @param source: The source url to move from
    
    @type dest: string
    @param dest: The destination url to move to

    @type message: string
    @param message: The message to log changes in history

    @rtype: string
    @return: The standard output of the 'svn move' command
    """
    cmd = [ 'svn', 'rename', source, dest, '-m', message ]

    return system( cmd,
                   simulate = simulate,
                   verbose = verbose )

def svn_propset( path,
               name,
               value,
               simulate = False,
               verbose = False  ):
    """ Set a property value of a file or directory
    
        @type path: string
        @param path: The path of the file or directory to set property for.

        @type name: string
        @param name: The name of the property to set.

        @type value: string
        @param value: The value of the property to set.
        
        @rtype: string
        @return: The standard output of the 'svn propset' command
    """
    try:
      cmd = [ 'svn', 'propset', name, value, path ]
        
      return system( cmd,
                     simulate = simulate,
                     verbose = verbose )
                     
    except SystemError as e:
      raise RuntimeError( 'SVN error: Unable to set property ' + name
                        + ' value: ' + value + ' for path: ' + path )

def svn_propget( path,
               name,
               verbose = False  ):
    """ Get a property value of a file or directory
    
        @type path: string
        @param path: The path of the file or directory to get property for.

        @type name: string
        @param name: The name of the property to get.
        
        @rtype: string
        @return: The standard output of the 'svn propget' command
    """
    try:
      cmd = [ 'svn', 'propget', name, path ]
        
      return system( cmd,
                     verbose = verbose )
                     
    except SystemError as e:
      raise RuntimeError( 'SVN error: Unable to get property ' + name
                        + ' value for path: ' + path )
                        
def svn_update( path,
              simulate = False,
              verbose = False  ):
    """ Update a working copy file or directory
    
        @type path: string
        @param path: The path of the file or directory to update.
        
        @rtype: string
        @return: The standard output of the 'svn update' command
    """
    try:
      cmd = [ 'svn', 'up', path ]
        
      return system( cmd,
                     simulate = simulate,
                     verbose = verbose )
                     
    except SystemError as e:
      raise RuntimeError( 'SVN error: Unable to update ' + path )
    
def svn_glob( *urlpatterns ):
    """ Process a search of matching svn entries using url patterns.
    
        @type urlpatterns: list of string
        @param urlpatterns: The list of url pattern to search entries for
        
        @rtype: list of string
        @return: The list of matching urls
    """
    # Create list to store matches
    url_matches = list()
    url_checked = set() # Contains url that have been checked for existance
                        # Used for optimization purpose
    
    # if type(urlpatterns) not in ( types.ListType, types.TupleType ):
      # urlpatterns = ( str(urlpatterns), )
    
    for url_pattern in urlpatterns:
      # Split url pattern
      url_pattern_splitted = urlsplit( normurl( url_pattern ) )
      
      # Create stack to solve pattern
      url_path_pattern_stack = list()
      url_path_pattern_stack.append(
          tuple(url_pattern_splitted.path.split(posixpath.sep)))
      
      while( len(url_path_pattern_stack) ):
        url_path_pattern_splitted = url_path_pattern_stack.pop()

        for i in six.moves.xrange(len(url_path_pattern_splitted)):
          # Find first path component that contains special characters
          if ( len(svn_glob_regexp.findall(
                                  url_path_pattern_splitted[i])) > 0 ):
            # Search matching entries from server
            url = urlunsplit(
                        url_pattern_splitted[ 0:2 ]
                        + ( posixpath.sep.join(
                            url_path_pattern_splitted[ 0:i ]
                        ), )
                        + url_pattern_splitted[ 3: ]
            )
                  
            # Check that url exists
            url_exists = False
            if ( url not in url_checked ) :
              if svn_exists( url ):
                url_exists = url_checked.add( url )
                url_exists = True
            
            # If the url does not exist, it is not possible to find
            # matching subdirectories
            if not url_exists:
                continue

            # Check that url is a directory
            # to avoid listings
            url_info = svn_info( url, xml = True )
            
            # Parses xml result
            l = lxml.objectify.fromstring( url_info )
            
            if l.xpath( 'entry/@kind' )[ 0 ] != 'dir' :
                continue
            
            url_list = svn_list( url, xml = True )
          
            # Parses xml result
            l = lxml.objectify.fromstring( url_list )
          
            # Get found entries
            for e in l.xpath( '*/entry' ):
              # print('Entry', url_path_pattern_splitted[ 0:i ] \
                          #+ ( str(e.name), ) \
                          #+ url_path_pattern_splitted[ i + 1: ])
              if fnmatch.fnmatch( str(e.name), url_path_pattern_splitted[i]):
                # Stacking the found entry matching pattern
                url_path_pattern_stack.append(
                                        url_path_pattern_splitted[ 0:i ]
                    + ( str(e.name), )
                    + url_path_pattern_splitted[ i + 1: ] )
                url_checked.add(
                    urlunsplit(
                    url_pattern_splitted[ 0:2 ]
                    + ( posixpath.sep.join( url_path_pattern_splitted[ 0:i ]
                                            + ( str(e.name), ) ), )
                    + url_pattern_splitted[ 3: ] ) )
                # print('matches')
                  
              # else:
                # print('not matches')
            break
            
          elif( i == (len(url_path_pattern_splitted) - 1) ):
            url = urlunsplit(
                        url_pattern_splitted[ 0:2 ]
                        + ( posixpath.sep.join( url_path_pattern_splitted ), )
                        + url_pattern_splitted[ 3: ]
            )

            if ( url not in url_checked ) :
              # Check that the element exists
              if svn_exists( url ):
                url_matches.append( url )
                url_checked.add( url )
                
            else:
              url_matches.append( url )
          
    return url_matches

def svn_update_version_info( version_file_url,
                             version = None,
                             version_format = version_format_release,
                             message = '',
                             simulate = False,
                             verbose = False ):
        """ Update the project info file for component branch version.
        
            @type: string
            @param version_file_url: The url of version file to update
                                [Default: None].
            
            @type: string
            @param version: The version to set in the project info file
                            [Default: None].
                                
            @type: string
            @param message: The message used to log the version info update in
                            svn. [Default: ''].
                            
            @rtype: bool
            @return: True if the project info version was updated, False 
                     otherwise.
        """
        import os, posixpath
        
        from brainvisa_cmake.brainvisa_clients import find_remote_project_info
        
        version = VersionNumber(
            version,
            format = version_format
        )
        tmp_dir = tempfile.mkdtemp()
        
        version_file_url_dir = posixpath.dirname(
            version_file_url
        )
        version_file_url_basename = posixpath.basename(
                                        version_file_url
                                    )
        
        version_file_local_dir = tmp_dir
                                
        svn_checkout(
            version_file_url_dir,
            version_file_local_dir,
            depth = 'files',
            verbose = verbose
        )
        
        version_file_path = os.path.join( version_file_local_dir,
                                          version_file_url_basename )
        if not os.path.exists( version_file_path ):
            return False
        
        version_file_content = open( version_file_path ).read()
        
        # Set version in project info file
        # It needs to have a version with at least 3
        # numbers
        if len(version) < 3:
            version.resize(3)
        
        if version_file_path.endswith( '.cmake' ):
            pattern = re.compile(
                r'BRAINVISA_PACKAGE_VERSION_MAJOR.+'
                r'BRAINVISA_PACKAGE_VERSION_PATCH \d+',
                re.DOTALL
            )
            
            version_file_content_new = pattern.sub(
                'BRAINVISA_PACKAGE_VERSION_MAJOR '
                + str(version[0]) + ' )\n'
                + 'set( BRAINVISA_PACKAGE_VERSION_MINOR '
                + str(version[1]) + ' )\n'
                + 'set( BRAINVISA_PACKAGE_VERSION_PATCH '
                + str(version[2]),
                version_file_content
            )
                                      
        elif version_file_path.endswith( '.py' ):
            pattern = re.compile(
                r'version_major.+\nversion_micro\s*=\s*\d+',
                re.DOTALL
            )
      
            version_file_content_new = pattern.sub(
                'version_major = ' + str(version[0]) + '\n'
                + 'version_minor = ' + str(version[1]) + '\n'
                + 'version_micro = ' + str(version[2]),
                version_file_content
            )
    
        if version_file_content != version_file_content_new:
            # Write new project info content to file
            # and commit local changes to the branch
            f = open( version_file_path, "w" )
            f.write( version_file_content_new )
            f.close()
            
            
            svn_commit(
                version_file_path,
                message = message,
                simulate = simulate,
                verbose = verbose
            )
            
        else:
            return False

        return True


# Define API functions
vcs_export = svn_export
vcs_glob = svn_glob
vcs_update_version_info = svn_update_version_info

class SvnComponent( VersionControlComponent ):

    KEY                     = 'svn'
    
    TRUNK_DIR               = 'trunk'
    BUG_FIX_DIR             = 'branches'
    RELEASES_DIR            = 'tags'
    VIEWS_DIR               = 'views'
    
    LATEST_RELEASE_ALIAS    = 'latest_release'
    LATEST_BUG_FIX_ALIAS    = 'bug_fix'
    
    def __init__( self,
                  project,
                  name,
                  path,
                  url,
                  params = None ):
        """ SvnComponent constructor.
            Be aware that SvnComponent uses a version cache to avoid svn 
            overhead accesses. This cache
        
            @type project: string
            @param project: The project name of the component
            
            @type name: string
            @param name: The name of the component
            
            @type path: string
            @param path: The relative path of the component
            
            @type url: string
            @param url: The client url to build the component

            @type params: string
            @param params: The versioning client parameters to use
        """
        super( SvnComponent, self ).__init__( project,
                                              name,
                                              path,
                                              url,
                                              params )
        
        parsed_url = urlparse( self.url() )
        
        # Find tags, branches, trunk in url to get a base url
        client_url_branch_type, client_url_base_path = self.branch_path_parse(
                                                            parsed_url.path
        )
              
        client_local_branch_type, client_local_base_path = \
                                                       self.branch_path_parse(
                                                           self.path()
                                                       )
        
        if not client_url_branch_type :
            raise RuntimeError( 'Url ' + self.url() + ' has not a valid '
                              + 'subversion structure for BrainVISA '
                              + 'components. It must contain a directory '
                              + 'among : trunk, branches, tags)' )
                                
        # if client_url_branch_type != client_local_branch_type:
            # raise RuntimeWarning( 'Url ' + self.url() + ' refers to a branch '
                                #+ 'type ' + client_url_branch_type + ' whereas '
                                #+ 'the local directory ' + self.path()
                                #+ ' refers to a different branch type '
                                #+ client_local_branch_type )
        
        self._url_branch_type = client_url_branch_type
        self._url_base = urlunparse( parsed_url[ 0:2 ]
                                     + ( client_url_base_path, )
                                     + parsed_url[ 3: ] )
                                            
        self._local_base = client_local_base_path
                                            
        # This is used to do local temporary operations
        # and to not retrieve files multiple times
        self._local_branches = dict()
        
        # This is used to cache versions
        self._branch_versions = dict()

    @classmethod
    def branch_path_parse( cls,
                           path,
                           sep = posixpath.sep ):
        """ Class method to parse a path and get the associated
            branch type and branch base path. The type can normally
            be infered from the given path. i.e. a path that contains a
            trunk directory is normally associated to a trunk version, etc.
        
            @type path: string
            @param path: The path to parse and find branch type and base path
                         from.
        
            @type sep: string
            @param sep: The path separator used to split the path.
                         
            @rtype: tuple
            @return: A tuple that contains the branch type and the base path
                     (i.e. the path without the branch type and directories
                           after)
        """
        
        # Find tags, branches, trunk in url to get a base url
        base_path = list()
        branch_type = None
        for d in path.split(sep):
            if d in ( SvnComponent.TRUNK_DIR,
                      SvnComponent.BUG_FIX_DIR,
                      SvnComponent.RELEASES_DIR,
                      SvnComponent.VIEWS_DIR ):
                branch_type = d
                break
                
            else:
                base_path.append(d)
                
        return ( branch_type,
                 posixpath.join( *base_path ), )
                 
    @classmethod
    def get_client( cls ) :
        """ Class method to get the Client class associated to the current
            VersionControlComponent class
        
            @rtype: Client
            @return: The Client class associated to the current
                     VersionControlComponent class
        """
        import brainvisa_cmake.svn
        
        return brainvisa_cmake.svn

    def __str__( self ) :
        """ SvnComponent string conversion
        
            @rtype: string
            @return: The string to display for the instance of SvnComponent
        """
        return os.linesep.join(
                    [ 'component: ' + self.project() + ':' + self.name(),
                      '- client_type: ' + self.get_client().__name__,
                      '- url: ' +  self.url(),
                      '- params: ' + str(self.params()),
                      '- url_branch_type: ' + self._url_branch_type,
                      '- url_base: ' + self._url_base ] )
        
    def branch_url( self,
                    branch_type = BranchType.TRUNK,
                    branch_name = None ):
        """ Get the svn url for a BranchType and a name
        
            @type: string
            @param branch_type: The svn BranchType to get url for
        
            @type: string
            @param branch_name: The name of the branch to get url for
            
            @rtype: string
            @return: The svn url of the branch for the specified name
        """
        if ( branch_type == BranchType.TRUNK ) :
            dirname = SvnComponent.TRUNK_DIR
        
        elif ( branch_type == BranchType.BUG_FIX ) :
            dirname = SvnComponent.BUG_FIX_DIR
        
        elif ( branch_type == BranchType.RELEASE ) :
            dirname = SvnComponent.RELEASES_DIR
        
        if (branch_name is None) or (branch_type == BranchType.TRUNK) :
            return posixpath.join( self._url_base,
                                   dirname )
        else:
            return posixpath.join( self._url_base,
                                   dirname,
                                   branch_name )
        
    def branch_path( self,
                      branch_type = BranchType.TRUNK,
                      branch_name = None ):
        """ Get the svn local path for a BranchType and a name
        
            @type: string
            @param branch_type: The svn BranchType to get local path for
        
            @type: string
            @param branch_name: The name of the branch to get local path for
            
            @rtype: string
            @return: The svn local path of the branch for the specified name.
        """
        if ( branch_type == BranchType.TRUNK ) :
            dirname = SvnComponent.TRUNK_DIR
        
        elif ( branch_type == BranchType.BUG_FIX ) :
            dirname = SvnComponent.BUG_FIX_DIR
        
        elif ( branch_type == BranchType.RELEASE ) :
            dirname = SvnComponent.RELEASES_DIR
        
        if (branch_name is None) or (branch_type == BranchType.TRUNK) :
            return os.path.join( self._local_base,
                                 dirname )
        else:
            return os.path.join( self._local_base,
                                 dirname,
                                 branch_name )
                 
    def branch_list( self,
                     branch_type = BranchType.TRUNK,
                     patterns = [ '*' ] ) :
        """ Lists branch children that matches one of the given patterns.
        
            @type: string
            @param branch_type: The svn BranchType to get children for.
            
            @type: string
            @param patterns: The list of patterns to match
                                     [Default: *].
            
            @rtype: list
            @return: A list that contains matching branch entries.
        """
        import fnmatch, lxml.objectify

        if not isinstance(patterns, (list, tuple)):
            patterns = ( str( patterns ), )
        
        entries = list()
        branch_url = self.branch_url( branch_type )
        
        # Parses xml result
        l = lxml.objectify.fromstring(
                self.client().svn_list( branch_url )
            )
        
        for e in l.xpath( '*/entry' ):
            for p in patterns:
                if fnmatch.fnmatch( str(e.name), p ):
                    if e.xpath( '@kind' )[ 0 ] == 'dir':
                        t = 'dir'
                    else:
                        t = 'file'
                        
                    entries.append( ( t, str(e.name) ) )
                    break
                
        return entries
        
    def branch_versions( self,
                         branch_type = BranchType.TRUNK,
                         version_patterns = [ '*' ] ) :
        """ Returns a dictionary of branch versions for a BranchType and a list
            of version patterns. To build this version dictionary, version
            are processed from branch name when it is possible, otherwise the
            project info file of the branch is parsed. When the version matches
            one of the version patterns, it is added to the result dictionary.
        
            @type: string
            @param branch_type: The svn BranchType to get versions for.
            
            @type: string
            @param version_patterns: The list of version patterns to match
                                     [Default: *].
            
            @rtype: dict
            @return: A dictionary that contains matching versions as keys
                     and their associated branch name
        """
        import fnmatch, lxml.objectify
        
        from brainvisa_cmake.version_number import VersionNumber
        
        if not isinstance(version_patterns, (list, tuple)):
            version_patterns = ( str( version_patterns ), )
        
        versions = dict()
        if ( branch_type == BranchType.TRUNK ) :
            v = self.branch_version( branch_type )
            versions[ VersionNumber( v, format = self._version_format ) ] = None
        
        else :
            branch_url = self.branch_url( branch_type )
            # Parses xml result
            l = lxml.objectify.fromstring(
                    self.client().svn_list( branch_url )
                )
            
            for e in l.xpath( '*/entry' ):
                if e.xpath( '@kind' )[ 0 ] == 'dir' :
                    # Read the version for the branch
                    v = self.branch_version(
                            branch_type,
                            str(e.name)
                        )
                              
                    for p in version_patterns:
                        if fnmatch.fnmatch( str(v), p ):
                            versions[ v ] = str(e.name)
                            break
                
        return versions
    
    def branch_version( self,
                        branch_type = BranchType.TRUNK,
                        branch_name = None ):
        """ Get the version for a BranchType and a name.
            
            @type branch_type: string
            @param branch_type: The BranchType to get version list for.
                                [Default: BranchType.TRUNK ]
            
            @type branch_name: string
            @param branch_name: The name of branch to get version for
                                [Default: None ].

            @rtype: string
            @return: The version for the branch if was possible to get it,
                     None otherwise.
        """
        from brainvisa_cmake.version_number import VersionNumber
        
        branch_version_key = ( branch_type, branch_name )
        if self._branch_versions.get( branch_version_key ) is None :
            if ( branch_type == BranchType.TRUNK ) \
                or ( branch_type == BranchType.BUG_FIX ) \
                or ( branch_type == BranchType.RELEASE \
                    and branch_name == self.LATEST_RELEASE_ALIAS ):
                # Read version from project info file
                p, c, v = self.branch_project_info(
                            branch_type,
                            branch_name
                        )
                
                branch_version = VersionNumber(
                                    v,
                                    format = self._version_format
                                )
            
            else:
                # Uses the branch name as the version. Be aware that, in this case
                branch_version = VersionNumber(
                                    branch_name,
                                    format = self._version_format
                                )
                                
            # Insert version in cache
            self._branch_versions[ branch_version_key ] = branch_version
            
            return branch_version
            
        else :
            return self._branch_versions[ branch_version_key ]
            
    def branch_name( self,
                     branch_type = BranchType.TRUNK,
                     version = None,
                     use_alias = True ):
        """ Get the name of a branch for a BranchType and a version.
            For BranchType.TRUNK the name returned is always None,
            for BranchType.BUG_FIX the name returned is the bug_fix version or
            'bug_fix' if the version is >= to the latest bug_fix version and
            use_alias is set to True, for BranchType.RELEASE the name returned
            is the release version or 'latest_release' if the version is >= to 
            the latest release version and use_alias is set to True.
            
            @type branch_type: string
            @param branch_type: The BranchType to get branch name for.
                                [Default: BranchType.TRUNK ]
            
            @type version: string
            @param version: The version of the branch to get name for
                            [Default: None ].
            
            @type use_alias: bool
            @param use_alias: Specify that the branch alias must be used
                              when needed
                              [Default: True ].
                            
            @rtype: string
            @return: The name of the branch if it was possible to get it,
                     None otherwise.
        """
        from brainvisa_cmake.version_number import VersionNumber
        
        if ( branch_type == BranchType.TRUNK ):
            return None
            
        else:
            version = VersionNumber( version, format = self._version_format )
            
            if ( branch_type == BranchType.BUG_FIX ):
                # bug_fix branches are named using 2 digits
                name = str(version[:2])
            else:
                # release branches are named using 3 digits
                name = str(version[:3])

            if use_alias:
                # When a branch named using the given version already exists
                # we do not use the alias
                if not self.client().svn_exists(
                    self.branch_url(
                            branch_type,
                            name
                    )
                ):
                    branch_version_max, branch_name_max = self.branch_version_max(
                                                            branch_type
                                                        )
                                                        
                    if version >= branch_version_max:
                        # The given version is the latest for the branch
                        if ( branch_type == BranchType.BUG_FIX ):
                            return self.LATEST_BUG_FIX_ALIAS
                        else:
                            return self.LATEST_RELEASE_ALIAS
                    
            # Uses the version as the branch name
            return name
            
    def branch_project_info( self,
                             branch_type = BranchType.TRUNK,
                             branch_name = None ) :
        """ Reads project info file for a BranchType and a version.
        
            @type: string
            @param branch_type: The svn BranchType to get the project info for
                                [Default: BranchType.TRUNK].
            
            @type: string
            @param branch_name: The name of the branch to get project info for
                                [Default: None].
            
            @rtype: tuple
            @return: A tuple containing project name, component name and version
                     read from the project info file.
        """
        from brainvisa_cmake.brainvisa_clients import read_remote_project_info
        
        info = read_remote_project_info(
                    self.client(),
                    self.branch_url( branch_type,
                                     branch_name ),
                    version_format = self._version_format
        )
               
        if info is None:
            return (self.project(), self.name(), None)
            
        else:
            return (self.project(), self.name(), info[2])
    
    def branch_exists( self,
                       branch_type = BranchType.TRUNK,
                       branch_name = None ):
        """ Checks that a BranchType version exists.
        
            @type: string
            @param branch_type: The svn BranchType to check
                                [Default: BranchType.TRUNK].
            
            @type: string
            @param branch_name: The name of the branch to check
                                [Default: None].
            
            @rtype: bool
            @return: True if the branch exists for the specified name,
                     False otherwise.
        """
        return self.client().svn_exists(
                    self.branch_url( branch_type,
                                     branch_name ) )
    
    def branch_create( self,
                       src_branch_type = BranchType.TRUNK,
                       src_branch_name = None,
                       dest_branch_type = BranchType.BUG_FIX,
                       dest_branch_name = None,
                       message = '',
                       simulate = False,
                       verbose = False ):
        """ Creates a new branch from a source branch.
        
            @type: string
            @param src_branch_type: The source BranchType to create from
                                    [Default: BranchType.TRUNK].
            
            @type: string
            @param src_branch_name: The name of the source branch to create from
                                    [Default: None].
            @type: string
            @param dest_branch_type: The destination BranchType to create
                                     [Default: BranchType.BUG_FIX].
            
            @type: string
            @param dest_branch_name: The name of the destination branch to
                                     create
                                     [Default: None].
                                
            @type: string
            @param message: The message to log to create the branch
                            [Default: ''].
        """
        src_branch_url = self.branch_url( src_branch_type,
                                          src_branch_name )
        dest_branch_url = self.branch_url( dest_branch_type,
                                           dest_branch_name )
                                           
        if ( ( dest_branch_type == BranchType.BUG_FIX ) \
               and ( dest_branch_name == self.LATEST_BUG_FIX_ALIAS ) ) \
           or \
           ( ( dest_branch_type == BranchType.RELEASE ) \
               and ( dest_branch_name == self.LATEST_RELEASE_ALIAS ) ):
            if self.client().svn_exists( dest_branch_url ):
                # It is necessary to first move the latest branch to its version
                # branch
                dest_version = self.branch_version(
                    dest_branch_type,
                    dest_branch_name
                )
                
                # Get the branch_name without aliases to rename:
                # bug_fix => X.Y
                # latest_release => X.Y.Z
                dest_version_branch_name = self.branch_name(
                                                dest_branch_type,
                                                dest_version,
                                                use_alias = False
                )
                dest_version_branch_url = self.branch_url(
                    dest_branch_type,
                    dest_version_branch_name
                )
                self.client().svn_move(
                    dest_branch_url,
                    dest_version_branch_url,
                    parents = True,
                    message = message,
                    simulate = simulate,
                    verbose = verbose
                )
                
                # Update version in cache
                self._branch_versions[
                    ( dest_branch_type,
                      dest_version_branch_name )
                ] = dest_version
        
        self.client().svn_copy(
            src_branch_url,
            dest_branch_url,
            parents = True,
            message = message,
            simulate = simulate,
            verbose = verbose
        )
        
    def branch_local_temporary( self,
                                branch_type = BranchType.TRUNK,
                                branch_name = None,
                                dir = None ):
        """ Get a local temporary directory associated to the client
            component branch name.
        
            @type: string
            @param branch_type: The BranchType to get local temporary directory
                                for
                                [Default: BranchType.TRUNK].
            
            @type: string
            @param branch_name: The name to get local temporary directory for
                                [Default: None].
            
            @rtype: string
            @return: local temporary directory associated to the client
                     component branch version.
        """
        if (branch_type, branch_name) not in self._local_branches:
            self._local_branches[ (branch_type, branch_name) ] = \
                tempfile.mkdtemp( prefix = '_'.join( ( self.project(),
                                                       self.name() ) ),
                                  dir = dir
                )

        return self._local_branches[ (branch_type, branch_name) ]
    
    def branch_update_version_info( self,
                                    branch_type = BranchType.TRUNK,
                                    branch_name = None,
                                    version = None,
                                    message = '',
                                    simulate = False,
                                    verbose = False ):
        """ Update the project info file for component branch version.
        
            @type: string
            @param branch_type: The BranchType to update project info file for
                                [Default: BranchType.TRUNK].
            
            @type: string
            @param branch_name: The name of the branch to update project info
                                file for
                                [Default: None].
            
            @type: string
            @param version: The version to set in the project info file
                            [Default: None].
                                
            @type: string
            @param message: The message used to log the version info update in
                            svn. [Default: ''].
                            
            @rtype: bool
            @return: True if the project info version was updated, False 
                     otherwise.
        """
        import os, posixpath
        
        from brainvisa_cmake.version_number import VersionNumber
        from brainvisa_cmake.brainvisa_clients import find_remote_project_info
        
        version = VersionNumber(
            version,
            format = self._version_format
        )
        
        # Checkout the branch files to a local directory
        branch_local = self.branch_local_temporary( branch_type,
                                                    branch_name )
        branch_url = self.branch_url( branch_type,
                                      branch_name )
                                    
        project_info_url = find_remote_project_info(
            self.client(),
            branch_url
        )
        
        if project_info_url is None:
            return False
            
        project_info_url_rel = project_info_url[ len(branch_url) + 1: ]
        
        project_info_url_dir = posixpath.dirname(
            project_info_url
        )
        
        project_info_local_dir = os.path.dirname(
                                    os.path.join(
                                        branch_local,
                                        project_info_url_rel
                                    )
        )
                                
        self.client().svn_checkout(
            project_info_url_dir,
            project_info_local_dir,
            depth = 'files',
            verbose = verbose
        )
        
        project_info_path = os.path.join( branch_local,
                                          project_info_url_rel )
        if not os.path.exists( project_info_path ):
            return False
        
        project_info_content = open( project_info_path ).read()
        
        # Set version in project info file
        # It needs to have a version with at least 3
        # numbers
        if len(version) < 3:
            version.resize(3)
        
        if project_info_path.endswith( '.cmake' ):
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
                                      
        elif project_info_path.endswith( '.py' ):
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
            # Write new project info content to file
            # and commit local changes to the branch
            f = open( project_info_path, "w" )
            f.write( project_info_content_new )
            f.close()
            
            self.client().svn_commit(
                project_info_path,
                message = message,
                simulate = simulate,
                verbose = verbose
            )

            self.client().svn_update(
                project_info_local_dir,
                verbose = verbose
            )
            
        else:
            return False

        # Update version in cache
        self._branch_versions[ ( branch_type, branch_name ) ] = version
        
        return True
    
    def branch_merge_version_info( self,
                                   src_branch_type = BranchType.BUG_FIX,
                                   src_branch_name = None,
                                   dest_branch_type = BranchType.TRUNK,
                                   dest_branch_name = None,
                                   message = '',
                                   simulate = False,
                                   verbose = False ):
        """ Merge the project info file for component branch version.
        
            @type: string
            @param src_branch_type: The source BranchType to merge project info
                                    file for
                                    [Default: BranchType.TRUNK].
            
            @type: string
            @param src_branch_name: The source branch to merge project info file
                                    for
                                    [Default: None].

            
            @type: string
            @param dest_branch_type: The destination BranchType to merge project
                                     info file for
                                     [Default: BranchType.TRUNK].
            
            @type: string
            @param dest_branch_name: The destination branch to merge project
                                     info file for
                                     [Default: None].
            
            @type: string
            @param message: The message used to log the merge of version info in
                            svn.
                            [Default: ''].
                            
            @rtype: bool
            @return: True if the project info version was merged, False 
                     otherwise.
        """
        import time, os, posixpath
        from brainvisa_cmake.brainvisa_clients import find_remote_project_info
        
        # Checkout the branch files to a local directory
        src_branch_local = self.branch_local_temporary( src_branch_type,
                                                        src_branch_name )
        dest_branch_local = self.branch_local_temporary( dest_branch_type,
                                                         dest_branch_name )        
        src_branch_url = self.branch_url( src_branch_type,
                                          src_branch_name )
        dest_branch_url = self.branch_url( dest_branch_type,
                                           dest_branch_name )
                                        
        src_project_info_url = find_remote_project_info(
            self.client(),
            src_branch_url
        )
                                        
        dest_project_info_url = find_remote_project_info(
            self.client(),
            dest_branch_url
                                )
                               
        if src_project_info_url is None or dest_project_info_url is None:
            return False
            
        src_project_info_url_rel = src_project_info_url[ len(src_branch_url) + 1: ]
        dest_project_info_url_rel = dest_project_info_url[ len(dest_branch_url) + 1: ]
        
        src_project_info_url_dir = posixpath.dirname(
            src_project_info_url
        )
        
        dest_project_info_url_dir = posixpath.dirname(
                                        dest_project_info_url
                                    )
        
        src_project_info_local_dir = os.path.dirname(
            os.path.join(
                src_branch_local,
                src_project_info_url_rel
            )
        )
        
        dest_project_info_local_dir = os.path.dirname(
            os.path.join(
                dest_branch_local,
                dest_project_info_url_rel
            )
        )
                                         
        # Checkout directory of project info file
        self.client().svn_checkout(
            src_project_info_url_dir,
            src_project_info_local_dir,
            depth = 'files',
            verbose = verbose
        )

        self.client().svn_checkout(
            dest_project_info_url_dir,
            dest_project_info_local_dir,
            depth = 'files',
            verbose = verbose
        )
        
        time.sleep(1)
        
        self.client().svn_merge(
            src_project_info_local_dir,
            dest_project_info_local_dir,
            accept = 'mine-full',
            record_only = True,
            verbose = verbose
        )
    
        self.client().svn_commit(
            dest_project_info_local_dir,
            message = message,
            simulate = simulate,
            verbose = verbose
        )
        
        return True
        
