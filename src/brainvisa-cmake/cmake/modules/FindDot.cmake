# Find dot executable and libraries
# The following variables are set:
#
#  DOT_FOUND - Was dot found
#  DOT_EXECUTABLE  - path to the dot executable
#  DOT_LIBRARIES - path to graphviz dynamic libraries needed to run dot
#  DOT_VERSION - dot version

if( DOT_EXECUTABLE )

  set( Dot_FOUND true )

else( DOT_EXECUTABLE )
  
  find_program( DOT_EXECUTABLE
    NAMES dot
    PATHS "$ENV{ProgramFiles}/ATT/Graphviz/bin"
    "C:/Program Files/ATT/Graphviz/bin"
    [HKEY_LOCAL_MACHINE\\SOFTWARE\\ATT\\Graphviz;InstallPath]/bin
    /Applications/Graphviz.app/Contents/MacOS
    /Applications/Doxygen.app/Contents/Resources
    /Applications/Doxygen.app/Contents/MacOS
    DOC "Graphviz Dot tool"
  )
  
  if( DOT_EXECUTABLE )
    set( DOT_FOUND true )
    execute_process( COMMAND "${DOT_EXECUTABLE}" "-V"
                     OUTPUT_VARIABLE _output  ERROR_VARIABLE _output OUTPUT_STRIP_TRAILING_WHITESPACE
		     RESULT_VARIABLE _result)
    # VERSION
    if( _output AND _result EQUAL 0 )
      set( _versionRegex ".*version ([0-9]*)\\.([0-9]*)\\.?([0-9]*).*" )
      string( REGEX MATCH "${_versionRegex}" match "${_output}" )
      if(match)
        set( DOT_VERSION_MAJOR "${CMAKE_MATCH_1}" )
        set( DOT_VERSION_MINOR "${CMAKE_MATCH_2}" )
        set( DOT_VERSION_PATCH "${CMAKE_MATCH_3}" )
        set( DOT_VERSION "${DOT_VERSION_MAJOR}.${DOT_VERSION_MINOR}")
        if(DOT_VERSION_PATCH)
          set(DOT_VERSION "${DOT_VERSION}.${DOT_VERSION_PATCH}")
        endif()
        set( DOT_VERSION "${DOT_VERSION}" CACHE STRING "Dot full version")
      endif()
    else()
      message( STATUS "Dot version not found" )
    endif()

    # LIBRARIES
    set( DOT_LIBRARIES )
    find_library( DOT_CDT_LIB NAMES cdt-4 cdt )
    if( NOT DOT_CDT_LIB )
      file( GLOB DOT_CDT_LIB /usr/lib/libcdt.so.? )  
    endif()
    
    if(DOT_CDT_LIB)
      set( DOT_LIBRARIES ${DOT_LIBRARIES} "${DOT_CDT_LIB}")
    else()
      message( STATUS "Graphviz Cdt library not found" )
    endif()
    unset(DOT_CDT_LIB CACHE)

    find_library( DOT_GVC_LIB NAMES gvc-5 gvc )
    if( NOT DOT_GVC_LIB )
      file( GLOB DOT_GVC_LIB /usr/lib/libgvc.so.? )
    endif()
    if( DOT_GVC_LIB )
      set( DOT_LIBRARIES ${DOT_LIBRARIES} "${DOT_GVC_LIB}")
    else()
      message( STATUS "Graphviz gvc library not found" )
    endif()
    unset(DOT_GVC_LIB CACHE)

    find_library( DOT_PATHPLAN_LIB NAMES pathplan-4 pathplan )
    if( NOT DOT_PATHPLAN_LIB )
      file( GLOB DOT_PATHPLAN_LIB /usr/lib/libpathplan.so.? )
    endif()
    if( DOT_PATHPLAN_LIB )
      set( DOT_LIBRARIES ${DOT_LIBRARIES} "${DOT_PATHPLAN_LIB}")
    else()
      message( STATUS "Graphviz pathplan library not found" )
    endif()
    unset(DOT_PATHPLAN_LIB CACHE)

    find_library( DOT_GRAPH_LIB NAMES graph-4 graph NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_PATH NO_CMAKE_SYSTEM_PATH )
    
    if( NOT DOT_GRAPH_LIB )
      file( GLOB DOT_GRAPH_LIB /usr/lib/libgraph.so.? )
    endif()
    if( DOT_GRAPH_LIB )
      set( DOT_LIBRARIES ${DOT_LIBRARIES} "${DOT_GRAPH_LIB}")
    else()
      message( STATUS "Graphviz graph library not found" )
    endif()
    unset(DOT_GRAPH_LIB CACHE)
    
    if( WIN32 )
      get_filename_component(realdot ${DOT_EXECUTABLE} REALPATH)
      get_filename_component(bindot ${realdot} PATH)
      
      BRAINVISA_FIND_FSENTRY( DOT_PLUGINS PATTERNS "libgvplugin_*" PATHS "${bindot}" )
      if( DOT_PLUGINS )
        set( DOT_LIBRARIES ${DOT_LIBRARIES} ${DOT_PLUGINS} )
      endif()
      
      BRAINVISA_FIND_FSENTRY( DOT_CONFIG PATTERNS "config*" PATHS "${bindot}" )
    endif()

    if( DOT_LIBRARIES )
      set( DOT_LIBRARIES ${DOT_LIBRARIES} CACHE PATH "Graphviz dynamic libraries needed to run dot")
    endif()

    if( NOT Dot_FIND_QUIETLY )
      message( STATUS "Found dot: \"${DOT_EXECUTABLE}\" ${DOT_VERSION}" )
    endif( NOT Dot_FIND_QUIETLY )
  else( DOT_EXECUTABLE )
    set( Dot_FOUND false )
    
    if( Dot_FIND_REQUIRED )
      message( FATAL_ERROR "Dot not found" )
    else()
      if( NOT Dot_FIND_QUIETLY )
        message( STATUS "Dot not found" )
      endif()
    endif()
    
  endif( DOT_EXECUTABLE )

endif( DOT_EXECUTABLE )
