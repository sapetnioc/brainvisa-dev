cmake_policy( SET CMP0011 NEW )
cmake_policy( SET CMP0009 NEW )
cmake_policy( SET CMP0054 NEW )
cmake_policy( SET CMP0057 NEW )
cmake_policy( SET CMP0072 NEW )

get_property( config_done GLOBAL PROPERTY BRAINVISA_CMAKE_CONFIG_DONE )

if (WIN32)
    set(BRAINVISA_CMAKE_LIBRARY_PATH_SUFFIXES lib bin)
else()
    set(BRAINVISA_CMAKE_LIBRARY_PATH_SUFFIXES lib)
endif()

# OS identifier
if( ${CMAKE_SYSTEM_NAME} STREQUAL "Linux" )
  if( EXISTS /etc/lsb-release )
    file( READ /etc/lsb-release _x )
    string( REGEX MATCH "DISTRIB_ID=([^\n]+)" _y "${_x}" )
    if( _y )
      string( TOLOWER ${CMAKE_MATCH_1} _y )
      set( LSB_DISTRIB ${_y} CACHE STRING "Linux distribution identifier" )
      string( REGEX MATCH "DISTRIB_RELEASE=([0-9.]+)" _ver "${_x}" )
      if( _ver )
        set( LSB_DISTRIB_RELEASE ${CMAKE_MATCH_1} CACHE STRING "Linux distribution version" )
      endif()
    endif()
  elseif( EXISTS /etc/redhat-release )
    file( READ /etc/redhat-release _x )
    string( REGEX MATCH "(.+) release ([0-9.]+)" _y "${_x}" )
    if( _y )
      string( TOLOWER ${CMAKE_MATCH_1} _y )
      set( LSB_DISTRIB ${_y} CACHE STRING "Linux distribution identifier" )
      set( LSB_DISTRIB_RELEASE ${CMAKE_MATCH_2} CACHE STRING "Linux distribution version" )
    endif()
  endif()
endif()

set( CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${brainvisa-cmake_DIR}/modules" )
if( NOT config_done )
  set_property( GLOBAL PROPERTY BRAINVISA_CMAKE_CONFIG_DONE YES )

  option( CMAKE_OVERRIDE_COMPILER_MISMATCH "Avoid CMake to completely erase the cache if a compiler mismatch is detected (for instance with find_package( VTK ))" ON )

  # Include code specific to a platform or site
  file( GLOB _files "${brainvisa-cmake_DIR}/specific/*.cmake" )
  foreach( _file ${_files} )
    include( "${_file}" )
  endforeach()

  # Requires CPack for its argument parsing macro
  if(NOT CPack_CMake_INCLUDED)
#     include( BRAINVISA_ADD_COMPONENT_GROUP )
  endif()

  if( NOT DEFINED BRAINVISA_SYSTEM_IDENTIFICATION )
    execute_process( COMMAND "${brainvisa-cmake_DIR}/../../../bin/bv_system_info" -s
      OUTPUT_VARIABLE output OUTPUT_STRIP_TRAILING_WHITESPACE
      RESULT_VARIABLE result )
    if( output AND result EQUAL 0 )
      set( BRAINVISA_SYSTEM_IDENTIFICATION "${output}" )
    else()
      set( BRAINVISA_SYSTEM_IDENTIFICATION "${CMAKE_SYSTEM_NAME}" )
    endif()
    set( BRAINVISA_SYSTEM_IDENTIFICATION "${BRAINVISA_SYSTEM_IDENTIFICATION}" CACHE STRING "Suffix for system identification in packages name" )
  endif()

  if (NOT DEFINED BRAINVISA_SYSTEM_VERSION)
    # Get system version
    set(result)
    string( REGEX REPLACE "[^-]+-(.*)" "\\1" result "${BRAINVISA_SYSTEM_IDENTIFICATION}" )
    set( BRAINVISA_SYSTEM_VERSION "${result}" CACHE STRING "Version for system identification in packages name" )
  endif()

  if(NOT DEFINED BRAINVISA_ADVANCED_FEATURE_TEST_MODE)
    option( BRAINVISA_ADVANCED_FEATURE_TEST_MODE "Enable/disable BrainVISA advanced feature test mode" OFF )
  endif()

  if(NOT DEFINED CCACHE_ENABLED)
    option( CCACHE_ENABLED "Enable/disable use of ccache if possible" OFF )
  endif()

  # Initialize python module containing compilation information
  set( BRAINVISA_COMPILATION_INFO "${CMAKE_BINARY_DIR}/${PYTHON_INSTALL_DIRECTORY}/brainvisa/compilation_info.py" )
  execute_process( COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_BINARY_DIR}/${PYTHON_INSTALL_DIRECTORY}/brainvisa" )
  configure_file( "${brainvisa-cmake_DIR}/compilation_info.py.in" "${BRAINVISA_COMPILATION_INFO}" @ONLY )

endif()

if(CCACHE_ENABLED)
  find_program(CCACHE_FOUND ccache)
  if(CCACHE_FOUND)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
  endif(CCACHE_FOUND)
endif()

# This ugly fix allows Boost to detect recent library versions
# as they are not always defined in FindBoost.cmake. It probably
# has to move to another file.
set( Boost_ADDITIONAL_VERSIONS
     "1.75.0" "1.75" "1.74.0" "1.74" "1.73.0" "1.73" "1.72.0" "1.72"
     "1.71.0" "1.71" "1.70.0" "1.70" "1.69.0" "1.69" "1.68.0" "1.68"
     "1.67.0" "1.67" "1.66.0" "1.66" "1.65.1" "1.65.0" "1.65"
     "1.64.0" "1.64" "1.63.0" "1.63" "1.62.0" "1.62" "1.61.0" "1.61"
     "1.60.0" "1.60" "1.59.0" "1.59" "1.58.0" "1.58" "1.57.0" "1.57"
     "1.56.0" "1.56" "1.55.0" "1.55" "1.54.0" "1.54" "1.53.0" "1.53"
     "1.52.0" "1.52" "1.51.0" "1.51" "1.50.0" "1.50" "1.49.0" "1.49"
     "1.48.0" "1.48" "1.47.0" "1.47" "1.46.1" "1.46.0" "1.46"
     "1.45.0" "1.45" "1.44.0" "1.44" "1.43.0" "1.43" "1.42.0" "1.42"
     "1.41.0" "1.41" "1.40.0" "1.40" "1.39.0" "1.39" )
# Do not use BoostConfig.cmake from boost-cmake, because its behaviour may be
# different from regular FindBoost.cmake.
set(Boost_NO_BOOST_CMAKE ON)

#
# BRAINVISA_SYSTEM_PATH_TO_LIST
#   Convert a path stored in a system environment variable into a cmake list.
#
# Usage:
#  BRAINVISA_SYSTEM_PATH_TO_LIST( <output variable> <system path> )
#
# Example:
#   BRAINVISA_SYSTEM_PATH_TO_LIST( PATH "$ENV{PATH}" )
#   foreach( p ${PATH} )
#     message( ${p} )
#   endforeach( p ${PATH} )
function( BRAINVISA_SYSTEM_PATH_TO_LIST  result_variable_name system_path )
  if( NOT WIN32 )
    string( REPLACE ":" ";" system_path "${system_path}" )
  endif( NOT WIN32 )
  set( ${result_variable_name} "${system_path}" PARENT_SCOPE )
endfunction( BRAINVISA_SYSTEM_PATH_TO_LIST  result_variable_name system_path )


# This code is a safeguard: libraries that are dynamically mounted by
# Singularity should never be used by the linker, see
# https://github.com/brainvisa/casa-distro/issues/113
if(NOT CMAKE_IGNORE_PATH IN_LIST "/.singularity.d/libs")
  list(APPEND CMAKE_IGNORE_PATH "/.singularity.d/libs")
endif()
BRAINVISA_SYSTEM_PATH_TO_LIST( ld_library_path_list "$ENV{LD_LIBRARY_PATH}" )
if("/.singularity.d/libs" IN_LIST ld_library_path_list)
  file(GLOB _lib_list "/.singularity.d/libs/*")
  list(LENGTH _lib_list _lib_list_len)
  if(NOT _lib_list_len EQUAL 0)
    message(FATAL_ERROR "The LD_LIBRARY_PATH environment variable contains \
'/.singularity.d/libs', which probably  means that you are running \
 bv_maker/cmake from within Singularity with binding of the NVidia \
drivers (probably). This has been found to result in broken builds, see \
<https://github.com/brainvisa/casa-distro/issues/113>.\

Please remember to always run configuration and compilation work \
(bv_maker, cmake, or make) without the NVidia driver binding, by \
starting your container:\

  - either with 'bv bv_maker',
  - or, by passing the 'opengl=container' option to 'casa_distro run'.
")
  endif()
  unset(_lib_list)
  unset(_lib_list_len)
endif()
unset(ld_library_path_list)


#
# BRAINVISA_TARGET_SYSTEM_COMMAND
#   Get a usable command to run on the target system (mainly for cross 
#   compilation).
#
# Usage:
#  BRAINVISA_TARGET_SYSTEM_COMMAND( <output variable> <command> [<arg1> ... <argn>] )
#
# Example:
#   BRAINVISA_TARGET_SYSTEM_COMMAND( TARGET_COMMAND "program.exe" "--help" )
#   message( ${p} )
function(BRAINVISA_TARGET_SYSTEM_COMMAND variable)
  set(__command "${ARGN}")
  if(CMAKE_CROSSCOMPILING)
    if(WIN32)
      find_package(Wine)
      if(WINE_FOUND)
        set(__command "${WINE_RUNTIME}" ${__command})
      else()
        message(SEND_ERROR "Unable to build command for target system wine, because wine was not found")
      endif()
    endif()
  endif()
  message("===== TARGET COMMAND: ${__command}")
  set(${variable} ${__command} PARENT_SCOPE)
  unset(__command)
endfunction()

macro( BRAINVISA_FIND_PACKAGE component )
  if( ${component}_IS_BEING_COMPILED AND NOT ${component}_BINARY_DIR )
    set( args "${ARGN}" )
    list( REMOVE_ITEM args REQUIRED ) # We do not want CMake to display an error and stop here
    list( REMOVE_ITEM args QUIET ) # Avoid to use QUIET twice
    find_package( "${component}" ${args} QUIET )
    if( NOT ${component}_FOUND )
      if( NOT BRAINVISA_FIND_FAILED_${component} )
        set( BRAINVISA_FIND_FAILED_${component} TRUE CACHE INTERNAL "" )
        message( SEND_ERROR "BrainVISA component ${component} has to be configured before it can be imported by ${BRAINVISA_PACKAGE_NAME}. Configure one more time to get rid of this error." )
      endif()
    endif()
  else()
    find_package( "${component}" ${ARGN} )
  endif()
endmacro()

function(BRAINVISA_TEMPORARY_FILE_NAME variable)
  set(_base "/tmp/bv_maker_")
  set(_counter 0)
  while(EXISTS "${_base}${_counter}")
    math(EXPR _counter "${_counter} + 1")
  endwhile(EXISTS "${_base}${_counter}")
  set(${variable} "${_base}${_counter}" PARENT_SCOPE)
endfunction()


function(BRAINVISA_READ_PROJECT_INFO directory)
    # Check pyproject.toml in priority
    foreach(glob "${directory}/pyproject.toml" "${directory}/*/pyproject.toml" "${directory}/python/*/pyproject.toml")
      file(GLOB pyproject "${glob}")
      break()
    endforeach()

    if(pyproject)
      if( PYTHON_EXECUTABLE )
          set( py_exe "${PYTHON_EXECUTABLE}" )
      else()
          set( py_exe "python" )
      endif()
      execute_process( COMMAND "${py_exe}" "-c" "from brainvisa_cmake.brainvisa_projects import project_info_to_cmake; print(project_info_to_cmake('${directory}'))" OUTPUT_VARIABLE variables_to_set ERROR_VARIABLE error )
      if(error)
          message(FATAL_ERROR "${error}")
      endif()
      while(variables_to_set)
        list(POP_FRONT variables_to_set name value)
        set(${name} "${value}" PARENT_SCOPE)
      endwhile()
    else()
      if(EXISTS "${directory}/project_info.cmake")
        set( _project_info_cmake "${directory}/project_info.cmake")
      elseif(EXISTS "${directory}/cmake/project_info.cmake")
        set( _project_info_cmake "${directory}/cmake/project_info.cmake")
      endif()
      if (DEFINED _project_info_cmake)
          include("${_project_info_cmake}")
          set(BRAINVISA_PACKAGE_NAME ${BRAINVISA_PACKAGE_NAME} PARENT_SCOPE)
          set(BRAINVISA_PACKAGE_MAIN_PROJECT ${BRAINVISA_PACKAGE_MAIN_PROJECT} PARENT_SCOPE)
          set(BRAINVISA_PACKAGE_VERSION_MAJOR ${BRAINVISA_PACKAGE_VERSION_MAJOR} PARENT_SCOPE)
          set(BRAINVISA_PACKAGE_VERSION_MINOR ${BRAINVISA_PACKAGE_VERSION_MINOR} PARENT_SCOPE)
          set(BRAINVISA_PACKAGE_VERSION_PATCH ${BRAINVISA_PACKAGE_VERSION_PATCH} PARENT_SCOPE)
          set(BRAINVISA_PACKAGE_MAINTAINER ${BRAINVISA_PACKAGE_MAINTAINER} PARENT_SCOPE)
          set(BRAINVISA_PACKAGE_LICENCES ${BRAINVISA_PACKAGE_LICENCES} PARENT_SCOPE)
      else()
          file(GLOB infos1 "${directory}/info.py")
          file(GLOB infos2 "${directory}/*/info.py")
          file(GLOB infos3 "${directory}/python/*/info.py")
          set(infos ${infos1} ${infos2} ${infos3})
          list(GET infos 0 info)
          file(TO_CMAKE_PATH "${info}" info)
          BRAINVISA_TEMPORARY_FILE_NAME(script)
          set(script "${script}.py")
          file(WRITE  "${script}"
      "from __future__ import print_function
import sys, os
if sys.version_info[0] >= 3:
    def execfile(filename, globals=globals(), locals=locals()):
        with open(filename) as f:
            file_contents = f.read()
        exec(compile(file_contents, filename, 'exec'), globals, locals)
info=os.path.normpath('${info}')
execfile(info)
cmake = os.path.join(os.path.normpath('${CMAKE_BINARY_DIR}'),'build_files',NAME,'project_info.cmake')
if not os.path.exists(cmake) or os.stat(cmake).st_mtime < os.stat(info).st_mtime:
    if 'PROJECT' not in dir():
        PROJECT = NAME # use same name for component and project
    f = open(cmake,'w')
    try:
        # check mandatory variables definitions in info.py
        for name in ('NAME', 'version_major', 'version_minor', 'version_micro', 'LICENSE'):
            if name not in locals():
                raise RuntimeError('No value found for %s. This variable should be defined in %s' % (name, info))
        print('set(BRAINVISA_PACKAGE_NAME \"%s\" PARENT_SCOPE)' % NAME, file=f)
        print('set(BRAINVISA_PACKAGE_MAIN_PROJECT \"%s\" PARENT_SCOPE)' % PROJECT, file=f)
        print('set(BRAINVISA_PACKAGE_VERSION_MAJOR %d PARENT_SCOPE)' % version_major, file=f)
        print('set(BRAINVISA_PACKAGE_VERSION_MINOR %d PARENT_SCOPE)' % version_minor, file=f)
        print('set(BRAINVISA_PACKAGE_VERSION_PATCH %d PARENT_SCOPE)' % version_micro, file=f)
        if 'MAINTAINER' in locals():
            print('set(BRAINVISA_PACKAGE_MAINTAINER \"%s\" PARENT_SCOPE)' % MAINTAINER, file=f)
        print('set(BRAINVISA_PACKAGE_LICENCES \"%s\" PARENT_SCOPE)' % LICENSE, file=f)
    except:
        os.remove(cmake)
        raise
    finally:
        f.close()
sys.stdout.write(cmake)
")
          if( PYTHON_HOST_EXECUTABLE )
              set( py_exe "${PYTHON_HOST_EXECUTABLE}" )
          else()
              # PYTHON_HOST_EXECUTABLE may not be defined yet.
              if( PYTHON_EXECUTABLE )
                  set( py_exe "${PYTHON_EXECUTABLE}" )
              else()
                  set( py_exe "python" )
              endif()
          endif()
          execute_process( COMMAND "${py_exe}" "${script}" OUTPUT_VARIABLE cmake ERROR_VARIABLE error )
          if(error)
              message(FATAL_ERROR "${error}")
          endif()
          if(EXISTS "${cmake}")
              include("${cmake}")
          endif()
          file(REMOVE "${script}")
      endif()
    endif()
endfunction()


function( BRAINVISA_FIND_COMPONENT_DIRECTORIES variable project_directory )
    set( result )
    file( GLOB_RECURSE projects_info "${path}/${project}/project_info.cmake" )
    foreach( project_info ${projects_info} )
        get_filename_component( component_dir "${info}" PATH )
        list(APPEND result "${component_dir}")
    endforeach()
    file( GLOB_RECURSE projects_info "${path}/${project}/info.py" )
    foreach( project_info ${projects_info} )
        get_filename_component( component_dir "${info}" PATH )
        get_filename_component( component_dir "${component_dir}" PATH )
        list(FIND result "${component_dir}" index)
        if(index EQUAL -1)
          list(APPEND result "${component_dir}")
        endif()
    endforeach()
    set(${variable} ${result} PARENT_SCOPE)
endfunction()

macro( BRAINVISA_PROJECT )
  if( BRAINVISA_REAL_SOURCE_DIR )
    BRAINVISA_READ_PROJECT_INFO( "${BRAINVISA_REAL_SOURCE_DIR}" )
  else()
    BRAINVISA_READ_PROJECT_INFO( "${CMAKE_CURRENT_SOURCE_DIR}" )
  endif()
  if( NOT DEFINED BRAINVISA_PACKAGE_VERSION )
    set( BRAINVISA_PACKAGE_VERSION "${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}.${BRAINVISA_PACKAGE_VERSION_PATCH}" )
  endif()

  project( ${BRAINVISA_PACKAGE_NAME} ${ARGN} )

  set( ${PROJECT_NAME}_VERSION_MAJOR ${BRAINVISA_PACKAGE_VERSION_MAJOR} )
  set( ${PROJECT_NAME}_VERSION_MINOR ${BRAINVISA_PACKAGE_VERSION_MINOR} )
  set( ${PROJECT_NAME}_VERSION_PATCH ${BRAINVISA_PACKAGE_VERSION_PATCH} )
  set( ${PROJECT_NAME}_VERSION "${BRAINVISA_PACKAGE_VERSION}" )
  if( DEFINED BRAINVISA_BVMAKER )
    set( ${PROJECT_NAME}_VERSION_MAJOR ${BRAINVISA_PACKAGE_VERSION_MAJOR} PARENT_SCOPE )
    set( ${PROJECT_NAME}_VERSION_MINOR ${BRAINVISA_PACKAGE_VERSION_MINOR} PARENT_SCOPE )
    set( ${PROJECT_NAME}_VERSION_PATCH ${BRAINVISA_PACKAGE_VERSION_PATCH} PARENT_SCOPE )
    set( ${PROJECT_NAME}_VERSION "${BRAINVISA_PACKAGE_VERSION}" PARENT_SCOPE )
  endif()

  set( _licences )
  foreach( _licence ${BRAINVISA_PACKAGE_LICENCES} )
    if( _licences )
      set( _licences "${_licences}, \"${_licence}\"" )
    else()
      set( _licences "\"${_licence}\"" )
    endif()
  endforeach()
  set( _run_install "False" )
  set( _dev_install "False" )
  set( _usrdoc_install "False" )
  set( _devdoc_install "False" )
  set( _doc_install "False" )
  set( _test_install "False" )
  foreach( _inst ${BRAINVISA_PACKAGE_DEFAULT_INSTALL} )
    if( "${_inst}" STREQUAL "run" )
      set( _run_install "True" )
    elseif( "${_inst}" STREQUAL "dev" )
      set( _dev_install "True" )
    elseif( "${_inst}" STREQUAL "usrdoc" )
      set( _usrdoc_install "True" )
    elseif( "${_inst}" STREQUAL "devdoc" )
      set( _devdoc_install "True" )
    elseif( "${_inst}" STREQUAL "doc" )
      set( _doc_install "True" )
    elseif( "${_inst}" STREQUAL "test" )
      set( _test_install "True" )
    endif()
  endforeach()

  file( APPEND "${BRAINVISA_COMPILATION_INFO}" "packages_info[ '${PROJECT_NAME}' ] = {\n  'name': '${PROJECT_NAME}',\n  'component' : '${PROJECT_NAME}',\n  'type': 'run',\n  'version': '${BRAINVISA_PACKAGE_VERSION}',\n  'project': '${BRAINVISA_PACKAGE_MAIN_PROJECT}',\n  'maintainer': '${BRAINVISA_PACKAGE_MAINTAINER}',\n  'licences': [${_licences}],\n  'default_install': ${_run_install},\n}\n" )
  file( APPEND "${BRAINVISA_COMPILATION_INFO}" "packages_info[ '${PROJECT_NAME}-dev' ] = {\n  'name': '${PROJECT_NAME}-dev',\n  'component' : '${PROJECT_NAME}-dev',\n  'type': 'dev',\n  'version': '${BRAINVISA_PACKAGE_VERSION}',\n  'project': '${BRAINVISA_PACKAGE_MAIN_PROJECT}',\n  'maintainer': '${BRAINVISA_PACKAGE_MAINTAINER}',\n  'licences': [${_licences}],\n  'default_install': ${_dev_install},\n}\n" )
  file( APPEND "${BRAINVISA_COMPILATION_INFO}" "packages_info[ '${PROJECT_NAME}-doc' ] = {\n  'name': '${PROJECT_NAME}-doc',\n  'component' : '${PROJECT_NAME}-doc',\n  'type': 'doc',\n  'version': '${BRAINVISA_PACKAGE_VERSION}',\n  'project': '${BRAINVISA_PACKAGE_MAIN_PROJECT}',\n  'maintainer': '${BRAINVISA_PACKAGE_MAINTAINER}',\n  'licences': [${_licences}],\n  'default_install': ${_doc_install},\n}\n" )
  file( APPEND "${BRAINVISA_COMPILATION_INFO}" "packages_info[ '${PROJECT_NAME}-usrdoc' ] = {\n  'name': '${PROJECT_NAME}-usrdoc',\n  'component' : '${PROJECT_NAME}-usrdoc',\n  'type': 'usrdoc',\n  'version': '${BRAINVISA_PACKAGE_VERSION}',\n  'project': '${BRAINVISA_PACKAGE_MAIN_PROJECT}',\n  'maintainer': '${BRAINVISA_PACKAGE_MAINTAINER}',\n  'licences': [${_licences}],\n  'default_install': ${_usrdoc_install},\n}\n" )
  file( APPEND "${BRAINVISA_COMPILATION_INFO}" "packages_info[ '${PROJECT_NAME}-devdoc' ] = {\n  'name': '${PROJECT_NAME}-devdoc',\n  'component' : '${PROJECT_NAME}-devdoc',\n  'type': 'devdoc',\n  'version': '${BRAINVISA_PACKAGE_VERSION}',\n  'project': '${BRAINVISA_PACKAGE_MAIN_PROJECT}',\n  'maintainer': '${BRAINVISA_PACKAGE_MAINTAINER}',\n  'licences': [${_licences}],\n  'default_install': ${_devdoc_install},\n}\n" )
  file( APPEND "${BRAINVISA_COMPILATION_INFO}" "packages_info[ '${PROJECT_NAME}-test' ] = {\n  'name': '${PROJECT_NAME}-test',\n  'component' : '${PROJECT_NAME}-test',\n  'type': 'test',\n  'version': '${BRAINVISA_PACKAGE_VERSION}',\n  'project': '${BRAINVISA_PACKAGE_MAIN_PROJECT}',\n  'maintainer': '${BRAINVISA_PACKAGE_MAINTAINER}',\n  'licences': [${_licences}],\n  'default_install': ${_test_install},\n}\n" )

  if(NOT CPack_CMake_INCLUDED)
    include( CPack )
  endif()

  set( ${PROJECT_NAME}_TARGET_COUNT 0 CACHE INTERNAL "Used to generate new targets" )
  set( ${PROJECT_NAME}-commands "" CACHE INTERNAL "Commands list for component ${PROJECT_NAME}" )
  BRAINVISA_CREATE_MAIN_COMPONENTS()

  set( CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" )
  if ( WIN32 )
    # This is necessary for modules to be copied in bin directory
    set( CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" )
  else()
    set( CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib" )
  endif()

  # Initialize dependency variables
  if( "${BRAINVISA_PACKAGE_TYPE}" STREQUAL "deb" )
    foreach( pack_type RUN DEV STR DOC )
      foreach( dependency_type DEPENDS RECOMMENDS SUGGESTS ENHANCES )
        unset( ${BRAINVISA_PACKAGE_NAME}_DEB_${pack_type}_${dependency_type} CACHE )
      endforeach()
    endforeach()
  endif()
endmacro()


function( BRAINVISA_CREATE_MAIN_COMPONENTS )
  if( NOT BRAINVISA_MAIN_COMPONENTS_CREATED )
    set( BRAINVISA_MAIN_COMPONENTS_CREATED true PARENT_SCOPE )
    BRAINVISA_ADD_COMPONENT_GROUP( runtime
                                   DISPLAY_NAME "Runtime"
                                   DESCRIPTION "All elements necessary to use ${PROJECT_NAME} at runtime without developpement files such as C++ headers." )
    BRAINVISA_ADD_COMPONENT_GROUP( dev
                                   DISPLAY_NAME "Developpement"
                                   DESCRIPTION "All elements necessary to compile libraries and programs that uses ${PROJECT_NAME} (such as C++ headers)." )
    BRAINVISA_ADD_COMPONENT_GROUP( doc
                                   DISPLAY_NAME "Documentation"
                                   DESCRIPTION "All documentations: development and user." )
    BRAINVISA_ADD_COMPONENT_GROUP( usrdoc
                                   DISPLAY_NAME "User Documentation"
                                   DESCRIPTION "User documentation: manual, tutorial." )
    BRAINVISA_ADD_COMPONENT_GROUP( devdoc
                                   DISPLAY_NAME "Development Documentation"
                                   DESCRIPTION "Development documentations: doxygen, epydoc, sphinx." )
    BRAINVISA_ADD_COMPONENT_GROUP( test
                                   DISPLAY_NAME "Test files"
                                   DESCRIPTION "Test programs, scripts, and data files" )

    add_dependencies( install-dev install-runtime )

    # target to run the tests in generation mode
    add_custom_target (testref)

    # targets to generate documentation
    add_custom_target( doc )
    add_custom_target( usrdoc )
    add_custom_target( devdoc )
    add_dependencies( doc usrdoc devdoc )
    add_dependencies( install-doc install-usrdoc install-devdoc )
    # add_dependencies( install-usrdoc usrdoc )
    # add_dependencies( install-devdoc devdoc )

    # targets to install the tests
    if( NOT TARGET install-test )
      add_custom_target( install-test )
    endif()
    add_dependencies( install-test install-runtime )

    # target to install without doc
    add_custom_target( install-nodoc )
    add_dependencies( install-nodoc install-runtime install-dev )

  endif( NOT BRAINVISA_MAIN_COMPONENTS_CREATED )

  BRAINVISA_ADD_COMPONENT( ${PROJECT_NAME}
                           GROUP runtime
                           DESCRIPTION "runtime files for ${PROJECT_NAME}" )

  BRAINVISA_ADD_COMPONENT( ${PROJECT_NAME}-dev
                           GROUP dev
                           DESCRIPTION "Developpement files for ${PROJECT_NAME}"
                           DEPENDS ${PROJECT_NAME} )
  BRAINVISA_ADD_COMPONENT( ${PROJECT_NAME}-doc
                           GROUP doc
                           DESCRIPTION "Documentation of ${PROJECT_NAME}" )
  BRAINVISA_ADD_COMPONENT( ${PROJECT_NAME}-usrdoc
                           GROUP usrdoc
                           DESCRIPTION "User Documentation of ${PROJECT_NAME}" )
  BRAINVISA_ADD_COMPONENT( ${PROJECT_NAME}-devdoc
                           GROUP devdoc
                           DESCRIPTION "Development Documentation of ${PROJECT_NAME}" )
  BRAINVISA_ADD_COMPONENT( ${PROJECT_NAME}-test
                           GROUP test
                           DESCRIPTION "Test files for ${PROJECT_NAME}" )

  # targets to generate the documentation of the project
  add_custom_target( ${PROJECT_NAME}-doc )
  add_dependencies( doc ${PROJECT_NAME}-doc )
  add_custom_target( ${PROJECT_NAME}-usrdoc
     COMMENT "Create \"share/doc/${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}\""
     COMMAND ${CMAKE_COMMAND} -E make_directory "${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}"
  )
  add_dependencies( usrdoc ${PROJECT_NAME}-usrdoc )
#   add_custom_target( ${PROJECT_NAME}-cmddoc )
#   add_dependencies( cmddoc ${PROJECT_NAME}-cmddoc )
  add_custom_target( ${PROJECT_NAME}-devdoc
     COMMENT "Create \"share/doc/${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}\""
     COMMAND ${CMAKE_COMMAND} -E make_directory "${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}"
  )
  add_dependencies( devdoc ${PROJECT_NAME}-devdoc )
#  add_dependencies( ${PROJECT_NAME}-doc ${PROJECT_NAME}-usrdoc ${PROJECT_NAME}-cmddoc  ${PROJECT_NAME}-devdoc)
  add_dependencies( ${PROJECT_NAME}-doc ${PROJECT_NAME}-usrdoc ${PROJECT_NAME}-devdoc)
  if( NOT TARGET install-${PROJECT_NAME}-doc )
    add_custom_target( install-${PROJECT_NAME}-doc )
  endif()
  if( NOT TARGET install-${PROJECT_NAME}-usrdoc )
    add_custom_target( install-${PROJECT_NAME}-usrdoc )
  endif()
  if( NOT TARGET install-${PROJECT_NAME}-devdoc )
    add_custom_target( install-${PROJECT_NAME}-devdoc )
  endif()
  add_dependencies( install-${PROJECT_NAME}-doc install-${PROJECT_NAME}-usrdoc install-${PROJECT_NAME}-devdoc )
  if( NOT TARGET install-${PROJECT_NAME}-test )
    add_custom_target( install-${PROJECT_NAME}-test )
  endif()
#  add_dependencies( install-${PROJECT_NAME}-usrdoc ${PROJECT_NAME}-usrdoc )
#  add_dependencies( install-${PROJECT_NAME}-devdoc ${PROJECT_NAME}-devdoc )

endfunction()


# BRAINVISA_DEPENDENCY
# Usage:
#   BRAINVISA_DEPENDENCY( <package type> <dependency type> <component> <component package type> [ <version ranges> ] [BINARY_INDEPENDENT] )
#
# Examples:
#   BRAINVISA_DEPENDENCY( RUN DEPENDS libblitz RUN "2.0.3-4" )
#   BRAINVISA_DEPENDENCY( DEV DEPENDS libblitz DEV ">= 2.0" )
#   BRAINVISA_DEPENDENCY( RUN RECOMMENDS dcmtk RUN "3.1.2" )
#   BRAINVISA_DEPENDENCY( DEV RECOMMENDS dcmtk DEV )
#   BRAINVISA_DEPENDENCY( RUN DEPENDS soma-io RUN "3.2.4-20100908" )
#   BRAINVISA_DEPENDENCY( DEV DEPENDS soma-io DEV ">= 3.2.0;<< 3.3.0" )
#   BRAINVISA_DEPENDENCY( RUN DEPENDS soma-base RUN ">= 3.2.0;<< 3.3.0" BINARY_INDEPENDENT )
#   BRAINVISA_DEPENDENCY( DEV DEPENDS soma-base DEV ">= 3.2.0;<< 3.3.0" )
#
function( BRAINVISA_DEPENDENCY pack_type dependency_type component component_pack_type  )
  # Parse optional arguments
  if( "${ARGV4}" STREQUAL "BINARY_INDEPENDENT" )
    set( binary_independent "True" )
    set( version_ranges )
  else()
    if( ARGV4 )
      if( "${ARGV5}" STREQUAL "BINARY_INDEPENDENT" )
        set( binary_independent True )
      else()
        set( binary_independent False )
      endif()
      set( version_ranges "${ARGV4}" )
    else()
      set( binary_independent False )
      set( version_ranges )
    endif()
  endif()

  # Check if component is external or not
  list( FIND BRAINVISA_COMPONENTS "${component}" is_brainvisa )
  if( NOT is_brainvisa EQUAL -1 )
    if( "${component_pack_type}" STREQUAL "DEV" )
      set( dest_package "${component}-dev" )
    elseif( "${component_pack_type}" STREQUAL "DOC" )
      set( dest_package "${component}-doc" )
    elseif( "${component_pack_type}" STREQUAL "TST" )
      set( dest_package "${component}-test" )
    else()
      set( dest_package "${component}" )
    endif()
  endif()
  if( BRAINVISA_COMPILATION_INFO )
    if( "${pack_type}" STREQUAL "DEV" )
      set( source_package "${PROJECT_NAME}-dev" )
    elseif( "${pack_type}" STREQUAL "DOC" )
      set( source_package "${PROJECT_NAME}-doc" )
    elseif( "${pack_type}" STREQUAL "USRDOC" )
      set( source_package "${PROJECT_NAME}-usrdoc" )
    elseif( "${pack_type}" STREQUAL "DEVDOC" )
      set( source_package "${PROJECT_NAME}-devdoc" )
    elseif( "${pack_type}" STREQUAL "TST" )
      set( source_package "${PROJECT_NAME}-test" )
    else()
      set( source_package "${PROJECT_NAME}" )
    endif()
    file( APPEND "${BRAINVISA_COMPILATION_INFO}" "packages_dependencies.setdefault( '${source_package}', set() ).add( ( '${dependency_type}', '${dest_package}', '${version_ranges}', ${binary_independent}) )\n" )
  else()
    # Component is not in BRAINVISA_COMPONENTS, it is considered as a third
    # party component. Since BrainVISA 5.0 we do not support packaging
    # third-party components anymore, so this dependency will simply be ignored
  endif()
endfunction()




# BRAINVISA_VERSION_CONVERT
#   Convert version number either to hexadecimal version
#   either to string version.
#
# Usage:
#   BRAINVISA_VERSION_CONVERT( <variable> version [HEX] [STR] [BYTES <number_of_bytes>] )
#
# Example:
#   BRAINVISA_VERSION_CONVERT( result "0x30206" STR )
#   BRAINVISA_VERSION_CONVERT( result "3.2.6" HEX BYTES 2 )
#
function( BRAINVISA_VERSION_CONVERT variable version )
  include(UseVersionConvert) 
  VERSION_CONVERT(${variable} ${version} ${ARGN})
endfunction()

# BRAINVISA_SET_PROJECT_VERSION
#   Read the VERSION file in "${PROJECT_SOURCE_DIR} and parse it to set the
#   following variables:
#     ${PROJECT_NAME}_VERSION = full version string (i.e. VERSION file content)
#     ${PROJECT_NAME}_VERSION_MAJOR = major version number (i.e. first number)
#     ${PROJECT_NAME}_VERSION_MINOR = minor version number (i.e. second number)
#     ${PROJECT_NAME}_VERSION_PATCH = patch version number (if any)
#   The following variables are also set with the same values as above:
#     BRAINVISA_CURRENT_PROJECT_VERSION
#     BRAINVISA_CURRENT_PROJECT_VERSION_MAJOR
#     BRAINVISA_CURRENT_PROJECT_VERSION_MINOR
#     BRAINVISA_CURRENT_PROJECT_VERSION_PATCH
#
# Usage:
#   BRAINVISA_SET_PROJECT_VERSION()
MACRO( BRAINVISA_SET_PROJECT_VERSION )
  SET( _versionVar ${PROJECT_NAME}_VERSION )
  IF( NOT DEFINED ${_versionVar} )
    FILE( READ "${PROJECT_SOURCE_DIR}/VERSION" _version )
    STRING( REGEX REPLACE "([^\n]*)\n" "\\1" _version "${_version}")
    STRING( REGEX REPLACE "([^.]+)\\.([^.]+)(\\.(.*))?" "\\1" _version_major "${_version}")
    STRING( REGEX REPLACE "([^.]+)\\.([^.]+)(\\.(.*))?" "\\2" _version_minor "${_version}")
    STRING( REGEX REPLACE "([^.]+)\\.([^.]+)\\.?(.*)" "\\3" _version_patch "${_version}")

    SET( ${_versionVar} ${_version} )
    SET( ${_versionVar}_MAJOR ${_version_major} )
    SET( ${_versionVar}_MINOR ${_version_minor} )
    SET( ${_versionVar}_PATCH ${_version_patch} )

    SET( BRAINVISA_CURRENT_PROJECT_VERSION  ${${_versionVar}} )
    SET( BRAINVISA_CURRENT_PROJECT_VERSION_MAJOR ${${_versionVar}_MAJOR} )
    SET( BRAINVISA_CURRENT_PROJECT_VERSION_MINOR ${${_versionVar}_MINOR} )
    SET( BRAINVISA_CURRENT_PROJECT_VERSION_PATCH ${${_versionVar}_PATCH} )
  ENDIF( NOT DEFINED ${_versionVar} )
ENDMACRO( BRAINVISA_SET_PROJECT_VERSION )


function( BRAINVISA_GENERATE_TARGET_NAME _variableName )
  if( DEFINED ${PROJECT_NAME}_TARGET_COUNT )
    math( EXPR ${PROJECT_NAME}_TARGET_COUNT ${${PROJECT_NAME}_TARGET_COUNT}+1 )
    set( ${PROJECT_NAME}_TARGET_COUNT ${${PROJECT_NAME}_TARGET_COUNT} CACHE INTERNAL "Used to generate new targets" )
  else( DEFINED ${PROJECT_NAME}_TARGET_COUNT )
    set( ${PROJECT_NAME}_TARGET_COUNT 1 CACHE INTERNAL "Used to generate new targets" )
  endif( DEFINED ${PROJECT_NAME}_TARGET_COUNT )
  set( ${_variableName} ${PROJECT_NAME}_target_${${PROJECT_NAME}_TARGET_COUNT} PARENT_SCOPE )
endfunction( BRAINVISA_GENERATE_TARGET_NAME )


# BRAINVISA_GET_FILE_LIST_FROM_PRO
#   Retrieve one (or more) list of file names from an *.pro file. This macro
#   exists for backward compatibility with build-config.
#
# Usage:
#   BRAINVISA_GET_FILE_LIST_FROM_PRO( <pro file name> <pro variable> <cmake variable> [<pro variable> <cmake variable>...] )
#
# Example:
#   BRAINVISA_GET_FILE_LIST_FROM_PRO(  ${CMAKE_CURRENT_SOURCE_DIR}/libvip.pro "HEADERS" _h "SOURCES" _s )
#
MACRO( BRAINVISA_GET_FILE_LIST_FROM_PRO _proFilename)
  file(READ "${_proFilename}" _var)
  # remove lines starting with '#'
  string(REGEX REPLACE "#[^\n]*\n" "" _var "${_var}")
  string(REGEX REPLACE "[ \t]*\\\\ *\n[ \t]*" " " _var "${_var}")

  SET( _args ${ARGN})
  LIST( LENGTH _args _i )
  WHILE( ${_i} GREATER 0 )
    LIST( GET _args 0 _proVariable )
    LIST( GET _args 1 _cmakeVariable )
    LIST( REMOVE_AT _args 0 1 )
    STRING( REGEX REPLACE "(.*\n)?${_proVariable}[ \t]*\\+?=[ \t]*([^\n]*)\n.*" "\\2" ${_cmakeVariable} "${_var}" )
    SEPARATE_ARGUMENTS( ${_cmakeVariable} )
#     MESSAGE( "${_proVariable} : ${${_cmakeVariable}}" )
    LIST( LENGTH _args _i )
  ENDWHILE( ${_i} GREATER 0 )
ENDMACRO( BRAINVISA_GET_FILE_LIST_FROM_PRO )


# BRAINVISA_COPY_AND_INSTALL_HEADERS
#
# Usage:
#   BRAINVISA_COPY_AND_INSTALL_HEADERS( <headers list> <include directory> <install component> [NO_SYMLINKS] )
#
# Example:
#
function( BRAINVISA_COPY_AND_INSTALL_HEADERS _headersVariable _includeDir targetVariable )
  if( "${ARGV3}" STREQUAL "NO_SYMLINKS" )
    set( symlinks FALSE )
  else()
    set( symlinks TRUE )
  endif()

  set( destHeaders )
  foreach( _currentHeader ${${_headersVariable}} )
    set( _destFile "${CMAKE_BINARY_DIR}/include/${_includeDir}/${_currentHeader}" )
    if( symlinks AND ( UNIX OR APPLE OR CMAKE_CROSSCOMPILING) )
      # Make a symlink instead of copying Python source allows to
      # execute code from the build tree and directly benefit from
      # modifications in the source tree (without typing make)
      get_filename_component( _path "${_destFile}" PATH )
      file( RELATIVE_PATH _relsource ${_path}
            "${CMAKE_CURRENT_SOURCE_DIR}/${_currentHeader}" )
      add_custom_command(
        OUTPUT "${_destFile}"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${_currentHeader}"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${_path}"
        COMMAND "${CMAKE_COMMAND}" -E create_symlink "${_relsource}" "${_destFile}" )
    else()
      add_custom_command(
        OUTPUT "${_destFile}"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${_currentHeader}"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/${_currentHeader}" "${_destFile}" )
    endif()
    set( destHeaders ${destHeaders}  "${_destFile}" )
    get_filename_component( _path "${_currentHeader}" PATH )
    BRAINVISA_INSTALL( FILES ${_currentHeader}
                       DESTINATION include/${_includeDir}/${_path}
                       COMPONENT ${PROJECT_NAME}-dev )
  endforeach()
  BRAINVISA_GENERATE_TARGET_NAME( target )
  add_custom_target( ${target} ALL
                     DEPENDS ${destHeaders} )
  set( ${targetVariable} "${target}" PARENT_SCOPE )
endfunction()


# BRAINVISA_COPY_FILES
#
# Usage:
#  BRAINVISA_COPY_FILES( <component> <source files> [SOURCE_DIRECTORY <directory>] DESTINATION <destination directory>  [IMMEDIATE] [GET_TARGET <target variable>] [TARGET <target name>] [GET_OUTPUT_FILES <target variable>] [NO_SYMLINKS] [FATAL <bool>] )
#
# FATAL has been added in brainvisa-cmake 5.1.2 and is true by default.
#
function( BRAINVISA_COPY_FILES component )
  set( _files "${ARGN}" )

  # Read GET_OUTPUT_FILES option
  list( FIND _files GET_OUTPUT_FILES result )
  if( result EQUAL -1 )
    set( outputVariable )
  else()
    list( REMOVE_AT _files ${result} )
    list( GET _files ${result} outputVariable )
    list( REMOVE_AT _files ${result} )
  endif()

  # Read GET_TARGET option
  list( FIND _files GET_TARGET result )
  if( result EQUAL -1 )

    # Read TARGET option
    list( FIND _files TARGET result )
    if( result EQUAL -1 )
      set( targetName )
    else()
      list( REMOVE_AT _files ${result} )
      list( GET _files ${result} targetName )
      list( REMOVE_AT _files ${result} )
    endif()

    set( targetVariable )
  else()
    list( REMOVE_AT _files ${result} )
    list( GET _files ${result} targetVariable )
    list( REMOVE_AT _files ${result} )
  endif()

  # Read DESTINATION option
  list( FIND _files DESTINATION result )
  if( result EQUAL -1 )
    message( FATAL_ERROR "DESTINATION argument is mandatory for BRAINVISA_COPY_FILES" )
  else()
    list( REMOVE_AT _files ${result} )
    list( GET _files ${result} _destination )
    list( REMOVE_AT _files ${result} )
  endif()

  # Read SOURCE_DIRECTORY option
  list( FIND _files SOURCE_DIRECTORY result )
  if( result EQUAL -1 )
    set( _sourceDirectory )
  else()
    list( REMOVE_AT _files ${result} )
    list( GET _files ${result} _sourceDirectory )
    list( REMOVE_AT _files ${result} )
  endif()

  # Read IMMEDIATE option
  list( FIND _files IMMEDIATE result )
  if( result EQUAL -1 )
    set( immediate FALSE )
  else()
    set( immediate TRUE )
    list( REMOVE_AT _files ${result} )
  endif()

  # Read NO_SYMLINKS option
  list( FIND _files NO_SYMLINKS result )
  if( result EQUAL -1 )
    set( symlinks TRUE )
  else()
    set( symlinks FALSE )
    list( REMOVE_AT _files ${result} )
  endif()

  # Read FATAL option
  list( FIND _files FATAL result )
  if( result EQUAL -1 )
    set( fatal 1 )
  else()
    list( REMOVE_AT _files ${result} )
    list( GET _files ${result} fatal )
    list( REMOVE_AT _files ${result} )
  endif()

#     message( "=== copy: from ${_sourceDirectory} to ${_destination} : ${_files}" )
  # Create a custom target for the files installation. The install-component target depends on this custom target
  BRAINVISA_GENERATE_TARGET_NAME( installTarget )

  add_custom_target( ${installTarget} )
  add_dependencies( install-${component} ${installTarget} )
  set( _allOutputFiles )
  set( _targetDepends  )
  foreach( _file ${_files} )
    if( IS_ABSOLUTE "${_file}" )
      set( _absoluteFile "${_file}"  )
      set( _path )
      get_filename_component( _file "${_file}" NAME )
    elseif( _sourceDirectory )
      set( _absoluteFile "${_sourceDirectory}/${_file}"  )
      get_filename_component( _path "${_file}" PATH )
    else()
      set( _absoluteFile "${CMAKE_CURRENT_SOURCE_DIR}/${_file}"  )
      get_filename_component( _path "${_file}" PATH )
    endif()
    if( EXISTS "${_absoluteFile}" )
      # do not copy a file on itself
      if(NOT "${_absoluteFile}" STREQUAL "${CMAKE_BINARY_DIR}/${_destination}/${_file}" )
        if( immediate )
          configure_file( "${_absoluteFile}"
                          "${CMAKE_BINARY_DIR}/${_destination}/${_file}"
                          COPYONLY )
        else()
          if( symlinks AND ( UNIX OR APPLE OR CMAKE_CROSSCOMPILING) )
            # Make a symlink instead of copying Python source allows to
            # execute code from the build tree and directly benefit from
            # modifications in the source tree (without typing make)
            get_filename_component( _path_file "${_file}" PATH )
            file( RELATIVE_PATH _relsource
                  "${CMAKE_BINARY_DIR}/${_destination}/${_path_file}"
                  "${_absoluteFile}" )
            add_custom_command(
              OUTPUT "${CMAKE_BINARY_DIR}/${_destination}/${_file}"
              COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_BINARY_DIR}/${_destination}/${_path_file}"
              COMMAND "${CMAKE_COMMAND}" -E create_symlink "${_relsource}" "${CMAKE_BINARY_DIR}/${_destination}/${_file}" )
          else()
            add_custom_command(
              OUTPUT "${CMAKE_BINARY_DIR}/${_destination}/${_file}"
              DEPENDS "${_absoluteFile}"
              COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_absoluteFile}" "${CMAKE_BINARY_DIR}/${_destination}/${_file}" )
          endif()
        endif()
      endif()
      if( outputVariable )
        list( APPEND _allOutputFiles  "${CMAKE_BINARY_DIR}/${_destination}/${_file}" )
      endif()

      # resolve file if it is a link, because installation needs the file not 
      # the link
      get_filename_component( _absoluteFile "${_absoluteFile}" REALPATH )
      
      # custom command attached to the custom target created for the files installation
      add_custom_command( TARGET ${installTarget} PRE_BUILD
          COMMAND if [ -n \"$(BRAINVISA_INSTALL_PREFIX)\" ] \; then "${CMAKE_COMMAND}" -E copy "${_absoluteFile}" "$(BRAINVISA_INSTALL_PREFIX)/${_destination}/${_file}" \; else "${CMAKE_COMMAND}" -E copy "${_absoluteFile}" "${CMAKE_INSTALL_PREFIX}/${_destination}/${_file}" \; fi )

      set( _targetDepends ${_targetDepends} "${CMAKE_BINARY_DIR}/${_destination}/${_file}" )
    else()
      if( fatal )
        message( FATAL_ERROR "Error: file \"${_absoluteFile}\" does not exist" )
      else()
        message( "Warning: file \"${_absoluteFile}\" does not exist" )
      endif()
    endif()
  endforeach()

  if (targetName)
    #message("Set target name : ${targetName}")
    set(target ${targetName})
  else()
    BRAINVISA_GENERATE_TARGET_NAME( target )
  endif()

  add_custom_target( ${target} ALL
                     DEPENDS ${_targetDepends} )
  if( targetVariable )
    set( ${targetVariable} "${target}" PARENT_SCOPE )
  endif()
  if( outputVariable )
    set( ${outputVariable} ${_allOutputFiles} PARENT_SCOPE )
  endif()
endfunction()


# BRAINVISA_COPY_DIRECTORY
#  Recursively copy and install all files in <source directory> except files named
#  CMakeLists.txt, *~, */.svn/*, *.od[tp], *.doc, *.s[dx]w.
#
# Usage:
#  BRAINVISA_COPY_DIRECTORY( <source directory> <destination directory> <component> [IMMEDIATE] [GET_TARGET <target variable>] [NO_SYMLINKS] [COPY_DOCS] )
#
#   if COPY_DOCS is used, files with extention *.od[tp], *.doc, *.s[dx]w are copied
#
function( BRAINVISA_COPY_DIRECTORY _directory _destination _component )
  set( _argn "${ARGN}" )

  # Read IMMEDIATE option
  list( FIND _argn IMMEDIATE result )
  if( result EQUAL -1 )
    set( immediate FALSE )
  else()
    set( immediate TRUE )
    list( REMOVE_AT _argn ${result} )
  endif()

  # Read GET_TARGET option
  list( FIND _argn GET_TARGET result )
  if( result EQUAL -1 )
    set( targetVariable )
  else()
    list( REMOVE_AT _argn ${result} )
    list( GET _argn ${result} targetVariable )
    list( REMOVE_AT _argn ${result} )
  endif()

  # Read NO_SYMLINKS option
  list( FIND _argn NO_SYMLINKS result )
  if( result EQUAL -1 )
    set( symlinks TRUE )
  else()
    set( symlinks FALSE )
    list( REMOVE_AT _argn ${result} )
  endif()

  # Read COPY_DOCS option
  list( FIND _argn COPY_DOCS result )
  if( result EQUAL -1 )
    set( copy_docs FALSE )
  else()
    set( copy_docs TRUE )
    list( REMOVE_AT _argn ${result} )
  endif()

  file( GLOB_RECURSE _selectedFiles RELATIVE "${_directory}" "${_directory}/*" )
  set( i 0 )
  list( LENGTH _selectedFiles l )
  while( ${i} LESS ${l} )
    list( GET _selectedFiles ${i} file )
    get_filename_component( f "${file}" NAME )
    if ( copy_docs )
        string( REGEX MATCH "(CMakeLists\\.txt)|(.*~)|(.*#.*)|(.*\\..*swp)$" _match "${file}" )
    else()
        string( REGEX MATCH "(CMakeLists\\.txt)|(.*~)|(.*#.*)|(.*\\.svn/.*)|(.*\\.od[tp])|(.*\\.doc)|(.*\\.s[dx]w)|(.*\\..*swp)$" _match "${file}" )
    endif()
    if( _match )
      list( REMOVE_AT _selectedFiles ${i} )
      math( EXPR l "${l} - 1" )
    else()
      math( EXPR i "${i} + 1" )
    endif()
  endwhile()
  if( NOT symlinks )
    set( _selectedFiles ${_selectedFiles} "NO_SYMLINKS" )
  endif()
  if( immediate )
    BRAINVISA_COPY_FILES( ${_component} ${_selectedFiles} SOURCE_DIRECTORY "${_directory}" DESTINATION "${_destination}" IMMEDIATE GET_TARGET "${targetVariable}" )
  else()
    BRAINVISA_COPY_FILES( ${_component} ${_selectedFiles} SOURCE_DIRECTORY "${_directory}" DESTINATION "${_destination}" GET_TARGET "${targetVariable}" )
  endif()
  if( targetVariable )
    set( ${targetVariable} "${${targetVariable}}" PARENT_SCOPE )
  endif()

endfunction()


# BRAINVISA_COPY_PYTHON_DIRECTORY
#   Create targets to copy, byte compile and install all Python code
#   contained in a directory.
#
# Usage:
#   BRAINVISA_COPY_PYTHON_DIRECTORY( <python directory> <component>
#                                    <destination directory> [NO_SYMLINKS]
#                                    [INSTALL_ONLY] )
#     <python directory>: python directory to copy
#     <component>: name of the component passed to BRAINVISA_INSTALL.
#     <destination directory>: directory where the files will be copied
#         (relative to build directory).
#   BRAINVISA_COPY_PYTHON_DIRECTORY( <python directory> <component> )
#         <destination directory> is set to the right most directory
#             name in <python directory>
#
# Example:
#   BRAINVISA_COPY_PYTHON_DIRECTORY(  ${CMAKE_CURRENT_SOURCE_DIR}/python brainvisa_python )
#
function( BRAINVISA_COPY_PYTHON_DIRECTORY _pythonDirectory _component )
  set( _args "${ARGN}" )
  # Read NO_SYMLINKS option
  list( FIND _args NO_SYMLINKS result )
  if( result EQUAL -1 )
    set( symlinks TRUE )
  else()
    set( symlinks FALSE )
    list( REMOVE_AT _args ${result} )
  endif()
  # Read INSTALL_ONLY option
  list( FIND _args INSTALL_ONLY result )
  if( result EQUAL -1 )
    set( install_only FALSE )
  else()
    set( install_only TRUE )
    list( REMOVE_AT _args ${result} )
  endif()

  list( LENGTH _args _argc )
  if( ${_argc} GREATER 0 )
    list( GET _args 0 _destDir )
  else()
    get_filename_component( _destDir "${_pythonDirectory}" NAME )
  endif()

  # When PYTHON_INSTALL_DIRECTORY is defined and the destination
  # python directory is "*/python" then PYTHON_INSTALL_DIRECTORY
  # is used for destination.
  # This allows to substitute the python directory used in many
  # CMake files. For example, in Conda environment, Python packages
  # should be installed in `lib/python<version>/site-packages
  get_filename_component( _destDirName "${_destDir}" NAME )
  if(("${_destDirName}" STREQUAL "python") AND (DEFINED PYTHON_INSTALL_DIRECTORY) )
    set( _destDir "${PYTHON_INSTALL_DIRECTORY}")
  endif()
  if(("${_destDirName}" STREQUAL "brainvisa") AND (DEFINED PYTHON_INSTALL_DIRECTORY) )
    set( _destDir "${PYTHON_INSTALL_DIRECTORY}/brainvisa")
  endif()

  # Make sure Python can be executed
  if( NOT DEFINED PYTHON_EXECUTABLE )
    find_package( PythonInterp REQUIRED )
  endif( NOT DEFINED PYTHON_EXECUTABLE )

  # Read source directory and separate Python sources (*.py) from other files
  set( _pythonSources )
  set( _nonPythonSources )
  file( GLOB_RECURSE _files RELATIVE "${_pythonDirectory}" "${_pythonDirectory}/*" )
  foreach( _i ${_files} )
    get_filename_component( _f ${_i} NAME )
    string( REGEX MATCH "(CMakeLists\\.txt)|(.*~)|(.*#.*)|(.*\\.svn/.*)|(.*\\..*swp)|(.*\\.py[co])$|(.*__pycache__/.*)" _match "${_i}" )
    if( NOT _match )
      string( REGEX MATCH ".*\\.py$" _match ${_f} )
      if( _match )
        set( _pythonSources ${_pythonSources} ${_i} )
      else( _match )
        set( _nonPythonSources ${_nonPythonSources} ${_i} )
      endif( _match )
    endif( NOT _match )
  endforeach( _i ${_files} )

#   if(install_only)
#     set(_nonPythonSources ${_pythonSources} ${_nonPythonSources})
#     set(_pythonSources)
#   endif()

  # List containing all source files and also byte compiled files in the build directory
  set( _targetDepends )

  # Copy or symlink Python sources
  foreach(_file ${_pythonSources})
    if( NOT install_only )
        # Copy the source file in build directory
        set( _fileBuild "${CMAKE_BINARY_DIR}/${_destDir}/${_file}" )
        get_filename_component( _path "${_fileBuild}" DIRECTORY )

        if( UNIX OR APPLE OR CMAKE_CROSSCOMPILING)
            # Make a symlink instead of copying Python source allows to
            # execute code from the build tree and directly benefit from
            # modifications in the source tree (without typing make)
            get_filename_component( _dest_directory "${_fileBuild}" DIRECTORY )
            file( RELATIVE_PATH _relsource "${_dest_directory}"
                  "${_pythonDirectory}/${_file}" )
            add_custom_command( OUTPUT "${_fileBuild}"
                                COMMAND "${CMAKE_COMMAND}" -E make_directory "${_path}"
                                COMMAND "${CMAKE_COMMAND}" -E create_symlink "${_relsource}" "${_fileBuild}"
                                DEPENDS "${_pythonDirectory}/${_file}"
                                VERBATIM )
        else()
            add_custom_command( OUTPUT "${_fileBuild}"
                                COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_pythonDirectory}/${_file}" "${_fileBuild}"
                                DEPENDS "${_pythonDirectory}/${_file}"
                                VERBATIM )
        endif()
        set( _targetDepends ${_targetDepends} "${_fileBuild}" )
    endif()
    get_filename_component( _dest "${_destDir}/${_file}" DIRECTORY )
    BRAINVISA_INSTALL(
      FILES "${_pythonDirectory}/${_file}"
      DESTINATION "${_dest}"
      COMPONENT ${_component} )
endforeach(_file ${_pythonSources})

  # Copy other files
  foreach(_file ${_nonPythonSources})
    if( NOT install_only )
        set( _fileBuild "${CMAKE_BINARY_DIR}/${_destDir}/${_file}" )
        if( UNIX OR APPLE OR CMAKE_CROSSCOMPILING)
        # Make a symlink instead of copying Python source allows to
        # execute code from the build tree and directly benefit from
        # modifications in the source tree (without typing make)
        get_filename_component( _path "${_fileBuild}" PATH )
        file( RELATIVE_PATH _relsource "${_path}"
              "${_pythonDirectory}/${_file}" )
        add_custom_command( OUTPUT "${_fileBuild}"
                            COMMAND "${CMAKE_COMMAND}" -E make_directory "${_path}"
                            COMMAND "${CMAKE_COMMAND}" -E create_symlink "${_relsource}" "${_fileBuild}"
                            DEPENDS "${_pythonDirectory}/${_file}"
                            VERBATIM )
        else()
        add_custom_command( OUTPUT "${_fileBuild}"
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_pythonDirectory}/${_file}" "${_fileBuild}"
            DEPENDS "${_pythonDirectory}/${_file}"
            VERBATIM )
        endif()
    endif()

    # Install source file and byte compiled files
    get_filename_component( _dest "${_destDir}/${_file}" DIRECTORY )
    BRAINVISA_INSTALL( FILES "${_pythonDirectory}/${_file}"
                       DESTINATION "${_dest}"
                       COMPONENT ${_component} )
    set( _targetDepends ${_targetDepends} "${_fileBuild}" )
  endforeach(_file ${_nonPythonSources})


  # Make a target that depends on all files that must be copied or generated
  # Is there a better way to force files creation ?
  BRAINVISA_GENERATE_TARGET_NAME( _target )
  add_custom_target( ${_target} ALL
                     DEPENDS ${_targetDepends} )
endfunction()


# BRAINVISA_INSTALL_DIRECTORY
#   Install a directory without copying it into the build tree.
# Usage:
#   BRAINVISA_INSTALL_DIRECTORY <directory> <destination> <component> )
#
# Example:
#  BRAINVISA_INSTALL_DIRECTORY( "/usr/lib/python2.7" "python" "brainvisa-python" )
function( BRAINVISA_INSTALL_DIRECTORY directory destination component )
  file( GLOB_RECURSE allFiles RELATIVE "${directory}" FOLLOW_SYMLINKS "${directory}/*" )
  foreach( file ${allFiles} )
    get_filename_component( path "${file}" PATH )
    get_filename_component( name "${file}" NAME )
    get_filename_component( file2 "${directory}/${path}/${name}" REALPATH )
    if( EXISTS "${directory}/${path}/${name}" )
      # at the first level under ${directory}, symlinks are not followed,
      # and we may get a symlink to a directory in ${file}
      if( IS_DIRECTORY "${file2}" )
        BRAINVISA_INSTALL_DIRECTORY( "${file2}" "${destination}/${path}/${name}" "${component}-dev" )
      else()
        BRAINVISA_INSTALL( PROGRAMS "${file2}"
          DESTINATION "${destination}/${path}"
          COMPONENT "${component}" )
      endif()
    else()
      message( "Warning: file \"${directory}/${path}/${name}\" does not exist (probably an invalid link)" )
    endif()
  endforeach()
endfunction()


# BRAINVISA_GET_SPACED_QUOTED_LIST
#   Transform a list into a string containing space separated items. Each item
#   is surounded by double quotes.
#
# Usage:
#  BRAINVISA_GET_SPACED_QUOTED_LIST( <list variable> <output variable> )
#
# Example:
#   SET( _list a b "c d" )
#   BRAINVISA_GET_SPACED_QUOTED_LIST( _list _quotedList )
#   # equivalent to SET( _quotedList "\"a\" \"b\" \"c d\"" )
MACRO( BRAINVISA_GET_SPACED_QUOTED_LIST _listVariable _outputVariable )
  SET( _list ${${_listVariable}} )
  SET( ${_outputVariable} )
  LIST( LENGTH _list _length )
  IF( _length GREATER 0 )
    LIST( GET _list 0 _item )
    LIST( REMOVE_AT _list 0 )
    STRING( REPLACE "\"" "\\\"" _item ${_item}  )
    SET( ${_outputVariable} "\"${_item}\"" )
    FOREACH( _item ${_list} )
      STRING( REPLACE "\"" "\\\"" _item ${_item}  )
      SET( ${_outputVariable} "${${_outputVariable}} \"${_item}\"" )
    ENDFOREACH( _item ${list} )
  ENDIF( _length GREATER 0 )
ENDMACRO( BRAINVISA_GET_SPACED_QUOTED_LIST _listVariable _outputVariable )


# BRAINVISA_GENERATE_COMMANDS_HELP_INDEX
#   Add target to generate command help index
#
# Usage:
#
#   BRAINVISA_GENERATE_COMMANDS_HELP_INDEX( COMPONENT <component> )
#
function( BRAINVISA_GENERATE_COMMANDS_HELP_INDEX )

  set(_argn ${ARGN})

  # Read options
  set( arg_index 0 )
  unset(_currentarg)
  unset(_components)
  unset(_output_directory)
  unset(_install_directory)
  unset(_depends)
  unset(_dirs)

  foreach( _arg ${_argn} )
    if( "_${_arg}" STREQUAL _COMPONENT )
      set(_currentarg "${_arg}")

    elseif( "_${_currentarg}" STREQUAL _COMPONENT )
      list( GET _argn ${arg_index} result )
      if(DEFINED _components)
        set( _components ${_components} "${result}" )
      else()
        set( _components "${result}" )
      endif()
    endif()

    math(EXPR arg_index "${arg_index} + 1")
  endforeach()

  unset(_currentarg)
  unset(_arg)

  # Set default option values
  if (NOT DEFINED _components)
    set( _components "${BRAINVISA_COMPONENTS}" )
  endif()

  get_filename_component( _output_directory "${CMAKE_BINARY_DIR}/share/doc" ABSOLUTE )
  set( _install_directory "$(BRAINVISA_INSTALL_PREFIX)/share/doc" )

  set(_index_file "index_commands.html")

  if(NOT TARGET bv_commands_doc)
    set(_depends "")
    set(_dirs "")
    set(_cmd_options)
    foreach(_component ${_components})
      set(_comp_cmds)
      foreach(_command ${${_component}-commands})
        if((NOT DEFINED ${_command}-help-generate) OR ${_command}-help-generate)
          list( APPEND _depends "${_output_directory}/commands-help/${_component}-${${_component}_VERSION}/${_command}" )
          if( NOT _comp_cmds )
            set( _comp_cmds "${_command}" )
          else()
            set( _comp_cmds "${_comp_cmds},${_command}" )
          endif()
        endif()
      endforeach()
      if( _comp_cmds )
        list( APPEND _cmd_options "-c" "${_component}:${_comp_cmds}" )
      endif()
      unset(_command)

      list( APPEND _dirs "${_output_directory}/commands-help/${_component}-${${_component}_VERSION}" )
    endforeach()

    if( _cmd_options )
      list( INSERT _cmd_options 0 "--no-default" )
    endif()

    file(TO_NATIVE_PATH "${_dirs}" _helppath)
    if (NOT WIN32)
      string(REPLACE ";" ":" _helppath "${_helppath}")
    endif()

#     message("--BRAINVISA_ADD_COMMAND_HELP_INDEX - _output_directory : ${_output_directory}")
#     message("--BRAINVISA_ADD_COMMAND_HELP_INDEX - _depends : ${_depends}")
#     message("--BRAINVISA_ADD_COMMAND_HELP_INDEX - _dirs : ${_dirs}")

    if(CMAKE_CROSSCOMPILING AND WINE32)
        find_package(Wine)
    endif()
    if( NOT CREATE_COMMANDS_DOC )
      message( "bv_create_commands_doc is not found or configured. "
               "Commands help will not be generated." )
    else()
      add_custom_command( OUTPUT "${_output_directory}/${_index_file}"
                          COMMAND ${CMAKE_TARGET_SYSTEM_PREFIX}
                                  "${PYTHON_EXECUTABLE}"
                                  ${CREATE_COMMANDS_DOC}
                                  -t "${_helppath}"
                                  -v 0
                                  ${_cmd_options}
                                  "${_output_directory}/${_index_file}"
                          DEPENDS ${_depends}
                          COMMENT "Generating documentation commands help index ..."
                          VERBATIM )

      add_custom_target( bv_commands_doc
                        DEPENDS "${_output_directory}/${_index_file}"
                        VERBATIM )

      add_custom_command( OUTPUT "${_install_directory}/${_index_file}"
                          COMMAND "${CMAKE_COMMAND}" -E make_directory "${_install_directory}"
                          COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_output_directory}/${_index_file}" "${_install_directory}/${_index_file}"
                          DEPENDS "${_output_directory}/${_index_file}"
                          COMMENT "Installing documentation commands help index ..."
                          VERBATIM )

      add_custom_target( install-bv_commands_doc
                        DEPENDS "${_install_directory}/${_index_file}"
                        VERBATIM )
    endif()
  endif()

  unset(_output_directory)
  unset(_install_directory)
  unset(_depends)
  unset(_dirs)

endfunction()

# BRAINVISA_ADD_COMMAND_HELP
#   Add target to generate command help files
#
# Usage:
#
#   BRAINVISA_ADD_COMMAND_HELP( name [COMPONENT <component>]
#                                    [HELP_COMMAND <command>]
#                                    [HELP_DEPENDS <dependencies>] )
#
function( BRAINVISA_ADD_COMMAND_HELP name)
  set(_argn ${ARGN})

  # Read options
  set( arg_index 0 )
  unset(_command)
  unset(_depends)
  unset(_component)
  unset(_currentarg)
  foreach( _arg ${_argn} )
    if( "${_arg}" STREQUAL HELP_COMMAND
        OR "_${_arg}" STREQUAL _ARGS
        OR "${_arg}" STREQUAL HELP_DEPENDS
        OR "_${_arg}" STREQUAL _COMPONENT )
      set(_currentarg "${_arg}")

    elseif( "${_currentarg}" STREQUAL HELP_COMMAND
            OR "_${_currentarg}" STREQUAL _ARGS )
      list( GET _argn ${arg_index} result )
      if(DEFINED _command)
        set( _command ${_command} "${result}" )
      else()
        set( _command "${result}" )
      endif()

    elseif( "${_currentarg}" STREQUAL HELP_DEPENDS )
      list( GET _argn ${arg_index} result )
      if(DEFINED _depends)
        set( _depends ${_depends} "${result}" )
      else()
        set( _depends "${result}" )
      endif()

    elseif( "_${_currentarg}" STREQUAL _COMPONENT )
      list( GET _argn ${arg_index} result )
      set( _component "${result}" )
    endif()

    math(EXPR arg_index "${arg_index} + 1")
  endforeach()

  unset(_currentarg)
  unset(_arg)

  get_filename_component( _namewe "${name}" NAME_WE)

  # Set default option values
  if (NOT DEFINED _component)
    set( _component "${PROJECT_NAME}" )
  endif()

  if ((NOT DEFINED _depends) AND (NOT DEFINED _command))
    # Default dependencies is set using command name
    set( _depends "${CMAKE_BINARY_DIR}/bin/${name}" )
  endif()

  if (NOT DEFINED _command)
    # Default is set to command name --help
    # but in some cases output name of the target is not the same as target name
    if(TARGET ${name})
      get_property( _output_command TARGET "${name}" PROPERTY OUTPUT_NAME )
    endif()

    if(DEFINED _output_command)
      set( _command "${CMAKE_BINARY_DIR}/bin/${_output_command}" "-h" )
      unset(_output_command)
    else()
      if (${name}-command-is-script)
        set( _command "${CMAKE_BINARY_DIR}/bin/${name}" "-h" )
      else()
        set( _command "${CMAKE_BINARY_DIR}/bin/${name}${CMAKE_EXECUTABLE_SUFFIX}" "-h" )
      endif()
    endif()

    if (${name}-command-is-script)
      # Execute command using python interpreter
      set( _command "${PYTHON_EXECUTABLE}" ${_command})
    endif()
  endif()

#   set( _command "${CMAKE_BINARY_DIR}/${_command}" )

  string(REPLACE ";" "', '" _command "${_command}")
  get_filename_component( _output_directory "${CMAKE_BINARY_DIR}/share/doc" ABSOLUTE)
  get_filename_component( _component_help_directory "${_output_directory}/commands-help/${_component}-${${_component}_VERSION}" ABSOLUTE)

#   message("--BRAINVISA_ADD_COMMAND_HELP - name : ${name}")
#   message("--BRAINVISA_ADD_COMMAND_HELP - _namewe : ${_namewe}")
#   message("--BRAINVISA_ADD_COMMAND_HELP - _output_directory : ${_output_directory}")
#   message("--BRAINVISA_ADD_COMMAND_HELP - _component_help_directory : ${_component_help_directory}")
#   message("--BRAINVISA_ADD_COMMAND_HELP - _depends : ${_depends}")

  if (NOT TARGET ${_component}-command-help)
    add_custom_target( ${_component}-command-help )
  endif()

  if(TARGET "${name}-help")
    message( FATAL_ERROR "Target: ${name}-help already exists. Impossible to use it for BRAINVISA_ADD_COMMAND_HELP" )
  else()
    if(CMAKE_CROSSCOMPILING AND WINE32)
      find_package(Wine)
    endif()
    # Add help generation target
    add_custom_command( OUTPUT "${_component_help_directory}/${name}"
                        COMMAND "${CMAKE_COMMAND}" -E make_directory "${_component_help_directory}"
                        COMMAND ${CMAKE_TARGET_SYSTEM_PREFIX}
                                "${PYTHON_EXECUTABLE}" -c "import sys, subprocess; subprocess.call( ['${_command}'], stdout = sys.stdout, stderr = sys.stdout )" > ${_component_help_directory}/${name}
                        DEPENDS ${_depends}
                        COMMENT "Generating ${name} help file ..."
                        VERBATIM )

    # It is necessary to remove the extension, because cmake
    # does not support '.' in target names
    add_custom_target( ${name}-help
                       DEPENDS "${_component_help_directory}/${name}"
                       VERBATIM )

    add_dependencies(${_component}-command-help ${name}-help)

  endif()

  unset(_command)
  unset(_namewe)
  unset(_depends)
  unset(_component)
  unset(_output_directory)

endfunction()

# BRAINVISA_GENERATE_COMMANDS_HELP
#   Add targets to generate commands help
#
# Usage:
#
#   BRAINVISA_GENERATE_COMMANDS_HELP( [COMPONENT] <component_1> ... <component_N>  )
#
function( BRAINVISA_GENERATE_COMMANDS_HELP )
  set(_argn ${ARGN})

  # Read options
  set( arg_index 0 )
  unset(_currentarg)
  unset(_components)
  foreach( _arg ${_argn} )
    if( "_${_arg}" STREQUAL _COMPONENT )
      set(_currentarg "${_arg}")

    else()
      list( GET _argn ${arg_index} result )
      if (DEFINED _components)
        list(APPEND _components "${result}")
      else()
        set( _components "${result}" )
      endif()
    endif()

    math(EXPR arg_index "${arg_index} + 1")
  endforeach()
  unset(_currentarg)
  unset(_arg)

  # Set default option values
  if (DEFINED _components)
    list(REMOVE_DUPLICATES _components)
  else()
    set( _components "${BRAINVISA_COMPONENTS}" )
  endif()

  #if ( BRAINVISA_ADVANCED_FEATURE_TEST_MODE )
  foreach(_component ${_components})
    if (DEFINED ${_component}-commands)
      foreach(_command ${${_component}-commands})
        if((NOT DEFINED ${_command}-help-generate)
            OR ${_command}-help-generate)

          # Add help generation
          BRAINVISA_ADD_COMMAND_HELP( "${_command}"
                                      HELP_COMMAND ${${_command}-help-command}
                                      COMPONENT ${_component} )
        endif()
      endforeach()
    endif()
  endforeach()
  #endif()

  unset(_command)
  unset(_component)
  unset(_components)
endfunction()

# BRAINVISA_ADD_EXECUTABLE
#   Add executable target and reference executable for the component.
#   Executables added with BRAINVISA_ADD_EXECUTABLE are referenced a
#   cache variable named ${component}-commands.
#
# Usage:
#
#   BRAINVISA_ADD_EXECUTABLE( <name>
#                                    [WIN32] [MACOSX_BUNDLE] [EXCLUDE_FROM_ALL]
#                                    source1 ... sourceN
#                                    [COMPONENT <component>]
#                                    [IS_SCRIPT]
#                                    [HELP_COMMAND <command> arg1 ... argN]
#                                    [HELP_GENERATE On/Off]
#                                    [OUTPUT_NAME commandname] )
#
#  if OUTPUT_NAME is set, set_property( TARGET <name> PROPERTY OUTPUT_NAME <commandname> )
#    is called, and the command help is set with the name <commandname> instead of <name>.
#
function( BRAINVISA_ADD_EXECUTABLE name )
  set(_argn ${ARGN})

  # Read options
  set( arg_index 0 )
  unset(_currentarg)
  unset(_is_script)
  unset(_help_command)
  unset(_help_generate)
  unset(_commandname)
  unset(_sources)
  unset(_exe_args)
  unset(_component)
  set( COMPONENT "COMPONENT" ) # prevents a bug in STREQUAL because
  # COMPONENT exists as a global variable
  foreach( _arg ${_argn} )
    if( "${_arg}" STREQUAL HELP_COMMAND
        OR "${_arg}" STREQUAL HELP_GENERATE
        OR "${_arg}" STREQUAL COMPONENT
        OR "${_arg}" STREQUAL OUTPUT_NAME )
      set(_currentarg "${_arg}")

    elseif( "${_arg}" STREQUAL "IS_SCRIPT" )
      set(_is_script TRUE)

    elseif( "${_currentarg}" STREQUAL "HELP_COMMAND" )
      list( GET _argn ${arg_index} result )
      if(DEFINED _help_command)
        set( _help_command ${_help_command} "${result}" )
      else()
        set( _help_command "${result}" )
      endif()

    elseif( "${_currentarg}" STREQUAL HELP_GENERATE )
      list( GET _argn ${arg_index} result )
      set( _help_generate "${result}" )

    elseif( "${_currentarg}" STREQUAL COMPONENT )
      list( GET _argn ${arg_index} result )
      set( _component "${result}" )

    elseif( "${_currentarg}" STREQUAL OUTPUT_NAME )
      list( GET _argn ${arg_index} result )
      set( _commandname "${result}" )

    else()

      # Add argument to excutable arguments
      list( GET _argn ${arg_index} result )
      if(DEFINED _exe_args)
        set(_exe_args ${_exe_args} "${result}" )
      else()
        set( _exe_args "${result}" )
      endif()

      # Add argument to sources
      if( (NOT "${_currentarg}" STREQUAL WIN32)
          AND (NOT "${_currentarg}" STREQUAL MACOSX_BUNDLE)
          AND (NOT "${_currentarg}" STREQUAL EXCLUDE_FROM_ALL) )
        if( DEFINED _sources )
          set( _sources ${_sources} "${result}" )
        else()
          set( _sources "${result}" )
        endif()
      endif()

    endif()

    math(EXPR arg_index "${arg_index} + 1")
  endforeach()
  unset(_currentarg)
  unset(_arg)

  # Set default option values
  if (NOT DEFINED _component)
    set( _component "${PROJECT_NAME}" )
  endif()

#   message("BRAINVISA_ADD_EXECUTABLE - name : ${name}")
#   message("BRAINVISA_ADD_EXECUTABLE - _exe_args : ${_exe_args}")
#   message("BRAINVISA_ADD_EXECUTABLE - _component : ${_component}")
#   message("BRAINVISA_ADD_EXECUTABLE - _is_script : ${_is_script}")
#   message("BRAINVISA_ADD_EXECUTABLE - _sources : ${_sources}")
#   message("BRAINVISA_ADD_EXECUTABLE - _commandname : ${_commandname}")

  if (NOT _is_script)
    # Add executable only if it is not a script
    add_executable( ${name} ${_exe_args} )
    add_custom_target( ${name}-clean
                       "${CMAKE_COMMAND}" -E remove -f "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${name}"
                       COMMENT "Cleaning ${name} ..." )
    if( _commandname )
      set_property( TARGET ${name} PROPERTY OUTPUT_NAME "${_commandname}" )
    endif()

#     message("BRAINVISA_ADD_EXECUTABLE - executable ${name} added")
  else()
    # In the case of a script we add a copy of the file to the runtime directory
    foreach(_source ${_sources})
      get_filename_component(_sourcename "${_source}" NAME)
      get_filename_component(_sourcedir "${_source}" PATH)
      get_filename_component(_sourcedir "${_sourcedir}" ABSOLUTE)
      file(RELATIVE_PATH _source "${_sourcedir}" "${_source}")
#       message("BRAINVISA_ADD_EXECUTABLE - ${_source}")
#       message("BRAINVISA_ADD_EXECUTABLE - ${_sourcenamewe}")
#       message("BRAINVISA_ADD_EXECUTABLE - ${_sourcedir}")
      BRAINVISA_COPY_FILES( ${_component} ${_source}
                            SOURCE_DIRECTORY "${_sourcedir}"
                            DESTINATION "bin"
                            TARGET ${_sourcename}.files )
    endforeach()
    unset(_source)
    unset(_sourcename)
    unset(_sourcedir)
    set(${name}-command-is-script ${_is_script} CACHE INTERNAL "${name} command is script")
  endif()

  # replace name with commandname for help generation
  if( _commandname )
    set( name "${_commandname}" )
  endif()

  # Append command name to the list of commands for the component
  if (DEFINED ${_component}-commands)
    set(_internal-commands ${${_component}-commands} "${name}")
    list(REMOVE_DUPLICATES _internal-commands)
    set(${_component}-commands ${_internal-commands} CACHE INTERNAL "Component ${_component} commands")
    unset(_internal-commands)
  else()
    set(${_component}-commands "${name}" CACHE INTERNAL "Component ${_component} commands")
  endif()

  # Store command to generate help
  if(DEFINED _help_command)
    set(${name}-help-command ${_help_command} CACHE INTERNAL "${name} help generation command")
  endif()

  # Store if command help must not be generated
  if(DEFINED _help_generate
     AND (NOT _help_generate))
    set(${name}-help-generate ${_help_generate} CACHE INTERNAL "${name} help must be generated")
  endif()

  unset(_is_script)
  unset(_sources)
  unset(_help_command)
  unset(_help_generate)
  unset(_exe_args)
endfunction()

# BRAINVISA_ADD_TEST
#  Add a test to the project with the specified arguments.
#  brainvisa_add_test(testname Exename arg1 arg2 ... )
#  If TYPE Python is given, the appropriate python interpreter is used to
#  start the test (i.e.: target python for cross compiling case).
#  Test command is also launched through bv_env_test command.
#  Each test in ctest is assigned a label corresponding to the project name.
#  If TESTREF is used, we re-use the command to run it in a special mode
#  for the generation of reference test files (this is launched by the testref
#  target).
#  TIMEOUT: the test command is interrupted after that duration. If TIMEOUT is
#  0, then no timeout is set (infinite). If TIMEOUT is not specified, a default
#  timeout will be used: DART_TESTING_TIMEOUT (same as used by CTest)
# Usage:
#
#   BRAINVISA_ADD_TEST( NAME <name> [CONFIGURATIONS [Debug|Release|...]]
#                       [WORKING_DIRECTORY dir]
#                       [TIMEOUT seconds]
#                       COMMAND <command> [arg1 [arg2 ...]]
#                       [TESTREF]
#  )
#
function( BRAINVISA_ADD_TEST )
  set(_argn ${ARGN})

  # Read options
  set( _arg_index 0 )
  unset(_name_args)
  unset(_command_args)
  set(_form 1)
  set(testref OFF)
  set(_working_dir)
  set(_timeout)
  set(_skip)

  foreach( _arg ${_argn} )
    if( _skip )
      set(_skip "")
    else()
      if( ${_arg_index} EQUAL 0 )
        if( _arg STREQUAL "NAME" )
          set(_form 2)
          math(EXPR _arg_index2 "${_arg_index} + 1")
          list( GET _argn ${_arg_index2} result )
          set( _name_args "${result}" )
          set( _skip "1" )
        else()
          list( GET _argn ${_arg_index} result )
          set(_name_args "${result}")
        endif()
      elseif( _arg STREQUAL "TESTREF" )
        set(testref ON)
      elseif( _arg STREQUAL "COMMAND" )
        # do nothing

      elseif( _arg STREQUAL "TIMEOUT" )
        math(EXPR _arg_index2 "${_arg_index} + 1")
        list( GET _argn ${_arg_index2} result )
        set( _timeout "${result}" )
        set( _skip "1" )

      else()
        if( _working_dir STREQUAL "*set_workdir*" )
          set( _working_dir "${_arg}" )
        elseif( _arg STREQUAL "WORKING_DIRECTORY" )
          set( _working_dir "*set_workdir*" )
        else()
          if( NOT DEFINED _command_args )
            set( _command_args "${_arg}" )
          else()
            set( _command_args "${_command_args}" "${_arg}" )
          endif()
        endif()
      endif()
    endif()

    math(EXPR _arg_index "${_arg_index} + 1")
  endforeach()

  if(CMAKE_CROSSCOMPILING)
    # Replaces python interpreter with target python interpreter
    # in test command arguments
    set(_arg_index 0)

    # Get host python interpreter real path
    get_filename_component(_python_executable "${PYTHON_HOST_EXECUTABLE}" REALPATH)

    # Get target python interpreter name
    get_filename_component(_python_test "${PYTHON_EXECUTABLE}" NAME)
    foreach( _arg ${_command_args} )
      list( GET _command_args ${_arg_index} result )
      if(EXISTS "${result}")
        get_filename_component(result "${result}" REALPATH)
        if("${result}" STREQUAL "${_python_executable}")
          list(REMOVE_AT _command_args ${_arg_index})
          list(INSERT _command_args ${_arg_index} "${_python_test}")
        endif()
      endif()

      math(EXPR _arg_index "${_arg_index} + 1")
    endforeach()

    unset(_python_test)
    unset(_python_executable)
  endif()

  if( NOT _timeout )
    # use the same default timeout as ctest
    if( "${DART_TESTING_TIMEOUT}" STREQUAL "" )
      set( DART_TESTING_TIMEOUT "1800"
           CACHE "STRING" "Maximum time allowed before CTest will kill the test" )
    endif()
    if( NOT "${DART_TESTING_TIMEOUT}" STREQUAL "0" )
      set( _timeout "${DART_TESTING_TIMEOUT}" )
    endif()
  endif()

  if( _timeout )
    set( _command_args "timeout" "-k" "10" "${_timeout}" ${_command_args} )
  endif()

  # If the test is not marked testref we don't pass options for run mode
  # (so this test don't have to bother about options)
  if(testref)
    set( _command_args_run ${_command_args} "--test_mode=run" )
    set( _command_args_ref ${_command_args} "--test_mode=ref" )
  else()
    set( _command_args_run ${_command_args} )
    set( _command_args_ref ${_command_args} )
  endif()

#   if(CMAKE_CROSSCOMPILING)
#     if(WIN32)
#       # For cross compilation on windows it is necessary to start commands
#       # using a command interpreter (cmd) to get an environment
#       BRAINVISA_GET_SPACED_QUOTED_LIST( _command_args_run _command_args_run )
#       BRAINVISA_GET_SPACED_QUOTED_LIST( _command_args_ref _command_args_ref )
#       set( _command_args_run "cmd" "/c" "${_command_args_run}" )
#       set( _command_args_ref "cmd" "/c" "${_command_args_ref}" )
#     endif()
#   endif()

  # Add bv_env_test encapsulation
  find_program(BV_ENV_TEST bv_env_test)
  if (BV_ENV_TEST)
    set(_command_args_run "${BV_ENV_TEST}" "${_command_args_run}")
    set(_command_args_ref "${BV_ENV_TEST}" "${_command_args_ref}")
  else()
    set(_command_args_run "${brainvisa-cmake_DIR}/../../../bin/bv_env_test"
                          "${_command_args_run}")
    set(_command_args_ref "${brainvisa-cmake_DIR}/../../../bin/bv_env_test"
                          "${_command_args_ref}")
  endif()

  # message("====== FORM ${_form}, NAME ${_name_args} =======")
  # message("====== COMMAND ${_command_args} =======")

  if(_form EQUAL 1)
    # Add the test in the first manner
    add_test(${_name_args}
             ${_command_args_run})
  else()
    # Add the test in the second manner
    add_test(NAME ${_name_args}
             COMMAND ${_command_args_run})
  endif()
  # Add the command in ref mode to the testref target
  if(testref)
    add_custom_target(${_name_args}-testref
                      COMMAND ${_command_args_ref})
    add_dependencies(testref ${_name_args}-testref)
  endif()
  # set project as test label
  if( BRAINVISA_PACKAGE_MAIN_PROJECT )
    set_tests_properties( ${_name_args} PROPERTIES
                          LABELS "${BRAINVISA_PACKAGE_MAIN_PROJECT}" )
  else()
    set_tests_properties( ${_name_args} PROPERTIES
                          LABELS "${PROJECT_NAME}" )
  endif()

  unset(_arg_index)
  unset(_name_args)
  unset(_command_args_run)
  unset(_command_args_ref)
  unset(_command_args)
  unset(testref)

endfunction()

# BRAINVISA_GENERATE_DOXYGEN_DOC
#    Add rules to generate doxygen documentation with "make doc" or "make devdoc".
#
# Usage:
#   BRAINVISA_GENERATE_DOXYGEN_DOC( <input_variable> [<file to copy> ...] [INPUT_PREFIX <path>] [COMPONENT <name>] )
#   <input_variable>: variable containing a string or a list of input sources.
#                     Its content will be copied in the INPUT field of the
#                     Doxygen configuration file.
#  <file to copy>: file (relative to ${CMAKE_CURRENT_SOURCE_DIR}) to copy in
#                  the build tree. Files are copied in ${DOXYGEN_BINARY_DIR}
#                  if defined, otherwise they are copied in
#                  ${PROJECT_BINARY_DIR}/doxygen. The doxygen configuration
#                  file is generated in the same directory.
#  INPUT_PREFIX: directory where to find input files
#  COMPONENT: component name for this doxygen documentation. it is used to create the output directory and the tag file name.
#   By default it is the PROJECT_NAME. but it is useful to give an alternative name when there are several libraries documented with doxygen in the same project.
#
#   Before calling this macro, it is possible to specify values that are going
#   to be written in doxygen configuration file by setting variable names
#   DOXYFILE_<doxyfile variable name>. For instance, in order to set project
#   name in Doxygen, one should use
#   SET( DOXYFILE_PROJECT_NAME, "My wonderful project" ).
#
# Example:
#     FIND_PACKAGE( Doxygen )
#     IF ( DOXYGEN_FOUND )
#       SET(component_name "cartodata")
#       set( DOXYFILE_PREDEFINED "${AIMS_DEFINITIONS}")
#       set( DOXYFILE_TAGFILES "cartobase.tag=../../cartobase-${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}/doxygen")
#       BRAINVISA_GENERATE_DOXYGEN_DOC( _headers
#                                  INPUT_PREFIX "${CMAKE_BINARY_DIR}/include/${component_name}"
#                                  COMPONENT "${component_name}")
#     ENDIF ( DOXYGEN_FOUND )
#
MACRO( BRAINVISA_GENERATE_DOXYGEN_DOC _inputVariable )
  IF( DOXYGEN_FOUND )

    set(_argn ${ARGN})
    # Read INPUT_PREFIX option
    list( FIND _argn INPUT_PREFIX result )
    if( result EQUAL -1 )
      set( inputPrefix "${CMAKE_CURRENT_SOURCE_DIR}" )
    else()
      list( REMOVE_AT _argn ${result} )
      list( GET _argn ${result} inputPrefix )
      list( REMOVE_AT _argn ${result} )
    endif()
    # Read DOC_NAME option
    list( FIND _argn COMPONENT result )
    if( result EQUAL -1 )
      set( component "${PROJECT_NAME}" )
    else()
      list( REMOVE_AT _argn ${result} )
      list( GET _argn ${result} component )
      list( REMOVE_AT _argn ${result} )
    endif()

    if(NOT DEFINED DOXYFILE_PROJECT_NAME)
      SET( DOXYFILE_PROJECT_NAME "${component}" )
    endif()
    if(NOT DEFINED DOXYFILE_OUTPUT_DIRECTORY)
      SET( DOXYFILE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/share/doc/${component}-${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}/doxygen" )
    endif()
    if(NOT DEFINED DOXYFILE_GENERATE_TAGFILE)
      set( DOXYFILE_GENERATE_TAGFILE "${CMAKE_BINARY_DIR}/share/doc/${component}-${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}/doxygen/${component}.tag" )
    endif()

    IF( DEFINED DOXYGEN_BINARY_DIR )
      SET( _doxygenBinaryDir "${DOXYGEN_BINARY_DIR}" )
    ELSE( DEFINED DOXYGEN_BINARY_DIR )
      SET( _doxygenBinaryDir "${CMAKE_CURRENT_BINARY_DIR}" )
    ENDIF( DEFINED DOXYGEN_BINARY_DIR )
    # If files in _inputVariable are relative, make them absolute
    list( GET ${_inputVariable} 0 _item )
    if( NOT EXISTS "${_item}" )
      set( _newList )
      foreach( _item ${${_inputVariable}} )
        set( _newList ${_newList} "${inputPrefix}/${_item}" )
      endforeach( _item ${${_inputVariable}} )
      BRAINVISA_GET_SPACED_QUOTED_LIST( _newList _input )
      set(_inputList ${_newList})
    else( NOT EXISTS "${_item}" )
      BRAINVISA_GET_SPACED_QUOTED_LIST( ${_inputVariable} _input )
      set(_inputList ${${_inputVariable}})
    endif( NOT EXISTS "${_item}" )

    SET( DOXYFILE_INPUT "${_input}" )
    INCLUDE( "${brainvisa-cmake_DIR}/DoxyfileDefaultValues.cmake" )
    SET( _generatedFiles )
    FOREACH( _file ${_argn} )
      CONFIGURE_FILE( "${CMAKE_CURRENT_SOURCE_DIR}/${_file}"
                      "${_doxygenBinaryDir}/${_file}"
                      COPYONLY )
      CONFIGURE_FILE( "${CMAKE_CURRENT_SOURCE_DIR}/${_file}"
                      "${DOXYFILE_HTML_OUTPUT}/${_file}"
                      COPYONLY )
      SET( _generatedFiles ${_generatedFiles} "${DOXYFILE_HTML_OUTPUT}/${_file}" "${_doxygenBinaryDir}/${_file}" )
    ENDFOREACH( _file ${ARGN} )

    if( DOXYFILE_PREDEFINED )
      # preprocess DOXYFILE_PREDEFINED items
      set( _predefined )
      foreach( _predef ${DOXYFILE_PREDEFINED} )
        if( _predefined )
          set( _predefined "${predefined} \"${_predef}\"" )
        else()
          set( _predefined "\"${_predef}\"" )
        endif()
      endforeach()
      set( DOXYFILE_PREDEFINED ${_predefined} )
    endif()

    CONFIGURE_FILE( "${brainvisa-cmake_DIR}/Doxyfile.in" "${_doxygenBinaryDir}/Doxyfile" @ONLY )
    #BRAINVISA_GENERATE_TARGET_NAME( _target )
    set(_target "${component}-doxygen")
    set( doxydeps "${_doxygenBinaryDir}/Doxyfile" )
    set( doxydeps ${_generatedFiles} ${doxydeps} )
    set( doxydeps ${_inputList} ${doxydeps} )
    ADD_CUSTOM_COMMAND( OUTPUT ${DOXYFILE_OUTPUT_DIRECTORY}/index.html
                      DEPENDS ${doxydeps}
                      COMMAND "${CMAKE_COMMAND}" -E make_directory "${DOXYFILE_OUTPUT_DIRECTORY}"
                      COMMAND "${DOXYGEN_EXECUTABLE}" "${_doxygenBinaryDir}/Doxyfile" )
    ADD_CUSTOM_TARGET( ${_target}
      DEPENDS ${DOXYFILE_OUTPUT_DIRECTORY}/index.html )
    # Make sure doc target exists, I do not know if it is clean
    add_dependencies( ${PROJECT_NAME}-devdoc ${_target} )
    # Install HTML documentation
    if( IS_ABSOLUTE "${DOXYFILE_HTML_OUTPUT}" )
      set( _directory "${DOXYFILE_HTML_OUTPUT}" )
    else( IS_ABSOLUTE "${DOXYFILE_HTML_OUTPUT}" )
      set( _directory "${DOXYFILE_OUTPUT_DIRECTORY}/${DOXYFILE_HTML_OUTPUT}" )
    endif( IS_ABSOLUTE "${DOXYFILE_HTML_OUTPUT}" )
    BRAINVISA_INSTALL( DIRECTORY "${_directory}"
                  DESTINATION "share/doc/${component}-${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}"
                  USE_SOURCE_PERMISSIONS
                  COMPONENT ${PROJECT_NAME}-devdoc )
  ENDIF( DOXYGEN_FOUND )
ENDMACRO( BRAINVISA_GENERATE_DOXYGEN_DOC )


# BRAINVISA_GENERATE_EPYDOC_DOC
#    Add rules to generate epydoc documentation with "make doc" or "make <component>-doc" or "make devdoc" or "make <component>-devdoc".
# Usage:
#
#   BRAINVISA_GENERATE_EPYDOC_DOC( <source directory> [ <source directory> ... ] <output directory> [ EXCLUDE <exclude list> ] )
#
# Example:
#
#   BRAINVISA_GENERATE_EPYDOC_DOC( "${CMAKE_BINARY_DIR}/python/soma"
#     "share/doc/${PROJECT_NAME}-${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}/epydoc/html"
#     EXCLUDE soma.aims* )
#
function( BRAINVISA_GENERATE_EPYDOC_DOC  )
  if( Epydoc_FOUND )
    set( args "${ARGN}" )
    list( FIND args EXCLUDE result )
    set( excludeParameters )
    if( NOT result EQUAL -1 )
      list( REMOVE_AT args ${result} )
      list( LENGTH args len )
      while( result LESS len )
        list( GET args ${result} exclude )
        list( REMOVE_AT args ${result} )
        list( LENGTH args len )
        set( excludeParameters ${excludeParameters} "--exclude" "${exclude}" )
      endwhile()
    endif()

    list( GET args -1 outputDirectory )
    list( REMOVE_AT args -1 )
    set( sourceDirectories ${args} )

    set( pythonFiles )
    foreach( sourceDirectory ${sourceDirectories} )
      file( GLOB_RECURSE result "${sourceDirectory}/*.py" )
      set( pythonFiles ${pythonFiles} ${result} )
    endforeach()
    if( DOT_EXECUTABLE )
      set( dotParameters --dotpath "${DOT_EXECUTABLE}" --graph classtree )
    else()
      set( dotParameters )
    endif()
    add_custom_command( OUTPUT "${CMAKE_BINARY_DIR}/${outputDirectory}/index.html"
                        DEPENDS ${pythonFiles}
                        COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_BINARY_DIR}/${outputDirectory}"
                          "${EPYDOC_EXECUTABLE}"
                          --html
                          --name "${PROJECT_NAME} ${${PROJECT_NAME}_VERSION}"
                          -o "${CMAKE_BINARY_DIR}/${outputDirectory}"
                          --inheritance grouped
                          ${dotParameters}
                          ${excludeParameters}
                          ${sourceDirectories} )
      BRAINVISA_GENERATE_TARGET_NAME( target )
      add_custom_target( ${target} DEPENDS "${CMAKE_BINARY_DIR}/${outputDirectory}/index.html" )
      add_dependencies( ${PROJECT_NAME}-devdoc ${target} )
      # Install HTML documentation
      BRAINVISA_INSTALL( DIRECTORY "${CMAKE_BINARY_DIR}/${outputDirectory}/"
                         DESTINATION "${outputDirectory}"
                         USE_SOURCE_PERMISSIONS
                         COMPONENT ${PROJECT_NAME}-devdoc )
  endif()
endfunction()


# BRAINVISA_GENERATE_SPHINX_DOC
#    Add rules to generate sphinx documentation with "make doc" or "make <component>-doc" or "make devdoc" or "make <component>-devdoc".
# Usage:
#
#   BRAINVISA_GENERATE_SPHINX_DOC( <source directory> <output directory>
#                                  [IGNORE_ERROR]
#                                  [TARGET <target_name>]
#                                  [USER] )
#
# Example:
#
#   BRAINVISA_GENERATE_SPHINX_DOC( "doc/source"
#     "share/doc/soma-workflow-${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}" )
#
# if TARGET argument is not specified, the target name defaults to ${PROJECT_NAME}-sphinx
#
# if IGNORE_ERROR is used, any error occuring during the sphinx doc generation will be ignored.
#
# if USER is specified, the generated doc will be part of the usrdoc (user
# documentation) global target, and included in user docs packages.
# Otherwise, by default, sphinx docs are considered developer docs (devdoc)
#
function( BRAINVISA_GENERATE_SPHINX_DOC  )
  if( SPHINX_FOUND AND SPHINXBUILD_EXECUTABLE )
    set( user FALSE )
    set( default_target "sphinx" )
    set( doctype "devdoc" )
    set( args "${ARGN}" )

    list( GET args 0 sourceDirectory )
    list( GET args 1 outputDirectory )
    set( target )
    list( FIND args TARGET result )
    if( NOT result EQUAL -1 )
      list( REMOVE_AT args ${result} )
      list( GET args ${result} target )
      list( REMOVE_AT args ${result} )
    endif()
    list( FIND args IGNORE_ERROR result )
    if( result EQUAL -1 )
      set( ignore_error_command )
    else()
      set( ignore_error_command || (exit 0) )
    endif()
    list( FIND args USER result )
    if( NOT result EQUAL -1 )
      set( user TRUE )
      set( default_target "usrsphinx" )
      set( doctype "usrdoc" )
      list( REMOVE_AT args ${result} )
    endif()

    set( source_directory "${sourceDirectory}" )
    if( NOT IS_ABSOLUTE "${sourceDirectory}" )
      set( source_directory "${CMAKE_CURRENT_SOURCE_DIR}/${sourceDirectory}" )
    endif()

    get_filename_component(install_directory "${outputDirectory}" PATH)

    set( output_directory "${outputDirectory}" )
    if( NOT IS_ABSOLUTE "${outputDirectory}" )
      set( output_directory "${CMAKE_BINARY_DIR}/${outputDirectory}" )
    endif()

    if( NOT target )
      set( target ${PROJECT_NAME}-${default_target} )
    endif()
    if(CMAKE_CROSSCOMPILING AND WINE32)
      find_package(Wine)
    endif()
    add_custom_target( ${target}
                      COMMAND "${CMAKE_COMMAND}" -E make_directory
                        "${output_directory}"
                      COMMAND ${CMAKE_TARGET_SYSTEM_PREFIX}
                        ${SPHINXBUILD_EXECUTABLE}
                        ${source_directory}
                        ${output_directory} ${ignore_error_command}
    )

    add_dependencies( ${PROJECT_NAME}-${doctype} ${target} )

    # Install HTML documentation
    BRAINVISA_INSTALL( DIRECTORY "${output_directory}"
                       DESTINATION "${install_directory}"
                       USE_SOURCE_PERMISSIONS
                       COMPONENT ${PROJECT_NAME}-${doctype} )
  endif()
endfunction()


#
#
function( BRAINVISA_ADD_COMPONENT_GROUP _group )
  if( NOT TARGET install-${_group} )
    set( _readVariable )
    set( _parentGroup )
    foreach( _i ${ARGN} )
      if( _readVariable )
        set( ${_readVariable} "${_i}" )
  #       set( _readVariable )
        break()
      else()
        if( "${_i}" STREQUAL PARENT_GROUP )
          set( _readVariable _parentGroup )
        endif()
      endif()
    endforeach()

  #    message( "Create group ${_group} with parent \"${_parentGroup}\"" )
    if(NOT CPack_CMake_INCLUDED)
      include( CPack )
    endif()
    cpack_add_component_group( ${_group} ${ARGN} )
    add_custom_target( install-${_group} )
    if( _parentGroup )
      add_dependencies( install-${_parentGroup} install-${_group} )
    endif()
  endif()
endfunction()


#
#
function( BRAINVISA_ADD_COMPONENT _component )
  if( NOT TARGET install-${_component} )
    set( _readVariable )
    set( _group )
    foreach( _i ${ARGN} )
      if( _readVariable )
        set( ${_readVariable} "${_i}" )
  #       set( _readVariable )
        break()
      else()
        if( "${_i}" STREQUAL GROUP )
          set( _readVariable _group )
        endif()
      endif()
    endforeach()

    #message( "Create component ${_component} in group ${_group}" )
    if(NOT CPack_CMake_INCLUDED)
      include( CPack )
    endif()
    cpack_add_component( ${_component}
                         ${ARGN} )
    add_custom_target( install-${_component}
                      COMMAND if [ -n \"$(BRAINVISA_INSTALL_PREFIX)\" ] \; then "${CMAKE_COMMAND}" -DCMAKE_INSTALL_PREFIX=\"$(BRAINVISA_INSTALL_PREFIX)\" -DCOMPONENT=${_component} -P "${CMAKE_BINARY_DIR}/cmake_install.cmake" \; else "${CMAKE_COMMAND}" -DCOMPONENT=${_component} -P "${CMAKE_BINARY_DIR}/cmake_install.cmake" \; fi )
    add_dependencies( install-${_group} install-${_component} )
  endif()
endfunction()


#
#
function( BRAINVISA_INSTALL )
  set( args "${ARGN}" )
  list( FIND args COMPONENT result )
  if( result EQUAL -1 )
    message( FATAL_ERROR "COMPONENT argument is mandatory for BRAINVISA_INSTALL" )
  else()
    install( ${ARGN} )
  endif()
endfunction()

# BRAINVISA_REAL_PATHS
#   Remove all symlinks from a list of paths by applying get_filename_component( ... REALPATH )
#   to each element of the list.
#
# Usage:
#
#   BRAINVISA_REAL_PATHS( output_variable [ <path> ... ] )
#
# Example:
#    file( GLOB glob_result /usr/lib/*.so )
#    BRAINVISA_REAL_PATHS( real_files ${glob_result} )
#    foreach( file ${real_files} )
#      message( "${file}" )
#    endforeach()
function( BRAINVISA_REAL_PATHS output_variable )
  set( result )
  foreach( file ${ARGN} )
    get_filename_component( real "${file}" REALPATH )
    set( result ${result} "${real}" )
  endforeach()
  set( ${output_variable} ${result} PARENT_SCOPE )
endfunction()

macro( BRAINVISA_ADD_MOC_FILES _sources )
  foreach( _current_FILE ${ARGN} )
    get_filename_component( _tmp_FILE ${_current_FILE} ABSOLUTE )
    file( READ "${_tmp_FILE}" _content )
    string( REGEX MATCH Q_OBJECT _match "${_content}" )
    if( _match )
      get_filename_component( _basename ${_tmp_FILE} NAME_WE )
      set( _moc ${CMAKE_CURRENT_BINARY_DIR}/${_basename}.moc.cpp )
      if( DESIRED_QT_VERSION EQUAL 3 )
        add_custom_command(OUTPUT ${_moc}
          COMMAND ${QT_MOC_EXECUTABLE}
          ARGS ${_tmp_FILE} -o ${_moc}
          DEPENDS ${_tmp_FILE}
        )
      elseif( DESIRED_QT_VERSION EQUAL 4 )
        QT4_GENERATE_MOC( "${_tmp_FILE}" "${_moc}" )
      elseif( DESIRED_QT_VERSION EQUAL 5 )
        qt5_generate_moc( "${_tmp_FILE}" "${_moc}" )
      elseif( DESIRED_QT_VERSION EQUAL 6 )
        qt6_generate_moc( "${_tmp_FILE}" "${_moc}" )
      endif()
      set(${_sources} ${${_sources}} "${_moc}" )
    endif()
  endforeach()
endmacro()


#
# Usage:
#   BRAINVISA_ADD_SIP_PYTHON_MODULE( <module> <directory> <mainSipFile> [ SIP_SOURCES <file> ... ] [ SIP_INCLUDE <directory> ... ] [ SIP_INSTALL <directory> ] )
#
#
macro( BRAINVISA_ADD_SIP_PYTHON_MODULE _moduleName _modulePath _mainSipFile )
  # Parse parameters
  set( _argn "${ARGN}" )
  list( FIND _argn SIP_INSTALL result )
  if( result EQUAL -1 )
    set( _SIP_INSTALL "share/${PROJECT_NAME}-${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}/sip" )
  else()
    list( REMOVE_AT _argn ${result} )
    list( GET _argn ${result} _SIP_INSTALL )
    list( REMOVE_AT _argn ${result} )
  endif()
  list( FIND _argn NUM_OUTPUT_FILES result )
  if( result EQUAL -1 )
    set( _sipSplitGeneratedCode 8 )
  else()
    list( REMOVE_AT _argn ${result} )
    list( GET _argn ${result} _sipSplitGeneratedCode )
    list( REMOVE_AT _argn ${result} )
  endif()
  set( _SIP_SOURCES )
  if( SIP_VERSION LESS 6.0.0 )
    set( _SIP_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}" )
  endif()
  set( _listVariable )
  foreach( _i ${_argn} )
    if( "${_i}" STREQUAL "SIP_SOURCES" OR
        "${_i}" STREQUAL "SIP_INCLUDE" )
      set( _listVariable "_${_i}" )
    else( "${_i}" STREQUAL "SIP_SOURCES" OR
        "${_i}" STREQUAL "SIP_INCLUDE" )
      if( _listVariable )
        set( ${_listVariable} ${${_listVariable}} "${_i}" )
      else( _listVariable )
        message( FATAL_ERROR "Invalid option for BRAINVISA_ADD_SIP_PYTHON_MODULE: ${_i}" )
      endif( _listVariable )
    endif( "${_i}" STREQUAL "SIP_SOURCES" OR
        "${_i}" STREQUAL "SIP_INCLUDE" )
  endforeach()

  list( FIND _SIP_SOURCES "${_mainSipFile}" result )
  if( NOT result EQUAL -1 )
    list( REMOVE_AT _SIP_SOURCES "${result}" )
  endif()

  # Build install rules for sip files
  BRAINVISA_COPY_FILES( ${PROJECT_NAME}-dev
    ${_mainSipFile} ${_SIP_SOURCES}
    DESTINATION "${_SIP_INSTALL}"
    GET_OUTPUT_FILES copied_sip_files
    )

  # Compute C++ file names that will be generated by sip.
  # This is only possible with -j option.
  if( SIP_VERSION VERSION_GREATER_EQUAL "6.0.0" )
    set( sip_gensrc_subdir "/sipbuild/${_moduleName}" )
  else()
    set( sip_gensrc_subdir "" )
  endif()
  set(_sipOutputFiles )
  foreach( _i RANGE 0 ${_sipSplitGeneratedCode} )
    if( ${_i} LESS ${_sipSplitGeneratedCode} )
      set(_sipOutputFiles ${_sipOutputFiles} "${CMAKE_CURRENT_BINARY_DIR}${sip_gensrc_subdir}/sip${_moduleName}part${_i}.cpp" )
    endif( ${_i} LESS ${_sipSplitGeneratedCode} )
  endforeach( _i RANGE 0 ${_sipSplitGeneratedCode} )

  # Build include options according to _SIP_INCLUDE
  set( _sipIncludeOptions )
  set( _sipDeps )
  set( PY_SIP_INCLUDE_DIRECTORIES "[" )
  set( _sep "" )
  foreach( _i ${_SIP_INCLUDE} )
    set( _sipIncludeOptions ${_sipIncludeOptions} -I "${_i}" )
    set( PY_SIP_INCLUDE_DIRECTORIES
         "${PY_SIP_INCLUDE_DIRECTORIES}${_sep}\"${_i}\"" )
    set( _sep ", " )
    file( GLOB _j "${_i}/*.sip" )
    list( APPEND _sipDeps ${_j} )
  endforeach( _i ${_SIP_INCLUDE} )
  set( PY_SIP_INCLUDE_DIRECTORIES "${PY_SIP_INCLUDE_DIRECTORIES}]" )
  # this will be many many dependencies,
  # but we cannot know the exact correct ones.
  list( REMOVE_DUPLICATES _sipDeps )

  # Add rule to generate C++ code with sip
  if( SIP_VERSION VERSION_GREATER_EQUAL "6.0.0" )

    set( sip_build_dir "${CMAKE_CURRENT_BINARY_DIR}" )
    # re-symlink all .sip files in build dir
    file( GLOB _sip_src "${CMAKE_BINARY_DIR}/${_SIP_INSTALL}/*.sip" )
    get_filename_component( _bname "${_mainSipFile}" NAME )
    file( REAL_PATH "${_mainSipFile}" _mainSipFullFile )
    execute_process( COMMAND cmake -E create_symlink "${_mainSipFullFile}" "${sip_build_dir}/${_bname}" )

#     message("CREATE PYPROJECT from: ${brainvisa-cmake_DIR}/../share/pyproject.toml.in to: ${sip_build_dir}/pyproject.toml")
    if( EXISTS "${brainvisa-cmake_DIR}/../share/pyproject.toml.in" )
      get_property( INCLUDE_DIRECTORIES DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES )
      # pythonize list
      set( PY_INCLUDE_DIRECTORIES "[" )
      set( _sep "" )
      foreach( _i ${INCLUDE_DIRECTORIES} )
        set( PY_INCLUDE_DIRECTORIES "${PY_INCLUDE_DIRECTORIES}${_sep}\"${_i}\"" )
        set( _sep ", " )
      endforeach()
      set( PY_INCLUDE_DIRECTORIES "${PY_INCLUDE_DIRECTORIES}]" )
      if( DESIRED_QT_VERSION EQUAL 6 )
        set( SIP_QT_VERSION Qt_6 )
      elseif( DESIRED_QT_VERSION EQUAL 5 )
        set( SIP_QT_VERSION Qt_5 )
      endif()
#       get_property( LINK_DIRECTORIES DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY LINK_DIRECTORIES )
#       configure_file( "pyproject.toml.in"
#                       "${CMAKE_CURRENT_BINARY_DIR}/sip/pyproject.toml"
#                       USE_SOURCE_PERMISSIONS )
      set( SIP_NUM_OUTPUT_FILES ${_sipSplitGeneratedCode} )
      set( SIP_MODULE_NAME ${_moduleName} )
      get_filename_component( SIP_MAIN_SOURCE ${_mainSipFile} NAME_WE )
      configure_file( "${brainvisa-cmake_DIR}/../share/pyproject.toml.in"
                      "${sip_build_dir}/pyproject.toml"
                      USE_SOURCE_PERMISSIONS )
    endif()

    if( ${SIP4MAKE_EXECUTABLE} STREQUAL ${SIP_EXECUTABLE} )
      # use regular sip
      add_custom_command(
        OUTPUT ${_sipOutputFiles}
        # Sip can generate less files than requested. The touch
        # command make sure that all the files are created (necessary)
        # for dependencies).
        COMMAND "${CMAKE_COMMAND}" -E remove ${_sipOutputFiles}
        COMMAND "${SIP_EXECUTABLE}" "--no-compile"
        COMMAND "${CMAKE_COMMAND}" -E touch ${_sipOutputFiles}
        DEPENDS ${copied_sip_files}
        DEPENDS ${_sipDeps}
        WORKING_DIRECTORY "${sip_build_dir}"
      )
    else()
      # use bv_sip4make, taking care of creating the expected number of files
      add_custom_command(
        OUTPUT ${_sipOutputFiles}
        COMMAND "${SIP4MAKE_EXECUTABLE}"
                -S "${SIP_EXECUTABLE}"
                -c "${CMAKE_CURRENT_BINARY_DIR}${sip_gensrc_subdir}"
                -j ${_sipSplitGeneratedCode}
                "--no-compile"
        DEPENDS ${copied_sip_files}
        DEPENDS ${_sipDeps}
        WORKING_DIRECTORY "${sip_build_dir}"
      )
    endif()

    add_definitions( -D_FORTIFY_SOURCE=2 -DSIP_PROTECTED_IS_PUBLIC
                     -Dprotected=public )

#   endif()
  else()

    if( DESIRED_QT_VERSION EQUAL 3 )
      set( _sipFlags "-t" "ALL" "-t" "WS_X11" "-t" "Qt_3_3_0" )
    else()
      string( REPLACE " " ";" _sipFlags
        "${PYQT${DESIRED_QT_VERSION}_SIP_FLAGS}" )
    endif()
    set( _sipFlags ${SIP_FLAGS} ${_sipFlags} )
    if( ${SIP4MAKE_EXECUTABLE} STREQUAL ${SIP_EXECUTABLE} )
      # use regular sip
      add_custom_command(
        OUTPUT ${_sipOutputFiles}
        # Sip can generate less files than requested. The touch
        # command make sure that all the files are created (necessary)
        # for dependencies).
        COMMAND "${CMAKE_COMMAND}" -E remove ${_sipOutputFiles}
        COMMAND "${SIP_EXECUTABLE}"
                -j ${_sipSplitGeneratedCode}
                ${_sipIncludeOptions}
                -c "${CMAKE_CURRENT_BINARY_DIR}"
                -e
                ${_sipFlags}
                -x VendorID -x Qt_STYLE_WINDOWSXP -x Qt_STYLE_INTERLACE
                ${_mainSipFile}
        COMMAND "${CMAKE_COMMAND}" -E touch ${_sipOutputFiles}
        DEPENDS ${copied_sip_files}
        DEPENDS ${_sipDeps}
      )
    else()
      # use bv_sip4make, taking care of creating the expected number of files
      add_custom_command(
        OUTPUT ${_sipOutputFiles}
        COMMAND "${SIP4MAKE_EXECUTABLE}"
                -S "${SIP_EXECUTABLE}"
                -j ${_sipSplitGeneratedCode}
                ${_sipIncludeOptions}
                -c "${CMAKE_CURRENT_BINARY_DIR}"
                -e
                ${_sipFlags}
                -x VendorID -x Qt_STYLE_WINDOWSXP -x Qt_STYLE_INTERLACE
                ${_mainSipFile}
        DEPENDS ${copied_sip_files}
        DEPENDS ${_sipDeps}
      )
    endif()
  endif()

  # Create library with sip generated files
  include_directories( BEFORE ${SIP_INCLUDE_DIR} )
  add_library( ${_moduleName} MODULE ${_sipOutputFiles} )
  set_target_properties( ${_moduleName} PROPERTIES
                LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${PYTHON_INSTALL_DIRECTORY}/${_modulePath}"
                PREFIX "" )
  if( WIN32 )
    set_target_properties( ${_moduleName} PROPERTIES SUFFIX ".pyd" )
  endif( WIN32 )
  if( PYTHON_FLAGS )
    #message("===== ADD python flags definitions for ${_moduleName} =====")
    set_target_properties( ${_moduleName} PROPERTIES COMPILE_DEFINITIONS ${PYTHON_FLAGS} )
  endif()
  BRAINVISA_INSTALL( TARGETS ${_moduleName}
                     DESTINATION "${PYTHON_INSTALL_DIRECTORY}/${_modulePath}"
                     COMPONENT ${PROJECT_NAME} )
endmacro( BRAINVISA_ADD_SIP_PYTHON_MODULE _moduleName _modulePath _installComponent _installComponentDevel _sipSplitGeneratedCode _mainSipFile )


function( BRAINVISA_CREATE_CMAKE_CONFIG_FILES )
  string( TOUPPER "${PROJECT_NAME}" PROJECT_NAME_UPPER )
  set( _prefixForCmakeFiles "share/${PROJECT_NAME}-${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}/cmake" )
  configure_file( cmake/${PROJECT_NAME}-config.cmake.in
                  "${CMAKE_BINARY_DIR}/${_prefixForCmakeFiles}/${PROJECT_NAME}-config.cmake"
                  @ONLY )
  set( _to_install 
        "${CMAKE_BINARY_DIR}/${_prefixForCmakeFiles}/${PROJECT_NAME}-config.cmake"
        "${CMAKE_BINARY_DIR}/${_prefixForCmakeFiles}/${PROJECT_NAME}-use.cmake" )
  if( EXISTS "${BRAINVISA_SOURCES_${PROJECT_NAME}}/cmake/${PROJECT_NAME}-config-version.cmake.in" )
    configure_file( "${BRAINVISA_SOURCES_${PROJECT_NAME}}/cmake/${PROJECT_NAME}-config-version.cmake.in"
                    "${CMAKE_BINARY_DIR}/${_prefixForCmakeFiles}/${PROJECT_NAME}-config-version.cmake"
                    @ONLY )
    set( _to_install ${_to_install} "${CMAKE_BINARY_DIR}/${_prefixForCmakeFiles}/${PROJECT_NAME}-config-version.cmake")
  elseif( EXISTS "${brainvisa-cmake_DIR}/brainvisa-cmake-config-version.cmake.in" )
    configure_file( "${brainvisa-cmake_DIR}/brainvisa-cmake-config-version.cmake.in"
                    "${CMAKE_BINARY_DIR}/${_prefixForCmakeFiles}/${PROJECT_NAME}-config-version.cmake"
                    @ONLY )
    set( _to_install ${_to_install} "${CMAKE_BINARY_DIR}/${_prefixForCmakeFiles}/${PROJECT_NAME}-config-version.cmake")
  endif()
  if( EXISTS "${BRAINVISA_SOURCES_${PROJECT_NAME}}/cmake/${PROJECT_NAME}-use.cmake.in" )
    configure_file( "${BRAINVISA_SOURCES_${PROJECT_NAME}}/cmake/${PROJECT_NAME}-use.cmake.in"
                    "${CMAKE_BINARY_DIR}/${_prefixForCmakeFiles}/${PROJECT_NAME}-use.cmake"
                    @ONLY )
  else()
    configure_file( "${brainvisa-cmake_DIR}/default-use.cmake.in"
                    "${CMAKE_BINARY_DIR}/${_prefixForCmakeFiles}/${PROJECT_NAME}-use.cmake"
                    @ONLY )
  endif()
  BRAINVISA_INSTALL( FILES
          ${_to_install}
          DESTINATION "${_prefixForCmakeFiles}"
          COMPONENT ${PROJECT_NAME}-dev )

endfunction()

# BRAINVISA_RESOLVE_SYMBOL_LIBRARIES
#   Resolve symbol library pathes. A list of library or symbol files is given in parameter, and the function gets the absolute path of these files,
#   check existance, and check that it is a symbol for dynamic library. If the file is a symbol file for dynamic library, try to find the matching
#   library file.
#
# Usage:
#
#   BRAINVISA_RESOLVE_SYMBOL_LIBRARIES( <output_variable> PATHS <list of library files> )
#
# Example:
#    find_package(LibXml2)
#    BRAINVISA_RESOLVE_SYMBOL_LIBRARIES( libxml2 ${LIBXML2_LIBRARIES} )
#
function( BRAINVISA_RESOLVE_SYMBOL_LIBRARIES output_variable )
  set(_argn ${ARGN})

  # Read options
  set( arg_index 0 )
  foreach( _arg ${_argn} )

    if( "${_arg}" STREQUAL "PATHS" )
      set(_currentarg "${_arg}")

    elseif( "${_currentarg}" STREQUAL "PATHS" )
      list( GET _argn ${arg_index} result )
      set( _paths ${_paths} ${result} )

    endif()

    math(EXPR arg_index "${arg_index} + 1")
  endforeach()

  set( result )
  foreach( lib ${_paths} )
    get_filename_component( real "${lib}" REALPATH )
    string(REGEX REPLACE "\\${CMAKE_SHARED_LIBRARY_SUFFIX}.*" "" realpathwe "${real}")
    get_filename_component(realnamewe "${realpathwe}" NAME)
    get_filename_component( realdir ${real} PATH )
    if( EXISTS "${real}" )
      if( WIN32)
        if( real MATCHES "${CMAKE_SHARED_LIBRARY_SUFFIX}${CMAKE_STATIC_LIBRARY_SUFFIX}" OR real MATCHES "${CMAKE_STATIC_LIBRARY_SUFFIX}" )
          # In this case, it necessary to get the real library file instead of symbols file
          if( NOT CMAKE_LIBTOOL )
            find_program( CMAKE_LIBTOOL NAMES dlltool )
          endif()
          if(CMAKE_LIBTOOL)
            execute_process( COMMAND "${CMAKE_LIBTOOL}" -I "${real}"
                             OUTPUT_VARIABLE _output OUTPUT_STRIP_TRAILING_WHITESPACE
                             ERROR_VARIABLE _error ERROR_STRIP_TRAILING_WHITESPACE
                             RESULT_VARIABLE _result )
            if(NOT _result)
              # In this case the file is a definition file, so we use the true dll path
              get_filename_component( realname "${_output}" NAME )

              # Try to find the exact library extracted from symbol file
              set(CMAKE_FIND_LIBRARY_PREFIXES_PREV ${CMAKE_FIND_LIBRARY_PREFIXES})
              set(CMAKE_FIND_LIBRARY_SUFFIXES_PREV ${CMAKE_FIND_LIBRARY_SUFFIXES})
              set(CMAKE_FIND_LIBRARY_PREFIXES "")
              set(CMAKE_FIND_LIBRARY_SUFFIXES "")
              find_library( _TMP_LIBRARY "${realname}" )
              set(CMAKE_FIND_LIBRARY_PREFIXES ${CMAKE_FIND_LIBRARY_PREFIXES_PREV})
              set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES_PREV})
              get_filename_component( real "${_TMP_LIBRARY}" REALPATH )
              unset( _TMP_LIBRARY CACHE )
            endif()

          # else()
            # file(GLOB real "${realdir}/../bin/${realnamewe}-*${CMAKE_SHARED_LIBRARY_SUFFIX}" "${realdir}/../bin/${realnamewe}${CMAKE_SHARED_LIBRARY_SUFFIX}")
            # get_filename_component(real "${real}" REALPATH )
          endif()
        endif()
        if( real MATCHES "${CMAKE_SHARED_LIBRARY_SUFFIX}" )
          set( result ${result} "${real}" )
        endif()
      endif()
    endif()
  endforeach()
  set( ${output_variable} ${result} PARENT_SCOPE )
endfunction()

# BRAINVISA_INSTALL_RUNTIME_LIBRARIES
#   Checks and creates install rules for the libraries of the given component.
#   A list of library files is given in parameter, and the function gets the absolute path of these files, check existance,
#   and check that it is a dynamic library. The library files are set in an install rule for the component.
#   The symlinks that point to the library are found and created in the install directory via a custom command attached to the install target of the component.
#
# Usage:
#
#   BRAINVISA_INSTALL_RUNTIME_LIBRARIES( <component> <list of library files> )
#
# Example:
#    find_package(LibXml2)
#    BRAINVISA_INSTALL_RUNTIME_LIBRARIES( libxml2 ${LIBXML2_LIBRARIES} )
#
function( BRAINVISA_INSTALL_RUNTIME_LIBRARIES component )
  set(args ${ARGN})
  set(destination "lib")
  list( FIND args DESTINATION result )
  if( NOT result EQUAL -1 )
    math(EXPR index_dest "${result} + 1")
    list(GET args ${index_dest} destination)
    list(REMOVE_AT args ${result} ${index_dest})
  endif()

  set( librariesToInstall )
  foreach( lib ${args} )
    set( macFramework "" )
    if( APPLE )
      get_filename_component( olib "${lib}" EXT )
      if( "${olib}" STREQUAL ".framework" )
        # get_filename_component( olib "${lib}" NAME_WE )
        # set( lib "${lib}/${olib}" )
        set( macFramework "1" )
      endif()
    endif()
    get_filename_component( real "${lib}" REALPATH )
    get_filename_component( realname "${real}" NAME )
    get_filename_component( ext "${lib}" EXT )
    string(REGEX REPLACE "\\${CMAKE_SHARED_LIBRARY_SUFFIX}.*" "" realpathwe "${real}")
    get_filename_component(realnamewe "${realpathwe}" NAME)
    get_filename_component(realdir ${real} PATH)
    get_filename_component( name "${lib}" NAME_WE)
    get_filename_component( dirname "${lib}" PATH)
    if(EXISTS "${real}")
      # check if it is a dynamic library: if it is a static library, no need to package it.
      if( WIN32 )
        # On windows, in some cases, files with static extension can be symbol files
        BRAINVISA_RESOLVE_SYMBOL_LIBRARIES( real PATHS "${lib}" )
        #message("WIN32 resolved library: ${lib} --> ${real}")
      elseif( ext MATCHES ${CMAKE_SHARED_LIBRARY_SUFFIX} OR macFramework )
        # Recreate in the lib install directory the symlinks on the library file
        if( UNIX OR APPLE )
          # get the link with version number
          if( ${macFramework} )
            file( GLOB othernames "${lib}" )
          else()
            # in case the realname of the lib is not the same as the link name, search with 2 glob expressions
            # ex: libsqlite3.so and libsqlite3-3.6.2.so.0
            if(realnamewe STREQUAL name)
              if(NOT realdir STREQUAL dirname)
                file(GLOB othernames "${lib}*"
                  "${realdir}/${realnamewe}${ext}*"
                  "${realdir}/${realnamewe}.*${ext}")
              else()
                file( GLOB othernames "${lib}*"
                  "${realdir}/${realnamewe}.*${ext}")
              endif()
            else()
              #message("search glob expressions : ${lib}* ${realdir}/${realnamewe}${ext}*")
              file( GLOB othernames "${lib}*"
                "${realdir}/${realnamewe}${ext}*"
                "${realdir}/${realnamewe}.*${ext}"
                "${realdir}/${name}${ext}*"
                "${realdir}/${name}.*${ext}" )
            endif()
          endif()
          list( REMOVE_DUPLICATES othernames )
          # message("othernames of the lib ${real} in ${realdir}/${realnamewe}:" )
          # message( "othernames : ${othernames}")
          # create linknames list to store the processed link names to avoid create several times the same link
          set(linknames)
          foreach(link ${othernames})
            get_filename_component(linkname ${link} NAME)
            list(FIND linknames ${linkname} link_found)
            # check it is a new linkname
            if(link_found EQUAL -1)
              list(APPEND linknames ${linkname})
              get_filename_component(linkreal ${link} REALPATH)
	      # if it is really a symlink and it has a name different from the name of the lib and the link points to the real library
              if(NOT link STREQUAL linkreal AND NOT linkname STREQUAL realname AND linkreal STREQUAL real)
                add_custom_command( TARGET install-${component} POST_BUILD
                        COMMAND if [ -n \"$(BRAINVISA_INSTALL_PREFIX)\" ] \; then cd "$(BRAINVISA_INSTALL_PREFIX)/${destination}" && "${CMAKE_COMMAND}" -E create_symlink "${realname}" "${linkname}" \; else cd "${CMAKE_INSTALL_PREFIX}/${destination}" && "${CMAKE_COMMAND}" -E create_symlink "${realname}" "${linkname}" \; fi )
                #message("Create symlink $(BRAINVISA_INSTALL_PREFIX)/${destination}/${linkname} -> $(BRAINVISA_INSTALL_PREFIX)/${destination}/${realname}")
              endif()
            endif()
          endforeach()
        endif()
        if ( NOT real )
          message( "WARNING: Cannot find valid library files for ${lib}." )
        endif()
      else()
        unset( real )
      endif()

      if ( real )
        set( librariesToInstall ${librariesToInstall} "${real}" )
      endif()

    else()
      message( "WARNING: Cannot install non existing library file ${lib}." )
    endif()
  endforeach()
  # install libraries
  #message("libraries to install : ${librariesToInstall}")
  if( macFramework )
    BRAINVISA_INSTALL( DIRECTORY ${librariesToInstall}
        DESTINATION "${destination}"
        COMPONENT "${component}"
        USE_SOURCE_PERMISSIONS )
  else()
    BRAINVISA_INSTALL( FILES ${librariesToInstall}
        DESTINATION "${destination}"
        COMPONENT "${component}"
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE )
  endif()
endfunction( BRAINVISA_INSTALL_RUNTIME_LIBRARIES )

# BRAINVISA_ADD_TRANSLATION
#   Search recursively qt linguist source files (*.ts) in the directory source share directory
#   and generates the commands to create the associated *.qm files in the build share directory
#   and creates associated install rules.
#
# Usage:
#
#   BRAINVISA_ADD_TRANSLATION( <name of the source share directory where finding the *.ts files> <name of the destination share directory where writing the *.qm files> <component> [source directory to search c++ files] )
#
function( BRAINVISA_ADD_TRANSLATION source_share_dir dest_share_dir component)

  list( LENGTH ARGN nargs )
  if( ${nargs} EQUAL 1 )
    list( GET ARGN 0 source_cpp_dir )
  else()
    set( source_cpp_dir "${CMAKE_CURRENT_SOURCE_DIR}/${source_share_dir}/.." )
  endif()

  file(GLOB_RECURSE TR_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/${source_share_dir}/po/*.ts")
  file( GLOB_RECURSE CPP_SOURCES "${source_cpp_dir}/*.ui" "${source_cpp_dir}/*.c" "${source_cpp_dir}/*.c++" "${source_cpp_dir}/*.cc" "${source_cpp_dir}/*.cpp" "${source_cpp_dir}/*.cxx" "${source_cpp_dir}/*.ch" "${source_cpp_dir}/*.h" "${source_cpp_dir}/*.h++" "${source_cpp_dir}/*.hh" "${source_cpp_dir}/*.hpp" "${source_cpp_dir}/*.hxx" )
  set( TRANSLATION_FILES )
  set( TR_BUILD )
  foreach(tr_source ${TR_SOURCES})
    file(RELATIVE_PATH tr_relative_name "${CMAKE_CURRENT_SOURCE_DIR}/${source_share_dir}/po" ${tr_source})
    get_filename_component(tr_relative_path ${tr_relative_name} PATH)
    set( lang "${tr_relative_path}" )
    get_filename_component( tr_name ${tr_source} NAME_WE )
    set( tr_dst "${CMAKE_BINARY_DIR}/${dest_share_dir}/po/${tr_relative_path}/${tr_name}_updated.ts" )
    set( rel_tr_dst "${dest_share_dir}/po/${tr_relative_path}/${tr_name}_updated.ts" )
    set( qm_dst "${CMAKE_BINARY_DIR}/${dest_share_dir}/po/${tr_relative_path}/${tr_name}.qm" )
    set_source_files_properties(${tr_dst} PROPERTIES OUTPUT_LOCATION "${CMAKE_BINARY_DIR}/${dest_share_dir}/po/${tr_relative_path}")
    list( APPEND TRANSLATION_FILES "${qm_dst}" )
    list( APPEND TR_BUILD "${tr_dst}" )

    # copied and adapted from FindQt4.cmake
    # make a .pro file to call lupdate on, so we don't make our commands too
    # long for some systems
    SET(_ts_pro ${CMAKE_BINARY_DIR}/${dest_share_dir}/po/${tr_relative_path}/${tr_name}_lupdate.pro)
    SET(_pro_srcs)
    FOREACH(_pro_src ${CPP_SOURCES})
      SET(_pro_srcs "${_pro_srcs} \"${_pro_src}\"")
    ENDFOREACH()
    FILE(WRITE ${_ts_pro} "SOURCES = ${_pro_srcs}")
    set( _lupdate_options -source-language "${lang}" -noobsolete )
    ADD_CUSTOM_COMMAND(OUTPUT "${tr_dst}" "${qm_dst}"
        COMMAND "${CMAKE_COMMAND}" ARGS -E copy "${tr_source}" "${tr_dst}"
        COMMAND "${QT_LUPDATE_EXECUTABLE}"
        ARGS ${_lupdate_options} "${_ts_pro}" -ts "${tr_dst}"
        COMMAND ${QT_LRELEASE_EXECUTABLE}
        ARGS ${tr_dst} -qm ${qm_dst}
        DEPENDS ${CPP_SOURCES} "${_ts_pro}" "${tr_source}" )
  endforeach()
  # QT4_ADD_TRANSLATION( TRANSLATION_FILES "${TR_BUILD}" )
  # BRAINVISA_GENERATE_TARGET_NAME(TRANSLATION_TARGET)
  add_custom_target(${component}-translation ALL
      DEPENDS ${TRANSLATION_FILES} ${TR_SOURCES} ${CPP_SOURCES} )
  foreach(tr_file ${TRANSLATION_FILES})
    file(RELATIVE_PATH tr_relative_name "${CMAKE_BINARY_DIR}/${dest_share_dir}/po" ${tr_file})
    get_filename_component(tr_relative_path ${tr_relative_name} PATH)
    BRAINVISA_INSTALL( FILES "${tr_file}"
      DESTINATION "${dest_share_dir}/po/${tr_relative_path}"
      COMPONENT ${component} )
  endforeach()
endfunction()


# BRAINVISA_ADD_PYTRANSLATION
#   Search recursively PyQt linguist source files (*.ts) generated from python
#   (PyQt) sources, in the directory source share directory
#   and generates the commands to create the associated *.qm files in the build
#   share directory and creates associated install rules.
#
# Usage:
#
#   BRAINVISA_ADD_PYTRANSLATION( <name of the source share directory where finding the *.ts files> <name of the destination share directory where writing the *.qm files> <component> [source directory to search python files] )
#
function( BRAINVISA_ADD_PYTRANSLATION source_share_dir dest_share_dir component)

  if( PYQT4_PYLUPDATE_EXECUTABLE )
    list( LENGTH ARGN nargs )
    if( ${nargs} EQUAL 1 )
      list( GET ARGN 0 source_py_dir )
    else()
      set( source_py_dir "${CMAKE_CURRENT_SOURCE_DIR}/${source_share_dir}/../python" )
    endif()

    file(GLOB_RECURSE TR_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/${source_share_dir}/po/*.ts")
    file( GLOB_RECURSE PY_SOURCES "${source_py_dir}/*.py" )
    file( GLOB_RECURSE UI_SOURCES "${source_py_dir}/*.ui" )
    set( TRANSLATION_FILES )
    set( TR_BUILD )
    foreach(tr_source ${TR_SOURCES})
      file(RELATIVE_PATH tr_relative_name "${CMAKE_CURRENT_SOURCE_DIR}/${source_share_dir}/po" ${tr_source})
      get_filename_component(tr_relative_path ${tr_relative_name} PATH)
      set( lang "${tr_relative_path}" )
      get_filename_component( tr_name ${tr_source} NAME_WE )
      set( tr_dst "${CMAKE_BINARY_DIR}/${dest_share_dir}/po/${tr_relative_path}/${tr_name}_updated.ts" )
      set( rel_tr_dst "${dest_share_dir}/po/${tr_relative_path}/${tr_name}_updated.ts" )
      set( qm_dst "${CMAKE_BINARY_DIR}/${dest_share_dir}/po/${tr_relative_path}/${tr_name}.qm" )
      set_source_files_properties(${tr_dst} PROPERTIES OUTPUT_LOCATION "${CMAKE_BINARY_DIR}/${dest_share_dir}/po/${tr_relative_path}")
      list( APPEND TRANSLATION_FILES "${qm_dst}" )
      list( APPEND TR_BUILD "${tr_dst}" )

      # copied and adapted from FindQt4.cmake
      # make a .pro file to call pylupdate on, so we don't make our commands too
      # long for some systems
      SET(_ts_pro ${CMAKE_BINARY_DIR}/${dest_share_dir}/po/${tr_relative_path}/${tr_name}_pylupdate.pro)
      SET(_pro_srcs)
      FOREACH(_pro_src ${PY_SOURCES})
        SET(_pro_srcs "${_pro_srcs} ${_pro_src} \\\n")
      ENDFOREACH()
      SET(_pro_uis)
      FOREACH(_pro_src ${UI_SOURCES})
        SET(_pro_uis "${_pro_uis} ${_pro_src} \\\n")
      ENDFOREACH()
      FILE(WRITE ${_ts_pro} "SOURCES = ${_pro_srcs}\n")
      if( UI_SOURCES )
        file( APPEND ${_ts_pro} "FORMS = ${_pro_uis}\n" )
      endif()
      file( APPEND ${_ts_pro} "TRANSLATIONS = ${tr_dst}\n" )
      ADD_CUSTOM_COMMAND(OUTPUT "${tr_dst}" "${qm_dst}"
          COMMAND "${CMAKE_COMMAND}" ARGS -E copy "${tr_source}" "${tr_dst}"
          COMMAND "${PYQT4_PYLUPDATE_EXECUTABLE}"
          ARGS -noobsolete "${_ts_pro}"
          COMMAND ${QT_LRELEASE_EXECUTABLE}
          ARGS ${tr_dst} -qm ${qm_dst}
          DEPENDS ${PY_SOURCES} ${UI_SOURCES} "${_ts_pro}" "${tr_source}" )
    endforeach()
    # QT4_ADD_TRANSLATION( TRANSLATION_FILES "${TR_BUILD}" )
    # BRAINVISA_GENERATE_TARGET_NAME(TRANSLATION_TARGET)
    add_custom_target(${component}-translation ALL
        DEPENDS ${TRANSLATION_FILES} ${TR_SOURCES} ${PY_SOURCES} ${UI_SOURCES} )
    foreach(tr_file ${TRANSLATION_FILES})
      file(RELATIVE_PATH tr_relative_name "${CMAKE_BINARY_DIR}/${dest_share_dir}/po" ${tr_file})
      get_filename_component(tr_relative_path ${tr_relative_name} PATH)
      BRAINVISA_INSTALL( FILES "${tr_file}"
        DESTINATION "${dest_share_dir}/po/${tr_relative_path}"
        COMPONENT ${component} )
    endforeach()
  endif() # PYQT4_PYLUPDATE_EXECUTABLE found
endfunction()


# BRAINVISA_FIND_FSENTRY
#   Find file system entries from PATHS using search PATTERNS.
#
# Usage:
#
#   BRAINVISA_FIND_FSENTRY( output_variable PATTERNS [ <pattern> ... ] PATHS [ <path> ... ] )
#
# Example:
#    BRAINVISA_FIND_FSENTRY( real_files PATTERNS *.so PATHS /usr/lib/ )
#    foreach( file ${real_files} )
#      message( "${file}" )
#    endforeach()
function( BRAINVISA_FIND_FSENTRY output_variable )
  set(_argn ${ARGN})

  # Read options
  set( arg_index 0 )
  foreach( _arg ${_argn} )

    if( "${_arg}" STREQUAL "PATTERNS" OR
        "${_arg}" STREQUAL "PATHS" )
      set(_currentarg "${_arg}")

    elseif( "${_currentarg}" STREQUAL "PATTERNS" )
      list( GET _argn ${arg_index} result )
      set( _patterns ${_patterns} ${result} )

    elseif( "${_currentarg}" STREQUAL "PATHS" )
      list( GET _argn ${arg_index} result )
      set( _paths ${_paths} ${result} )

    endif()

    math(EXPR arg_index "${arg_index} + 1")
  endforeach()

  # Set default option values
  list( LENGTH _patterns _len)
  if( _len EQUAL 0 )
    set( _patterns "*" )
  endif()

  list( LENGTH _paths _len)
  if( _len EQUAL 0 )
    set( _paths "${CMAKE_CURRENT_SOURCE_DIR}" $ENV{PATH} )
  endif()

  set( result )
  foreach( _path ${_paths} )
    string( LENGTH "${_path}" _path_len )
    foreach( _pattern ${_patterns} )
      string( LENGTH "${_pattern}" _pattern_len )
      if ( _path_len EQUAL 0 )
        set( _path "${_pattern}" )
      elseif ( _pattern_len EQUAL 0 )
        set( _path "${_path}" )
      else()
        set( _path "${_path}/${_pattern}" )
      endif()
      file( TO_CMAKE_PATH "${_path}" _path )
      file( GLOB glob_result "${_path}" )

      BRAINVISA_REAL_PATHS( _realpaths ${glob_result} )
      foreach( _realpath ${_realpaths} )
        list( FIND result ${_realpath} _pathfound )
        if( _pathfound EQUAL -1 )
          set( result ${result} "${_realpath}" )
        endif()
      endforeach()
    endforeach()
  endforeach()
  set( ${output_variable} ${result} PARENT_SCOPE )
endfunction()


# BRAINVISA_PYUIC
#   Run pyside-uic / pyuic4 / pyuic on a .ui file to generate the
#   corresponding .py module
#
# Usage:
#
#   BRAINVISA_PYUIC( <source_ui_file> <dest_py_file> <relative_path> <dest_path> )
#
function( BRAINVISA_PYUIC source_ui_file dest_py_file relative_path dest_path )
  if( PYUIC )
    BRAINVISA_GENERATE_TARGET_NAME( target )
    # ensure the working directory will exist
    file( MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/${dest_path}" )
    add_custom_command(
      OUTPUT "${dest_py_file}"
      COMMAND ${PYUIC} -o "${dest_py_file}" "${CMAKE_CURRENT_SOURCE_DIR}/${relative_path}/${source_ui_file}"
      WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/${dest_path}"
      DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${relative_path}/${source_ui_file}"
    )
    add_custom_target( ${target} ALL
      DEPENDS "${dest_py_file}"
      WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/${dest_path}"
    )
    BRAINVISA_INSTALL( FILES
        "${CMAKE_BINARY_DIR}/${dest_path}/${dest_py_file}"
      DESTINATION ${dest_path}
      COMPONENT ${PROJECT_NAME} )
  endif()
endfunction()

# BRAINVISA_QT_WRAP_UI
#   Works like QT4_WRAP_UI, but in addition, the directory of
#   generated files is user-defined (<input_outdir>).
#
# Usage:
#
#   BRAINVISA_QT_WRAP_UI( <outfiles> <inputfile> <input_outdir> )
#
MACRO ( BRAINVISA_QT_WRAP_UI outfiles inputfiles input_outdir )
  set(_old_dir "${CMAKE_CURRENT_BINARY_DIR}")
  set(CMAKE_CURRENT_BINARY_DIR "${input_outdir}")
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
  if( DESIRED_QT_VERSION EQUAL 4 )
    QT4_WRAP_UI(${outfiles} ${inputfiles})
  elseif( DESIRED_QT_VERSION EQUAL 5 )
    qt5_wrap_ui(${outfiles} ${inputfiles})
  elseif( DESIRED_QT_VERSION EQUAL 6 )
    qt6_wrap_ui(${outfiles} ${inputfiles})
  endif()
  set(CMAKE_CURRENT_BINARY_DIR ${_old_dir})
ENDMACRO()

# compatibility function. Obsolete. Use BRAINVISA_QT_WRAP_UI instead.
MACRO ( BRAINVISA_QT4_WRAP_UI outfiles inputfiles input_outdir )
  BRAINVISA_QT_WRAP_UI( ${outfiles} ${inputfiles} ${input_outdir} )
ENDMACRO()

