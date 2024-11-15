include_directories( ${SIP_INCLUDE_DIRS} )

BRAINVISA_ADD_SIP_PYTHON_MODULE( brainvisa_cmake_tutorialsip 
  brainvisa_cmake_tutorial
  "brainvisa-cmake_tutorial.sip" )
target_link_libraries(  brainvisa_cmake_tutorialsip ${PROJECT_NAME} "${PYTHON_LIBRARY}" )

BRAINVISA_INSTALL( TARGETS brainvisa_cmake_tutorialsip 
                   DESTINATION python/brainvisa_cmake_tutorial
                   COMPONENT ${PROJECT_NAME} )
