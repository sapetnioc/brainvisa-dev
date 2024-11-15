# Try to find the jpeg XR library
# Once done this will define
#
# LIBJPEGXR_FOUND        - system has jpegxr and it can be used
# LIBJPEGXR_INCLUDE_DIRS - directory where the header file can be found
# LIBJPEGXR_LIBRARIES    - the jpegxr libraries

IF( LIBJPEGXR_INCLUDE_DIRS AND LIBJPEGXR_LIBRARIES )
  SET( LIBJPEGXR_FOUND TRUE )
ELSE()

  # First try to search jpegxr through pkg_config.
  find_package(PkgConfig)
  if(PKG_CONFIG_FOUND)
    pkg_search_module(_LIBJPEGXR libjxr)
    if(_LIBJPEGXR_FOUND)
      if(_LIBJPEGXR_LIBRARIES)
          foreach(__library ${_LIBJPEGXR_LIBRARIES})
            string(TOUPPER ${__library} __library_name)
            find_library(LIBJPEGXR_LIB${__library_name}
                         NAMES ${__library}
                         PATHS ${_LIBJPEGXR_LIBRARY_DIRS})
            list(APPEND LIBJPEGXR_LIBRARIES
                 ${LIBJPEGXR_LIB${__library_name}})
          endforeach()
          unset(__library)
          unset(__library_name)
      endif()
      set(LIBJPEGXR_LIBRARIES ${LIBJPEGXR_LIBRARIES} CACHE PATH "Paths to lib jpegxr header files")
      set(LIBJPEGXR_INCLUDE_DIRS ${_LIBJPEGXR_INCLUDE_DIRS} CACHE PATH "Paths to lib jpegxr header files")
      set(LIBJPEGXR_VERSION "${_LIBJPEGXR_VERSION}" CACHE STRING "Version of jpegxr library")
    endif()
  endif()
  
  if(NOT LIBJPEGXR_LIBRARIES)
    FIND_PATH( LIBJPEGXR_INCLUDE_DIRS libjxr
        /usr/local/include/jxrlib
        /usr/local/include
        /usr/include/jxrlib
        /usr/include
    )

    FIND_LIBRARY( LIBJPEGXR_LIBRARY
        NAMES jpegxr
        PATHS /usr/lib 
            /usr/local/lib
    )
    
    FIND_LIBRARY( LIBJPEGXRGLUE_LIBRARY
        NAMES jxrglue
        PATHS /usr/lib 
              /usr/local/lib
    )
    
    SET(LIBJPEGXR_LIBRARIES 
        ${LIBJPEGXR_LIBRARY}
        ${LIBJPEGXRGLUE_LIBRARY})
  ENDIF()
  
  IF( LIBJPEGXR_INCLUDE_DIRS AND LIBJPEGXR_LIBRARIES )
    SET( LIBJPEGXR_FOUND TRUE )
  ELSE()
    IF( LIBJPEGXR_FIND_REQUIRED )
        MESSAGE( SEND_ERROR "JpegXR library was not found." )
    ELSE()
      IF( NOT LIBJPEGXR_FIND_QUIETLY )
        MESSAGE( STATUS "JpegXR library was not found." )
      ENDIF()
    ENDIF()
  ENDIF()
  
ENDIF()