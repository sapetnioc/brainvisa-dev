# Find LibXCB
#
# LIBXCB_FOUND
# LIBXCB_LIBRARIES - XCB libraries (may include xcb-render and xcb-shm if found)

IF(LIBXCB_LIBRARIES)
  # already found
  SET(LIBXCB_FOUND TRUE)
ELSE()

  # First try to search cairo through pkg_config.
  find_package(PkgConfig)
  if(PKG_CONFIG_FOUND)
    pkg_search_module(_LIBXCB xcb)
    if(_LIBXCB_FOUND)
      find_library( LIBXCB_LIBRARY ${_LIBXCB_LIBRARIES}
                    PATHS ${_LIBXCB_LIBRARY_DIRS} )
      set( LIBXCB_INCLUDE_DIRS ${_LIBXCB_INCLUDE_DIRS} CACHE PATH "Paths to xcb header files" )
      set( LIBXCB_VERSION "${_LIBXCB_VERSION}" CACHE STRING "Version of xcb library")

      if( LIBXCB_LIBRARY )
        set( LIBXCB_FOUND TRUE)

        # look for xcb modules
        foreach( module "render" "shm" "image" "icccm" "sync" "xfixes" "randr"
                 "shape" "keysyms" "xkb" "util" "renderutil" "xinerama" )
          pkg_search_module( _LIBXCB_${module} xcb-${module} )
          if( _LIBXCB_${module}_FOUND )
            find_library( LIBXCB_${module}_LIBRARY
                          ${_LIBXCB_${module}_LIBRARIES}
                          PATH ${_LIBXCB_${module}_LIBRARY_DIRS} )
            list( APPEND LIBXCB_LIBRARIES ${LIBXCB_${module}_LIBRARY} )
          endif()
        endforeach()

        set( LIBXCB_LIBRARIES ${LIBXCB_LIBRARIES} CACHE PATH "LibXCB libraries" FORCE )
      endif()
    endif()
  endif()

  if(NOT LIBXCB_LIBRARIES)
    find_library(LIBXCB_LIBRARIES xcb)
    if(NOT LIBXCB_LIBRARIES)
      file( GLOB LIBXCB_LIBRARIES /usr/lib/libxcb.so.? )
    endif()
  endif()

  IF(LIBCAIRO_LIBRARIES)
    set(LIBXCB_LIBRARIES ${LIBXCB_LIBRARIES} CACHE PATH "LibXCB libraries" FORCE)
    SET(LIBXCB_FOUND TRUE)
  ELSE()
    SET(LIBXCB_FOUND FALSE)

    IF( LIBXCB_FIND_REQUIRED )
        MESSAGE( SEND_ERROR "LibXCB was not found." )
    ENDIF()
    IF(NOT LIBXCB_FIND_QUIETLY)
        MESSAGE(STATUS "LibXCB was not found.")
    ENDIF()
  ENDIF()

ENDIF()

