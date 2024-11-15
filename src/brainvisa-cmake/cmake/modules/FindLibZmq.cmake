# Find LIBZMQ
#
# LIBZMQ_FOUND
# LIBZMQ_LIBRARIES - the zmq library

if( LIBZMQ_LIBRARIES )
  # Already found
  set( LIBZMQ_FOUND TRUE )
else()

  find_library( LIBZMQ_LIBRARIES NAMES zmq )
  if( LIBZMQ_LIBRARIES )
    set( LIBZMQ_FOUND TRUE )
  else()
    set( LIBZMQ_FOUND FALSE )

    if( LIBZMQ_FIND_REQUIRED )
        message( SEND_ERROR "LIBZMQ was not found." )
    elseif( NOT LIBZMQ_FIND_QUIETLY )
        message( STATUS "LIBZMQ was not found." )
    endif()
  endif()
endif()

