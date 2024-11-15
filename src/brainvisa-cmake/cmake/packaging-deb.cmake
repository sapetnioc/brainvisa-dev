set( BRAINVISA_PACKAGING_TEMPORARY_DIRECTORY "/tmp" CACHE PATH "Temporary directory used to create packages" )

function( BRAINVISA_VALID_DEBIAN_PACKAGE_NAME package_name output_variable )
  string( REPLACE "_" "-" result "${package_name}" )
  set( ${output_variable} "${result}" PARENT_SCOPE )
endfunction()

function( BRAINVISA_DEBIAN_ARCHITECTURE output_variable )
  execute_process( COMMAND apt-config dump RESULT_VARIABLE result OUTPUT_VARIABLE output )
  if( result GREATER -1 )
    string( REGEX MATCH "APT::Architecture *\"([^\"]*)\";?" match "${output}" )
    if( match )
      set( ${output_variable} ${CMAKE_MATCH_1} PARENT_SCOPE )
    else()
      set( ${output_variable} "${CMAKE_SYSTEM_PROCESSOR}" PARENT_SCOPE )
    endif()
  else()
    set( ${output_variable} "${CMAKE_SYSTEM_PROCESSOR}" PARENT_SCOPE )
  endif()
endfunction()


function( BRAINVISA_PACKAGING_INITIALIZE_THIRDPARTY_COMPONENT component package_name package_maintainer package_version )
  message( STATUS "Initializing debian packaging for component ${component}" )
  
  foreach( package_type RUN DEV DOC DEVDOC SRC )
    foreach( dependency_type DEPENDS RECOMMENDS SUGGESTS ENHANCES )
      unset( ${component}_DEB_${package_type}_${dependency_type} CACHE )
    endforeach()
  endforeach()
endfunction()


function( BRAINVISA_PACKAGING_DEPENDENCY pack_type dependency_type component component_pack_type version_ranges binary_independent )
  BRAINVISA_VALID_DEBIAN_PACKAGE_NAME( "${component}" package_name )
  if ( version_ranges )
    foreach( range ${version_ranges} )
      set( ${PROJECT_NAME}_DEB_${pack_type}_${dependency_type} ${${PROJECT_NAME}_DEB_${pack_type}_${dependency_type}} "${package_name}( ${range} )" CACHE INTERNAL "" )
    endforeach()
  else()
    set( ${PROJECT_NAME}_DEB_${pack_type}_${dependency_type} ${${PROJECT_NAME}_DEB_${pack_type}_${dependency_type}} "${package_name}" CACHE INTERNAL "" )
  endif()
endfunction()


function( BRAINVISA_CREATE_RUN_PACKAGE component package_name package_maintainer package_version )
  BRAINVISA_VALID_DEBIAN_PACKAGE_NAME( "${package_name}" package_name )
  BRAINVISA_DEBIAN_ARCHITECTURE( architecture )
  
  set( DEB_DEPENDENCIES )
  if( ${component}_DEB_RUN_DEPENDS )
    string( REPLACE ";" "," dependencies "${${component}_DEB_RUN_DEPENDS}" )
    set( DEB_DEPENDENCIES "${DEB_DEPENDENCIES}Depends: ${dependencies}\n" )
  endif()
  if( ${component}_DEB_RUN_RECOMMENDS )
    string( REPLACE ";" "," dependencies "${${component}_DEB_RUN_RECOMMENDS}" )
    set( DEB_DEPENDENCIES "${DEB_DEPENDENCIES}Recommends: ${dependencies}\n" )
  endif()
  if( ${component}_DEB_RUN_SUGGESTS )
    string( REPLACE ";" "," dependencies "${${component}_DEB_RUN_SUGGESTS}" )
    set( DEB_DEPENDENCIES "${DEB_DEPENDENCIES}Suggests: ${dependencies}\n" )
  endif()
  if( ${component}_DEB_RUN_ENHANCES )
    string( REPLACE ";" "," dependencies "${${component}_DEB_RUN_ENHANCES}" )
    set( DEB_DEPENDENCIES "${DEB_DEPENDENCIES}Enhances: ${dependencies}\n" )
  endif()
  
  configure_file( "${brainvisa-cmake_DIR}/debian-control-run.in"
                  "${CMAKE_BINARY_DIR}/debian/control-${package_name}-run" 
                  @ONLY )

  set( _tmpDir "${BRAINVISA_PACKAGING_TEMPORARY_DIRECTORY}/brainvisa-cmake_${package_name}" )
  set( _packageNameRun "${CMAKE_BINARY_DIR}/${package_name}-${package_version}-${BRAINVISA_PACKAGING_SUFFIX}.deb" )

  add_custom_command( OUTPUT "${_packageNameRun}"
    COMMENT "Creating package \"${_packageNameRun}\""
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${_tmpDir}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_tmpDir}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_tmpDir}/DEBIAN"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_BINARY_DIR}/debian/control-${package_name}-run" "${_tmpDir}/DEBIAN/control"
    COMMAND ${CMAKE_COMMAND} "-DCMAKE_INSTALL_PREFIX=${_tmpDir}${CMAKE_INSTALL_PREFIX}" -DCOMPONENT=${component} -P "${CMAKE_BINARY_DIR}/cmake_install.cmake"
    COMMAND dpkg --build "${_tmpDir}" "${_packageNameRun}"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${_tmpDir}"
  )
  add_custom_target( "${component}-package-run"
    DEPENDS "${_packageNameRun}" )
