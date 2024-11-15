# -*- coding: utf-8 -*-

from brainvisa_cmake.version_number        import VersionNumber, \
                                                  version_format_release
from brainvisa_cmake.brainvisa_projects    import parse_versioning_client_info
from brainvisa_cmake.brainvisa_clients     import normurl

class BranchType(object):
    """ Branch types that can be used by clients
        TRUNK: branch used for main development and new features integration
        BUG_FIX: branch that are created to initiate a release and that can be
                bug fixed
        RELEASE: branch that is never modified and that correspond to a release
    """

    TRUNK = 'trunk'
    BUG_FIX = 'bug_fix'
    RELEASE = 'release'


#class BranchVersionReadingMode:
    #""" Modes available to read branch version
        #AUTO: branch version is read :
              #- from branch/name when possible, from project info file in other
                #cases.
                #This is fastest mode because it limits version control use but 
                #but can return incomplete version. For example a bug_fix/2.7
                #branch wich has a project info 2.7.3 version when read from name
                #is read 2.7 version.
              #- or projectversion used for main development and new features integration
        #PROJECT_INFO_ALWAYS: branch that is never modified and that correspond
                             #to a release
    #"""
    #AUTO = -1
    #PROJECT_INFO_ALWAYS = 1

def get_version_control_component( project,
                                   name,
                                   client_info  ):
    """ Return a VersionControlComponent using its associated client
        information.
    
        @type project: string
        @param project: The project name of the component
        
        @type name: string
        @param name: The name of the component
        
        @type client_info: string
        @param client_info: The versioning client information is described using
                            the format <client_type> <url> [<client_parameters>]
                            i.e: svn https://bioproj.extra.cea.fr/neurosvn/brainvisa/aims/aims-gpl/branches/4.4
                              or git https://github.com/neurospin/soma-workflow.git master
    """
    from brainvisa_cmake import svn
    from brainvisa_cmake.svn import SvnComponent
    
    client_key, client_url, client_params = parse_versioning_client_info(
                                                client_info[0]
                                            )
    client_path = client_info[1]
                    
    if client_key != 'svn':
        raise RuntimeError('Found invalid source management type: "%s". Only "svn" is implemented.' % client_key)
    
    return SvnComponent( project, name,
                         client_path,
                         client_url, client_params )
        
