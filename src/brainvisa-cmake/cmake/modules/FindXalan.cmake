# Find Xalan executable (or jar file)
# The following variables are set:
#
#  XALAN_FOUND - Was found
#  XALAN_EXECUTABLE  - path to the XALAN executable

if( XALAN_EXECUTABLE )

  set( XALAN_FOUND true )

else( )
  
  find_program( XALAN_EXECUTABLE
    NAMES xalan xalan.bat
    DOC "Xalan XSLT Processor"
  )
  # if there is no xalan program, search for a jar archive for java
  if(NOT XALAN_EXECUTABLE)
    find_package(Java)
    if(JAVA_RUNTIME)
      find_file(xalan_jar NAMES xalan.jar xalan2.jar xalan-j2.jar
        PATH_SUFFIXES share/java
        DOC "Xalan jar file")
      if(xalan_jar)
        set(XALAN_EXECUTABLE "${JAVA_RUNTIME} -jar ${xalan_jar}" CACHE STRING "Xalan XSLT Processor command")
      endif()
    endif()
  endif()
  if( XALAN_EXECUTABLE )
    set( XALAN_FOUND true )

    if( NOT Xalan_FIND_QUIETLY )
      message( STATUS "Found Xalan: \"${XALAN_EXECUTABLE}\"" )
    endif( NOT Xalan_FIND_QUIETLY )
      
  else()
    set( Xalan_FOUND false )
    
    if( Xalan_FIND_REQUIRED )
      message( FATAL_ERROR "Xalan not found" )
    else()
      if( NOT Xalan_FIND_QUIETLY )
        message( STATUS "Xalan not found" )
      endif()
    endif()
    
  endif()

endif()
