# - find DCMTK libraries
#

#  DCMTK_INCLUDE_DIR   - Directories to include to use DCMTK
#  DCMTK_LIBRARIES     - Files to link against to use DCMTK
#  DCMTK_FOUND         - If false, don't try to use DCMTK
#  DCMTK_DIR           - (optional) Source directory for DCMTK
#  DCMTK_VERSION       - (optional) Version for DCMTK
#
# DCMTK_DIR can be used to make it simpler to find the various include
# directories and compiled libraries if you've just compiled it in the
# source tree. Just set it to the root of the tree where you extracted
# the source.
#
# Written for VXL by Amitha Perera. -> Hacked by P. Fillard
# Hacked again by Yann Cointepas
# Hacked again by Cyril Poupon


set( _directories
  "${DCMTK_DIR}"
)

if( NOT _directories )
set( _directories
  "$ENV{DCMTK_DIR}"
)
endif()
  
set( _includeSuffixes
  include
  dcmtk/include
  include/dcmtk
  dcmtk
)
set( _librarySuffixes
  lib
  dcmtk/lib
)
set( _shareSuffixes 
  share/dcmtk
  dcmtk/share/dcmtk
)

# include directory config

if( NOT DCMTK_PRE_353 )
  find_path( DCMTK_config_INCLUDE_DIR config/osconfig.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )
endif()

if( NOT DCMTK_config_INCLUDE_DIR OR DCMTK_PRE_353 )
  # For DCMTK <= 3.5.3
  find_path( DCMTK_config_INCLUDE_DIR osconfig.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )
  if( DCMTK_config_INCLUDE_DIR )
    set( DCMTK_PRE_353 TRUE CACHE STRING
      "if DcmTk version is older or equal to  3.5.3" )
    mark_as_advanced( DCMTK_PRE_353 )
  endif( DCMTK_config_INCLUDE_DIR )
endif()

