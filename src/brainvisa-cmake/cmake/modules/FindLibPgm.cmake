# Find LIBPGM
#
# LIBPGM_FOUND
# LIBPGM_LIBRARIES - the pgm library

if( LIBPGM_LIBRARIES )
  # Already found
  set( LIBPGM_FOUND TRUE )
else()

  find_library( LIBPGM_LIBRARIES NAMES pgm )
  if( LIBPGM_LIBRARIES )
    set( LIBPGM_FOUND TRUE )
  else()
    set( LIBPGM_FOUND FALSE )

    if( LIBPGM_FIND_REQUIRED )
        message( SEND_ERROR "LIBPGM was not found." )
    elseif( NOT LIBPGM_FIND_QUIETLY )
        message( STATUS "LIBPGM was not found." )
    endif()
  endif()
endif()

