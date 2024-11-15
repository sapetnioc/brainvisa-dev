# A CMake find module for libffi.
#
# Once done, this module will define
# LIBFFI_FOUND - system has libffi
# LIBFFI_INCLUDE_DIRS - the libffi include directory
# LIBFFI_LIBRARIES - link to these to use libffi
# LIBFFI_VERSION - version of libffi used

if(NOT LIBFFI_FOUND)
    find_package(PkgConfig)
    if(PKG_CONFIG_FOUND) # libffi search is supported only through pkg_config.
        pkg_search_module(_LIBFFI libffi)
        if(_LIBFFI_FOUND)
            find_library( LIBFFI_LIBRARIES ${_LIBFFI_LIBRARIES}
                        PATHS ${_LIBFFI_LIBRARY_DIRS} )
            set( LIBFFI_INCLUDE_DIRS ${_LIBFFI_INCLUDEDIR} CACHE PATH "paths to LIBFFI header files" )
            set( LIBFFI_VERSION "${_LIBFFI_VERSION}" CACHE STRING "version of LIBFFI library")

            if( LIBFFI_INCLUDE_DIRS AND LIBFFI_LIBRARIES )
                set( LIBFFI_FOUND TRUE CACHE BOOL "specify that LIBFFI library was found")
            endif()
        endif()
    endif()
endif()