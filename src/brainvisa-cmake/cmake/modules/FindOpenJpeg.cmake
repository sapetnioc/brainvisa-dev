# Try to find the openjpeg (jpeg 2000)  library
# Once done this will define
#
# OPENJPEG_FOUND        - system has openjpeg and it can be used
# OPENJPEG_INCLUDE_DIRS - directory where the header file can be found
# OPENJPEG_LIBRARIES    - the openjpeg libraries

IF( OPENJPEG_INCLUDE_DIRS AND OPENJPEG_LIBRARIES )
    SET( OPENJPEG_FOUND TRUE )
ELSE()
    # First try to search openjpeg through pkg_config.
    find_package(PkgConfig)
    if(PKG_CONFIG_FOUND)
        pkg_search_module(_OPENJPEG libopenjp2)
        if(NOT _OPENJPEG_FOUND)
           # Test if OpenJpeg-1 is installed
   	   pkg_search_module(_OPENJPEG libopenjpeg1)
        endif()
        if(_OPENJPEG_FOUND)
            find_library(OPENJPEG_LIBRARIES ${_OPENJPEG_LIBRARIES}
                         PATHS ${_OPENJPEG_LIBRARY_DIRS})
            set(OPENJPEG_INCLUDE_DIRS ${_OPENJPEG_INCLUDE_DIRS}
                CACHE PATH "Paths to lib openjpeg header files")
            set(OPENJPEG_VERSION "${_OPENJPEG_VERSION}"
                CACHE STRING "Version of openjpeg library")
        endif()
    endif()
  
    IF(NOT _OPENJPEG_FOUND)
        FIND_PATH( OPENJPEG_INCLUDE_DIRS openjpeg.h
            /usr/local/include/openjpeg
            /usr/local/include
            /usr/include/openjpeg
            /usr/include
        )

        SET( OPENJPEG_NAMES ${OPENJPEG_NAMES} openjpeg )
        FIND_LIBRARY( OPENJPEG_LIBRARY
            NAMES ${OPENJPEG_NAMES}
            PATHS /usr/lib 
                  /usr/local/lib
                  /usr/lib/x86_64-linux-gnu
        )       
        set(OPENJPEG_LIBRARIES ${OPENJPEG_LIBRARY} 
            CACHE PATH "OpenJpeg libraries" FORCE)
            
        IF( OPENJPEG_INCLUDE_DIRS )
            # Try to find version
            list(APPEND __openjpeg_version_files "openjpeg.h")
            list(APPEND __openjpeg_version_regex
                "#define[ \\t]*OPENJPEG_VERSION[ \\t]*\"([^\"]*)\"")
            
            foreach(__include_dir ${OPENJPEG_INCLUDE_DIRS})
                foreach(__vf ${__openjpeg_version_files})
                    set(__vf "${__include_dir}/${__vf}")
                    if( EXISTS "${__vf}" )
                        foreach(__re ${__openjpeg_version_regex})
                            file( READ "${__vf}" header )
                            string( REGEX MATCH "${__re}" match "${header}" )
                            if( match )
                                set( OPENJPEG_VERSION "${CMAKE_MATCH_1}" 
                                     CACHE STRING "OpenJPEG version" )
                                break()
                            endif()
                        endforeach()
                        unset(__re)
                    endif()
                    if(OPENJPEG_VERSION)
                        break()
                    endif()
                endforeach()
            unset(__vf)
            if(OPENJPEG_VERSION)
                break()
            endif()
            endforeach()
            unset(__include_dir)
            unset(__openjpeg_version_files)
            unset(__openjpeg_version_regex)
        ENDIF()
        
        IF( OPENJPEG_INCLUDE_DIRS AND OPENJPEG_LIBRARIES )
            SET( OPENJPEG_FOUND TRUE )
        ELSE()
            IF( NOT OPENJPEG_FOUND )
                SET( OPENJPEG_DIR "" CACHE PATH 
                     "Root of OpenJpeg source tree (optional)." )
                MARK_AS_ADVANCED( OPENJPEG_DIR )
            ENDIF( NOT OPENJPEG_FOUND )
            IF( OPENJPEG_FIND_REQUIRED )
                MESSAGE( SEND_ERROR 
                         "OpenJpeg library was not found." )
            ELSE()
                IF( NOT OPENJPEG_FIND_QUIETLY )
                    MESSAGE( STATUS 
                             "OpenJpeg library was not found." )
                ENDIF()
            ENDIF()
        ENDIF()
    ENDIF()
  
ENDIF()