endfunction()

function( BRAINVISA_CREATE_DEV_PACKAGE component package_name package_maintainer package_version )
  BRAINVISA_VALID_DEBIAN_PACKAGE_NAME( "${package_name}-dev" package_name )
  BRAINVISA_DEBIAN_ARCHITECTURE( architecture )
  
  set( DEB_DEV_DEPENDENCIES )
  if( ${component}_DEB_DEV_DEPENDS )
    string( REPLACE ";" "," dependencies "${${component}_DEB_DEV_DEPENDS}" )
    set( DEB_DEV_DEPENDENCIES "${DEB_DEV_DEPENDENCIES}Depends: ${dependencies}\n" )
  endif()
  if( ${component}_DEB_DEV_RECOMMENDS )
    string( REPLACE ";" "," dependencies "${${component}_DEB_DEV_RECOMMENDS}" )
    set( DEB_DEV_DEPENDENCIES "${DEB_DEV_DEPENDENCIES}Recommends: ${dependencies}\n" )
  endif()
  if( ${component}_DEB_DEV_SUGGESTS )
    string( REPLACE ";" "," dependencies "${${component}_DEB_DEV_SUGGESTS}" )
    set( DEB_DEV_DEPENDENCIES "${DEB_DEV_DEPENDENCIES}Suggests: ${dependencies}\n" )
  endif()
  if( ${component}_DEB_DEV_ENHANCES )
    string( REPLACE ";" "," dependencies "${${component}_DEB_DEV_ENHANCES}" )
    set( DEB_DEV_DEPENDENCIES "${DEB_DEV_DEPENDENCIES}Enhances: ${dependencies}\n" )
  endif()
  
  configure_file( "${brainvisa-cmake_DIR}/debian-control-dev.in"
                  "${CMAKE_BINARY_DIR}/debian/control-${package_name}-dev" 
                  @ONLY )

  set( _tmpDir "${BRAINVISA_PACKAGING_TEMPORARY_DIRECTORY}/brainvisa-cmake_${package_name}" )
  set( _packageNameDev "${CMAKE_BINARY_DIR}/${package_name}-dev-${package_version}-${BRAINVISA_PACKAGING_SUFFIX}.deb" )

  add_custom_command( OUTPUT "${_packageNameDev}"
    COMMENT "Creating package \"${_packageNameDev}\""
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${_tmpDir}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_tmpDir}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_tmpDir}/DEBIAN"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_BINARY_DIR}/debian/control-${package_name}-dev" "${_tmpDir}/DEBIAN/control"
    COMMAND ${CMAKE_COMMAND} "-DCMAKE_INSTALL_PREFIX=${_tmpDir}${CMAKE_INSTALL_PREFIX}" -DCOMPONENT=${component}-devel -P "${CMAKE_BINARY_DIR}/cmake_install.cmake"
    COMMAND dpkg --build "${_tmpDir}" "${_packageNameRun}"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${_tmpDir}"
  )
  add_custom_target( "${component}-package-dev"
    DEPENDS "${_packageNameDev}" )
endfunction()

