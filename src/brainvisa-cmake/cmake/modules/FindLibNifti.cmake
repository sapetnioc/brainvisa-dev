# A CMake find module for libnifti.
#
# Once done, this module will define
# LIBNIFTI_FOUND - system has libnifti
# LIBNIFTI_INCLUDE_DIRS - the libnifti include directory
# LIBNIFTI_LIBRARIES - link to these to use libnifi
# LIBNIFTI_VERSION - version of libnifti

if( LIBNIFTI_LIBRARIES )

  # already found
  SET( LIBNIFTI_FOUND TRUE )

else()

  find_library( LIBNIFTI_LIBRARY NAMES niftiio )
  if( LIBNIFTI_LIBRARY )
    find_library( ZNZ_LIBRARY NAMES znz )
    set( LIBNIFTI_LIBRARIES ${LIBNIFTI_LIBRARY} ${ZNZ_LIBRARY} CACHE PATH
         "LibNifti libraries" )

    find_path( LIBNIFTI_INCLUDE_DIR NAMES nifti1.h
               PATH_SUFFIXES include include/nifti )

    set( LIBNIFTI_INCLUDE_DIRS ${LIBNIFTI_INCLUDE_DIR}
         CACHE PATH "LibNifti include directories" )
    set( LIBNIFTI_VERSION "2.0.0" CACHE STRING "LibNifti version" )

    set( LIBNIFTI_FOUND TRUE )
  else()
    set( LIBNIFTI_FOUND FALSE )

    if( LIBNIFTI_FIND_REQUIRED )
        message( SEND_ERROR "LibNifti was not found." )
    endif()
    if( NOT LIBNIFTI_FIND_QUIETLY )
        message( STATUS "LibNifti was not found." )
    endif()
  endif()

endif()
