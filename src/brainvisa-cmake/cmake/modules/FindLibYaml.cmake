# Try to find the yaml library
# Once done this will define
#
# YAML_FOUND        - system has yaml and it can be used
# YAML_INCLUDE_DIRS - directory where the header file can be found
# YAML_LIBRARIES    - the yaml libraries

IF( YAML_INCLUDE_DIRS AND YAML_LIBRARIES )
    SET( YAML_FOUND TRUE )
ELSE()
    # First try to search yaml through pkg_config.
    find_package(PkgConfig)
    if(PKG_CONFIG_FOUND)
        pkg_search_module(_YAML yaml-0.1)
        if(_YAML_FOUND)
            find_library(YAML_LIBRARIES ${_YAML_LIBRARIES}
                         PATHS ${_YAML_LIBRARY_DIRS})
            set(YAML_INCLUDE_DIRS ${_YAML_INCLUDEDIR}
                CACHE PATH "Paths to lib yaml header files")
            set(YAML_VERSION "${_YAML_VERSION}"
                CACHE STRING "Version of yaml library")
        endif()
    endif()
  
    IF(NOT _YAML_FOUND)
        FIND_PATH( YAML_INCLUDE_DIRS yaml.h
            /usr/local/include/yaml
            /usr/local/include
            /usr/include/yaml
            /usr/include
        )

        SET( YAML_NAMES ${YAML_NAMES} yaml )
        FIND_LIBRARY( YAML_LIBRARY
            NAMES ${YAML_NAMES}
            PATHS /usr/lib 
                  /usr/local/lib
                  /usr/lib/x86_64-linux-gnu
        )
        set(YAML_LIBRARIES ${YAML_LIBRARY} 
            CACHE PATH "Yaml libraries" FORCE)
        IF( YAML_INCLUDE_DIRS AND YAML_LIBRARIES )
            SET( YAML_FOUND TRUE )
        ELSE()
            IF( NOT YAML_FOUND )
                SET( YAML_DIR "" CACHE PATH 
                     "Root of Yaml source tree (optional)." )
                MARK_AS_ADVANCED( YAML_DIR )
            ENDIF( NOT YAML_FOUND )
            IF( YAML_FIND_REQUIRED )
                MESSAGE( SEND_ERROR 
                         "Yaml library was not found." )
            ELSE()
                IF( NOT YAML_FIND_QUIETLY )
                    MESSAGE( STATUS 
                             "Yaml library was not found." )
                ENDIF()
            ENDIF()
        ENDIF()
    ENDIF()
  
ENDIF()