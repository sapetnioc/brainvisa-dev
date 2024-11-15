set( _headers
  brainvisa-cmake_tutorial.h
)
set( _sources
  brainvisa-cmake_tutorial.cc
)
BRAINVISA_COPY_AND_INSTALL_HEADERS( _headers  ${PROJECT_NAME} )
add_library( ${PROJECT_NAME} SHARED ${_sources} )
set_property( TARGET ${PROJECT_NAME} PROPERTY VERSION ${${PROJECT_NAME}_VERSION} )
# target_link_libraries( cartobase ${LIBXML2_LIBRARIES} ${Sigc++2_LIBRARIES}  )
BRAINVISA_INSTALL( TARGETS ${PROJECT_NAME}
                   DESTINATION lib
                   COMPONENT ${PROJECT_NAME} )
BRAINVISA_GENERATE_DOXYGEN_DOC( _headers  )
