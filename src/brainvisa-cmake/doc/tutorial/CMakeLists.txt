cmake_minimum_required( VERSION 3.20 )

find_package( brainvisa-cmake REQUIRED )

BRAINVISA_PROJECT()

find_package( PythonInterp REQUIRED )
BRAINVISA_ADD_RUNTIME_DEPENDENCY( THIRDPARTY PythonInterp REQUIRED )

find_package( Dot )
# TODO: no error in BRAINVISA_ADD_SIP_PYTHON_MODULE if SIP is not found
find_package( SIP REQUIRED)


BRAINVISA_COPY_PYTHON_DIRECTORY( "${CMAKE_CURRENT_SOURCE_DIR}/python"
                                 ${PROJECT_NAME} )
BRAINVISA_COPY_DIRECTORY( "${CMAKE_CURRENT_SOURCE_DIR}/share" 
                          "share/${PROJECT_NAME}-${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}"
                          ${PROJECT_NAME} )
# BRAINVISA_GENERATE_EPYDOC_DOC( "${CMAKE_CURRENT_SOURCE_DIR}/python"
#                                "share/doc/${PROJECT_NAME}-${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}/epydoc/html" )

# TODO: Should be managed by brainvisa-cmake
include_directories( "${CMAKE_BINARY_DIR}/include" )

add_subdirectory( src )

BRAINVISA_CREATE_CMAKE_CONFIG_FILES()
