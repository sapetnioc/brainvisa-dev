# A CMake find module for the dlib library.
#
# http://dlib.net
#
# Once done, this module will define
# DLIB_FOUND - system has dlib
# DLIB_INCLUDE_DIRS - the dlib include directory
# DLIB_LIBRARIES - link to these to use dlib
# DLIB_VERSION - version of dlib used
if(NOT DLIB_FOUND)
    find_package(PkgConfig)
    if(PKG_CONFIG_FOUND)
        pkg_search_module(_DLIB dlib)
        if(_DLIB_FOUND)
            find_library( DLIB_LIBRARIES ${_DLIB_LIBRARIES}
                        PATHS ${_DLIB_LIBRARY_DIRS} )
            set( DLIB_INCLUDE_DIRS ${_DLIB_INCLUDE_DIRS} CACHE PATH "paths to dlib header files" )
            set( DLIB_VERSION "${_DLIB_VERSION}" CACHE STRING "version of dlib library")

            if( DLIB_INCLUDE_DIRS AND DLIB_LIBRARIES )
                set( DLIB_FOUND TRUE CACHE BOOL "specify that dlib library was found")
            endif()
        endif()
    endif()
endif()