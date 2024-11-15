find_package(Env)

# ENV_EXECUTE_PROCESS
#
# Usage:
#  ENV_EXECUTE_PROCESS(COMMAND <cmd1> [args1...]
#                      [COMMAND <cmd2> [args2...] [...]]
#                      [ENV <env_var1>=<value_1> [...]]
#                      [WORKING_DIRECTORY <directory>]
#                      [TIMEOUT <seconds>]
#                      [RESULT_VARIABLE <variable>]
#                      [OUTPUT_VARIABLE <variable>]
#                      [ERROR_VARIABLE <variable>]
#                      [INPUT_FILE <file>]
#                      [OUTPUT_FILE <file>]
#                      [ERROR_FILE <file>]
#                      [OUTPUT_QUIET]
#                      [ERROR_QUIET]
#                      [OUTPUT_STRIP_TRAILING_WHITESPACE]
#                      [ERROR_STRIP_TRAILING_WHITESPACE])
#
macro(ENV_EXECUTE_PROCESS)
  set( _args "${ARGN}" )
  
  # Set keywords to find in parameters
  set( _exec_process_keywords 
      WORKING_DIRECTORY
      TIMEOUT
      RESULT_VARIABLE
      OUTPUT_VARIABLE
      ERROR_VARIABLE
      INPUT_FILE
      OUTPUT_FILE
      ERROR_FILE
      OUTPUT_QUIET
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_STRIP_TRAILING_WHITESPACE )

  #message( "Parameters: ${_args}" )
  list( FIND _args ENV _arg_index )
    list( LENGTH _args _args_length )
    set(_capture)
    set(_commands_count 0)
    set(i 0)
    while( i LESS _args_length )
        list( GET _args ${i} _param )
        #message( "Dealing with param: ${_param}" )
        if ( _param STREQUAL "ENV" )
            string( TOLOWER "_${_param}_params" _capture )
        elseif ( _param STREQUAL "COMMAND" )
            # Found new command to get parameters for
            math( EXPR _commands_count "${_commands_count} + 1" )
            string( TOLOWER "_${_param}${_commands_count}_params" _capture )
        elseif (_capture)
            list(FIND _exec_process_keywords "${_param}" _keyword_index )  
            if( _keyword_index EQUAL -1)
                #message("${_param} is not a keyword. Capturing to ${_capture}.")
                list( APPEND "${_capture}" "${_param}" )
            else()
                #message("${_param} is a keyword. Capturing to _exec_process_params.")
                
                # Found an execute_process keyword so we stop parameters capture
                unset(_capture)
                list( APPEND _exec_process_params "${_param}" )
            endif()
        else()
            list( APPEND _exec_process_params "${_param}" )
        endif()
        math( EXPR i "${i} + 1" )
    endwhile()
    
    # Build global command
    set( i 0 )
    set(_command)
    #message( "_commands_count: ${_commands_count}")
    #message( "_env_params: ${_env_params}")
    #message( "_exec_process_params: ${_exec_process_params}")
    while( i LESS _commands_count )
        list( APPEND _command COMMAND "${ENV_EXECUTABLE}" )
        list( APPEND _command ${_env_params} )
        list( APPEND _command ${_command${_commands_count}_params} )
        unset( "_command${_commands_count}_params" )
        math( EXPR i "${i} + 1" )
    endwhile()
    list( APPEND _command ${_exec_process_params} )
    
    # Run the complete final command
    #message("Command: ${_command}")
    execute_process( ${_command} )
    
    unset(i)
    unset(_command)
    unset(_commands_count)
    unset(_env_params)
    unset(_exec_process_params)
    unset(_capture)
    unset(_exec_process_keywords)
    unset(_keyword_index)
    unset(_param)
    unset(_params)
    unset(_params_length)
    unset(_param_index)
    
endmacro()
