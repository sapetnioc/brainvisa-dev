# Find Wine
#
# WINE_FOUND
# WINE_RUNTIME - the wine runtime binary
# WINE_PATH - the wine path binary

if(WINE_RUNTIME AND WINE_PATH)
  set(WINE_FOUND TRUE)
else()
    # Try to find wine
    find_program(WINE_RUNTIME NAMES wine)
    find_program(WINE_PATH NAMES winepath)

    if(WINE_RUNTIME AND WINE_PATH)
        # wine programs were found
        set(WINE_FOUND TRUE)

        if(WINE_RUNTIME AND WINE_PATH)
            message(STATUS "Wine runtime found ${WINE_RUNTIME}")
            option(CMAKE_CROSSCOMPILING_RUNNABLE "Specify wether it possible or not to run cross compiled binaries on host environment" ON)
            set(CMAKE_TARGET_SYSTEM_PREFIX "${WINE_RUNTIME}" CACHE STRING "Specify target system command to run cross compiled commands")
        endif()

    else()
        set(WINE_FOUND FALSE)
        
        if(WINE_FIND_REQUIRED)
            message(SEND_ERROR "Wine was not found.")
        elseif(NOT WINE_FIND_QUIETLY)
            message(STATUS "Wine was not found.")
        endif()
    endif()
endif()

if(WINE_PATH AND NOT COMMAND TARGET_TO_HOST_PATH)
    message(STATUS "Defining TARGET_TO_HOST_PATH function (Windows => Linux)")
    function(TARGET_TO_HOST_PATH __path __output_var)
        #message("==== TARGET_TO_HOST_PATH (Windows => Linux), path: ${__path}")
        set(__tmp_path)
        foreach(__p ${__path})
            execute_process(COMMAND "${WINE_PATH}" "-u" "-0" "${__p}"
                            OUTPUT_VARIABLE __p)
            # This is the simplest way to resolve issues dued to ':' characters
            # in wine drives
            get_filename_component(__p "${__p}" REALPATH)
            list(APPEND __tmp_path "${__p}")
        endforeach()
        #message("==== TARGET_TO_HOST_PATH (Windows => Linux), translated path: ${__tmp_path}")
        set("${__output_var}" ${__tmp_path} PARENT_SCOPE)
    endfunction()
endif()

if(WINE_PATH AND NOT COMMAND HOST_TO_TARGET_PATH)
    message(STATUS "Defining HOST_TO_TARGET_PATH function (Linux => Windows)")
    function(HOST_TO_TARGET_PATH __path __output_var)
        #message("===== HOST_TO_TARGET_PATH (Linux => Windows), path: ${__path}")
        set(__tmp_path)
        foreach(__p ${__path})
            execute_process(COMMAND "${WINE_PATH}" "-w" "-0" "${__p}"
                            OUTPUT_VARIABLE __p)
            list(APPEND __tmp_path "${__p}")
        endforeach()
        #message("===== HOST_TO_TARGET_PATH (Linux => Windows), translated path: ${__tmp_path}")
        set("${__output_var}" ${__tmp_path} PARENT_SCOPE)    
    endfunction()
endif()