# macro( CREATE_DEV_PACKAGE )
#   GET_DEBIAN_PACKAGE_NAME( ${BRAINVISA_PACKAGE_NAME} )
#   GET_DEBIAN_ARCHITECTURE()
#   set( DEB_DEV_DEPENDENCIES )
#   if( ${BRAINVISA_PACKAGE_NAME}_DEB_DEV_DEPENDS )
#     string( REPLACE ";" "," dependencies "${${BRAINVISA_PACKAGE_NAME}_DEB_DEV_DEPENDS}" )
#     set( DEB_DEV_DEPENDENCIES "${DEB_DEV_DEPENDENCIES}Depends: ${dependencies}\n" )
#   endif()
#   if( ${BRAINVISA_PACKAGE_NAME}_DEB_DEV_RECOMMENDS )
#     string( REPLACE ";" "," dependencies "${${BRAINVISA_PACKAGE_NAME}_DEB_DEV_RECOMMENDS}" )
#     set( DEB_DEV_DEPENDENCIES "${DEB_DEV_DEPENDENCIES}Recommends: ${dependencies}\n" )
#   endif()
#   if( ${BRAINVISA_PACKAGE_NAME}_DEB_DEV_SUGGESTS )
#     string( REPLACE ";" "," dependencies "${${BRAINVISA_PACKAGE_NAME}_DEB_DEV_SUGGESTS}" )
#     set( DEB_DEV_DEPENDENCIES "${DEB_DEV_DEPENDENCIES}Suggests: ${dependencies}\n" )
#   endif()
#   if( ${BRAINVISA_PACKAGE_NAME}_DEB_DEV_ENHANCES )
#     string( REPLACE ";" "," dependencies "${${BRAINVISA_PACKAGE_NAME}_DEB_DEV_ENHANCES}" )
#     set( DEB_DEV_DEPENDENCIES "${DEB_DEV_DEPENDENCIES}Enhances: ${dependencies}\n" )
#   endif()
#   
#   configure_file( "${brainvisa-cmake_DIR}/debian-control-dev.in"
#                   "${CMAKE_BINARY_DIR}/debian/control-${BRAINVISA_PACKAGE_NAME}-dev" 
#                   @ONLY )
# 
#   set( _tmpDir "${BRAINVISA_PACKAGING_TEMPORARY_DIRECTORY}/brainvisa-cmake_${BRAINVISA_PACKAGE_NAME}" )
#   set( _packageNameDev "${CMAKE_BINARY_DIR}/${BRAINVISA_PACKAGE_NAME}-dev-${BRAINVISA_PACKAGE_VERSION}-${BRAINVISA_PACKAGING_SUFFIX}.deb" )
# 
#   add_custom_command( OUTPUT "${_packageNameDev}"
#     COMMENT "Creating package \"${_packageNameDev}\""
#     COMMAND ${CMAKE_COMMAND} -E remove_directory "${_tmpDir}-dev"
#     COMMAND ${CMAKE_COMMAND} -E make_directory "${_tmpDir}-dev"
#     COMMAND ${CMAKE_COMMAND} -E make_directory "${_tmpDir}-dev/DEBIAN"
#     COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_BINARY_DIR}/debian/control-${BRAINVISA_PACKAGE_NAME}-dev" "${_tmpDir}-dev/DEBIAN/control"
#     COMMAND ${CMAKE_COMMAND} "-DCMAKE_INSTALL_PREFIX=${_tmpDir}-dev${CMAKE_INSTALL_PREFIX}" -DCOMPONENT=${BRAINVISA_PACKAGE_NAME}-devel -P "${CMAKE_BINARY_DIR}/cmake_install.cmake"
#     COMMAND dpkg --build "${_tmpDir}-dev" "${_packageNameDev}"
#     COMMAND ${CMAKE_COMMAND} -E remove_directory "${_tmpDir}-dev"
#   )
#   add_custom_target( "${BRAINVISA_PACKAGE_NAME}-package-dev"
#     DEPENDS "${_packageNameDev}" )
# endmacro()


function( BRAINVISA_CREATE_DOC_PACKAGE component package_name package_maintainer package_version )
endfunction()

function( BRAINVISA_CREATE_DEVDOC_PACKAGE component package_name package_maintainer package_version )
endfunction()

function( BRAINVISA_CREATE_SRC_PACKAGE component package_name package_maintainer package_version )
endfunction()
