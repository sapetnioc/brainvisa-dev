if( EXISTS "${CMAKE_BINARY_DIR}/bv_maker.cmake" )
  include( "${CMAKE_BINARY_DIR}/bv_maker.cmake" NO_POLICY_SCOPE )
endif()

find_package( brainvisa-cmake NO_POLICY_SCOPE )

foreach( component ${BRAINVISA_COMPONENTS} )
  file( GLOB _share_list "${CMAKE_BINARY_DIR}/share/${component}-*" )
  foreach( _share ${_share_list} )
    get_filename_component(share_dir "${_share}/cmake" ABSOLUTE)
    get_filename_component(share_dir "${share_dir}" REALPATH)
    get_filename_component(component_dir "${${component}_DIR}" ABSOLUTE)
    get_filename_component(component_dir "${component_dir}" REALPATH)
    if( NOT "${share_dir}" STREQUAL "${component_dir}" )
      message( "WARNING: removing \"${_share}\" directory to avoid confusion with \"${component_dir}\"" )
      execute_process( COMMAND "${CMAKE_COMMAND}" -E remove_directory "${_share}" )
    endif()
  endforeach()
endforeach()

# Set default Qt desired version
set( DESIRED_QT_VERSION 5 CACHE STRING
     "Pick a version of QT to use: 3, 4, 5..." )

# Set default C preprocessor command
if(NOT CMAKE_C_PREPROCESSOR)
    # Assume default to GCC toolchain
    if (COMPILER_PREFIX)
        set(_toolchain_prefix "${COMPILER_PREFIX}-")
    endif()
    set(CMAKE_C_PREPROCESSOR "${_toolchain_prefix}cpp -C" CACHE STRING "C preprocessor command to use" )
endif()

# Set minimum C++ version
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set( BRAINVISA_BVMAKER TRUE )

add_custom_target( post-install )

set( CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} "${CMAKE_BINARY_DIR}" )
include_directories( "${CMAKE_BINARY_DIR}/include" )

BRAINVISA_CREATE_MAIN_COMPONENTS()

function( silent_execute_process working_directory )
  unset( command )
  unset( i )
  unset( j )
  unset( result )
  unset( output )
  unset( error )
  foreach( i ${ARGN} )
    foreach( j ${i} )
      set( command ${command} "${j}" )
    endforeach()
  endforeach()
  execute_process( COMMAND ${command}
    WORKING_DIRECTORY "${working_directory}"
    RESULT_VARIABLE result
    OUTPUT_QUIET 
    ERROR_QUIET
  )

  if( NOT result EQUAL 0 )
    message( "ERROR: command failed:${command}" )
    message( "       working directory = \"${working_directory}\"" )
    message( "---------- command output ----------"  )
    execute_process( COMMAND ${command} WORKING_DIRECTORY "${working_directory}" )
    message( "---------- end of command output ----------"  )
    message( FATAL_ERROR )
  endif()
endfunction()

# BRAINVISA_CMAKE_BUILD_TYPE variable may be used to specify whether to
# configure/install brainvisa-cmake, so as to bootstrap it (use it in a second
# cmake run after it is installed):
# if BRAINVISA_CMAKE_BUILD_TYPE == "brainvisa-cmake-only", do only
# bv-cmake config/installation
# if BRAINVISA_CMAKE_BUILD_TYPE == "no-brainvisa-cmake", do only other
# components configuration
# otherwise, do everything.
# This variabled may be passed to cmake commandline using
# -DBRAINVISA_CMAKE_BUILD_TYPE, it will not be stored in cache.

