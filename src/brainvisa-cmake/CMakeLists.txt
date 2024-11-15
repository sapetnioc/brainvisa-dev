
if( BRAINVISA_BVMAKER )
  # in BV mode, force CMAKE_INSTALL_PREFIX to point to build directory
  set( CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR} )
endif()

cmake_policy( SET CMP0048 NEW )
project( brainvisa-cmake LANGUAGES CXX VERSION 1.0 )

cmake_minimum_required( VERSION 3.20 )

function( BRAINVISA_GLOB_AND_FILTER glob variable )
  file( ${glob} allFiles ${ARGN} )
  set( result )
  foreach( f ${allFiles} )
    get_filename_component( n "${f}" NAME )
    if ( NOT IS_DIRECTORY "${f}" AND NOT n STREQUAL ".svn" )
      set( result ${result} "${f}" )
    endif ()
  endforeach()
  set( ${variable} ${result} PARENT_SCOPE )
endfunction()


include( "${CMAKE_CURRENT_SOURCE_DIR}/cmake/project_info.cmake" )
install( FILES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/project_info.cmake"
         DESTINATION "python/brainvisa_cmake"
         COMPONENT brainvisa-cmake )

set( brainvisa-cmake_INSTALL_PREFIX "share/brainvisa-cmake-${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}" )

install( FILES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/brainvisa-cmake-config.cmake"
               "${CMAKE_CURRENT_SOURCE_DIR}/cmake/brainvisa-cmake-config-version.cmake"
         DESTINATION "${brainvisa-cmake_INSTALL_PREFIX}/cmake"
         COMPONENT brainvisa-cmake )
foreach( _dir cmake cmake/specific cmake/specific/linux_distribution 
              cmake/specific/windows cmake/specific/windows/mingw32 
              cmake/specific/windows/i686-w64-mingw32 )
  file( GLOB _files "${CMAKE_CURRENT_SOURCE_DIR}/${_dir}/*.cmake" )
  install( FILES ${_files}
           DESTINATION "${brainvisa-cmake_INSTALL_PREFIX}/${_dir}"
           COMPONENT brainvisa-cmake )
endforeach()
file( GLOB _files "${CMAKE_CURRENT_SOURCE_DIR}/cmake/*.in" )
install( FILES ${_files}
         DESTINATION "${brainvisa-cmake_INSTALL_PREFIX}/cmake"
         COMPONENT brainvisa-cmake )
install( FILES cmake/CMakeLists.txt
         DESTINATION "${brainvisa-cmake_INSTALL_PREFIX}/cmake"
         COMPONENT brainvisa-cmake )
file( GLOB _files "${CMAKE_CURRENT_SOURCE_DIR}/cmake/*.py" )
install( FILES ${_files}
         DESTINATION "${brainvisa-cmake_INSTALL_PREFIX}/cmake"
         PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
         COMPONENT brainvisa-cmake )
file( GLOB _files "${CMAKE_CURRENT_SOURCE_DIR}/share/*.in" )
install( FILES ${_files}
         DESTINATION "${brainvisa-cmake_INSTALL_PREFIX}/share"
         COMPONENT brainvisa-cmake )

BRAINVISA_GLOB_AND_FILTER( GLOB _files "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules/*[^~]" )
install( FILES ${_files}
         DESTINATION "${brainvisa-cmake_INSTALL_PREFIX}/cmake/modules"
         COMPONENT brainvisa-cmake )

install( DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules/test_programs"
         DESTINATION "${brainvisa-cmake_INSTALL_PREFIX}/cmake/modules"
         USE_SOURCE_PERMISSIONS
         COMPONENT brainvisa-cmake
         PATTERN ".svn" EXCLUDE
         PATTERN "*~" EXCLUDE )

BRAINVISA_GLOB_AND_FILTER( GLOB_RECURSE _files 
                           RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
                           "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/*[^~]" )
foreach(_f ${_files})
    get_filename_component(_d "${_f}" PATH)
    install( FILES "${CMAKE_CURRENT_SOURCE_DIR}/${_f}"
             DESTINATION "${brainvisa-cmake_INSTALL_PREFIX}/${_d}"
             COMPONENT brainvisa-cmake )
endforeach()

