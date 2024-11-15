# Find LibHyphen
#
# LIBHYPHEN_FOUND
# LIBHYPHRN_LIBRARIES

if( LIBHYPHEN_LIBRARIES )
  # Already found
  set( LIBHYPHEN_FOUND TRUE )
else()

  set( _libs )
  find_library( LIBHYPHEN_LIBRARY NAMES hyphen )
  if( LIBHYPHEN_LIBRARY )
    set( LIBHYPHEN_FOUND TRUE )
    list( APPEND _libs ${LIBHYPHEN_LIBRARY} )

    set( LIBHYPHEN_LIBRARIES ${_libs} CACHE FILEPATH "libhyphen libraries" )

  else()
    set( LIBHYPHEN_FOUND FALSE )

    if( LIBHYPHEN_FIND_REQUIRED )
        message( SEND_ERROR "LibHyphen was not found." )
    elseif( NOT LIBHYPHEN_FIND_QUIETLY )
        message( STATUS "LibHyphen was not found." )
    endif()
  endif()

endif()

