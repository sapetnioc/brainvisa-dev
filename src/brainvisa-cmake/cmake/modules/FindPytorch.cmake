# - Find pytorch module in python
#
#  PYTORCH_FOUND      - Was the torch module found
#  PYTORCH_VERSION    - version of the torch module
#  PYTORCH_MODULE_DIR - main directory of the torch module
#

find_package( PythonInterp )
if( PYTHONINTERP_FOUND )

  if ( PYTORCH_VERSION AND PYTHON_EXECUTABLE )
    # Pytorch already found, do nothing
    set( PYTORCH_FOUND TRUE )
  else()

    execute_process( COMMAND ${PYTHON_EXECUTABLE} "-c" "from __future__ import print_function; import torch; print(torch.__file__)"
                    OUTPUT_VARIABLE _torch_mod_file
                    RESULT_VARIABLE _res )
    if( _res EQUAL 0 )
      get_filename_component( _torch_mod_dir "${_torch_mod_file}" PATH )
      set( PYTORCH_FOUND TRUE )
      set( PYTORCH_MODULE_DIR "${_torch_mod_dir}" CACHE PATH
           "main directory of the torch module" )
      execute_process( COMMAND ${PYTHON_EXECUTABLE} "-c" "from __future__ import print_function; import torch; print(torch.__version__)"
                    OUTPUT_VARIABLE _torch_version
                    ERROR_VARIABLE _dummy
                    RESULT_VARIABLE _res )
      if( _res EQUAL 0 )
        set( PYTORCH_VERSION "${_torch_version}" CACHE STRING
             "version of the torch module" )
      endif()
    endif()

  endif()

# else() # PythonInterp_FOUND
#
#   set( PYTORCH_FOUND FALSE )

endif()

