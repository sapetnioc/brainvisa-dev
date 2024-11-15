# A CMake find module for liborc.
#
# Once done, this module will define
# LIBORC_FOUND - system has liborc
# LIBORC_INCLUDE_DIRS - the liborc include directory
# LIBORC_LIBRARIES - link to these to use liborc

if( LIBORC_LIBRARIES )

  # already found
  SET( LIBORC_FOUND TRUE )

else()

  set( LIBORC_VERSION 0.4 )
  find_library( LIBORC_LIBRARIES orc-${LIBORC_VERSION} )
  if( LIBORC_LIBRARIES )
#     set( LIBORC_LIBRARIES ${LIBORC_LIBRARIES} CACHE PATH "Liborc libraries" FORCE)

    find_path( LIBORC_INCLUDE_DIR NAMES orc.h PATH_SUFFIXES include include/orc-0.4/orc )

    set( LIBORC_INCLUDE_DIRS ${LIBORC_INCLUDE_DIR} ${LIBORC_INCLUDE_DIR}
         CACHE PATH "LibOrc include directories" )

    set( LIBORC_FOUND TRUE )
  else()
    set( LIBORC_FOUND FALSE )

    if( LIBORC_FIND_REQUIRED )
        message( SEND_ERROR "LibOrc was not found." )
    endif()
    if( NOT LIBORC_FIND_QUIETLY )
        message( STATUS "LibOrc was not found." )
    endif()
  endif()

endif()
