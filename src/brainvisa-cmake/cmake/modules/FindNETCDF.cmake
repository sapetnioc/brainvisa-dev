# Try to find the minc library
# Once done this will define
#
# NETCDF_FOUND        - system has netcdf and it can be used
# NETCDF_INCLUDE_DIR  - directory where the header file can be found
# NETCDF_LIBRARIES    - the netcdf libraries
# NETCDF_LIBRARY      - the netcdf libraries
# NETCDF_NEEDS_MPI    - TRUE if NetCDF is built using MPI library
#
# Need to look for Netcdf and hdf5 as well

if( NETCDF_INCLUDE_DIR AND NETCDF_LIBRARY )
    SET( NETCDF_FOUND "YES" )
else()

    find_package( PkgConfig QUIET )
    if( PkgConfig_FOUND )

        pkg_check_modules( PC_NETCDF QUIET netcdf )

    endif()
    if( PC_NETCDF_FOUND )

        # configured via pkg-config
        set( NETCDF_INCLUDE_DIR
             ${PC_NETCDF_INCLUDEDIR} ${PC_NETCDF_INCLUDE_DIRS}
             CACHE PATH "NetCDF include path" )
        set( NETCDF_LIBRARIES )
        foreach( lib ${PC_NETCDF_LIBRARIES} )
          find_library( netcdf_lib ${lib}
                        PATHS ${PC_NETCDF_LIBRARY_DIRS} )
          if( netcdf_lib )
            list( APPEND NETCDF_LIBRARIES ${netcdf_lib} )
          endif()
          unset( netcdf_lib CACHE )
        endforeach()
        set( NETCDF_LIBRARIES ${NETCDF_LIBRARIES} CACHE PATH "NetCDF libraries")
        set( NETCDF_LIBRARY ${NETCDF_LIBRARIES} CACHE PATH "NetCDF libraries")
        set( NETCDF_FOUND "YES" )

    endif()

    if( NOT NETCDF_INCLUDE_DIR ) #OR NOT EXISTS "${NETCDF_INCLUDE_DIR}/netcdf.h" )
        # pkg-config does not work: try the manual way

        unset( NETCDF_INCLUDE_DIR )
        unset( NETCDF_INCLUDE_DIR CACHE )

        FIND_PATH( NETCDF_INCLUDE_DIR netcdf.h
            ${NETCDF_DIR}/include
            ${NETCDF_DIR}/include/netcdf-3
            ${NETCDF_DIR}/include/netcdf
            /usr/include
            /usr/include/netcdf-3
            /usr/include/netcdf
        )

        FIND_LIBRARY( NETCDF_LIBRARY netcdf
            ${NETCDF_DIR}/lib
            /usr/lib
        )

        IF( NETCDF_LIBRARY )
            SET( NETCDF_FOUND "YES" )
            set( NETCDF_LIBRARIES ${NETCDF_LIBRARY}
                 CACHE PATH "NetCDF libraries")
        ENDIF( NETCDF_LIBRARY )

    endif()


    if( NETCDF_FOUND )

        IF( NETCDF_INCLUDE_DIR )
            if(NOT NETCDF_VERSION)
                # Try to get version
                if( EXISTS "${NETCDF_INCLUDE_DIR}/netcdf_meta.h" )
                    file( READ "${NETCDF_INCLUDE_DIR}/netcdf_meta.h" header )
                    string( REGEX MATCH "#define[ \\t]+NC_VERSION[ \\t]+\"([^\"]+)\"" match "${header}" )
                    if( match )
                        set( NETCDF_VERSION "${CMAKE_MATCH_1}" 
                            CACHE STRING "Netcdf library version")
                    endif()
                endif()
                
                if(NOT NETCDF_VERSION)
                    find_program(__nc_config nc-config
                                 PATHS "/i2bm/brainvisa/Windows-7-x86_64/netcdf-4.1.3/bin")
                    message("Found nc-config: ${__nc_config}")
                    if(__nc_config)
                        execute_process(COMMAND ${__nc_config} --version
                                        OUTPUT_VARIABLE __result)
                        string( REGEX MATCH "netCDF[ \\t]+([0-9.]+)" match "${__result}" )
                        if( match )
                            set( NETCDF_VERSION "${CMAKE_MATCH_1}" 
                                CACHE STRING "Netcdf library version")
                        endif()
                    endif()
                endif()
            endif()
            
            # check dependance on mpi
            list( GET NETCDF_INCLUDE_DIR 0 incdir )
            file(READ "${incdir}/netcdf.h" _netcdf_h )
            string(REGEX MATCH "#include <mpi.h>" _mpi_inc ${_netcdf_h} )
            if( _mpi_inc )
                find_package( MPI )
                set( NETCDF_INCLUDE_DIR ${NETCDF_INCLUDE_DIR} ${MPI_C_INCLUDE_PATH}
                    CACHE PATH "NetCDF include path" FORCE )
                set( NETCDF_NEEDS_MPI "TRUE"
                    CACHE STRING "if NetCDF is built using MPI library" )
            endif()

        ENDIF( NETCDF_INCLUDE_DIR )

    else()

        SET( NETCDF_DIR "" CACHE PATH "Root of NETCDF source tree (optional)." )
        MARK_AS_ADVANCED( NETCDF_DIR )

    endif()

#     message("*** NETCDF config:")
#     message("NETCDF_FOUND: ${NETCDF_FOUND}")
#     message("NETCDF_INCLUDE_DIR: ${NETCDF_INCLUDE_DIR}")
#     message("NETCDF_LIBRARIES: ${NETCDF_LIBRARIES}")
#     message("NETCDF_LIBRARY: ${NETCDF_LIBRARY}")
#     message("NETCDF_NEEDS_MPI: ${NETCDF_NEEDS_MPI}")
endif()