class VersionControlComponent(object):
    """ Base abstract class that is used to get component informations
        independently of its version control type (svn, ...)
    """
    def __init__( self,
                  project,
                  name,
                  path,
                  url,
                  params = None ):
        """ VersionControlComponent constructor
        
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
        super( VersionControlComponent, self ).__init__()
        
        self._project = project
        self._name = name
        self._path = path
        self._url = normurl( url )
        self._params = params
        self._client = self.get_client()
        self._version_format = version_format_release           # Version format

    def client( self ) :
        """ Returns a Client instance associated to the VersionControlComponent
        
            @rtype: Client
            @return: The Client instance associated to the
                     VersionControlComponent
        """
        return self._client

    @classmethod
    def get_client( cls ) :
        """ Class method that returns a Client object associated to the
            VersionControlComponent.
            This method must be implemented by subclasses.
        
            @rtype: Client
            @return: The Client class associated to the VersionControlComponent
        """
        raise RuntimeError( 'VersionControlComponent: client_type method is '
                          + 'not implemented. It must be defined by '
                          + 'subclasses.' )

    def name( self ) :
        """ Returns the name of the VersionControlComponent.
        
            @rtype: string
            @return: The name of the VersionControlComponent
        """
        return self._name

    def project( self ) :
        """ Returns the project of the VersionControlComponent.
        
            @rtype: string
            @return: The project of the VersionControlComponent
        """
        return self._project

    def path( self ) :
        """ Returns the local path of the VersionControlComponent.
        
            @rtype: string
            @return: The local path of the VersionControlComponent
        """
        return self._path
        
    def url( self ) :
        """ Returns the url of the VersionControlComponent.
        
            @rtype: string
            @return: The url of the VersionControlComponent
        """
        return self._url
        
    def params( self ) :
        """ Returns the parameters used by the VersionControlComponent.
        
            @rtype: string
            @return: The parameters used by the VersionControlComponent
        """
        return self._params

    def branch_version_is_max( self,
                               branch_type,
                               version ):
        """ Check that a version is the maximum version for a BranchType.
            
            @type: string
            @param branch_type: The BranchType to check maximum version.
            
            @type: string
            @param version: The version to check.
            
            @rtype: bool
            @return: A boolean that is True if the version is the maximum for
                     the branch_type, False otherwise. When no branch version
                     exists, version is always the maximum version.
        """
        branch_version_max, branch_name = self.branch_version_max( branch_type )
        
        # When branch_info or branch_info[0] are None, it means that no version
        # was found for the specified branch_type. So the given version is
        # necessarly the maximum version.
        return ( branch_version_max < VersionNumber( version,
                                                     format = self._version_format ) )
        
    def branch_version_max( self,
                            branch_type = BranchType.TRUNK,
                            version_patterns = [ '*' ] ):
        """ Maximum version for a BranchType and a list of version patterns.
            
            @type: string
            @param branch_type: The BranchType to get maximum version for.
            
            @type: list
            @param version_patterns: The version patterns to match
                                     [Default: [ '*' ] ].
            
            @rtype: string
            @return: A tuple that contains the maximum version and the branch
                     name for the branch type and version patterns.
        """
        branch_versions = self.branch_versions(
                              branch_type = branch_type,
                              version_patterns = version_patterns
                          )
        if (len(branch_versions) > 0):
            m =  max( branch_versions.keys() )
            return ( m, branch_versions[m] )
        
        return ( VersionNumber(
                     None,
                     format = self._version_format
                 ), None )
    
    def branch_versions( self,
                         branch_type = BranchType.TRUNK,
                         version_patterns = [ '*' ] ):
        """ Returns a dictionary of branch versions for a BranchType. Versions
            returned matches at least one of the version patterns.
            This method must be implemented by subclasses.
            
            @type: string
            @param branch_type: The svn BranchType to get versions for.
            
            @type: string
            @param version_patterns: The list of version patterns to match
                                     [Default: *].
            
            @rtype: dict
            @return: A dictionary that contains matching versions as keys
                     and their associated branch name
        """
        raise RuntimeError( 'VersionControlComponent: branch_version_list '
                          + 'method is not implemented. It must be defined by '
                          + 'subclasses.' )
    
    def branch_version( self,
                        branch_type = BranchType.TRUNK,
                        branch_name = None):
        """ Get the version for a BranchType and a name.
            This method must be implemented by subclasses.
            
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
        raise RuntimeError( 'VersionControlComponent: branch_version method '
                          + 'is not implemented. It must be defined by '
                          + 'subclasses.' )
    
    def branch_version_inc( self, branch_type, version ):
        """ Increments the version for a specified branch type.
            If the branch_type is:
            - BranchType.TRUNK => the version is incremented at the major position
                                (position 0). i.e. '1.2.3' => '2.0.0'. If the
                                version to increment is None, '1' is returned.
                                
            - BranchType.BUG_FIX => the version is incremented at the minor position
                                (position 1). i.e. '1.2.3' => '1.3.0'. If the
                                version to increment is None, '1.0' is returned.
                                
            - BranchType.RELEASE => the version is incremented at the micro position
                                (position 2). i.e. 1.2.3 => 1.2.4. If the
                                version to increment is None, '1.0.0' is returned.
            
            @type branch_type: BranchType
            @param branch_type: The type of the branch to increment version for.
            
            @type version: string
            @param version: The version to increment.
            
            @rtype: string
            @return: The incremented version for the branch type.
        """
        version = VersionNumber(
                      version,
                      format = self._version_format
                  )
        
        if branch_type == BranchType.TRUNK:
            position = 0
        
        elif branch_type == BranchType.BUG_FIX:
            position = 1
        
        elif branch_type == BranchType.RELEASE:
            position = 2
        
        else:
            raise RuntimeError( 'Unable to increment version:', version,
                                'for unknown branch type:', branch_type )
        
        return version.increment( position = position )
    
    def branch_name( self,
                     branch_type = BranchType.TRUNK,
                     version = None,
                     use_alias = True ):
        """ Get the name of a branch for a BranchType and a version.
            This method must be implemented by subclasses.
            
            @type: string
            @param branch_type: The BranchType to get branch name for.
                                [Default: BranchType.TRUNK ]
            
            @type: string
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
        raise RuntimeError( 'VersionControlComponent: branch_name method is '
                          + 'not implemented. It must be defined by '
                          + 'subclasses.' )
                          
    def branch_project_info( self,
                             branch_type = BranchType.TRUNK, 
                             branch_name = None ) :
        """ Reads project info file for a BranchType and a version.
            This method must be implemented by subclasses.
            
            @type: string
            @param branch_type: The BranchType to get the project info for
                                [Default: BranchType.TRUNK].
            
            @type: string
            @param branch_name: The branch to get project info for
                                [Default: None].
            
            @rtype: tuple
            @return: A tuple containing project name, component name and version
                     read from the project info file.
        """
        raise RuntimeError( 'VersionControlComponent: branch_project_info '
                          + 'method is not implemented. It must be defined by '
                          + 'subclasses.' )
    
    def branch_exists( self,
                       branch_type = BranchType.TRUNK,
                       branch_name = None ):
        """ Checks that a BranchType version exists.
            This method must be implemented by subclasses.
            
            @type: string
            @param branch_type: The BranchType to check
                                [Default: BranchType.TRUNK].
            
            @type: string
            @param branch_name: The branch name to check
                                [Default: None].
            
            @rtype: bool
            @return: True if the branch exists for the specified version,
                     False otherwise.
        """
        raise RuntimeError( 'VersionControlComponent: branch_exists method is '
                          + 'not implemented. It must be defined by '
                          + 'subclasses.' )
  
    def branch_create( self,
                       src_branch_type = BranchType.TRUNK,
                       src_branch_name = None,
                       dest_branch_type =  BranchType.BUG_FIX,
                       dest_branch_name = None,
                       message = '',
                       simulate = False,
                       verbose = False ):
        """ Creates a new branch from a source branch.
            This method must be implemented by subclasses.
            
            @type: string
            @param src_branch_type: The source BranchType to create from
                                    [Default: BranchType.TRUNK].
            
            @type: string
            @param src_branch_name: The source branch name to create from
                                    [Default: None].
            @type: string
            @param dest_branch_type: The destination BranchType to create
                                    [Default: BranchType.BUG_FIX].
            
            @type: string
            @param dest_branch_name: The destination branch name to create
                                     [Default: None].
            
            @type: string
            @param message: The message to log to create the branch
                            [Default: ''].
        """
        raise RuntimeError( 'VersionControlComponent: branch_create method is '
                          + 'not implemented. It must be defined by '
                          + 'subclasses.' )

    
    def branch_update_version_info( self,
                                    branch_type = BranchType.TRUNK,
                                    branch_name = None,
                                    version = None,
                                    message = '',
                                    simulate = False,
                                    verbose = False ):
        """ Update the project info file for component branch version.
            This method must be implemented by subclasses.
            
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
            @param message: The message used to log the version info update.
                            [Default: ''].
                            
            @rtype: bool
            @return: True if the project info version was updated, False 
                     otherwise.
        """
        raise RuntimeError( 'VersionControlComponent: '
                          + 'branch_update_version_info method is not '
                          + 'implemented. It must be defined by subclasses.' )
                          
    def branch_merge_version_info( self,
                                   src_branch_type = BranchType.BUG_FIX,
                                   src_branch_name = None,
                                   dest_branch_type = BranchType.TRUNK,
                                   dest_branch_name = None,
                                   message = '',
                                   simulate = False,
                                   verbose = False ):
        """ Merge the project info file for component branch version.
            This method must be implemented by subclasses.
            
            @type: string
            @param src_branch_type: The source BranchType to merge project info
                                    file for [Default: BranchType.BUG_FIX].
            
            @type: string
            @param src_branch_name: The source branch to merge project info file
                                    for [Default: None].

            @type: string
            @param dest_branch_type: The destination BranchType to merge project
                                     info file for [Default: BranchType.TRUNK].
            
            @type: string
            @param dest_branch_name: The destination branch to merge project
                                     info file for [Default: None].
            
            @type: string
            @param message: The message used to log the merge of version info.
                            [Default: ''].
            
            @rtype: bool
            @return: True if the project info version was merged, False 
                     otherwise.
        """
        raise RuntimeError( 'VersionControlComponent: '
                          + 'branch_merge_version_info method is not '
                          + 'implemented. It must be defined by subclasses.' )
                          
    #def branch_set_alias( self,
                          #alias,
                          #branch_type,
                          #branch_name,
                          #message = '',
                          #simulate = False,
                          #verbose = False ):
        #""" Set an alias to a component branch version.
            #This method must be implemented by subclasses.
            
            #@type: string
            #@param branch_type: The BranchType to set alias for.
            
            #@type: string
            #@param branch_name: The name to set alias for.

            #@type: string
            #@param message: The message used to log the alias set.
                            #[Default: ''].
            
            #@rtype: bool
            #@return: True if the alias was set, False otherwise.
        #"""
        #raise RuntimeError( 'VersionControlComponent: branch_set_alias '
                          #+ 'method is not implemented. It must be defined '
                          #+ 'by subclasses.' )
                          
