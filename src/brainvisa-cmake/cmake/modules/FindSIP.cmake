# This file defines the following variables:
#
# SIP_EXECUTABLE - Path and filename of the SIP command line executable.
#
# SIP_INCLUDE_DIR - Directory holding the SIP C++ header file.
#
# SIP_INCLUDE_DIRS - All include directories necessary to compile sip generated files.
#
# SIP_VERSION - The version of SIP found expressed as a 6 digit hex number
#     suitable for comparision as a string.
#

# message( "SIP_VERSION: ${SIP_VERSION}" )
if( SIP_VERSION )
  # SIP is already found, do nothing
  set( SIP_INCLUDE_DIRS "${PYTHON_INCLUDE_PATH}" "${SIP_INCLUDE_DIR}" )
  set(SIP_FOUND TRUE)
else( SIP_VERSION )
    if( ( DESIRED_QT_VERSION EQUAL 6 ) AND NOT DESIRED_SIP_VERSION )
      set( DESIRED_SIP_VERSION 6 )
    endif()
    if( DESIRED_SIP_VERSION GREATER 5 )
        # Try to find sip in target root path
        find_program( SIP_EXECUTABLE
          NAMES sip-build${CMAKE_EXECUTABLE_SUFFIX}
          ONLY_CMAKE_FIND_ROOT_PATH
          DOC "Path to sip-build executable" )
        find_program( SIP_MODULE_EXECUTABLE
          NAMES sip-module${CMAKE_EXECUTABLE_SUFFIX}
          ONLY_CMAKE_FIND_ROOT_PATH
          DOC "Path to sip-module executable" )
    elseif( DESIRED_SIP_VERSION EQUAL 5 )
        # Try to find sip in target root path
        find_program( SIP_EXECUTABLE
          NAMES sip5${CMAKE_EXECUTABLE_SUFFIX}
          ONLY_CMAKE_FIND_ROOT_PATH
          DOC "Path to sip executable" )
        find_program( SIP_MODULE_EXECUTABLE
          NAMES sip-module${CMAKE_EXECUTABLE_SUFFIX}
          ONLY_CMAKE_FIND_ROOT_PATH
          DOC "Path to sip-module executable" )
    else()
        # Try to find sip in target root path
        find_program( SIP_EXECUTABLE
          NAMES sip${CMAKE_EXECUTABLE_SUFFIX}
          ONLY_CMAKE_FIND_ROOT_PATH
          DOC "Path to sip executable" )
    endif()
  
    if( SIP_EXECUTABLE )
      find_package( python REQUIRED )
      if(CMAKE_CROSSCOMPILING AND WIN32)
        find_package(Wine)
      endif()
    
      mark_as_advanced( SIP_EXECUTABLE )
      execute_process( COMMAND ${CMAKE_TARGET_SYSTEM_PREFIX} ${SIP_EXECUTABLE} -V OUTPUT_VARIABLE SIP_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE )
      set( SIP_VERSION "${SIP_VERSION}" CACHE STRING "Version of sip executable" )
      mark_as_advanced( SIP_VERSION )
      if( SIP_VERSION VERSION_LESS 5.0.0 )
        execute_process( COMMAND ${CMAKE_TARGET_SYSTEM_PREFIX} ${PYTHON_EXECUTABLE} -c "import sipconfig, sys; sys.stdout.write(sipconfig.Configuration().sip_inc_dir + '\\n')"
          OUTPUT_VARIABLE SIP_INCLUDE_DIR OUTPUT_STRIP_TRAILING_WHITESPACE )
        set( SIP_INCLUDE_DIR "${SIP_INCLUDE_DIR}" CACHE PATH "Path to sip include files" )
        mark_as_advanced( SIP_INCLUDE_DIR )
      else()
        set( SIP_INCLUDE_DIR "${CMAKE_BINARY_DIR}/include" CACHE PATH "Path to sip include files" )
        mark_as_advanced( SIP_INCLUDE_DIR )
      endif()
      set( SIP_INCLUDE_DIRS "${PYTHON_INCLUDE_PATH}" "${SIP_INCLUDE_DIR}" )
      set( SIP_FOUND TRUE )
      if( NOT SIP_FIND_QUIETLY )
        message( STATUS "Found SIP version: ${SIP_VERSION}" )
      endif(NOT SIP_FIND_QUIETLY)
    else( SIP_EXECUTABLE )
      set( SIP_FOUND FALSE )
      if( SIP_FIND_REQUIRED )
        message( FATAL_ERROR "SIP not found" )
      endif( SIP_FIND_REQUIRED )
    endif( SIP_EXECUTABLE )

    if( SIP_FOUND )
      if( ( ${SIP_VERSION} VERSION_GREATER 4.7.4 ) AND
        ( ${SIP_VERSION} VERSION_LESS 4.7.7 ) )
        # this flag is used in pyaims/pyanatomist to work around buggy throw
        # statements which make sip segfault
        set( SIP_FLAGS "-t" "SIPTHROW_BUG" CACHE STRING "options passed to SIP program" )
      elseif( ${SIP_VERSION} VERSION_GREATER 4.19.9 )
        # using sip >= 4.19.9, the sip module may be a "private copy" inside
        # PyQt, we must use the module as it is named in PyQt.
        execute_process( COMMAND ${CMAKE_TARGET_SYSTEM_PREFIX} ${PYTHON_EXECUTABLE} -c "import PyQt${DESIRED_QT_VERSION}.sip"
            RESULT_VARIABLE _new_module )
        if( _new_module EQUAL 0 )
          set( SIP_FLAGS "-n" "PyQt${DESIRED_QT_VERSION}.sip" CACHE STRING
              "options passed to SIP program" )
          set( SIP_MODULE "PyQt${DESIRED_QT_VERSION}.sip" CACHE STRING
               "sip python module" )
          # get the sip ABI version in PyQt
          find_file( _find_sipabi_py FindSipABI.py PATHS ${CMAKE_MODULE_PATH} )
          execute_process(COMMAND ${CMAKE_TARGET_SYSTEM_PREFIX} ${PYTHON_HOST_EXECUTABLE} "${_find_sipabi_py}" "${SIP_MODULE}" OUTPUT_VARIABLE SIP_ABI )
        else()
          set( SIP_FLAGS "" CACHE STRING "options passed to SIP program" )
          set( SIP_MODULE "sip" CACHE STRING "sip python module" )
        endif()
        if( SIP_MODULE_EXECUTABLE )  # sip 5/6
          if( SIP_ABI )
            set( SIP_ABI ${SIP_ABI} CACHE STRING "SIP ABI version" )
            set( _added_flags "--abi-version" "${SIP_ABI}" )
          execute_process( COMMAND "${SIP_MODULE_EXECUTABLE}" "--sip-h" "--target-dir" "${CMAKE_BINARY_DIR}/include" ${_added_flags} "${SIP_MODULE}" )
          endif()
        endif()
      else()
        set( SIP_FLAGS "" CACHE STRING "options passed to SIP program" )
        set( SIP_MODULE "sip" CACHE STRING "sip python module" )
      endif()
      if( NOT SIP4MAKE_EXECUTABLE )
        find_program( SIP4MAKE_EXECUTABLE
          NAMES bv_sip4make
          PATHS "${brainvisa-cmake_SOURCE_DIR}/bin"
          NO_DEFAULT_PATH
          DOC "Path to bv_sip4make script" )
      endif()
      if( NOT SIP4MAKE_EXECUTABLE )
        # find the sip4make.py wrapper script
        find_program( SIP4MAKE_EXECUTABLE
          NAMES bv_sip4make
          DOC "Path to bv_sip4make script" )
        if( NOT SIP4MAKE_EXECUTABLE )
          # not found: use the regular sip executable
          set( SIP4MAKE_EXECUTABLE "$SIP_EXECUTABLE" CACHE FILEPATH "Path to bv_sip4make script (or sip itself as fallback)" )
        endif()
      endif()
    endif()

endif( SIP_VERSION )
