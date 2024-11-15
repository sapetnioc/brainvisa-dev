# Try to find the hdf5 library
# Once done this will define
#
# HDF5_FOUND         - system has hdf5 and it can be used
# HDF5_INCLUDE_DIRS  - directory where the header file can be found
# HDF5_LIBRARIES     - the hdf5 libraries
# HDF5_DEFINITIONS


if( NOT HDF5_FOUND )

  if (NOT CMAKE_CROSSCOMPILING)
    # First, try to use the FindHDF5 module included with CMake 2.8 and later
    if( CMAKE_VERSION VERSION_GREATER 2.8.6 )
      # look for hl module only with cmake >= 2.8.7
      set( HDF5_FIND_COMPONENTS C;HL )
    endif()
    include("${CMAKE_ROOT}/Modules/FindHDF5.cmake" OPTIONAL)
  endif()

  # for compatibility with our older code
  if( HDF5_FOUND )
    set( HDF5_LIBRARY ${HDF5_LIBRARIES} CACHE FILEPATH "HDF5 library" )
  endif()

  # Fall back to a simpler detection method
  if( NOT HDF5_FOUND )

    FIND_PATH( HDF5_INCLUDE_DIR hdf5.h
      ${HDF5_DIR}/include
      /usr/include
    )

    FIND_LIBRARY( HDF5_LIBRARIES hdf5
      ${HDF5_DIR}/lib
      /usr/lib
    )

    find_library( HDF5_HL_LIBRARIES hdf5_hl
      ${HDF5_DIR}/lib
      /usr/lib
    )

    IF( HDF5_INCLUDE_DIR )
      IF(NOT(HDF5_C_INCLUDE_DIR))
        set(HDF5_C_INCLUDE_DIR "${HDF5_INCLUDE_DIR}")
      ENDIF()
      
      IF( HDF5_LIBRARIES )

        SET( HDF5_FOUND "YES" CACHE BOOL "specify that HDF5 library was found")
        set( HDF5_DEFINITIONS )
        set( HDF5_INCLUDE_DIRS ${HDF5_INCLUDE_DIR} )

      ENDIF( HDF5_LIBRARIES )
    ENDIF( HDF5_INCLUDE_DIR )

    IF( NOT HDF5_FOUND )
      SET( HDF5_DIR "" CACHE PATH "Root of HDF5 source tree (optional)." )
      MARK_AS_ADVANCED( HDF5_DIR )
    ENDIF( NOT HDF5_FOUND )
  endif()

  # For compatibility with our older code
  if( HDF5_FOUND )
    # Try to find HDF5 version
    if( EXISTS "${HDF5_C_INCLUDE_DIR}/H5pubconf.h" )
      file( READ "${HDF5_C_INCLUDE_DIR}/H5pubconf.h" header )
      string( REGEX MATCH "#define[ \\t]+(H5_)?VERSION[ \\t]+\"([^\"]+)\"" match "${header}" )
      if( match )
        set(HDF5_VERSION "${CMAKE_MATCH_2}" CACHE STRING "HDF5 library version")
      endif()
    endif()
      
    set( HDF5_LIBRARY ${HDF5_LIBRARIES} CACHE FILEPATH "HDF5 library" )
    if( NOT HDF5_INCLUDE_DIR )
      set( HDF5_INCLUDE_DIR ${HDF5_C_INCLUDE_DIR} )
    endif()
  endif()

endif()
