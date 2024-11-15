# - Find python interpreter, libraries, includes and modules
# This module calls find_package( PythonInterp ) to find Python
# executable. Then it calls Python in order to get other information.
# The following variables are set:
#
#  PYTHON_FOUND - Was Python found
#  PYTHON_HOST_EXECUTABLE  - path to the Python interpreter
#  PYTHON_HOST_EXECUTABLE_NAME - name of the python interpreter
#  PYTHON_HOST_PREFIX - path to the install directory of the python interpreter
#  PYTHON_HOST_MODULES_PATH - path to main Python modules
#  PYTHON_HOST_VERSION - Python full version (e.g. "2.7.12")
#  PYTHON_HOST_SHORT_VERSION - Python short version (e.g. "2.7")
#  PYTHON_EXECUTABLE - path to the target python interpreter
#  PYTHON_EXECUTABLE_NAME - name of the target python interpreter
#  PYTHON_PREFIX - path to the install directory of the target python interpreter
#  PYTHON_MODULES_PATH - path to main Python modules
#  PYTHON_VERSION - Python target full version (e.g. "2.7.12")
#  PYTHON_SHORT_VERSION - Python target short version (e.g. "2.7")
#  PYTHON_INCLUDE_PATH - path to target python header files
#  PYTHON_LIBRARY - path to target python dynamic library
#  PYTHON_FLAGS - flags used to compile target python dynamic library
function(__GET_PYTHON_INFO __python_executable __output_prefix __translate_path __target_system_prefix)

  get_filename_component("${__output_prefix}_EXECUTABLE_NAME" 
                         "${__python_executable}" NAME CACHE)
     
  execute_process( COMMAND ${__target_system_prefix}
                           "${__python_executable}"
                           "-c" "import sys, os; sys.stdout.write(os.path.normpath( sys.prefix ))"
    OUTPUT_VARIABLE _prefix )
  if(__translate_path AND COMMAND TARGET_TO_HOST_PATH)
    #message("==== __GET_PYTHON_INFO, TARGET_TO_HOST_PATH is defined")
    TARGET_TO_HOST_PATH( "${_prefix}" _prefix ) 
  endif()
  FILE( TO_CMAKE_PATH "${_prefix}" "${__output_prefix}_PREFIX" )
  set("${__output_prefix}_PREFIX" "${${__output_prefix}_PREFIX}"
        CACHE FILEPATH "Python install prefix")
  execute_process( COMMAND ${__target_system_prefix}
                           "${__python_executable}" 
                           "-c" "import sys; sys.stdout.write('.'.join( (str(i) for i in sys.version_info[ :2 ]) ))"
    OUTPUT_VARIABLE _version )
  execute_process( COMMAND ${__target_system_prefix}
                           "${__python_executable}" 
                           "-c" "import sys; sys.stdout.write('.'.join( (str(i) for i in sys.version_info[ :3 ]) ))"
    OUTPUT_VARIABLE _fullVersion )
  message( STATUS "Using python ${_fullVersion}: ${__python_executable}" )
  execute_process( COMMAND ${__target_system_prefix}
                           "${__python_executable}"
                           "-c" "import sys, os; print(';'.join([s for s in sys.path if os.path.exists(s)]))"
    OUTPUT_VARIABLE _pythonpath OUTPUT_STRIP_TRAILING_WHITESPACE )
  if(__translate_path AND COMMAND TARGET_TO_HOST_PATH)
    TARGET_TO_HOST_PATH( "${_pythonpath}" _pythonpath ) 
  endif()

  set( "${__output_prefix}_VERSION" "${_fullVersion}" CACHE STRING "Python full version (e.g. \"2.7.12\")" FORCE)
  set( "${__output_prefix}_SHORT_VERSION" "${_version}" CACHE STRING "Python short version (e.g. \"2.7\")" FORCE)

  find_path( "${__output_prefix}_MODULES_PATH2"
    NAMES platform.py
    HINTS
      "${_prefix}/lib"
      ${_pythonpath}
      ${PYTHON_FRAMEWORK_INCLUDES}
      [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_version}\\InstallPath]/include
    PATH_SUFFIXES
      python${_version}
  )
  find_path( "${__output_prefix}_MODULES_PATH1"
    NAMES os.py
    HINTS
      "${_prefix}/lib"
      ${PYTHON_FRAMEWORK_INCLUDES}
      [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_version}\\InstallPath]/include
    PATH_SUFFIXES
      python${_version}
  )
  # keep paths ending with "site-packages"
  set( "${__output_prefix}_MODULES_PATH3" )
  foreach( _mod ${_pythonpath} )
    get_filename_component( _modname ${_mod} NAME )
    if( ${_modname} STREQUAL "site-packages"
        OR ${_modname} STREQUAL "dist-packages" )
      get_filename_component( _modpath ${_mod} PATH )
      if( EXISTS ${_modpath} )
        list( APPEND "${__output_prefix}_MODULES_PATH3" ${_modpath} )
      endif()
    endif()
  endforeach()

  set(_mod_vars ${__output_prefix}_MODULES_PATH3
                ${__output_prefix}_MODULES_PATH1
                ${__output_prefix}_MODULES_PATH2)
  set(_mod_paths)
  foreach(_v ${_mod_vars})
    if(${_v})
      list(APPEND _mod_paths ${${_v}})
    endif()
  endforeach()

  # in case of cross compilation it is possible that _mod_paths is empty
  # for python host modules search. So it is necessary to check.
  if (_mod_paths)
    list( REMOVE_DUPLICATES _mod_paths )
    set( "${__output_prefix}_MODULES_PATH" ${_mod_paths}
        CACHE PATH "Python main modules paths" FORCE)
  endif()
  mark_as_advanced( "${__output_prefix}_MODULES_PATH" )
  unset( "${__output_prefix}_MODULES_PATH1" CACHE )
  unset( "${__output_prefix}_MODULES_PATH2" CACHE )
  unset( "${__output_prefix}_MODULES_PATH3" CACHE )