BRAINVISA_GLOB_AND_FILTER( GLOB _files "${CMAKE_CURRENT_SOURCE_DIR}/scripts/*[^~]" )
install( FILES ${_files}
         DESTINATION "${brainvisa-cmake_INSTALL_PREFIX}/scripts"
         COMPONENT brainvisa-cmake )

BRAINVISA_GLOB_AND_FILTER( GLOB _files "${CMAKE_CURRENT_SOURCE_DIR}/scripts/windows/*[^~]" )
install( FILES ${_files}
         DESTINATION "${brainvisa-cmake_INSTALL_PREFIX}/scripts/windows"
         COMPONENT brainvisa-cmake )

# Packaging
set( PACKAGE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}" CACHE PATH "Installation path for debian package" )
configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/debian-control.in"
                "${CMAKE_BINARY_DIR}/debian-control"
                @ONLY )
set( packageName "${CMAKE_BINARY_DIR}/brainvisa-cmake-${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}.${BRAINVISA_PACKAGE_VERSION_PATCH}.deb" )
set( tmpDir "/tmp/brainvisa-cmake_create_deb" )
add_custom_command( OUTPUT "${packageName}"
  DEPENDS "${CMAKE_BINARY_DIR}/debian-control"
  COMMENT "Creating package \"${packageName}\""
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${tmpDir}"
  COMMAND ${CMAKE_COMMAND} -E make_directory "${tmpDir}"
  COMMAND ${CMAKE_COMMAND} -E make_directory "${tmpDir}/DEBIAN"
  COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_BINARY_DIR}/debian-control" "${tmpDir}/DEBIAN/control"
  COMMAND ${CMAKE_COMMAND} "-DCMAKE_INSTALL_PREFIX=${tmpDir}${PACKAGE_INSTALL_PREFIX}" -P "${CMAKE_BINARY_DIR}/cmake_install.cmake"
  COMMAND dpkg --build "${tmpDir}" "${packageName}"
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${tmpDir}"
)
add_custom_target( "deb-package" DEPENDS "${packageName}" )

if( DESIRED_QT_VERSION )
  add_definitions( -DDESIRED_QT_VERSION=${DESIRED_QT_VERSION} )
endif()

install( DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/python"
         DESTINATION "."
         USE_SOURCE_PERMISSIONS
         COMPONENT brainvisa-cmake
         PATTERN ".svn" EXCLUDE
         PATTERN "*~" EXCLUDE )

install( DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin"
         DESTINATION "."
         USE_SOURCE_PERMISSIONS
         COMPONENT brainvisa-cmake
         PATTERN "*~" EXCLUDE )

install( DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/etc"
         DESTINATION "."
         USE_SOURCE_PERMISSIONS
         COMPONENT brainvisa-cmake
         PATTERN "*~" EXCLUDE )

# Generate a list of all brainvisa-cmake installed files
# so that bv_maker can copy and already installed brainvisa-cmake
if( NOT DISABLE_FILE_INSTALLATION_LIST AND NOT BRAINVISA_BVMAKER )
  # Must remove the CMakeCache before configuring again brainvisa-cmake into a new tmp build directory,
  # else the source directory is considered as a build directory and the build files are not copied into tmp directory
  if( EXISTS "${CMAKE_BINARY_DIR}/CMakeCache.txt" )
    execute_process( COMMAND "${CMAKE_COMMAND}" -E remove "${CMAKE_BINARY_DIR}/CMakeCache.txt" )
  endif()
  set( tmp "${CMAKE_BINARY_DIR}/tmp" )
  execute_process( COMMAND "${CMAKE_COMMAND}" -E make_directory "${tmp}" )
  execute_process( COMMAND "${CMAKE_COMMAND}" -E make_directory "${tmp}/install" )
  execute_process( COMMAND "${CMAKE_COMMAND}"  "-G" "${CMAKE_GENERATOR}" -DDISABLE_FILE_INSTALLATION_LIST=YES "-DCMAKE_INSTALL_PREFIX:STRING=${tmp}/install" "${CMAKE_CURRENT_SOURCE_DIR}"
                  WORKING_DIRECTORY "${tmp}")
