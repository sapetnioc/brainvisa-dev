# This file defines the following variables:
#
# PYQT3_FOUND   - true if PyQt had been found
# PYQT3_VERSION - The version of PyQt as a human readable string.
# PYQT3_SIP_DIR - The directory holding the PyQt .sip files.

if( PYQT3_VERSION )
  set( PYQT3_FOUND true )
else( PYQT3_VERSION )
  if( NOT PYTHON_EXECUTABLE )
    if( PyQt_FIND_REQUIRED )
      find_package( PythonInterp REQUIRED )
    else( PyQt_FIND_REQUIRED )
      find_package( PythonInterp )
    endif( PyQt_FIND_REQUIRED )
  endif( NOT PYTHON_EXECUTABLE )

  set( PYQT3_FOUND false )
  if( PYTHON_HOST_EXECUTABLE )
    execute_process( COMMAND ${PYTHON_HOST_EXECUTABLE}
      -c "from __future__ import print_function; import pyqtconfig;cfg=pyqtconfig.Configuration();print(cfg.pyqt_version_str+\";\"+cfg.pyqt_sip_dir+\";\")"
      OUTPUT_VARIABLE _pyqtConfig
      ERROR_VARIABLE _error
      RESULT_VARIABLE _result )
      if( ${_result} EQUAL 0 )
        list( GET _pyqtConfig 0 PYQT3_VERSION )
        list( GET _pyqtConfig 1 PYQT3_SIP_DIR )
        set( PYQT3_FOUND true )
      else( ${_result} EQUAL 0 )
        if( NOT PyQt_FIND_QUIETLY )
          message( SEND_ERROR "Python code to find PyQt configuration produced an error:\n${_error}" )
        endif( NOT PyQt_FIND_QUIETLY )
      endif( ${_result} EQUAL 0 )
  endif( PYTHON_HOST_EXECUTABLE )

  if( PYQT3_FOUND )
    if( NOT PyQt_FIND_QUIETLY )
      message( STATUS "Found PyQt ${PYQT3_VERSION}" )
    endif( NOT PyQt_FIND_QUIETLY )
  else( PYQT3_FOUND )
    if( PyQt_FIND_REQUIRED )
      message( FATAL_ERROR "Could not find PyQt" )
    elseif( NOT PyQt_FIND_QUIETLY )
      message( STATUS "Could not find PyQt" )
    endif( PyQt_FIND_REQUIRED )
  endif( PYQT3_FOUND )

  set( PYQT3_VERSION "${PYQT3_VERSION}" CACHE STRING "PyQt 3 version" )
  mark_as_advanced(PYQT3_VERSION)
  file( TO_CMAKE_PATH "${PYQT3_SIP_DIR}" PYQT3_SIP_DIR )
  set( PYQT3_SIP_DIR "${PYQT3_SIP_DIR}" CACHE FILEPATH "PyQt 3 sip path" )
  mark_as_advanced(PYQT3_SIP_DIR)

endif( PYQT3_VERSION )
