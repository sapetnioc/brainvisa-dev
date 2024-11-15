find_package(PkgConfig)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(FUSE "fuse")
    if(FUSE_FOUND)
        set(FUSE_DEFINITIONS ${FUSE_CFLAGS} ${FUSE_CFLAGS_OTHER})
    endif()
else()
    find_path(
        FUSE_INCLUDE_DIRS
        NAMES fuse_opt.h
        DOC "Include directories for FUSE"
    )

    find_library(
        FUSE_LIBRARIES
        NAMES "fuse"
        DOC "Libraries for FUSE"
    )
endif()

if(NOT FUSE_INCLUDE_DIRS OR NOT FUSE_LIBRARIES)
    set(FUSE_FOUND FALSE)
else()
    set(FUSE_FOUND TRUE)
endif()
