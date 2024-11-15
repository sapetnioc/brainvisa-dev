# Try to find the libkdtree library
# Once done this will define
#
# LIBKDTREE_FOUND        - system has minc and it can be used
# LIBKDTREE_INCLUDE_DIR  - directory where the header file can be found
### LIBKDTREE_LIBRARIES    - the libraries (none)
#

if( LIBKDTREE_INCLUDE_DIR )
    SET( LIBKDTREE_FOUND "YES" )
else()
    FIND_PATH( LIBKDTREE_INCLUDE_DIR kdtree.hpp
        ${LIBKDTREE_DIR}/include
        /usr/include
    )

    IF( LIBKDTREE_INCLUDE_DIR )
        SET( LIBKDTREE_FOUND "YES" )
    ENDIF( LIBKDTREE_INCLUDE_DIR )

    IF( NOT LIBKDTREE_FOUND )
        SET( LIBKDTREE_DIR "" CACHE PATH "Root of LibKDTree source tree (optional)." )
        MARK_AS_ADVANCED( LIBKDTREE_DIR )
    ENDIF( NOT LIBKDTREE_FOUND )
endif()