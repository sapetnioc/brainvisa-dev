# Find LibGFortran
#
# LIBGFORTRAN_FOUND
# LIBGFORTRAN_LIBRARIES - the gfortran and g2c libraries

if( LIBGFORTRAN_LIBRARIES )
  # already found  
  set( LIBGFORTRAN_FOUND TRUE )
else()
  find_library( LIBGFORTRAN gfortran gfortran-3 )
  
  if( NOT LIBGFORTRAN )
    # On Mandriva-2008 libgfortran is in /usr/lib/libgfortran.so.2 and CMake cannot find it
    # because there is no /usr/lib/libgfortran.so
    file( GLOB LIBGFORTRAN /usr/lib64/libgfortran.so.? )
    if( NOT LIBGFORTRAN )
      file( GLOB LIBGFORTRAN /usr/lib/libgfortran.so.? )
    endif()
    if( NOT LIBGFORTRAN )
      file( GLOB LIBGFORTRAN /usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/?/libgfortran.so )
    endif()
    if( NOT LIBGFORTRAN )
      file( GLOB LIBGFORTRAN /usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/?.?/libgfortran.so )
    endif()
    if( NOT LIBGFORTRAN )
      # Mac + brew case
      file( GLOB LIBGFORTRAN /usr/local/opt/gcc/lib/gcc/*/libgfortran.dylib )
    endif()
  endif()
  if( WIN32 AND NOT LIBGFORTRAN )
    BRAINVISA_FIND_FSENTRY( LIBGFORTRAN PATTERNS "libgfortran*" PATHS $ENV{PATH} )
  endif()
  
  if( NOT LIBGFORTRAN_LIBRARIES AND CMAKE_Fortran_COMPILER )
    # look relative to command path
    get_filename_component( _fortran ${CMAKE_Fortran_COMPILER} REALPATH )
    get_filename_component( _fpath ${_fortran} PATH )
    file( GLOB _fpath2 "${_fpath}/lib/gcc/*" )
    find_library( LIBGFORTRAN gfortran gfortran-3 HINTS ${fpath2} )
  endif()

  # g2c doesn't mean to be mandatory on ubuntu or macos
  find_library( LIBG2C g2c )
  if( NOT LIBG2C )
    file( GLOB LIBG2C /usr/lib64/libg2c.so.? )
    if( NOT LIBG2C )
      file( GLOB LIBG2C /usr/lib/libg2c.so.? )
    endif()
  endif()
  if( LIBGFORTRAN )
    set( LIBGFORTRAN_LIBRARIES ${LIBGFORTRAN_LIBRARIES} "${LIBGFORTRAN}" )
    unset(LIBGFORTRAN CACHE)
  endif()
  if( LIBG2C )
    set( LIBGFORTRAN_LIBRARIES ${LIBGFORTRAN_LIBRARIES} "${LIBG2C}" )
    unset(LIBG2C CACHE)
  endif()
  
  if(NOT GFORTRAN_VERSION)
    execute_process( COMMAND "${CMAKE_Fortran_COMPILER}" "-v"
                     ERROR_VARIABLE _gfortran_v )
    string( REGEX MATCH "gcc version (([0-9]+)(.[0-9]+)?)" _gfortranver "${_gfortran_v}" )
    set( GFORTRAN_VERSION ${CMAKE_MATCH_1} CACHE STRING "gfortran version" )
  endif()

  if( LIBGFORTRAN_LIBRARIES )
    set( LIBGFORTRAN_FOUND TRUE )
    set( LIBGFORTRAN_LIBRARIES "${LIBGFORTRAN_LIBRARIES}" CACHE PATH "gfortran libraries" FORCE )
  else()
    set( LIBGFORTRAN_FOUND FALSE )
    if( LIBGFORTRAN_FIND_REQUIRED )
        message( SEND_ERROR "LIBGFORTRAN was not found." )
    elseif( NOT LIBGFORTRAN_FIND_QUIETLY )
        message( STATUS "LIBGFORTRAN was not found." )
    endif()
  endif()
endif()


