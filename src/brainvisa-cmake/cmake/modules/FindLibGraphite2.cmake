# Find LibGraphite2
#
# LIBGRAPHITE2_FOUND
# LIBGRAPHITE2_LIBRARIES - the graphite2 libraries

if( LIBGRAPHITE2_LIBRARIES )
  # Already found
  set( LIBGRAPHITE2_FOUND TRUE )
else()

  set( _libs )
  find_library( LIBGRAPHITE2_LIBRARY NAMES graphite2 )
  if( LIBGRAPHITE2_LIBRARY )
    set( LIBGRAPHITE2_FOUND TRUE )
    list( APPEND _libs ${LIBGRAPHITE2_LIBRARY} )

    set( LIBGRAPHITE2_LIBRARIES ${_libs} CACHE FILEPATH "libgraphite2 libraries" )

  else()
    set( LIBGRAPHITE2_FOUND FALSE )

    if( LIBGRAPHITE2_FIND_REQUIRED )
        message( SEND_ERROR "LibGraphite2 was not found." )
    elseif( NOT LIBGRAPHITE2_FIND_QUIETLY )
        message( STATUS "LibGraphite2 was not found." )
    endif()
  endif()

endif()

