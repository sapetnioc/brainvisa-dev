# A CMake find module for libsz.
#
# Once done, this module will define
# SZLIB_FOUND - system has libsz
# SZLIB_INCLUDE_DIRS - the libsz include directory
# SZLIB_LIBRARIES - link to these to use libsz

if( SZLIB_LIBRARIES )

  # already found
  SET( SZLIB_FOUND TRUE )

else()

  find_library( SZLIB_LIBRARIES sz )
  if( SZLIB_LIBRARIES )
    find_library( LIBAEC_LIBRARY aec )
    if( LIBAEC_LIBRARY )
      list( APPEND SZLIB_LIBRARIES ${LIBAEC_LIBRARY} )
    endif()
    set( SZLIB_LIBRARIES ${SZLIB_LIBRARIES} CACHE PATH "SZLib libraries" FORCE)

    find_path( SZLIB_INCLUDE_DIR NAMES szlib.h PATH_SUFFIXES include )
    find_path( AECLIB_INCLUDE_DIR NAMES libaec.h PATH_SUFFIXES include )

    set( SZLIB_INCLUDE_DIRS ${SZLIB_INCLUDE_DIR} ${AECLIB_INCLUDE_DIR}
         CACHE PATH "SZLib include directories" )

    set( SZLIB_FOUND TRUE )
  else()
    set( SZLIB_FOUND FALSE )

    if( SZLIB_FIND_REQUIRED )
        message( SEND_ERROR "SZLib was not found." )
    endif()
    if( NOT SZLIB_FIND_QUIETLY )
        message( STATUS "SZLib was not found." )
    endif()
  endif()

endif()
