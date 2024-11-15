#message("===== i686-w64-mingw32 cache initialization =====")
if(NOT BRAINVISA_CROSSCOMPILATION_DIR)
  message(FATAL_ERROR "BRAINVISA_CROSSCOMPILATION_DIR is not set")
endif(NOT BRAINVISA_CROSSCOMPILATION_DIR)

if (NOT COMPILER_PREFIX)
    set(COMPILER_PREFIX "i686-w64-mingw32")
endif()

# Add brainvisa root directory
set(CMAKE_FIND_ROOT_PATH
    ${BRAINVISA_CROSSCOMPILATION_DIR} 
    ${CMAKE_FIND_ROOT_PATH})

# QT settings
execute_process(COMMAND qmake -query QT_INSTALL_BINS
                OUTPUT_VARIABLE __qt_binary_dir
                OUTPUT_STRIP_TRAILING_WHITESPACE)
set(QT_BINARY_DIR "${__qt_binary_dir}"
    CACHE FILEPATH "QT binary directory")
    
set(QT_QMAKE_EXECUTABLE "${BRAINVISA_CROSSCOMPILATION_DIR}/qt/bin/qmake"
    CACHE FILEPATH "QT qmake executable")
     
# Set specific options for debug symbols when wine is used
# at the runtime
set(CMAKE_C_FLAGS_DEBUG "-gstabs" 
    CACHE STRING "Flags used by the compiler during debug builds.")
set(CMAKE_CXX_FLAGS_DEBUG "-gstabs"
    CACHE STRING "Flags used by the compiler during debug builds.")
set(CMAKE_Fortran_FLAGS_DEBUG "-gstabs" 
    CACHE STRING "Flags used by the compiler during debug builds.")
    