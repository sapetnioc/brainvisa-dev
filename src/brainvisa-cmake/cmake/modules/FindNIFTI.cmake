# Try to find the nifti libraya
# Once done this will define
#
# NIFTI_FOUND        - system has nifti and it can be used
# NIFTI_INCLUDE_DIR  - directory where the arrayobject.h header file can be found
# NIFTI_LIBRARIES    - the nifti libraries
#

if(NIFTI_INCLUDE_DIR AND NIFTI_LIBRARIES)
    set(NIFTI_FOUND "YES")
else()
    FIND_PATH( NIFTI_INCLUDE_DIR nifti1.h
        ${NIFTI_DIR}/include
        /usr/include 
        /usr/include/nifti 
    )


    FIND_LIBRARY( NIFTI_niftiio_LIBRARY niftiio
        ${NIFTI_DIR}/lib
        /usr/lib
    )


    FIND_LIBRARY( NIFTI_fslio_LIBRARY fslio
        ${NIFTI_DIR}/lib
        /usr/lib
    )


    FIND_LIBRARY( NIFTI_nifticdf_LIBRARY nifticdf
        ${NIFTI_DIR}/lib
        /usr/lib
    )


    FIND_LIBRARY(NIFTI_znz_LIBRARY znz
        ${NIFTI_DIR}/lib
        /usr/lib
    )



    IF( NIFTI_INCLUDE_DIR )
        IF( NIFTI_niftiio_LIBRARY )
            IF( NIFTI_nifticdf_LIBRARY )
                IF( NIFTI_znz_LIBRARY )

                SET( NIFTI_FOUND "YES" )

                SET( NIFTI_LIBRARIES
                    ${NIFTI_niftiio_LIBRARY}
                    ${NIFTI_nifticdf_LIBRARY}
                    ${NIFTI_znz_LIBRARY}
                )

                ENDIF( NIFTI_znz_LIBRARY )
            ENDIF( NIFTI_nifticdf_LIBRARY )
        ENDIF( NIFTI_niftiio_LIBRARY )
    ENDIF( NIFTI_INCLUDE_DIR )

    IF( NIFTI_fslio_LIBRARY )

        SET( NIFTI_LIBRARIES
            ${NIFTI_LIBRARIES}
            ${NIFTI_fslio_LIBRARY}
        )

    ENDIF( NIFTI_fslio_LIBRARY )

    IF(NIFTI_LIBRARIES)
        SET( NIFTI_LIBRARIES ${NIFTI_LIBRARIES} 
             CACHE STRING "NIFTI libraries")
    ENDIF()

    IF( NOT NIFTI_FOUND )
        SET( NIFTI_DIR "" CACHE PATH "Root of NIFTI source tree (optional)." )
        MARK_AS_ADVANCED( NIFTI_DIR )
    ENDIF( NOT NIFTI_FOUND )
endif()