# Try to find the root library (cern tool)
# Once done this will define
#
# Root_FOUND        - system has root and it can be used
# Root_INCLUDE_DIRS - the root include directory
# Root_LIB_DIR      - the root libraries directory
# Root_LIBS         - the root libraries
# Root_CFLAGS       - the root c++ compilation flags
# Root_VERSION      - version of the library
# Root_PATH         - path to the root rootdir

#configuration SHFJ
#set(Root_PATH /shfj/local/root-5.34.36) #Ubuntu 16.04
#set(Root_PATH /shfj/local/root-5.34.14) #Ubuntu 14.04

IF(EXISTS Root_INCLUDE_DIR)
  # already found  
  SET(Root_FOUND TRUE)
ELSE(EXISTS Root_INCLUDE_DIR)
  IF(EXISTS ${Root_PATH}/bin/root-config)
    SET(Root_FOUND TRUE)
    execute_process(COMMAND ${Root_PATH}/bin/root-config --incdir OUTPUT_VARIABLE Root_INCLUDE_DIRS)
    STRING(REGEX REPLACE "\n" "" Root_INCLUDE_DIRS ${Root_INCLUDE_DIRS})
    SET(Root_INCLUDE_DIRS ${Root_INCLUDE_DIRS} ${Root_PATH}/math/minuit2/inc/)
    execute_process(COMMAND ${Root_PATH}/bin/root-config --libdir OUTPUT_VARIABLE Root_LIB_DIR)
    STRING(REGEX REPLACE "\n" "" Root_LIB_DIR ${Root_LIB_DIR})
    execute_process(COMMAND ${Root_PATH}/bin/root-config --version OUTPUT_VARIABLE Root_VERSION)
    STRING(REGEX REPLACE "\n" "" Root_VERSION ${Root_VERSION})
    execute_process(COMMAND ${Root_PATH}/bin/root-config --cflags OUTPUT_VARIABLE Root_CFLAGS)
    STRING(REGEX REPLACE "\n" "" Root_CFLAGS ${Root_CFLAGS})
    SET(Root_CFLAGS ${Root_CFLAGS} -D_REENTRANT -DCARTO_DEBUGMODE=\"release\" -DAIMS -DHAVE_ZLIB)
    SET(Root_LIBS ${Root_LIB_DIR}/libMinuit2.so ${Root_LIB_DIR}/libMinuit.so ${Root_LIB_DIR}/libMathMore.so ${Root_LIB_DIR}/libMathCore.so ${Root_LIB_DIR}/libCint.so ${Root_LIB_DIR}/libCore.so  ${Root_LIB_DIR}/libFTGL.so ${Root_LIB_DIR}/libTree.so ${Root_LIB_DIR}/libRIO.so ${Root_LIB_DIR}/libNet.so ${Root_LIB_DIR}/libHist.so ${Root_LIB_DIR}/libGraf.so ${Root_LIB_DIR}/libGraf3d.so ${Root_LIB_DIR}/libGpad.so ${Root_LIB_DIR}/libMatrix.so ${Root_LIB_DIR}/libRint.so ${Root_LIB_DIR}/libPostscript.so ${Root_LIB_DIR}/libPhysics.so ${Root_LIB_DIR}/libThread.so)
    SET(Root_LIBS ${Root_LIBS} m dl aimsalgo aimsalgopub aimsdata graph cartodata cartobase cartobase_1 cartobase_0 sigc-2.0 xml2 blitz pthread)
  ELSE(EXISTS ${Root_PATH}/bin/root-config)
    SET(Root_FOUND FALSE)
  ENDIF(EXISTS ${Root_PATH}/bin/root-config)
ENDIF(EXISTS Root_INCLUDE_DIR)

message(STATUS "Root_FOUND: ${Root_FOUND}")
message(STATUS "Root_INCLUDE_DIRS: ${Root_INCLUDE_DIRS}")
message(STATUS "Root_LIB_DIR: ${Root_LIB_DIR}")
message(STATUS "Root_VERSION: ${Root_VERSION}")
message(STATUS "Root_PATH: ${Root_PATH}")
message(STATUS "Root_CFLAGS: ${Root_CFLAGS}")
message(STATUS "Root_LIBS: ${Root_LIBS}")
