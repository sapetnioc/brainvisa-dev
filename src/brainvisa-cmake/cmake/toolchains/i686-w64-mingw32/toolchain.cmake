#message("===== i686-w64-mingw32 toolchain setup =====")
# the name of the target operating system
set(CMAKE_SYSTEM_NAME Windows)

if (NOT COMPILER_PREFIX)
    set(COMPILER_PREFIX "i686-w64-mingw32")
endif()

#message("===== MINGW toolchain ${COMPILER_PREFIX} =====")
# which compilers to use for C and C++
find_program(CMAKE_RC_COMPILER NAMES ${COMPILER_PREFIX}-windres)
find_program(CMAKE_C_COMPILER NAMES ${COMPILER_PREFIX}-gcc)
find_program(CMAKE_CXX_COMPILER NAMES ${COMPILER_PREFIX}-g++)
find_program(CMAKE_Fortran_COMPILER NAMES ${COMPILER_PREFIX}-gfortran)
find_program(CMAKE_LIBTOOL NAMES ${COMPILER_PREFIX}-dlltool)

# here is the target environment located
set(CMAKE_FIND_ROOT_PATH /usr/${COMPILER_PREFIX})
set(CMAKE_LIBRARY_PATH /usr/${COMPILER_PREFIX}/lib /usr/lib/gcc/${COMPILER_PREFIX}/4.8 ${CMAKE_FIND_ROOT_PATH})

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search 
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
