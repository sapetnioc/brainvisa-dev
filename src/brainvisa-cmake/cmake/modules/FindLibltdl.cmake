# Find Libltdl
#
# LIBLTDL_FOUND
# LIBLTDL_LIBRARIES - ltdl library

IF(LIBLTDL_LIBRARIES)
  # already found  
  SET(LIBLTDL_FOUND TRUE)
ELSE()
  find_library(LIBLTDL_LIBRARIES ltdl)
  if(NOT LIBLTDL_LIBRARIES)
    file( GLOB LIBLTDL_LIBRARIES /usr/lib/libltdl.so.? )
  endif()
  IF(LIBLTDL_LIBRARIES)
    set(LIBLTDL_LIBRARIES ${LIBLTDL_LIBRARIES} CACHE PATH "Libltdl libraries" FORCE)
    SET(LIBLTDL_FOUND TRUE)
  ELSE()
    SET(LIBLTDL_FOUND FALSE)
      
    IF( LIBLTDL_FIND_REQUIRED )
        MESSAGE( SEND_ERROR "Libltdl was not found." )
    ENDIF()
    IF(NOT LIBLTDL_FIND_QUIETLY)
        MESSAGE(STATUS "Libltdl was not found.")
    ENDIF()
  ENDIF()

ENDIF()

