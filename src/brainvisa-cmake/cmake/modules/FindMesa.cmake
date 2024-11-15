# Find Mesa libraries
# The following variables are set:
#
#  MESA_FOUND - Was mesa found
#  MESA_LIBRARIES - mesa dynamic libraries

if( MESA_LIBRARIES )

  set( MESA_FOUND true )

else()

  set(lib_paths "mesa/lib" "mesa/lib64" "lib" "lib64")
  find_library( GL_LIB GL 
        PATHS ${CMAKE_PREFIX_PATH}
        PATH_SUFFIXES ${lib_paths}
        NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
  find_library( GL_LIB GL 
        PATH_SUFFIXES ${lib_paths} )
  if( NOT GL_LIB )
    # libgl might be found only a libGL.so.1
    file( GLOB GL_LIB /usr/lib64/mesa/libGL.so.? )
    if( NOT GL_LIB )
      file( GLOB GL_LIB /usr/lib/mesa/libGL.so.? )
    endif()
  endif()
  find_library( OSMESA_LIB OSMesa 
        PATHS ${CMAKE_PREFIX_PATH}
        PATH_SUFFIXES ${lib_paths}
        NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
  find_library( OSMESA_LIB OSMesa 
        PATH_SUFFIXES ${lib_paths} )
  if(GL_LIB AND OSMESA_LIB)
    set(MESA_LIBRARIES "${GL_LIB}" "${OSMESA_LIB}")
    set(MESA_FOUND TRUE)
  else()
    SET(MESA_FOUND FALSE)
    IF( MESA_FIND_REQUIRED )
        MESSAGE( SEND_ERROR "mesa libraries were not found." )
    ENDIF()
    IF(NOT MESA_FIND_QUIETLY)
        MESSAGE(STATUS "mesa libraries were not found.")
    ENDIF()

  endif()
      
endif()
