# A CMake find module for gdk-pixbuf.
#
# Once done, this module will define
# GDKPIXBUF_FOUND - system has gdk-pixbuf
# GDKPIXBUF_INCLUDE_DIRS - the gdk-pixbuf include directory
# GDKPIXBUF_LIBRARIES - link to these to use gdk-pixbuf
# GDKPIXBUF_VERSION - version of gdk-pixbuf used

if(NOT GDKPIXBUF_FOUND)
    find_package(PkgConfig)
    find_package(Glib)
    if(PKG_CONFIG_FOUND AND GLIB_FOUND) # gdk-pixbuf search is supported only through pkg_config.
        pkg_search_module(_GDKPIXBUF gdk-pixbuf-2.0)
        if(_GDKPIXBUF_FOUND)
            find_library( GDKPIXBUF_LIBRARIES ${_GDKPIXBUF_LIBRARIES}
                        PATHS ${_GDKPIXBUF_LIBRARY_DIRS} )
            set( GDKPIXBUF_INCLUDE_DIRS ${_GDKPIXBUF_INCLUDE_DIRS} CACHE PATH "paths to gdk-pixbuf header files" )
            set( GDKPIXBUF_VERSION "${_GDKPIXBUF_VERSION}" CACHE STRING "version of gdk-pixbuf library")

            if( GDKPIXBUF_INCLUDE_DIRS AND GDKPIXBUF_LIBRARIES )
                set( GDKPIXBUF_FOUND TRUE CACHE BOOL "specify that gdk-pixbuf library was found")
            endif()
        endif()
    endif()
endif()
