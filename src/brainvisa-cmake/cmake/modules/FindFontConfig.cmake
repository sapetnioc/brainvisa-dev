# Try to find the fontconfig library
# Once done this will define
#
# FontConfig_FOUND        - system has fontconfig and it can be used
# FontConfig_INCLUDE_DIR  - the fontconfig include directory
# FontConfig_LIBRARIES    - the fontconfig libraries
# FontConfig_VERSION      - version of the library
#

IF(EXISTS FontConfig_INCLUDE_DIR)
  # already found  
  SET(FontConfig_FOUND TRUE)
ELSE(EXISTS FontConfig_INCLUDE_DIR)
  # use pkg-config to get the directories and then use these values
  # in the FIND_PATH() and FIND_LIBRARY() calls
  FIND_PACKAGE(PkgConfig)
  PKG_CHECK_MODULES(FC fontconfig)

  IF(FC_FOUND)
    FIND_LIBRARY( FontConfig_LIBRARIES ${FC_LIBRARIES} )
    FIND_PATH( FontConfig_INCLUDE_DIR fontconfig.h /usr/include/fontconfig NO_DEFAULT_PATH )
    FIND_PATH( FontConfig_INCLUDE_DIR fontconfig/fontconfig.h )
    SET(FontConfig_FOUND TRUE)
    SET(FontConfig_VERSION ${FC_VERSION} CACHE STRING "FontConfig Version")
  ELSE(FC_FOUND)
    FIND_LIBRARY( FontConfig_LIBRARIES fontconfig )
    FIND_PATH( FontConfig_INCLUDE_DIR fontconfig.h /usr/include/fontconfig NO_DEFAULT_PATH )
    FIND_PATH( FontConfig_INCLUDE_DIR fontconfig/fontconfig.h )

    SET(FontConfig_FOUND FALSE)
    IF( FontConfig_INCLUDE_DIR AND FontConfig_LIBRARIES )
      SET( FontConfig_FOUND TRUE )
    ENDIF( FontConfig_INCLUDE_DIR AND FontConfig_LIBRARIES )
    
    IF(NOT FontConfig_FOUND)
      IF( FontConfig_FIND_REQUIRED )
        MESSAGE( SEND_ERROR "FontConfig was not found." )
      ENDIF( FontConfig_FIND_REQUIRED )
      IF(NOT FontConfig_FIND_QUIETLY)
        MESSAGE(STATUS "FontConfig was not found.")
      ENDIF(NOT FontConfig_FIND_QUIETLY)
    ENDIF(NOT FontConfig_FOUND)

  ENDIF(FC_FOUND)

ENDIF(EXISTS FontConfig_INCLUDE_DIR)

