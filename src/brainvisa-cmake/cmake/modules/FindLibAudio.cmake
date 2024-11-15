# Find LIBAUDIO
#
# LIBAUDIO_FOUND
# LIBAUDIO_LIBRARIES - the NAS Audio library

if( LIBAUDIOLIBRARIES )
  # Already found
  set( LIBAUDIO_FOUND TRUE )
else()

  find_library( LIBAUDIO_LIBRARIES NAMES audio )
  if( NOT(LIBAUDIO_LIBRARIES OR CMAKE_CROSSCOMPILING))
    file( GLOB LIBAUDIO_LIBRARIES2 /usr/lib/x86_64-linux*/libaudio.so.2 )
    if( LIBAUDIO_LIBRARIES2 )
      set( LIBAUDIO_LIBRARIES "${LIBAUDIO_LIBRARIES2}" CACHE STRING "libaudio library" FORCE )
    endif()
  endif()
  if( LIBAUDIO_LIBRARIES )
    set( LIBAUDIO_FOUND TRUE )
  else()
    set( LIBAUDIO_FOUND FALSE )

    if( LIBAUDIO_FIND_REQUIRED )
        message( SEND_ERROR "LIBAUDIO was not found." )
    elseif( NOT LIBAUDIO_FIND_QUIETLY )
        message( STATUS "LIBAUDIO was not found." )
    endif()
  endif()
endif()