#                    OUTPUT_QUIET
#                    ERROR_QUIET )
  execute_process( COMMAND "${CMAKE_MAKE_PROGRAM}" install
                  WORKING_DIRECTORY "${tmp}")
#                    OUTPUT_QUIET
#                    ERROR_QUIET )
  file( GLOB_RECURSE installed_files RELATIVE "${tmp}/install" "${tmp}/install/*" )
  execute_process( COMMAND "${CMAKE_COMMAND}" -E remove_directory "${tmp}" )
  file( WRITE "${CMAKE_BINARY_DIR}/installed_files.txt" "" )
  foreach( i ${installed_files} )
    file( APPEND "${CMAKE_BINARY_DIR}/installed_files.txt" "${i}\n" )
  endforeach()
  install( FILES "${CMAKE_BINARY_DIR}/installed_files.txt"
          DESTINATION "python/brainvisa_cmake" )
endif()

if(NOT CPack_CMake_INCLUDED)
  include( CPack )
endif()

if( NOT TARGET install-runtime )
  cpack_add_component_group( runtime
                             DISPLAY_NAME "Runtime"
                             DESCRIPTION "All elements necessary to use ${PROJECT_NAME} at runtime without developpement files such as C++ headers." )
  add_custom_target( install-runtime )
endif()

if( NOT TARGET install-${PROJECT_NAME} )
  cpack_add_component( ${PROJECT_NAME} )
  add_custom_target( install-${PROJECT_NAME}
                     COMMAND if [ -n "$(BRAINVISA_INSTALL_PREFIX)" ] \; then "${CMAKE_COMMAND}" -DCMAKE_INSTALL_PREFIX="$(BRAINVISA_INSTALL_PREFIX)" -DCOMPONENT=${PROJECT_NAME} -P "${CMAKE_BINARY_DIR}/build_files/${PROJECT_NAME}/cmake_install.cmake" \; else "${CMAKE_COMMAND}" -DCOMPONENT=${PROJECT_NAME} -P "${CMAKE_BINARY_DIR}/build_files/${PROJECT_NAME}/cmake_install.cmake" \; fi )
  add_dependencies( install-runtime install-${PROJECT_NAME} )
endif()


# in the following we do more or less what brainvisa_project() does.

if( BRAINVISA_BVMAKER )

  BRAINVISA_PROJECT()
       
  find_package( Sphinx )
  find_package( python )

  BRAINVISA_GENERATE_SPHINX_DOC( "doc/sphinx"
    "share/doc/${PROJECT_NAME}-${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}" USER )

  file( GLOB _commands "${CMAKE_CURRENT_SOURCE_DIR}/bin/*[!%~]" )
  # disable help for some internal or undocumented commands
  set(__excluded_commands 
      bv_clean_jenkins
      bv_sendmail
      bv_sources_copyright)
   
  foreach( _command ${__excluded_commands} )
    set( ${_command}-help-generate FALSE CACHE INTERNAL
        "${_command} help must be generated")
  endforeach()
  
  # define an install rule for the python symlink
  if( NOT DEFINED PIXI )
    add_custom_target( install-brainvisa-cmake-python-symlink
                       COMMAND if [ -n "$(BRAINVISA_INSTALL_PREFIX)" ] \; then "${CMAKE_COMMAND}" "-E" "make_directory" "$(BRAINVISA_INSTALL_PREFIX)/bin" \; else "${CMAKE_COMMAND}" "-E" "make_directory" "${CMAKE_INSTALL_PREFIX}/bin" \; fi
                       COMMAND if [ -n "$(BRAINVISA_INSTALL_PREFIX)" ] \; then if [ \! -e "$(BRAINVISA_INSTALL_PREFIX)/bin/python" ]; then "${CMAKE_COMMAND}" "-E" "create_symlink" "${PYTHON_EXECUTABLE}" "$(BRAINVISA_INSTALL_PREFIX)/bin/python" \; fi else if [ \! -e "$(CMAKE_INSTALL_PREFIX)/bin/python" ]; then "${CMAKE_COMMAND}" "-E" "create_symlink" "${PYTHON_EXECUTABLE}" "${CMAKE_INSTALL_PREFIX}/bin/python" \; fi fi )
    add_dependencies( install-brainvisa-cmake install-brainvisa-cmake-python-symlink )
  endif()

endif()

