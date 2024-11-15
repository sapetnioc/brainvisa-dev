# A CMake find module for GObject-2.0.
#
# Once done, this module will define
# GOBJECT_FOUND - system has GObject
# GOBJECT_INCLUDE_DIRS - the GObject include directory
# GOBJECT_LIBRARIES - link to these to use GObject
# GOBJECT_VERSION - version of GObject used

if(NOT GOBJECT_FOUND)
    find_package(PkgConfig)
    find_package(Glib)
    if(PKG_CONFIG_FOUND AND GLIB_FOUND) # GObject search is supported only through pkg_config.
        pkg_search_module(_GOBJECT gobject-2.0)
        if(_GOBJECT_FOUND)
            find_library( GOBJECT_LIBRARIES ${_GOBJECT_LIBRARIES}
                        PATHS ${_GOBJECT_LIBRARY_DIRS} )
            set( GOBJECT_INCLUDE_DIRS ${_GOBJECT_INCLUDE_DIRS} CACHE PATH "paths to GObject header files" )
            set( GOBJECT_VERSION "${_GOBJECT_VERSION}" CACHE STRING "version of GObject library")

            if( GOBJECT_INCLUDE_DIRS AND GOBJECT_LIBRARIES )
                set( GOBJECT_FOUND TRUE CACHE BOOL "specify that GObject library was found")
            endif()
        endif()
    endif()
endif()
