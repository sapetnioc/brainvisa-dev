# Find LibPcre
#
# LIBPCRE_FOUND
# LIBPCRE_LIBRARIES   - pcre library
# LIBPCRE16_LIBRARIES - pcre16 library
# LIBPCRE32_LIBRARIES - pcre32 library

IF(LIBPCRE_LIBRARIES)
  # already found
  SET(LIBPCRE_FOUND TRUE)
ELSE()
  find_library(LIBPCRE_LIBRARIES pcre)
  if(NOT LIBPCRE_LIBRARIES)
    file( GLOB LIBPCRE_LIBRARIES /usr/lib/libpcre.so.? )
  endif()
  find_library(LIBPCRE16_LIBRARIES pcre16)
  if(NOT LIBPCRE16_LIBRARIES)
    file( GLOB LIBPCRE16_LIBRARIES /usr/lib/libpcre16.so.? )
  endif()
  find_library(LIBPCRE32_LIBRARIES pcre)
  if(NOT LIBPCRE32_LIBRARIES)
    file( GLOB LIBPCRE32_LIBRARIES /usr/lib/libpcre32.so.? )
  endif()
  IF(LIBPCRE_LIBRARIES)
    set(LIBPCRE_LIBRARIES ${LIBPCRE_LIBRARIES} CACHE PATH "LibPcre libraries" FORCE)
    SET( LIBPCRE_FOUND TRUE )
    set( LIBPCRE16_LIBRARIES ${LIBPCRE16_LIBRARIES} CACHE
      PATH "LibPcre16 libraries" )
    set( LIBPCRE32_LIBRARIES ${LIBPCRE32_LIBRARIES} CACHE
      PATH "LibPcre32 libraries" )
  ELSE()
    SET(LIBPCRE_FOUND FALSE)

    IF( LIBPCRE_FIND_REQUIRED )
        MESSAGE( SEND_ERROR "LibPcre was not found." )
    ENDIF()
    IF(NOT LIBPCRE_FIND_QUIETLY)
        MESSAGE(STATUS "LibPcre was not found.")
    ENDIF()
  ENDIF()

ENDIF()

