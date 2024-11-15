# Find dot executable and libraries
# The following variables are set:
#
#  FOP_FOUND - Was dot found
#  FOP_EXECUTABLE  - path to the dot executable
#  FOP_VERSION - dot version

if( FOP_EXECUTABLE )

  set( FOP_FOUND true )

else( FOP_EXECUTABLE )
  
  find_program( FOP_EXECUTABLE
    NAMES fop fop.bat
  )
  
  if( FOP_EXECUTABLE )
    set( FOP_FOUND true )
    execute_process( COMMAND "${FOP_EXECUTABLE}" "-v"
                     OUTPUT_VARIABLE _output  ERROR_VARIABLE _output OUTPUT_STRIP_TRAILING_WHITESPACE
		     RESULT_VARIABLE _result)
    # VERSION
    if( _output )
      set( _versionRegex ".*FOP ([0-9]*)\\.([0-9]*)\\.?([0-9]*).*" )
      string( REGEX MATCH "${_versionRegex}" match "${_output}" )
      if(match)
        set( FOP_VERSION_MAJOR "${CMAKE_MATCH_1}" )
        set( FOP_VERSION_MINOR "${CMAKE_MATCH_2}" )
        set( FOP_VERSION_PATCH "${CMAKE_MATCH_3}" )
        set( FOP_VERSION "${FOP_VERSION_MAJOR}.${FOP_VERSION_MINOR}")
        if(FOP_VERSION_PATCH)
          set(FOP_VERSION "${FOP_VERSION}.${FOP_VERSION_PATCH}")
        endif()
        set( FOP_VERSION "${FOP_VERSION}" CACHE STRING "Fop full version")
      endif()
    else()
      message( STATUS "Fop version not found" )
    endif()

    if( NOT Fop_FIND_QUIETLY )
      message( STATUS "Found Fop: \"${FOP_EXECUTABLE}\" ${FOP_VERSION}" )
    endif()
    
  else( FOP_EXECUTABLE )
  
    set( FOP_FOUND false )
    
    if( Fop_FIND_REQUIRED )
      message( FATAL_ERROR "Fop not found" )
    else()
      if( NOT Fop_FIND_QUIETLY )
        message( STATUS "Fop not found" )
      endif()
    endif()
    
  endif( FOP_EXECUTABLE )

endif()
