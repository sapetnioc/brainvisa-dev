# Find Sqlite3
#
# This file defines the following variables:
#
# SQLITE3_FOUND
# SQLITE3_EXECUTABLE - Path and filename of the SQLITE3 command line executable.
# SQLITE3_INCLUDE_DIR - Directory holding the SQLITE3 C++ header file.
# SQLITE3_LIBRARIES - the sqlite3 library
# SQLITE3_VERSION - The version of SQLITE3 

if( SQLITE3_VERSION )
  # SQLITE3 is already found, do nothing
  set(SQLITE3_FOUND TRUE)
else()
  find_program( SQLITE3_EXECUTABLE
    NAMES sqlite3
    DOC "Path to sqlite3 executable" )

  if( SQLITE3_EXECUTABLE )
    mark_as_advanced( SQLITE3_EXECUTABLE )

    execute_process( COMMAND ${SQLITE3_EXECUTABLE} -version OUTPUT_VARIABLE _SQLITE3_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE )
    string( REGEX MATCH "^([0-9]+([.][0-9]+)*)([ \t].*)?$"
      SQLITE3_VERSION "${_SQLITE3_VERSION}" )
    set( SQLITE3_VERSION "${CMAKE_MATCH_1}" CACHE
      STRING "Version of sqlite3 executable" )
    mark_as_advanced( SQLITE3_VERSION )

    find_library(SQLITE3_LIBRARIES sqlite3)
    find_path( SQLITE3_INCLUDE_DIR sqlite3.h )

    if (SQLITE3_INCLUDE_DIR AND SQLITE3_LIBRARIES)
      set( SQLITE3_FOUND TRUE )
    endif()
    if( NOT SQLITE3_FIND_QUIETLY )
      message( STATUS "Found sqlite3 version: ${SQLITE3_VERSION}" )
    endif()

  else()
    set( SQLITE3_FOUND FALSE )
    if( SQLITE3_FIND_REQUIRED )
      message( FATAL_ERROR "SQLITE3 not found" )
    endif()

  endif()
endif()

