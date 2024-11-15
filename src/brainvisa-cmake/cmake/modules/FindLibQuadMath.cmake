# Find LIBQUADMATH
#
# LIBQUADMATH_FOUND
# LIBQUADMATH_LIBRARIES - the quadmath library

if( LIBQUADMATH_LIBRARIES )
  # Already found  
  set( LIBQUADMATH_FOUND TRUE )
else()
  find_library( LIBQUADMATH_LIBRARIES NAMES quadmath quadmath-0 )
  if(NOT GCC_VERSION)
    execute_process( COMMAND "${CMAKE_CXX_COMPILER}" "-v"
                     ERROR_VARIABLE _gcc_v )
    string( REGEX MATCH "gcc version (([0-9]+)(.[0-9]+)?)" _gccver "${_gcc_v}" )
    set( GCC_VERSION ${CMAKE_MATCH_1} CACHE STRING "gcc version" )
  endif()
  
  if( NOT LIBQUADMATH_LIBRARIES )
    string( REGEX MATCH "(([0-9]+)(.[0-9]+)?)" _gccmaj "${GCC_VERSION}" )
    set( _GCCPATH
      "/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/${GCC_VERSION}"
      "/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/${CMAKE_MATCH_2}"
    )
    find_library( LIBQUADMATH_LIBRARIES quadmath quadmath-0 PATHS ${_GCCPATH} )
    if( NOT LIBQUADMATH_LIBRARIES )
      foreach( _gccpath_ ${_GCCPATH} )
        file( GLOB LIBQUADMATH_LIBRARIES "${_gccpath_}/libquadmath.so" )
        if( LIBQUADMATH_LIBRARIES )
          break()
        endif()
        file( GLOB LIBQUADMATH_LIBRARIES "${_gccpath_}/libquadmath.so.?" )
        if( LIBQUADMATH_LIBRARIES )
          break()
        endif()
      endforeach()
    endif()
    unset( _GCCPATH )
    unset( _gccpath_ )
  endif()
  
  if( NOT LIBQUADMATH_LIBRARIES )
    # Try to find it using MinGW
    find_package(MinGW)
    if( MINGW_FOUND )
      file( GLOB LIBQUADMATH_LIBRARIES "${MINGW_BIN_DIR}/libquadmath*" )
    else()
      file( GLOB LIBQUADMATH_LIBRARIES /usr/lib/ure/lib/libquadmath.so.? )
    endif()
  endif()
  if( LIBQUADMATH_LIBRARIES )
    set( LIBQUADMATH_LIBRARIES "${LIBQUADMATH_LIBRARIES}" 
         CACHE PATH "LIBQUADMATH library" FORCE )
  endif()
  if( LIBQUADMATH_LIBRARIES )
    if(GCC_VERSION)
        # Version is the same than GCC one
        set(LIBQUADMATH_VERSION "${GCC_VERSION}" 
            CACHE STRING "quadmath library version")
    endif()
    set( LIBQUADMATH_FOUND TRUE )
  else()
    set( LIBQUADMATH_FOUND FALSE )
      
    if( LIBQUADMATH_FIND_REQUIRED )
        message( SEND_ERROR "LIBQUADMATH was not found." )
    elseif( NOT LIBQUADMATH_FIND_QUIETLY )
        message( STATUS "LIBQUADMATH was not found." )
    endif()
  endif()
endif()