# First pass to configure brainvisa-cmake component
# if( NOT BRAINVISA_CMAKE_BUILD_TYPE
#   OR NOT BRAINVISA_CMAKE_BUILD_TYPE STREQUAL "no-brainvisa-cmake" )
#   list( FIND BRAINVISA_COMPONENTS brainvisa-cmake where )
#   if( where GREATER -1 )
#     set( component brainvisa-cmake )
#     if( BRAINVISA_SOURCES_${component} )
#       set( ${component}_IS_BEING_COMPILED TRUE CACHE BOOL INTERNAL )
#       message( STATUS "Configuring component ${component} from source directory \"${BRAINVISA_SOURCES_${component}}\"" )
#       file( MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/${component}" )
#       unset(opts)
#       set(opts "-D" "CMAKE_INSTALL_PREFIX:PATH=${CMAKE_BINARY_DIR}")
#       foreach(opt ${BRAINVISA_CMAKE_OPTIONS})
#         #message("Add ${opt}")
#         #message("${opt} value: ${${opt}}")

#         if ("${opt}" STREQUAL "CMAKE_INIT_CACHE")
#           set(opts ${opts} "-C" "${${opt}}")
#         else()
#           set(opts ${opts} "-D" "${opt}=${${opt}}")
#         endif()        
#       endforeach()
      
#       silent_execute_process( "${CMAKE_BINARY_DIR}/${component}" "${CMAKE_COMMAND}" "-G" "${CMAKE_GENERATOR}" ${opts} "${BRAINVISA_SOURCES_${component}}" )
#       silent_execute_process( "${CMAKE_BINARY_DIR}/${component}" "${CMAKE_BUILD_TOOL}" install )
#       set_property( GLOBAL PROPERTY BRAINVISA_CMAKE_CONFIG_DONE )
#       unset( brainvisa-cmake_DIR CACHE )
#       unset( brainvisa-cmake_DIR )
#       unset( opts )
#       unset( opt )
#       find_package( brainvisa-cmake )
#     endif()
#   endif()
# endif()

# if BRAINVISA_CMAKE_BUILD_TYPE is set to "brainvisa-cmake-only", do only the brainvisa-cmake configuration/installation.
# this option is used to bootstrap installing bv-cmake, then re-run cmake
if( NOT BRAINVISA_CMAKE_BUILD_TYPE
  OR NOT BRAINVISA_CMAKE_BUILD_TYPE STREQUAL "brainvisa-cmake-only" )

  # Second pass to configure all other components
  foreach( component ${BRAINVISA_COMPONENTS} )
#     if( NOT component STREQUAL brainvisa-cmake )
      if( BRAINVISA_SOURCES_${component} )
        set( ${component}_IS_BEING_COMPILED TRUE CACHE BOOL INTERNAL )
        if( EXISTS "${BRAINVISA_SOURCES_${component}}/broken_component.log" )
          message( "WARNING: Component ${component} is ignored because its compilation was not possible. When the problem is fixed, the component can be reactivated by removing \"${BRAINVISA_SOURCES_${component}}/broken_component.log\"" )
        else()
          message( STATUS "Configuring component ${component} from source directory \"${BRAINVISA_SOURCES_${component}}\"" )
          add_subdirectory( "${BRAINVISA_SOURCES_${component}}" "build_files/${component}" )
        endif()
      endif()
#     endif()
  endforeach()

  # Third pass to do post configuration
  foreach( component ${BRAINVISA_COMPONENTS} )
    if( NOT component STREQUAL brainvisa-cmake )
      if( BRAINVISA_SOURCES_${component} )
        if( EXISTS "${BRAINVISA_SOURCES_${component}}/CMakeLists_postconfig.txt" )
          message( STATUS "Post-configuring component ${component} from source directory \"${BRAINVISA_SOURCES_${component}}\"" )
          include( "${BRAINVISA_SOURCES_${component}}/CMakeLists_postconfig.txt" )
        endif()
      endif()
    endif()
  endforeach()

  if( BRAINVISA_DEPENDENCY_GRAPH )
    file( APPEND "${BRAINVISA_DEPENDENCY_GRAPH}" "}\n" )
  endif()

  enable_testing()

endif()

unset( BRAINVISA_CMAKE_BUILD_TYPE CACHE )
