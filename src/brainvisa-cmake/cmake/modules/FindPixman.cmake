# Find Pixman
#
# LIBPIXMAN_FOUND
# LIBPIXMAN_LIBRARIES - pixman library
IF(LIBPIXMAN_LIBRARIES)
  # already found  
  SET(LIBPIXMAN_FOUND TRUE)
ELSE()

  # First try to search pixman through pkg_config.
  find_package(PkgConfig)
  if(PKG_CONFIG_FOUND)
    pkg_search_module(_LIBPIXMAN pixman-1)
    if(_LIBPIXMAN_FOUND)
      find_library( LIBPIXMAN_LIBRARIES ${_LIBPIXMAN_LIBRARIES}
                    PATHS ${_LIBPIXMAN_LIBRARY_DIRS} )
      set( LIBPIXMAN_INCLUDE_DIRS ${_LIBPIXMAN_INCLUDE_DIRS} CACHE PATH "Paths to pixman header files" )
      set( LIBPIXMAN_VERSION "${_LIBPIXMAN_VERSION}" CACHE STRING "Version of pixman library")

      if( LIBPIXMAN_INCLUDE_DIRS AND LIBPIXMAN_LIBRARIES )
        set( LIBPIXMAN_FOUND TRUE)
      endif()
    endif()
  endif()

  if(NOT LIBPIXMAN_LIBRARIES)
    find_library(LIBPIXMAN_LIBRARIES pixman)
    if(NOT LIBPIXMAN_LIBRARIES)
      file( GLOB LIBPIXMAN_LIBRARIES /usr/lib/libpixman.so.? )
    endif()
  endif()
  
  IF(LIBPIXMAN_LIBRARIES)
    set(LIBPIXMAN_LIBRARIES ${LIBPIXMAN_LIBRARIES} CACHE PATH "Pixman libraries" FORCE)
    SET(LIBPIXMAN_FOUND TRUE)
  ELSE()
    SET(LIBPIXMAN_FOUND FALSE)
      
    IF( LIBPIXMAN_FIND_REQUIRED )
        MESSAGE( SEND_ERROR "Pixman was not found." )
    ENDIF()
    IF(NOT LIBPIXMAN_FIND_QUIETLY)
        MESSAGE(STATUS "Pixman was not found.")
    ENDIF()
  ENDIF()

ENDIF()

