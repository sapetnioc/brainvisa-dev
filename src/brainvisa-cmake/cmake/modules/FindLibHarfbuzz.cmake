# Find LIBHARFBUZZ
#
# LIBHARFBUZZ_FOUND
# LIBHARFBUZZ_LIBRARIES - the harfbuzz libraries

if( LIBHARFBUZZ_LIBRARIES )
  # Already found
  set( LIBHARFBUZZ_FOUND TRUE )
else()

  set( _libs )
  find_library( LIBHARFBUZZ_LIBRARY NAMES harfbuzz )
  if( LIBHARFBUZZ_LIBRARY )
    set( LIBHARFBUZZ_FOUND TRUE )
    list( APPEND _libs ${LIBHARFBUZZ_LIBRARY} )

    set( LIBHARFBUZZ_LIBRARIES ${_libs} CACHE FILEPATH "libharfbuzz libraries" )

  else()
    set( LIBHARFBUZZ_FOUND FALSE )

    if( LIBHARFBUZZ_FIND_REQUIRED )
        message( SEND_ERROR "LIBHARFBUZZ was not found." )
    elseif( NOT LIBHARFBUZZ_FIND_QUIETLY )
        message( STATUS "LIBHARFBUZZ was not found." )
    endif()
  endif()

endif()

