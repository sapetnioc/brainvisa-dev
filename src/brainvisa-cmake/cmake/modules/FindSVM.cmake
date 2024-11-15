# Try to find the svm library
# Once done this will define
#
# SVM_FOUND        - system has svm and it can be used
# SVM_INCLUDE_DIRS - directory where the header file can be found
# SVM_LIBRARIES    - the svm libraries


# __SVM_GET_VERSION
#    Read version from header file
#
# Usage:
#
#   __SVM_GET_VERSION( filepath )
#
function(__SVM_GET_VERSION)
    list( GET ARGN 0 __header_file )

    # Read file content from header file
    file(READ "${__header_file}" __svm_header_content)
    
    # Extract version information
    set(__regex "#define LIBSVM_VERSION \([0-9]+\)")
    string(REGEX MATCHALL "${__regex}" __replaced ${__svm_header_content})
    if( NOT __replaced )
        # libsvm older than 3.0 did not contain version information
        set(__version "2.83") # most likely this version, doesn't really matter
    else()
        string(LENGTH "${__replaced}" __length)
        math(EXPR __length "${__length} - 23")
        string(SUBSTRING "${__replaced}" 23 ${__length} __replaced)
        string(LENGTH "${__replaced}" __length)
        set(__version_lst)
        while("${__length}" GREATER 2)
            math(EXPR __start "${__length} - 2")
            string(SUBSTRING "${__replaced}" ${__start} 2 __part)
            #string(SUBSTRING "${__replaced}" 0 ${__start} __replaced)
            list(INSERT __version_lst 0 "${__part}")
            set(__length ${__start})
        endwhile()
        if(${__length} GREATER 0)
            string(SUBSTRING "${__replaced}" 0 ${__length} __part)
            list(INSERT __version_lst 0 "${__part}")
        endif()
        list(LENGTH __version_lst __length)
        if(${__length} GREATER 0)
            list(GET __version_lst 0 __major )
            set(__major "${__major}" PARENT_SCOPE)
            if(${__length} GREATER 1)
                list(GET __version_lst 1 __minor )
                set(__minor ${__minor} PARENT_SCOPE)
            endif()
        endif()
        string(REPLACE ";" "." __version "${__version_lst}")
    endif()
    set(__version "${__version}" PARENT_SCOPE)
    #message("===== __version_lst: ${__version_lst}, __version ${__version}, __major: ${__major}, __minor: ${__minor}")

endfunction()

if(SVM_INCLUDE_DIRS AND SVM_LIBRARIES)
  set(SVM_FOUND TRUE)
else()
  find_path( SVM_INCLUDE_DIRS "svm.h"
      PATHS ${SVM_DIR}/include
      /usr/local/include
      /usr/include
      PATH_SUFFIXES libsvm/include include/libsvm-3.0/libsvm include/libsvm-2.0/libsvm include/libsvm include )
  
  FIND_LIBRARY( SVM_LIBRARIES svm
    PATHS ${SVM_DIR}/lib
    /usr/local/lib
    /usr/lib
    PATH_SUFFIXES libsvm/lib lib
  )
  
  if( SVM_INCLUDE_DIRS AND SVM_LIBRARIES )
    # Try to find the version of svm library
    set(__version)
    __SVM_GET_VERSION("${SVM_INCLUDE_DIRS}/svm.h")
    set(SVM_VERSION "${__version}" CACHE STRING "Version of SVM")
    set(SVM_VERSION_MAJOR "${__version_major}" CACHE STRING "Major version of SVM")
    set(SVM_VERSION_MINOR "${__version_minor}" CACHE STRING "Minor version of SVM")
    set(SVM_FOUND TRUE)
    message(STATUS "-- Found LibSVM2: ${SVM_LIBRARIES} (found version: \"${SVM_VERSION}\")")
  else()
    IF( NOT SVM_FOUND )
      SET( SVM_DIR "" CACHE PATH "Root of SVM source tree (optional)." )
      MARK_AS_ADVANCED( SVM_DIR )
    ENDIF( NOT SVM_FOUND )
    if( SVM_FIND_REQUIRED )
      message( SEND_ERROR "SVM library was not found." )
    else()
      if(NOT SVM_FIND_QUIETLY)
        message(STATUS "SVM library was not found.")
      endif()
    endif()

  endif()
  
endif()