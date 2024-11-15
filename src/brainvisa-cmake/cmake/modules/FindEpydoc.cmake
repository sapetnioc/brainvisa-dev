if( EPYDOC_EXECUTABLE )

  set( Epydoc_FOUND true )

else( EPYDOC_EXECUTABLE )
  find_program( EPYDOC_EXECUTABLE
    NAMES epydoc
    DOC "documentation generation tool for Python (http://epydoc.sourceforge.net/)"
  )
  
  if( EPYDOC_EXECUTABLE )
    set( Epydoc_FOUND true )
    execute_process( COMMAND ${EPYDOC_EXECUTABLE} --version
                     OUTPUT_VARIABLE _output
                     RESULT_VARIABLE _result )
    if( ${_result} EQUAL 0 )
      set( _versionRegex ".*version ([0-9]*)\\.([0-9]*)\\.([0-9]*).*" )
      string( REGEX REPLACE "${_versionRegex}" "\\1" Epydoc_VERSION_MAJOR "${_output}" )
      string( REGEX REPLACE "${_versionRegex}" "\\2" Epydoc_VERSION_MINOR "${_output}" )
      string( REGEX REPLACE "${_versionRegex}" "\\3" Epydoc_VERSION_PATCH "${_output}" )
      if( NOT Epydoc_FIND_QUIETLY )
        message( STATUS "Found epydoc version ${Epydoc_VERSION_MAJOR}.${Epydoc_VERSION_MINOR}.${Epydoc_VERSION_PATCH}: \"${EPYDOC_EXECUTABLE}\"" )
      endif()
    else( ${_result} EQUAL 0 )
      if( NOT Epydoc_FIND_QUIETLY )
        message( STATUS "Found epydoc with unknown version: \"${EPYDOC_EXECUTABLE}\"" )
      endif()
    endif()
  else()
    set( Epydoc_FOUND false )
    if( NOT Epydoc_FIND_QUIETLY )
      if( Epydoc_FIND_REQUIRED )
        message( FATAL_ERROR "Epydoc not found" )
      else()
        message( STATUS "Epydoc not found" )
      endif()
    endif()
  endif()

endif()
