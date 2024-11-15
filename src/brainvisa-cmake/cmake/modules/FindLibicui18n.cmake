# Find LIBICUI18N
#
# LIBICUI18N_FOUND
# LIBICUI18N_LIBRARIES - the icui18n libraries

if( LIBICUI18N_LIBRARIES )
  # Already found
  set( LIBICUI18N_FOUND TRUE )
else()

  set( _libs )
  find_library( LIBICUI18N_LIBRARY NAMES icui18n )
  if( LIBICUI18N_LIBRARY )
    set( LIBICUI18N_FOUND TRUE )
    list( APPEND _libs ${LIBICUI18N_LIBRARY} )
    find_library( LIBICUUC_LIBRARY NAMES icuuc )
    if( LIBICUUC_LIBRARY )
      list( APPEND _libs ${LIBICUUC_LIBRARY} )
    endif()
    find_library( LIBICUDATA_LIBRARY NAMES icudata )
    if( LIBICUDATA_LIBRARY )
      list( APPEND _libs ${LIBICUDATA_LIBRARY} )
    endif()

    set( LIBICUI18N_LIBRARIES ${_libs} CACHE FILEPATH "libicui18n libraries" )

  else()
    set( LIBICUI18N_FOUND FALSE )

    if( LIBICUI18N_FIND_REQUIRED )
        message( SEND_ERROR "LIBICUI18N was not found." )
    elseif( NOT LIBICUI18N_FIND_QUIETLY )
        message( STATUS "LIBICUI18N was not found." )
    endif()
  endif()

endif()

