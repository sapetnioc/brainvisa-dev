# Find LIBGCC
#
# LIBGCC_FOUND
# LIBGCC_LIBRARIES - the gcc library

if( LIBGCC_LIBRARIES )
  # already found  
  set( LIBGCC_FOUND TRUE )
else()
  find_library( LIBGCC_LIBRARIES NAMES gcc_s gcc_s_dw2-1 )
  if( NOT LIBGCC_LIBRARIES )
    # On Ubuntu 10.4 libgcc_s is in /lib/libgcc_s.so.1 and CMake cannot find it
    # because there is no /lib/libgcc_s.so
    file( GLOB LIBGCC_LIBRARIES /lib/libgcc_s.so.? )
    if( NOT LIBGCC_LIBRARIES )
      file( GLOB LIBGCC_LIBRARIES /lib/libgcc_s.so )
    endif()
    # fix for CentOS7
    if( NOT LIBGCC_LIBRARIES )
      file( GLOB LIBGCC_LIBRARIES /lib64/libgcc_s.so.? )
      if( NOT LIBGCC_LIBRARIES )
        file( GLOB LIBGCC_LIBRARIES /lib64/libgcc_s.so )
      endif()
    endif()
    # end of fix for CentOS7
    if(NOT GCC_VERSION OR NOT LIBGCC_LIBRARIES)
      execute_process( COMMAND "${CMAKE_CXX_COMPILER}" "-v"
        ERROR_VARIABLE _gcc_v )
      string( REGEX MATCH "gcc version (([0-9]+)(.[0-9]+)?)" _gccver "${_gcc_v}" )
      set( GCC_VERSION ${CMAKE_MATCH_1} CACHE STRING "gcc version" )
      
      if( NOT LIBGCC_LIBRARIES )
        set( _GCCPATH
          "/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/${GCC_VERSION}"
          "/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/${CMAKE_MATCH_2}" )
        find_library( _LIBGCC_LIBRARIES gcc_s PATHS ${_GCCPATH} )
        if( _LIBGCC_LIBRARIES )
          set( LIBGCC_LIBRARIES ${_LIBGCC_LIBRARIES} )
        endif()
        unset( _LIBGCC_LIBRARIES CACHE )
#       if( NOT LIBGCC_LIBRARIES )
#         file( GLOB LIBGCC_LIBRARIES "${_GCCPATH}/libgcc_s.so" )
#       endif()
        unset( _GCCPATH )
      endif()
    endif()
    
    if(NOT LIBGCC_LIBRARIES AND COMPILER_PREFIX AND CMAKE_CROSSCOMPILING)
        if(WIN32)
            file( GLOB LIBGCC_LIBRARIES "/usr/lib/gcc/${COMPILER_PREFIX}/${GCC_VERSION}/libgcc_s*.dll*" )
            #message("==== Found gcc libraries ${LIBGCC_LIBRARIES}")
        endif()
    endif()
    
    if( NOT LIBGCC_LIBRARIES )
      # Try to find it using MinGW
      find_package(MinGW)
      if( MINGW_FOUND )
        file( GLOB LIBGCC_LIBRARIES "${MINGW_BIN_DIR}/libgcc_s*" )
      else()
        file( GLOB LIBGCC_LIBRARIES /usr/lib/ure/lib/libgcc_s.so.? )
      endif()
    endif()
    if( LIBGCC_LIBRARIES )
      set( LIBGCC_LIBRARIES "${LIBGCC_LIBRARIES}" CACHE PATH "libgcc_s library" FORCE )
    endif()
  endif()
  if( LIBGCC_LIBRARIES )
    set( LIBGCC_FOUND TRUE )
  else()
    set( LIBGCC_FOUND FALSE )
      
    if( LIBGCC_FIND_REQUIRED )
        message( SEND_ERROR "LIBGCC was not found." )
    elseif( NOT LIBGCC_FIND_QUIETLY )
        message( STATUS "LIBGCC was not found." )
    endif()
  endif()
endif()

