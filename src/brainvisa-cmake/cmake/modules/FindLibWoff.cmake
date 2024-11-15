# Find LibWoff
#
# LIBWOFF_FOUND
# LIBWOFF_LIBRARIES

if( LIBWOFF_LIBRARIES )
  # Already found
  set( LIBWOFF_FOUND TRUE )
else()

  find_package( LibBrotli REQUIRED )

  set( _libs )
  find_library( LIBWOFF2COMMON_LIBRARY NAMES woff2common )
  if( LIBWOFF2COMMON_LIBRARY )
    set( LIBWOFF_FOUND TRUE )
    list( APPEND _libs ${LIBWOFF2COMMON_LIBRARY} )

    find_library( LIBWOFF2DEC_LIBRARY NAMES woff2dec )
    if( LIBWOFF2DEC_LIBRARY )
      list( APPEND _libs ${LIBWOFF2DEC_LIBRARY} )
    endif()

    find_library( LIBWOFF2ENC_LIBRARY NAMES woff2enc )
    if( LIBWOFF2ENC_LIBRARY )
      list( APPEND _libs ${LIBWOFF2ENC_LIBRARY} )
    endif()

    set( LIBWOFF_LIBRARIES ${_libs} CACHE FILEPATH "libwoff2 libraries" )

  else()
    set( LIBWOFF_FOUND FALSE )

    if( LIBWOFF_FIND_REQUIRED )
        message( SEND_ERROR "LibWoff was not found." )
    elseif( NOT LIBWOFF_FIND_QUIETLY )
        message( STATUS "LibWoff was not found." )
    endif()
  endif()

endif()

