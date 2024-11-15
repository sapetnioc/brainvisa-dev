# Find Stdc++
#
# STDCPP_FOUND
# STDCPP_LIBRARIES - the stdc++6 library

IF(STDCPP_LIBRARIES)
  # already found  
  SET(STDCPP_FOUND TRUE)
ELSE(STDCPP_LIBRARIES)
  FIND_FILE( STDCPP_LIBRARIES "libstdc++.so.6" 
     PATHS /usr/lib64 /usr/lib /usr/lib/gcc/x86_64-linux-gnu )
  IF( NOT STDCPP_LIBRARIES )
    FIND_FILE( STDCPP_LIBRARIES "libstdc++.so"
      PATHS "/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/?.?"
      "/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/?" )
  ENDIF()

  IF( NOT STDCPP_LIBRARIES )
    FIND_LIBRARY( STDCPP_LIBRARIES libstdc++-6 )
  ENDIF()
  
  IF( NOT STDCPP_LIBRARIES )
    execute_process( COMMAND "${CMAKE_CXX_COMPILER}" "-v"
      ERROR_VARIABLE _gcc_v )
    string( REGEX MATCH "gcc version (([0-9]+)(.[0-9]+)?)" _gccver "${_gcc_v}" )
    set( GCC_VERSION ${CMAKE_MATCH_1} CACHE STRING "gcc version" )
    set( _GCCPATH
      "/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/${GCC_VERSION}"
      "/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/${CMAKE_MATCH_2}")
    find_library( STDCPP_LIBRARIES "stdc++" PATHS ${_GCCPATH} )
    unset( _GCCPATH )
  ENDIF()
  
  IF( STDCPP_LIBRARIES )
    SET(STDCPP_FOUND TRUE)
    set( STDCPP_LIBRARIES ${STDCPP_LIBRARIES} CACHE PATH "stdc++ libraries" )
  ELSE()
    SET(STDCPP_FOUND FALSE)
      
    IF( STDCPP_FIND_REQUIRED )
        MESSAGE( SEND_ERROR "Stdc++6 was not found." )
    ENDIF()
    IF(NOT STDCPP_FIND_QUIETLY)
        MESSAGE(STATUS "Stdc++6 was not found.")
    ENDIF()
  ENDIF()

ENDIF()

