# This file is included when PIXI variable is set. It must point to the directory of a
# pixi project properly configured to be used by brainvisa-cmake.
# It defines variables that are tricks to allow compilation in this environment.

message("Using Pixi environment located in ${PIXI}")
set(DESIRED_QT_VERSION 5)
set(DESIRED_SIP_VERSION 6)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated")
set(CMAKE_SYSTEM_PREFIX_PATH "$ENV{CONDA_PREFIX}" "${CMAKE_SYSTEM_PREFIX_PATH}")

# The following line makes the linker use RUNPATH instead of RPATH.
# The latter does not takes precedence over LD_LIBRARY_PATH
set(CMAKE_EXE_LINKER_FLAGS "-Wl,--enable-new-dtags -L${CMAKE_BINARY_DIR}/lib -L$ENV{CONDA_PREFIX}/lib" CACHE INTERNAL "")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}" CACHE INTERNAL "")
set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}" CACHE INTERNAL "")
include_directories(BEFORE "$CASA/include" "$ENV{CONDA_PREFIX}/include")

#set(DCMTK_DIR "$ENV{CONDA_PREFIX}" CACHE STRING "")
set(OpenGL_GL_PREFERENCE "GLVND" CACHE STRING "")
set(OPENGL_FIX_INCLUDE_DIRECTORIES "$ENV{CONDA_PREFIX}/mesalib/include")
set(OPENGL_egl_LIBRARY "$ENV{CONDA_PREFIX}/x86_64-conda-linux-gnu/sysroot/usr/lib64/libEGL.so" CACHE PATH "")
set(OPENGL_gl_LIBRARY "$ENV{CONDA_PREFIX}/x86_64-conda-linux-gnu/sysroot/usr/lib64/libGL.so" CACHE PATH "")
set(OPENGL_glu_LIBRARY "$ENV{CONDA_PREFIX}/lib/libGLU.so" CACHE PATH "")
set(OPENGL_glx_LIBRARY "$ENV{CONDA_PREFIX}/x86_64-conda-linux-gnu/sysroot/usr/lib64/libGLX.so" CACHE PATH "")
set(OPENGL_opengl_LIBRARY "$ENV{CONDA_PREFIX}/x86_64-conda-linux-gnu/sysroot/usr/lib64/libOpenGL.so" CACHE PATH "")
set(OPENGL_FIX_LIBRARIES 
    "X11" "GL" "GLdispatch" "GLX" "xcb" "Xau" "Xdmcp" "bsd" "rt" "GLU" "Xext" CACHE INTERNAL "")
execute_process(COMMAND python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE python_version
)
set(PYTHON_INSTALL_DIRECTORY lib/python${python_version}/site-packages)
set(BUILD_VIDAIO NO)
set(CMAKE_BUILD_RPATH "${CMAKE_BINARY_DIR}/lib:$ENV{CONDA_PREFIX}/lib:$ENV{CONDA_PREFIX}/x86_64-conda-linux-gnu/sysroot/lib64")
set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib:$ORIGIN/../x86_64-conda-linux-gnu/sysroot/lib64")
set(CMAKE_BUILD_RPATH "${CMAKE_BINARY_DIR}/lib:$ENV{CONDA_PREFIX}/lib")
set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib")
