# Try to find gnu scientific library GSL
# See 
# http://www.gnu.org/software/gsl/  and 
# http://gnuwin32.sourceforge.net/packages/gsl.htm
#
# Once run this will define: 
# 
# GSL_FOUND       = system has GSL lib
#
# GSL_LIBRARIES   = full path to the libraries
#    on Unix/Linux with additional linker flags from "gsl-config --libs"
# 
# CMAKE_GSL_CXX_FLAGS  = Unix compiler flags for GSL, essentially "`gsl-config --cxxflags`"
#
# GSL_INCLUDE_DIR      = where to find headers 
#
# GSL_LINK_DIRECTORIES = link directories, useful for rpath on Unix
# GSL_EXE_LINKER_FLAGS = rpath on Unix
#
# Felix Woelk 07/2004
# Jan Woetzel
#
# www.mip.informatik.uni-kiel.de
# --------------------------------

IF(WIN32)
  # JW tested with gsl-1.8, Windows XP, MSVS 7.1
  SET(GSL_POSSIBLE_ROOT_DIRS
    ${GSL_ROOT_DIR}
    $ENV{GSL_ROOT_DIR}
    ${GSL_DIR}
    ${GSL_HOME}    
    $ENV{GSL_DIR}
    $ENV{GSL_HOME}
    $ENV{EXTRA}
    "C:/home/jw/source2/gsl-1.8"
    )
  FIND_PATH(GSL_INCLUDE_DIR
    NAMES gsl/gsl_cdf.h gsl/gsl_randist.h
    PATHS ${GSL_POSSIBLE_ROOT_DIRS}
    PATH_SUFFIXES include
    DOC "GSL header include dir"
    )
  
  FIND_LIBRARY(GSL_GSL_LIBRARY
    NAMES gsl libgsl
    PATHS  ${GSL_POSSIBLE_ROOT_DIRS}
    PATH_SUFFIXES lib
    DOC "GSL library dir" )  
  
  FIND_LIBRARY(GSL_GSLCBLAS_LIBRARY
    NAMES gslcblas libgslcblas
    PATHS  ${GSL_POSSIBLE_ROOT_DIRS}
    PATH_SUFFIXES lib
    DOC "GSL cblas library dir" )
  
  SET(GSL_LIBRARIES ${GSL_GSL_LIBRARY})

  #MESSAGE("DBG\n"
  #  "GSL_GSL_LIBRARY=${GSL_GSL_LIBRARY}\n"
  #  "GSL_GSLCBLAS_LIBRARY=${GSL_GSLCBLAS_LIBRARY}\n"
  #  "GSL_LIBRARIES=${GSL_LIBRARIES}")


ELSE(WIN32)
  
  IF(UNIX)
    #configuration SHFJ
    #SET (GSL_DIR "/shfj/local/gsl-2.3_Ubuntu-16.04-x86_64") #Ubuntu 16.04
    #SET (GSL_DIR "/shfj/local/gsl-2.3_Ubuntu-14.04-x86_64") #Ubuntu 14.04

    SET(GSL_CONFIG_PREFER_PATH 
      "$ENV{GSL_DIR}/bin"
      "$ENV{GSL_DIR}"
      "$ENV{GSL_HOME}/bin" 
      "$ENV{GSL_HOME}" 
      CACHE STRING "preferred path to GSL (gsl-config)")
    FIND_PROGRAM(GSL_CONFIG gsl-config
      ${GSL_CONFIG_PREFER_PATH}
      /usr/bin/
      )
    # MESSAGE("DBG GSL_CONFIG ${GSL_CONFIG}")
    
    IF (GSL_CONFIG) 
      # set CXXFLAGS to be fed into CXX_FLAGS by the user:
      SET(GSL_CXX_FLAGS "`${GSL_CONFIG} --cflags`")
      
      # set INCLUDE_DIRS to prefix+include
      EXEC_PROGRAM(${GSL_CONFIG}
        ARGS --prefix
        OUTPUT_VARIABLE GSL_PREFIX)
      SET(GSL_INCLUDE_DIR ${GSL_PREFIX}/include CACHE STRING INTERNAL)

      # set link libraries and link flags
      EXEC_PROGRAM(${GSL_CONFIG}
        ARGS --libs
        OUTPUT_VARIABLE GSL_LIBRARIES)
