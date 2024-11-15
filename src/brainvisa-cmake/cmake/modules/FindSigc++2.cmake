# Find Sigc++2
#
# Sigc++2_FOUND - TRUE if Sigc++2 was found
# Sigc++2_INCLUDE_DIRS - paths to Sigc++2 header files
# Sigc++2_LIBRARIES - the Sigc++2 library
# Sigc++2_VERSION - version of Sigc++2 library

if( Sigc++2_INCLUDE_DIRS AND Sigc++2_LIBRARIES )
  # already found  
  set( Sigc++2_FOUND TRUE )
else()
  set( Sigc++2_FOUND FALSE )
  # use pkg-config to get the directories and then use these values
  # in the FIND_PATH() and FIND_LIBRARY() calls
  find_package( PkgConfig )
  pkg_search_module( _SIGCPP2 sigc++-2.0 )

  if( _SIGCPP2_FOUND )
    find_library( Sigc++2_LIBRARIES ${_SIGCPP2_LIBRARIES} 
                  PATHS ${_SIGCPP2_LIBRARY_DIRS} )
    find_path( Sigc++2_INCLUDE_CONFIG_DIR sigc++config.h
      PATHS ${_SIGCPP2_INCLUDE_DIRS}
      PATH_SUFFIXES sigc++-2.0 sigc++-2.0/include lib/sigc++-2.0/include )
    set( Sigc++2_INCLUDE_DIRS ${_SIGCPP2_INCLUDE_DIRS} CACHE PATH "paths to Sigc++2 header files" )
    set( Sigc++2_VERSION "${_SIGCPP2_VERSION}" CACHE STRING "version of Sigc++2 library")
    set( Sigc++2_INCLUDE_CONFIG_DIR "${Sigc++2_INCLUDE_CONFIG_DIR}" CACHE PATH "paths to Sigc++2 config header files" )
    if( Sigc++2_LIBRARIES )
      set( Sigc++2_FOUND TRUE )
    endif()
  else()
    find_path( Sigc++2_INCLUDE_DIR sigc++/sigc++.h
      PATH_SUFFIXES sigc++-2.0 )
    find_path( Sigc++2_INCLUDE_CONFIG_DIR sigc++config.h
      PATHS /usr/lib
      PATH_SUFFIXES sigc++-2.0 sigc++-2.0/include lib/sigc++-2.0/include )
    find_library( Sigc++2_LIBRARIES NAMES sigc-2.0 )
    if( Sigc++2_INCLUDE_DIR AND Sigc++2_INCLUDE_CONFIG_DIR AND Sigc++2_LIBRARIES )
      set( Sigc++2_FOUND TRUE )
    endif()

    set( Sigc++2_INCLUDE_DIRS "${Sigc++2_INCLUDE_DIR}" "${Sigc++2_INCLUDE_CONFIG_DIR}" CACHE PATH "paths to Sigc++2 header files" )

    if( NOT Sigc++2_FOUND )
      if( Sigc++2_FIND_REQUIRED )
        message( SEND_ERROR "Sigc++-2.0 was not found." )
      elseif( NOT Sigc++2_FIND_QUIETLY )
        message(STATUS "Sigc++-2.0 was not found.")
      endif()
    endif()
  endif()

endif()

