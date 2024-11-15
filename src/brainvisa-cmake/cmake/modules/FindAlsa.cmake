# Find Alsa asound library and include directory
# The following variables are set:
#
#  ALSA_FOUND - Was alsa found
#  ALSA_LIBRARIES - asound dynamic library
#  ALSA_INCLUDE_DIR - include directory where to find alsa/asoundlib.h

if( ALSA_LIBRARIES )

  set( ALSA_FOUND true )

else()
  FIND_PATH( ALSA_INCLUDE_DIR alsa/asoundlib.h )

  find_library( ALSA_LIBRARIES asound )

  IF(ALSA_INCLUDE_DIR AND ALSA_LIBRARIES)
    SET(ALSA_FOUND TRUE)
  ELSE()
    SET(ALSA_FOUND FALSE)
      
    IF( ALSA_FIND_REQUIRED )
        MESSAGE( SEND_ERROR "Library asound was not found." )
    ENDIF()
    IF(NOT ALSA_FIND_QUIETLY)
        MESSAGE(STATUS "Library asound was not found.")
    ENDIF()
  ENDIF()

endif()