#      SET(GSL_INCLUDE_DIR ${GSL_PREFIX}/include CACHE STRING INTERNAL)

#      SET(GSL_LIBRARIES "`${GSL_CONFIG} --libs`")
# Hacked by C. Poupon the previous does not work on linux and is replaced by
# the following execution of the GSL_CONFIG command
      
      # extract link dirs for rpath  
      EXEC_PROGRAM(${GSL_CONFIG}
        ARGS --libs
        OUTPUT_VARIABLE GSL_CONFIG_LIBS )

      # split off the link dirs (for rpath)
      # use regular expression to match wildcard equivalent "-L*<endchar>"
      # with <endchar> is a space or a semicolon
      STRING(REGEX MATCHALL "[-][L]([^ ;])+" 
        GSL_LINK_DIRECTORIES_WITH_PREFIX 
        "${GSL_CONFIG_LIBS}" )
      #      MESSAGE("DBG  GSL_LINK_DIRECTORIES_WITH_PREFIX=${GSL_LINK_DIRECTORIES_WITH_PREFIX}")

      # remove prefix -L because we need the pure directory for LINK_DIRECTORIES
      
      IF (GSL_LINK_DIRECTORIES_WITH_PREFIX)
        STRING(REGEX REPLACE "[-][L]" "" GSL_LINK_DIRECTORIES ${GSL_LINK_DIRECTORIES_WITH_PREFIX} )
      ENDIF (GSL_LINK_DIRECTORIES_WITH_PREFIX)
      SET(GSL_EXE_LINKER_FLAGS "-Wl,-rpath,${GSL_LINK_DIRECTORIES}" CACHE STRING INTERNAL)
      #      MESSAGE("DBG  GSL_LINK_DIRECTORIES=${GSL_LINK_DIRECTORIES}")
      #      MESSAGE("DBG  GSL_EXE_LINKER_FLAGS=${GSL_EXE_LINKER_FLAGS}")

      #      ADD_DEFINITIONS("-DHAVE_GSL")
      #      SET(GSL_DEFINITIONS "-DHAVE_GSL")
      MARK_AS_ADVANCED(
        GSL_CXX_FLAGS
        GSL_INCLUDE_DIR
        GSL_LIBRARIES
        GSL_LINK_DIRECTORIES
        GSL_DEFINITIONS
	)
      MESSAGE(STATUS "Using GSL from ${GSL_PREFIX}")
      
    ELSE(GSL_CONFIG)
      MESSAGE("FindGSL.cmake: gsl-config not found. Please set it manually. GSL_CONFIG=${GSL_CONFIG}")
    ENDIF(GSL_CONFIG)

  ENDIF(UNIX)
ENDIF(WIN32)


IF(GSL_LIBRARIES)
  IF(GSL_INCLUDE_DIR OR GSL_CXX_FLAGS)

    SET(GSL_FOUND 1)
    
  ENDIF(GSL_INCLUDE_DIR OR GSL_CXX_FLAGS)
ENDIF(GSL_LIBRARIES)

# Report failure (newer CMake versions do not do this automatically)
IF(NOT GSL_FOUND)
  IF(GSL_FIND_REQUIRED)
    MESSAGE(FATAL_ERROR "Could NOT find GSL (GNU Scientific Library), which is required.")
  ELSE(GSL_FIND_REQUIRED)
    IF(NOT GSL_FIND_QUIETLY)
      MESSAGE(STATUS "Could NOT find GSL (GNU Scientific Library)")
    ENDIF(NOT GSL_FIND_QUIETLY)
  ENDIF(GSL_FIND_REQUIRED)
ENDIF(NOT GSL_FOUND)
