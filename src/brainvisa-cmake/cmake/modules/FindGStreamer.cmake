# A CMake find module for GStreamer-1.0.
#
# Once done, this module will define
# GSTREAMER_FOUND - system has GStreamer
# GSTREAMER_INCLUDE_DIRS - the GStreamer include directory
# GSTREAMER_LIBRARIES - link to these to use GStreamer
# GSTREAMER_VERSION - version of GStreamer used
# GSTAPP_LIBRARIES - link to these to use libgstapp
# GSTBASE_LIBRARIES - link to these to use libgstbase
# GSTINTERFACES_LIBRARIES - link to these to use libgstinterfaces
# GSTPBUTILS_LIBRARIES - link to these to use libgstpbutils
# GSTVIDEO_LIBRARIES - link to these to use libgstvideo
# GSTAUDIO_LIBRARIES - link to these to use libgstaudio
# GSTTAG_LIBRARIES - link to these to use libgsttag
# GSTFFT_LIBRARIES - link to these to use libgstfft

if (NOT GSTREAMER_INCLUDE_DIRS OR NOT GSTREAMER_LIBRARIES)
    find_package(PkgConfig)
    if(PKG_CONFIG_FOUND) # Glib search is supported only through pkg_config.
        # Do not search gstreamer 1.0 on CentOS-7.4
        # because both versions are installed but we want 
        # to use 0.10 version
        if(NOT(LSB_DISTRIB STREQUAL "centos linux"
            AND LSB_DISTRIB_RELEASE VERSION_GREATER "7.4"))
            pkg_search_module(_GSTREAMER gstreamer-1.0)
        endif()
        if( _GSTREAMER_FOUND )
            set( _gstreamer_ver 1.0 )
        else()
            pkg_search_module(_GSTREAMER gstreamer-0.10) # ubuntu 12.04
            if( _GSTREAMER_FOUND )
            set( _gstreamer_ver 0.10 )
            endif()
        endif()
        if( _GSTREAMER_FOUND )
            find_library( GSTREAMER_LIBRARIES ${_GSTREAMER_LIBRARIES}
                        PATHS ${_GSTREAMER_LIBRARY_DIRS} )
            pkg_search_module(_GSTAPP gstreamer-app-${_gstreamer_ver})
            if(_GSTAPP_FOUND)
                find_library( GSTAPP_LIBRARIES ${_GSTAPP_LIBRARIES}
                                PATHS ${_GSTAPP_LIBRARY_DIRS} )
            endif()
            pkg_search_module(_GSTBASE gstreamer-base-${_gstreamer_ver})
            if(_GSTBASE_FOUND)
                find_library( GSTBASE_LIBRARIES gstbase-${_gstreamer_ver}
                                PATHS ${_GSTBASE_LIBRARY_DIRS} )
            endif()
            pkg_search_module(_GSTINTERFACES gstreamer-interfaces-${_gstreamer_ver})
            if(_GSTINTERFACES_FOUND)
                find_library( GSTINTERFACES_LIBRARIES gstinterfaces-${_gstreamer_ver}
                                PATHS ${_GSTINTERFACES_LIBRARY_DIRS} )
            endif()
            pkg_search_module(_GSTPBUTILS gstreamer-pbutils-${_gstreamer_ver})
            if(_GSTPBUTILS_FOUND)
                find_library( GSTPBUTILS_LIBRARIES gstpbutils-${_gstreamer_ver}
                                PATHS ${_GSTPBUTILS_LIBRARY_DIRS} )
            endif()
            pkg_search_module(_GSTVIDEO gstreamer-video-${_gstreamer_ver})
            if(_GSTVIDEO_FOUND)
                find_library( GSTVIDEO_LIBRARIES gstvideo-${_gstreamer_ver}
                                PATHS ${_GSTVIDEO_LIBRARY_DIRS} )
            endif()
            pkg_search_module(_GSTAUDIO gstreamer-audio-${_gstreamer_ver})
            if(_GSTAUDIO_FOUND)
                find_library( GSTAUDIO_LIBRARIES gstaudio-${_gstreamer_ver}
                                PATHS ${_GSTAUDIO_LIBRARY_DIRS} )
            endif()
            pkg_search_module(_GSTTAG gstreamer-tag-${_gstreamer_ver})
            if(_GSTTAG_FOUND)
                find_library( GSTTAG_LIBRARIES gsttag-${_gstreamer_ver}
                                PATHS ${_GSTTAG_LIBRARY_DIRS} )
            endif()
            pkg_search_module(_GSTFFT gstreamer-fft-${_gstreamer_ver})
            if(_GSTFFT_FOUND)
                find_library( GSTFFT_LIBRARIES gstfft-${_gstreamer_ver}
                                PATHS ${_GSTFFT_LIBRARY_DIRS} )
            endif()
            set( GSTREAMER_INCLUDE_DIRS ${_GSTREAMER_INCLUDE_DIRS} CACHE PATH "paths to GStreamer header files" )
            set( GSTREAMER_VERSION "${_GSTREAMER_VERSION}" CACHE STRING "version of GStreamer library")

            if( GSTREAMER_INCLUDE_DIRS AND GSTREAMER_LIBRARIES )
                set( GSTREAMER_FOUND TRUE CACHE BOOL "specify that GStreamer library was found")
            endif()
        endif()
    endif()
endif()