if( DCMTK_PRE_353 )
  # For DCMTK <= 3.5.3

  find_path( DCMTK_ofstd_INCLUDE_DIR ofstd/ofstdinc.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  find_path( DCMTK_dcmdata_INCLUDE_DIR dcmdata/dctypes.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  find_path( DCMTK_dcmimgle_INCLUDE_DIR dcmimgle/dcmimage.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

else()
  # For DCMTK >= 3.5.4

  # include directory dcmdata
  find_path( DCMTK_dcmdata_INCLUDE_DIR dcmtk/dcmdata/dctypes.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory dcmimage
  find_path( DCMTK_dcmimage_INCLUDE_DIR dcmtk/dcmimage/diargimg.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory dcmimgle
  find_path( DCMTK_dcmimgle_INCLUDE_DIR dcmtk/dcmimgle/dcmimage.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory dcmjpeg
  find_path( DCMTK_dcmjpeg_INCLUDE_DIR dcmtk/dcmjpeg/djdijg16.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory dcmjpls
  find_path( DCMTK_dcmjpls_INCLUDE_DIR dcmtk/dcmjpls/djcodecd.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory dcmnet
  find_path( DCMTK_dcmnet_INCLUDE_DIR dcmtk/dcmnet/dcmtrans.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory dcmpstat
  find_path( DCMTK_dcmpstat_INCLUDE_DIR dcmtk/dcmpstat/dcmpstat.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory dcmqrdb
  find_path( DCMTK_dcmqrdb_INCLUDE_DIR dcmtk/dcmqrdb/dcmqrdba.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory dcmsign
  find_path( DCMTK_dcmsign_INCLUDE_DIR dcmtk/dcmsign/dcsignat.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory dcmsr
  find_path( DCMTK_dcmsr_INCLUDE_DIR dcmtk/dcmsr/dsrbascc.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory dcmtls
  find_path( DCMTK_dcmtls_INCLUDE_DIR dcmtk/dcmtls/tlslayer.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory dcmwlm
  find_path( DCMTK_dcmwlm_INCLUDE_DIR dcmtk/dcmwlm/wldsfs.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory oflog
  find_path( DCMTK_oflog_INCLUDE_DIR dcmtk/oflog/logger.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )

  # include directory ofstd
  find_path( DCMTK_ofstd_INCLUDE_DIR dcmtk/ofstd/ofstdinc.h
    PATHS ${_directories}
    PATH_SUFFIXES ${_includeSuffixes}
  )


endif()


# find library dcmdata
find_library( DCMTK_dcmdata_LIBRARY dcmdata
    PATHS ${_directories}
    PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmimage
find_library( DCMTK_dcmimage_LIBRARY dcmimage
    PATHS ${_directories}
    PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmimgle
find_library( DCMTK_dcmimgle_LIBRARY dcmimgle
    PATHS ${_directories}
    PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmjpeg
find_library(DCMTK_dcmjpeg_LIBRARY dcmjpeg
  PATHS ${_directories}
  PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmjpls
find_library(DCMTK_dcmjpls_LIBRARY dcmjpls
  PATHS ${_directories}
  PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmnet
find_library( DCMTK_dcmnet_LIBRARY dcmnet
    PATHS ${_directories}
    PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmpstat
find_library( DCMTK_dcmpstat_LIBRARY dcmpstat
    PATHS ${_directories}
    PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmqrdb
find_library( DCMTK_dcmqrdb_LIBRARY dcmqrdb
    PATHS ${_directories}
    PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmdsig
find_library( DCMTK_dcmdsig_LIBRARY dcmdsig
    PATHS ${_directories}
    PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmsr
find_library( DCMTK_dcmsr_LIBRARY dcmsr
    PATHS ${_directories}
    PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmtls
find_library( DCMTK_dcmtls_LIBRARY dcmtls
    PATHS ${_directories}
    PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmwlm
find_library( DCMTK_dcmwlm_LIBRARY dcmwlm
    PATHS ${_directories}
    PATH_SUFFIXES ${_librarySuffixes}
)

# find library oflog
find_library(DCMTK_oflog_LIBRARY oflog
  PATHS ${_directories}
  PATH_SUFFIXES ${_librarySuffixes}
)

# find library ofstd
find_library( DCMTK_ofstd_LIBRARY ofstd
    PATHS ${_directories}
    PATH_SUFFIXES ${_librarySuffixes}
)

# find library ijg8
find_library(DCMTK_ijg8_LIBRARY ijg8
  PATHS ${_directories}
  PATH_SUFFIXES ${_librarySuffixes}
)

# find library ijg12
find_library(DCMTK_ijg12_LIBRARY ijg12
  PATHS ${_directories}
  PATH_SUFFIXES ${_librarySuffixes}
)

# find library ijg16
find_library(DCMTK_ijg16_LIBRARY ijg16
  PATHS ${_directories}
  PATH_SUFFIXES ${_librarySuffixes}
)

# find library dcmdsig
find_library(DCMTK_dcmdsig_LIBRARY dcmdsig
  PATHS ${_directories}
  PATH_SUFFIXES ${_librarySuffixes}
)

find_file( DCMTK_dict dicom.dic
    PATHS ${_directories} ${CMAKE_LIBRARY_PATH} ${CMAKE_FRAMEWORK_PATH}
    PATH_SUFFIXES ${_librarySuffixes} ${_shareSuffixes}
)
if( NOT DCMTK_dict )
  get_filename_component( _libdir ${DCMTK_dcmdata_LIBRARY} DIRECTORY )
  find_file( DCMTK_dict dicom.dic
    PATHS ${_libdir} ${_libdir}/../share/libdcmtk5
    ${_libdir}/../share/libdcmtk12 /usr/share/libdcmtk5 /usr/share/libdcmtk12
    PATH_SUFFIXES ${_librarySuffixes} ${_shareSuffixes}
)
endif()

if( DCMTK_config_INCLUDE_DIR AND
    DCMTK_ofstd_INCLUDE_DIR AND
    DCMTK_ofstd_LIBRARY AND
    DCMTK_dcmdata_INCLUDE_DIR AND
    DCMTK_dcmdata_LIBRARY AND
    DCMTK_dcmimgle_INCLUDE_DIR AND
    DCMTK_dcmimgle_LIBRARY )

  SET( DCMTK_FOUND "YES" )
  
  IF( DCMTK_PRE_353 )
    SET( DCMTK_INCLUDE_DIR
      ${DCMTK_config_INCLUDE_DIR}
      ${DCMTK_ofstd_INCLUDE_DIR}/ofstd
      ${DCMTK_dcmdata_INCLUDE_DIR}/dcmdata
      ${DCMTK_dcmimgle_INCLUDE_DIR}/dcmimgle
    )
  ELSE()
    SET( DCMTK_INCLUDE_DIR
      ${DCMTK_dcmdata_INCLUDE_DIR}
      ${DCMTK_config_INCLUDE_DIR}
      ${DCMTK_config_INCLUDE_DIR}/../
      ${DCMTK_config_INCLUDE_DIR}/config
      ${DCMTK_dcmdata_INCLUDE_DIR}/dcmtk/dcmdata
      ${DCMTK_dcmimage_INCLUDE_DIR}/dcmtk/dcmdata
      ${DCMTK_dcmimgle_INCLUDE_DIR}/dcmtk/dcmnet
      ${DCMTK_dcmimgle_INCLUDE_DIR}/dcmtk/dcmtls
      ${DCMTK_dcmimgle_INCLUDE_DIR}/dcmtk/dcmimgle
      ${DCMTK_dcmimgle_INCLUDE_DIR}/dcmtk/dcmjpeg
      ${DCMTK_ofstd_INCLUDE_DIR}/dcmtk/ofstd
    )
  ENDIF()

  # For DCMTK >= 3.6.0
  IF(DCMTK_oflog_LIBRARY)
   SET(DCMTK_INCLUDE_DIR
     ${DCMTK_dcmdata_INCLUDE_DIR}
     ${DCMTK_config_INCLUDE_DIR}
     ${DCMTK_config_INCLUDE_DIR}/../
     ${DCMTK_config_INCLUDE_DIR}/config
     ${DCMTK_dcmdata_INCLUDE_DIR}/dcmtk/dcmdata
     ${DCMTK_dcmimage_INCLUDE_DIR}/dcmtk/dcmimage
     ${DCMTK_dcmimgle_INCLUDE_DIR}/dcmtk/dcmimgle
     ${DCMTK_dcmjpeg_INCLUDE_DIR}/dcmtk/dcmjpeg
     ${DCMTK_dcmjpls_INCLUDE_DIR}/dcmtk/dcmjpls
     ${DCMTK_dcmnet_INCLUDE_DIR}/dcmtk/dcmnet
     ${DCMTK_dcmpstat_INCLUDE_DIR}/dcmtk/dcmpstat
     ${DCMTK_dcmqrdb_INCLUDE_DIR}/dcmtk/dcmqrdb
     ${DCMTK_dcmsign_INCLUDE_DIR}/dcmtk/dcmsign
     ${DCMTK_dcmsr_INCLUDE_DIR}/dcmtk/dcmsr
     ${DCMTK_dcmtls_INCLUDE_DIR}/dcmtk/dcmtls
     ${DCMTK_dcmwlm_INCLUDE_DIR}/dcmtk/dcmwlm
     ${DCMTK_oflog_INCLUDE_DIR}/dcmtk/oflog
     ${DCMTK_ofstd_INCLUDE_DIR}/dcmtk/ofstd
   )
   SET(DCMTK_LIBRARIES
     ${DCMTK_dcmjpeg_LIBRARY}
     ${DCMTK_dcmdata_LIBRARY}
     ${DCMTK_dcmimage_LIBRARY}
     ${DCMTK_dcmimgle_LIBRARY}
     ${DCMTK_dcmnet_LIBRARY}
     ${DCMTK_dcmpstat_LIBRARY}
     ${DCMTK_dcmqrdb_LIBRARY}
     ${DCMTK_dcmsr_LIBRARY}
     ${DCMTK_dcmtls_LIBRARY}
     ${DCMTK_ijg12_LIBRARY}
     ${DCMTK_ijg16_LIBRARY}
     ${DCMTK_ijg8_LIBRARY}
     ${DCMTK_oflog_LIBRARY}
     ${DCMTK_ofstd_LIBRARY}
     ${DCMTK_dcmdsig_LIBRARY}
   )
  ELSE(DCMTK_oflog_LIBRARY)
    IF(DCMTK_PRE_353)
      SET( DCMTK_LIBRARIES
        ${DCMTK_dcmimgle_LIBRARY}
        ${DCMTK_dcmdata_LIBRARY}
        ${DCMTK_ofstd_LIBRARY}
      )
    ELSE()
        SET(DCMTK_LIBRARIES
            ${DCMTK_dcmjpeg_LIBRARY}
            ${DCMTK_dcmdata_LIBRARY}
            ${DCMTK_dcmdsig_LIBRARY}
            ${DCMTK_dcmimage_LIBRARY}
            ${DCMTK_dcmimgle_LIBRARY}
            ${DCMTK_dcmpstat_LIBRARY}
            ${DCMTK_dcmqrdb_LIBRARY}
            ${DCMTK_dcmsr_LIBRARY}
            ${DCMTK_dcmtls_LIBRARY}
            ${DCMTK_dcmwlm_LIBRARY}
            ${DCMTK_ijg12_LIBRARY}
            ${DCMTK_ijg16_LIBRARY}
            ${DCMTK_ijg8_LIBRARY}
            ${DCMTK_ofstd_LIBRARY}
        )
    ENDIF()
    IF(DCMTK_dcmnet_LIBRARY)
      SET( DCMTK_LIBRARIES
      ${DCMTK_dcmnet_LIBRARY}
      ${DCMTK_LIBRARIES}
      )
    ENDIF(DCMTK_dcmnet_LIBRARY)

  ENDIF(DCMTK_oflog_LIBRARY)

  LIST(REMOVE_DUPLICATES DCMTK_INCLUDE_DIR)

  IF(DEFINED ENV{DCMTK_DIR})
  	set(DCMTK_INCLUDE_DIR ${DCMTK_INCLUDE_DIR}
        $ENV{DCMTK_DIR}/include)
  ELSEIF(DEFINED DCMTK_DIR)
  	set(DCMTK_INCLUDE_DIR ${DCMTK_INCLUDE_DIR}
        ${DCMTK_DIR}/include)
  ENDIF()

  IF(DCMTK_dcmnet_LIBRARY)
   IF(EXISTS /etc/debian_version AND EXISTS /lib64/libwrap.so.0)
     SET( DCMTK_LIBRARIES
     ${DCMTK_LIBRARIES}
     /lib64/libwrap.so.0
     )
   ELSE()
     IF(EXISTS /etc/debian_version AND EXISTS /usr/lib/libwrap.so)
       SET( DCMTK_LIBRARIES
     	 ${DCMTK_LIBRARIES}
     	 /usr/lib/libwrap.so
       )
     ELSE()
       IF(EXISTS /etc/redhat-release AND EXISTS /usr/lib64/libwrap.so.0)
     	 SET( DCMTK_LIBRARIES
     	 ${DCMTK_LIBRARIES}
     	 /usr/lib64/libwrap.so.0
     	 )
       ELSE()
     	 IF(EXISTS /etc/debian_version AND EXISTS /lib/libwrap.so.0)
     	   SET( DCMTK_LIBRARIES
     	   ${DCMTK_LIBRARIES}
     	   /lib/libwrap.so.0
     	   )
     	 ELSE()
     	   IF(EXISTS /etc/redhat-release AND EXISTS /usr/lib/libwrap.so.0)
     	     SET( DCMTK_LIBRARIES
     	     ${DCMTK_LIBRARIES}
     	     /usr/lib/libwrap.so.0
     	     )
	   ELSE()
	   
     	     IF(EXISTS /etc/redhat-release AND EXISTS /lib/x86_64-linux-gnu/libwrap.so.0)
     	       SET( DCMTK_LIBRARIES 
	       ${DCMTK_LIBRARIES}
               /etc/redhat-release AND EXISTS /lib/x86_64-linux-gnu/libwrap.so.0
     	       )
	     ENDIF(EXISTS /etc/redhat-release AND EXISTS /lib/x86_64-linux-gnu/libwrap.so.0)
	   
     	   ENDIF(EXISTS /etc/redhat-release AND EXISTS /usr/lib/libwrap.so.0)
     	 ENDIF(EXISTS /etc/debian_version AND EXISTS /lib/libwrap.so.0)
       ENDIF()
     ENDIF()
   ENDIF()

  ENDIF(DCMTK_dcmnet_LIBRARY)

  if( DCMTK_dcmtls_LIBRARY )
    find_package( OpenSSL )
    if( OPENSSL_FOUND )
      set( DCMTK_LIBRARIES ${DCMTK_LIBRARIES} ${OPENSSL_LIBRARIES}  )
    endif()
  endif()

  IF( WIN32)
    find_library(netapi32 netapi32)
    SET( DCMTK_LIBRARIES ${DCMTK_LIBRARIES} ${netapi32} )
  ENDIF( WIN32 )

  IF( UNIX )
    find_package( ZLIB REQUIRED)
    if( ZLIB_FOUND )
      SET( DCMTK_LIBRARIES ${DCMTK_LIBRARIES} ${ZLIB_LIBRARIES} )
    endif( ZLIB_FOUND )
  ENDIF( UNIX )

  if(NOT DCMTK_VERSION)
    # Try to find version
    list(APPEND __dcmtk_version_files 
          "dcmtk/dcmdata/dcuid.h"
          "dcmtk/config/cfunix.h"
          "dcmtk/config/osconfig.h")
        
    list(APPEND __dcmtk_version_regex
          "#define[ \\t]*OFFIS_DCMTK_VERSION_STRING[ \\t]*\"([^\"]*)\""
          "#define[ \\t]*PACKAGE_VERSION[ \\t]*\"([^\"]*)\"")
  
    foreach(__include_dir ${DCMTK_INCLUDE_DIR})
      foreach(__vf ${__dcmtk_version_files})
        set(__vf "${__include_dir}/${__vf}")
        if( EXISTS "${__vf}" )
          foreach(__re ${__dcmtk_version_regex})
            file( READ "${__vf}" header )
            string( REGEX MATCH "${__re}" match "${header}" )
            if( match )
              set( DCMTK_VERSION "${CMAKE_MATCH_1}" CACHE STRING "Dicom toolkit version" )
              break()
            endif()
          endforeach()
          unset(__re)
        endif()
        if(DCMTK_VERSION)
          break()
        endif()
      endforeach()
      unset(__vf)
      if(DCMTK_VERSION)
        break()
      endif()
    endforeach()
    unset(__include_dir)
    unset(__dcmtk_version_files)
    unset(__dcmtk_version_regex)
  endif()

  IF( APPLE )
    find_package( ZLIB )
    if( ZLIB_FOUND )
      SET( DCMTK_LIBRARIES ${DCMTK_LIBRARIES} ${ZLIB_LIBRARIES} )
    endif( ZLIB_FOUND )
    if( DCMTK_VERSION VERSION_GREATER "3.6.1" )
      find_package( Iconv )
      if( Iconv_FOUND )
        set( DCMTK_LIBRARIES ${DCMTK_LIBRARIES} ${Iconv_LIBRARIES} )
      endif()
    endif()
  ENDIF( APPLE )

endif()


if( NOT DCMTK_FOUND )
  set( DCMTK_DIR "" CACHE PATH "Root of DCMTK source tree (optional)." )
  mark_as_advanced( DCMTK_DIR )
  if( NOT DCMTK_FIND_QUIETLY )
    if( DCMTK_FIND_REQUIRED )
      message( FATAL_ERROR "dcmtk not found" )
    else()
      message( STATUS "dcmtk not found" )
    endif()
  endif()
endif()
