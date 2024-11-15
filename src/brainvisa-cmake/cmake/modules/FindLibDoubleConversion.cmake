# Find LibDoubleConversion
#
# LIBDOUBLECONVERSION_FOUND
# LIBDOUBLECONVERSION_LIBRARIES - the double-conversion libraries

if( LIBDOUBLECONVERSION_LIBRARIES )
  # Already found
  set( LIBDOUBLECONVERSION_FOUND TRUE )
else()

  set( _libs )
  find_library( LIBDOUBLECONVERSION_LIBRARY NAMES double-conversion )
  if( LIBDOUBLECONVERSION_LIBRARY )
    set( LIBDOUBLECONVERSION_FOUND TRUE )
    list( APPEND _libs ${LIBDOUBLECONVERSION_LIBRARY} )

    set( LIBDOUBLECONVERSION_LIBRARIES ${_libs} CACHE FILEPATH "libdouble-conversion libraries" )

  else()
    set( LIBDOUBLECONVERSION_FOUND FALSE )

    if( LIBDOUBLECONVERSION_FIND_REQUIRED )
        message( SEND_ERROR "LIBDOUBLECONVERSION was not found." )
    elseif( NOT LIBDOUBLECONVERSION_FIND_QUIETLY )
        message( STATUS "LIBDOUBLECONVERSION was not found." )
    endif()
  endif()

endif()

