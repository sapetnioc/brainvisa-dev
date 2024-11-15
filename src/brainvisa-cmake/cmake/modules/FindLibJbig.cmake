# A CMake find module for libjbig.
#
# Once done, this module will define
# LIBJBIG_FOUND - system has libjbig
# LIBJBIG_INCLUDE_DIRS - the libjbig include directory
# LIBJBIG_LIBRARIES - link to these to use libjbig

if( LIBJBIG_LIBRARIES )

  # already found
  SET( LIBJBIG_FOUND TRUE )

else()

  set( LIBJBIG_VERSION 0.0 )
  find_library( LIBJBIG_LIBRARIES jbig )
  if( LIBJBIG_LIBRARIES )

    find_path( LIBJBIG_INCLUDE_DIR NAMES jbig.h PATH_SUFFIXES include )

    set( LIBJBIG_INCLUDE_DIRS ${LIBJBIG_INCLUDE_DIR}
         CACHE PATH "LibJbig include directories" )

    set( LIBJBIG_FOUND TRUE )
  else()
    set( LIBJBIG_FOUND FALSE )

    if( LIBJBIG_FIND_REQUIRED )
        message( SEND_ERROR "LibJbig was not found." )
    endif()
    if( NOT LIBJBIG_FIND_QUIETLY )
        message( STATUS "LibJbig was not found." )
    endif()
  endif()

endif()
