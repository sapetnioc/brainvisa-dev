# Find LibCairo
#
# LIBCAIRO_FOUND
# LIBCAIRO_LIBRARIES - cairo library

IF(LIBCAIRO_LIBRARIES)
  # already found  
  SET(LIBCAIRO_FOUND TRUE)
ELSE()

  # First try to search cairo through pkg_config.
  find_package(PkgConfig)
  if(PKG_CONFIG_FOUND)
    pkg_search_module(_LIBCAIRO cairo)
    if(_LIBCAIRO_FOUND)
      find_library( LIBCAIRO_LIBRARIES ${_LIBCAIRO_LIBRARIES}
                    PATHS ${_LIBCAIRO_LIBRARY_DIRS} )
      set( LIBCAIRO_INCLUDE_DIRS ${_LIBCAIRO_INCLUDE_DIRS} CACHE PATH "Paths to cairo header files" )
      set( LIBCAIRO_VERSION "${_LIBCAIRO_VERSION}" CACHE STRING "Version of cairo library")

      if( LIBCAIRO_INCLUDE_DIRS AND LIBCAIRO_LIBRARIES )
        set( LIBCAIRO_FOUND TRUE)
      endif()
    endif()
  endif()

  if(NOT LIBCAIRO_LIBRARIES)
    find_library(LIBCAIRO_LIBRARIES cairo)
    if(NOT LIBCAIRO_LIBRARIES)
      file( GLOB LIBCAIRO_LIBRARIES /usr/lib/libcairo.so.? )
    endif()
  endif()
  
  IF(LIBCAIRO_LIBRARIES)
    set(LIBCAIRO_LIBRARIES ${LIBCAIRO_LIBRARIES} CACHE PATH "LibCairo libraries" FORCE)
    SET(LIBCAIRO_FOUND TRUE)
  ELSE()
    SET(LIBCAIRO_FOUND FALSE)
      
    IF( LIBCAIRO_FIND_REQUIRED )
        MESSAGE( SEND_ERROR "LibCairo was not found." )
    ENDIF()
    IF(NOT LIBCAIRO_FIND_QUIETLY)
        MESSAGE(STATUS "LibCairo was not found.")
    ENDIF()
  ENDIF()

ENDIF()

