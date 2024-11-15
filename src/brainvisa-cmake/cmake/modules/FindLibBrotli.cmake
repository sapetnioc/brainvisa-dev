# Find LibBrotli
#
# LIBBROTLI_FOUND
# LIBBROTLI_LIBRARIES

if( LIBBROTLI_LIBRARIES )
  # Already found
  set( LIBBROTLI_FOUND TRUE )
else()

  set( _libs )
  find_library( LIBBROTLICOMMON_LIBRARY NAMES brotlicommon )
  if( LIBBROTLICOMMON_LIBRARY )
    set( LIBBROTLI_FOUND TRUE )
    list( APPEND _libs ${LIBBROTLICOMMON_LIBRARY} )

    find_library( LIBBROTLIDEC_LIBRARY NAMES brotlidec )
    if( LIBBROTLIDEC_LIBRARY )
      list( APPEND _libs ${LIBBROTLIDEC_LIBRARY} )
    endif()

    find_library( LIBBROTLIENC_LIBRARY NAMES brotlienc )
    if( LIBBROTLIENC_LIBRARY )
      list( APPEND _libs ${LIBBROTLIENC_LIBRARY} )
    endif()

    set( LIBBROTLI_LIBRARIES ${_libs} CACHE FILEPATH "libbrotli libraries" )

  else()
    set( LIBBROTLI_FOUND FALSE )

    if( LIBBROTLI_FIND_REQUIRED )
        message( SEND_ERROR "LibBrotli was not found." )
    elseif( NOT LIBBROTLI_FIND_QUIETLY )
        message( STATUS "LibBrotli was not found." )
    endif()
  endif()

endif()

