# Find MinGW
#
# MINGW_FOUND
# MINGW_ROOT_DIR - the mingw root installation directory
# MINGW_BIN_DIR - the mingw binary directory
# MINGW_LIB_DIR - the mingw library directory
# MINGW_INCLUDE_DIR - the mingw include directory
# MINGW_SHARE_DIR - the mingw share directory

if( MINGW_ROOT_DIR AND MINGW_LIB_DIR AND MINGW_INCLUDE_DIR AND MINGW_SHARE_DIR)
  set( MINGW_FOUND TRUE )
else()
  # Try to find mingw32-make program
  FIND_PROGRAM(MINGW_MAKE_PROGRAM mingw32-make PATHS
    "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\MinGW;InstallLocation]/bin" 
    c:/MinGW/bin /MinGW/bin)

  if(MINGW_MAKE_PROGRAM)
    # mingw32-make program was found
    set( MINGW_FOUND TRUE )
    
    get_filename_component(MINGW_BIN_DIR "${MINGW_MAKE_PROGRAM}" PATH)
    get_filename_component(MINGW_ROOT_DIR "${MINGW_BIN_DIR}" PATH)  
    
    set(MINGW_ROOT_DIR "${MINGW_ROOT_DIR}" CACHE PATH "MinGW root directory" FORCE)
    set(MINGW_BIN_DIR "${MINGW_BIN_DIR}" CACHE PATH "MinGW binary directory" FORCE)  
    
    if (IS_DIRECTORY "${MINGW_ROOT_DIR}/lib")
      set(MINGW_LIB_DIR "${MINGW_ROOT_DIR}/lib" CACHE PATH "MinGW library directory" FORCE)  
    else()
      set(MINGW_LIB_DIR MINGW_LIB_DIR-NOTFOUND)
    endif()
    
    if (IS_DIRECTORY "${MINGW_ROOT_DIR}/include")
      set(MINGW_INCLUDE_DIR "${MINGW_ROOT_DIR}/include" CACHE PATH "MinGW include directory" FORCE)
    else()
      set(MINGW_INCLUDE_DIR MINGW_INCLUDE_DIR-NOTFOUND)
    endif()
    
    if (IS_DIRECTORY "${MINGW_ROOT_DIR}/share")
      set(MINGW_SHARE_DIR "${MINGW_ROOT_DIR}/share" CACHE PATH "MinGW share directory" FORCE)
    else()
      set(MINGW_SHARE_DIR MINGW_SHARE_DIR-NOTFOUND)
    endif()
        
  else()
    set( MINGW_FOUND FALSE )
    
    if( MINGW_FIND_REQUIRED )
        message( SEND_ERROR "MinGW was not found." )
    elseif( NOT MINGW_FIND_QUIETLY )
        message( STATUS "MinGW was not found." )
    endif()
  endif()
endif()