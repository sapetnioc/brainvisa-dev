# Find LibWebp
#
# LIBWEBP_FOUND
# LIBWEBP_LIBRARIES

if( LIBWEBP_LIBRARIES )
  # Already found
  set( LIBWEBP_FOUND TRUE )
else()

  set( _libs )
  find_library( LIBWEBP_LIBRARY NAMES webp )
  if( LIBWEBP_LIBRARY )
    set( LIBWEBP_FOUND TRUE )
    list( APPEND _libs ${LIBWEBP_LIBRARY} )
    set( LIBWEBP_LIBRARIES ${_libs} CACHE FILEPATH "libwebp libraries" )

  else()
    set( LIBWEBP_FOUND FALSE )

    if( LIBWEBP_FIND_REQUIRED )
        message( SEND_ERROR "LibWebp was not found." )
    elseif( NOT LIBWEBP_FIND_QUIETLY )
        message( STATUS "LibWebp was not found." )
    endif()
  endif()

endif()