endfunction()

if ( PYTHON_VERSION AND PYTHON_EXECUTABLE AND PYTHON_PREFIX
    AND PYTHON_HOST_VERSION AND PYTHON_HOST_EXECUTABLE AND PYTHON_HOST_PREFIX)
  # Python already found, do nothing
  set( PYTHON_FOUND TRUE )
else()
  find_package( PythonInterp REQUIRED )
  include( CMakeFindFrameworks )
  # Search for the python framework on Apple.
  cmake_find_frameworks( Python )

  # Get python information for the host python interpreter
  __GET_PYTHON_INFO("${PYTHON_HOST_EXECUTABLE}" PYTHON_HOST NO "")
  
  # Also get target python interpreter information if possible
  if(CMAKE_CROSSCOMPILING)
    if(WIN32)
        find_package(Wine)
    endif()
    if(CMAKE_CROSSCOMPILING_RUNNABLE)
        # Get python information for the target Python interpreter
        __GET_PYTHON_INFO("${PYTHON_EXECUTABLE}" PYTHON YES "${CMAKE_TARGET_SYSTEM_PREFIX}")
    endif()
  else()
    set(PYTHON_EXECUTABLE_NAME "${PYTHON_HOST_EXECUTABLE_NAME}" 
        CACHE STRING "Target python name")
    set(PYTHON_VERSION ${PYTHON_HOST_VERSION}
        CACHE STRING "Target python version") 
    set(PYTHON_SHORT_VERSION ${PYTHON_HOST_SHORT_VERSION}
        CACHE STRING "Target python short version") 
    set(PYTHON_MODULES_PATH ${PYTHON_HOST_MODULES_PATH}
        CACHE STRING "Target python modules")
    set(PYTHON_PREFIX ${PYTHON_HOST_PREFIX}
        CACHE FILEPATH "Target python install prefix")
  endif()
  
  # Get library and include path
  set( PYTHON_FRAMEWORK_INCLUDES )
  set( PYTHON_FRAMEWORK_LIBRARIES )
  if( Python_FRAMEWORKS AND NOT PYTHON_INCLUDE_PATH )
    foreach( _dir ${Python_FRAMEWORKS} )
      set( PYTHON_FRAMEWORK_INCLUDES ${PYTHON_FRAMEWORK_INCLUDES}
          "${_dir}/Versions/${PYTHON_SHORT_VERSION}/include/python${PYTHON_SHORT_VERSION}" )
      set( PYTHON_FRAMEWORK_LIBRARIES ${PYTHON_FRAMEWORK_LIBRARIES}
          "${_dir}/Versions/${PYTHON_SHORT_VERSION}/lib" )
    endforeach()
  endif()
  find_path( PYTHON_INCLUDE_PATH
    NAMES Python.h
    PATHS
      "${PYTHON_PREFIX}/include"
    PATH_SUFFIXES
      python${PYTHON_SHORT_VERSION}m
      python${PYTHON_SHORT_VERSION}
    NO_DEFAULT_PATH
  )
  find_path( PYTHON_INCLUDE_PATH
    NAMES Python.h
    PATHS
      ${PYTHON_FRAMEWORK_INCLUDES}
      [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${PYTHON_SHORT_VERSION}\\InstallPath]/include
    PATH_SUFFIXES
      python${PYTHON_SHORT_VERSION}
  )
  mark_as_advanced( PYTHON_INCLUDE_PATH )
  
  # try to find the "python3-config" or "python2-config" program
  get_filename_component( _py_exe_dir ${PYTHON_EXECUTABLE} PATH )
  set( _py_config_exe 
        "${_py_exe_dir}/python${PYTHON_SHORT_VERSION}-config${CMAKE_EXECUTABLE_SUFFIX}" )
  if( EXISTS ${_py_config_exe} )
    execute_process( COMMAND "${_py_config_exe}" "--libs"
                     OUTPUT_VARIABLE _py_libs )
    string( REGEX MATCH "(python[^ ]*)" _py_main_lib "${_py_libs}" )
  endif()

  find_package(PythonLibs REQUIRED)

  if( WIN64 )
    set( PYTHON_FLAGS MS_WIN64 CACHE STRING "Flags used to compile target python interpreter" )
  endif()
  
