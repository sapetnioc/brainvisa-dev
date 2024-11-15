# Find qwt include dir and library
# The following variables are set:
#
#  QWT_FOUND - Was qwt found
#  QWT_LIBRARY -  qwt dynamic library
#  QWT_INCLUDE_DIR - include directory where to find qwt.h

if(QWT_LIBRARY AND QWT_INCLUDE_DIR)
  set(QWT_FOUND TRUE) 
endif()

if( NOT QWT_FOUND )
  set( paths qwt-qt${DESIRED_QT_VERSION} qwt5-qt${DESIRED_QT_VERSION} qwt qwt5 )
  set( include_paths)
  set( lib_paths)
  foreach( path ${paths} )
    set( include_paths ${include_paths} "${path}" "${path}/include" )
    set( lib_paths ${lib_paths} "${path}" "${path}/lib" )
  endforeach()
  set(include_paths ${include_paths} "include")
  set(lib_paths ${lib_paths} "lib")

  # First look only in paths from CMAKE_PREFIX_PATH
  find_path( QWT_INCLUDE_DIR qwt.h 
             PATHS ${CMAKE_PREFIX_PATH} ENV QWTDIR
             PATH_SUFFIXES ${include_paths}
             NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH )
  find_library( QWT_LIBRARY 
                NAMES qwt-qt${DESIRED_QT_VERSION} qwt5-qt${DESIRED_QT_VERSION} qwt5 qwt
                PATHS ${CMAKE_PREFIX_PATH} ENV QWTDIR
                PATH_SUFFIXES ${lib_paths}
                NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH )

  # Then look into all standard paths
  find_path( QWT_INCLUDE_DIR qwt.h 
             PATH_SUFFIXES ${include_paths} )
  find_library( QWT_LIBRARY 
                NAMES qwt-qt${DESIRED_QT_VERSION} qwt5-qt${DESIRED_QT_VERSION} qwt5 qwt
                PATH_SUFFIXES ${lib_paths} )

  # check that it is linked against the correct version of Qt
  if( QWT_LIBRARY AND (UNIX AND NOT APPLE) )
    execute_process( COMMAND ldd ${QWT_LIBRARY} OUTPUT_VARIABLE _qwt_libs )
#     message("QWT_LIBRARY: ${QWT_LIBRARY}")
#     message("Qwt linked libs:")
#     message("${_qwt_libs}")
    if( DESIRED_QT_VERSION EQUAL 4 )
      string( REGEX MATCH ".*(libQt5[^$]*)$" _match ${_qwt_libs} )
      if( _match )
        message( "Qwt is found but is linked against a different version of Qt (${QWT_LIBRARY}). Desired Qt version is ${DESIRED_QT_VERSION}" )
        unset( QWT_LIBRARY CACHE )
        unset( QWT_LIBRARY )
      endif()
    elseif( DESIRED_QT_VERSION EQUAL 5 )
      string( REGEX MATCH ".*(libQt[^$\\r\\n]*\\.so\\.4[^$]*)$" _match ${_qwt_libs} )
      if( _match )
        message( "Qwt is found but is linked against a different version of Qt (${QWT_LIBRARY}). Desired Qt version is ${DESIRED_QT_VERSION}" )
        unset( QWT_LIBRARY CACHE )
        unset( QWT_LIBRARY )
      endif()
    endif()
  endif()

  if( APPLE AND QWT_LIBRARY AND NOT QWT_INCLUDE_DIR )
    # if the lib is a framework
    find_path( QWT_INCLUDE_DIR qwt.h
               PATHS ${QWT_LIBRARY}/Headers
               NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH )
  endif()

  SET(QWT_FOUND FALSE)
  IF(QWT_INCLUDE_DIR AND QWT_LIBRARY)
    
    if(NOT QWT_VERSION)
      # Try to find qwt version
      if( EXISTS "${QWT_INCLUDE_DIR}/qwt_global.h" )
        include(UseVersionConvert)
        file( READ "${QWT_INCLUDE_DIR}/qwt_global.h" header )
        string( REGEX MATCH "#define[ \\t]+QWT_VERSION[ \\t]+(0x[0-9a-fA-F]+)" match "${header}" )

        if( match )
          # Convert hexadecimal version
          version_convert(__version ${CMAKE_MATCH_1} STR)
          set(QWT_VERSION "${__version}" 
              CACHE STRING "Qwt library version")
          unset(__version)
        endif()
      endif()
    endif()
    
    SET(QWT_FOUND TRUE)
  ENDIF(QWT_INCLUDE_DIR AND QWT_LIBRARY)

  IF(NOT QWT_FOUND)
    IF(NOT QWT_FIND_QUIETLY)
      MESSAGE(STATUS "Qwt was not found.")
    ELSE(NOT QWT_FIND_QUIETLY)
      IF(QWT_FIND_REQUIRED)
        MESSAGE(FATAL_ERROR "Qwt was not found.")
      ENDIF(QWT_FIND_REQUIRED)
    ENDIF(NOT QWT_FIND_QUIETLY)
  ENDIF(NOT QWT_FOUND)
endif()
