# A CMake find module for Gio-2.0.
#
# Once done, this module will define
# GIO_FOUND - system has Gio
# GIO_INCLUDE_DIRS - the Gio include directory
# GIO_LIBRARIES - link to these to use Gio
# GIO_VERSION - version of Gio used

if(NOT GIO_FOUND)
    find_package(PkgConfig)
    find_package(Glib)
    if(PKG_CONFIG_FOUND AND GLIB_FOUND) # Gio search is supported only through pkg_config.
        pkg_search_module(_GIO gio-2.0)
        if(_GIO_FOUND)
            find_library( GIO_LIBRARIES ${_GIO_LIBRARIES}
                        PATHS ${_GIO_LIBRARY_DIRS} )
            set( GIO_INCLUDE_DIRS ${_GIO_INCLUDE_DIRS} CACHE PATH "paths to Gio header files" )
            set( GIO_VERSION "${_GIO_VERSION}" CACHE STRING "version of Gio library")

            if( GIO_INCLUDE_DIRS AND GIO_LIBRARIES )
                set( GIO_FOUND TRUE CACHE BOOL "specify that Gio library was found")
            endif()
        endif()
    endif()
endif()