#   message("==== Python host interpreter")
#   message("PYTHON_HOST_EXECUTABLE: ${PYTHON_HOST_EXECUTABLE}") 
#   message("PYTHON_HOST_EXECUTABLE_NAME: ${PYTHON_HOST_EXECUTABLE_NAME}") 
#   message("PYTHON_HOST_PREFIX: ${PYTHON_HOST_PREFIX}")
#   message("PYTHON_HOST_VERSION: ${PYTHON_HOST_VERSION}") 
#   message("PYTHON_HOST_SHORT_VERSION: ${PYTHON_HOST_SHORT_VERSION}")
#   message("PYTHON_HOST_MODULES_PATH: ${PYTHON_HOST_MODULES_PATH}")
#   message("==== Python target interpreter") 
#   message("PYTHON_EXECUTABLE: ${PYTHON_EXECUTABLE}") 
#   message("PYTHON_EXECUTABLE_NAME: ${PYTHON_EXECUTABLE_NAME}") 
#   message("PYTHON_PREFIX: ${PYTHON_PREFIX}")
#   message("PYTHON_VERSION: ${PYTHON_VERSION}") 
#   message("PYTHON_SHORT_VERSION: ${PYTHON_SHORT_VERSION}")
#   message("PYTHON_INCLUDE_PATH: ${PYTHON_INCLUDE_PATH}")
#   message("PYTHON_LIBRARY: ${PYTHON_LIBRARY}")
#   message("PYTHON_MODULES_PATH: ${PYTHON_MODULES_PATH}")
#   message("====")
#   
  # handle the QUIETLY and REQUIRED arguments and set PYTHONINTERP_FOUND to TRUE if
  # all listed variables are TRUE
  INCLUDE(FindPackageHandleStandardArgs)
  FIND_PACKAGE_HANDLE_STANDARD_ARGS(python DEFAULT_MSG PYTHON_INCLUDE_PATH PYTHON_LIBRARY)
endif()
