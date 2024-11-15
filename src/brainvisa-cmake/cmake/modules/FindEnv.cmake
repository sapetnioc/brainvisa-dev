if(NOT ENV_EXECUTABLE)
    find_program(ENV_EXECUTABLE NAMES env)
    
    if (NOT ENV_EXECUTABLE)
        message(WARNING "Unable to find env program")
    endif()
    
    mark_as_advanced(ENV_EXECUTABLE)
endif()
