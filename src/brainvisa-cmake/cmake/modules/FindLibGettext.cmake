# Find gettext libraries
#
# LIBGETTEXT_FOUND
# LIBGETTEXT_LIBASPRINTF - libasprintf library
# LIBGETTEXT_LIBINTL - libintl library
# LIBGETTEXT_LIBGETTEXTLIB - libgettextlib library
# LIBGETTEXT_LIBGETTEXTPO - libgettextpo library
# LIBGETTEXT_LIBGETTEXTSRC - libgettextsrc library
# LIBGETTEXT_LIBRARIES - gettext libraries

IF(LIBGETTEXT_LIBRARIES)
  # already found  
  SET(LIBGETTEXT_FOUND TRUE)
ELSE()
    unset(__library)
    foreach(__library asprintf 
                      intl 
                      gettextlib 
                      gettextpo 
                      gettextsrc)
        string(TOUPPER ${__library} __var_name)
        
        find_library(LIBGETTEXT_LIB${__var_name} ${__library})
        if(NOT LIBGETTEXT_LIB${__var_name})
            file(GLOB LIBGETTEXT_LIB${__var_name}
                 /usr/lib/lib${__library}.so.?)
        endif()
        
        if(LIBGETTEXT_LIB${__var_name})
            list(APPEND 
                 LIBGETTEXT_LIBRARIES
                 ${LIBGETTEXT_LIB${__var_name}})
            set(LIBGETTEXT_LIB${__var_name}
                ${LIBGETTEXT_LIB${__var_name}}
                CACHE PATH "Gettext ${__library} library"
                FORCE)
        endif()
    endforeach()
    unset(__library)
    
    # Find specific include directories
    FIND_PATH(LIBGETTEXT_INCLUDE_DIR NAMES gettext-po.h)

    if(LIBGETTEXT_LIBRARIES)
        include(UseVersionConvert)
        
        # Try to find gettext version
        if( EXISTS "${LIBGETTEXT_INCLUDE_DIR}/gettext-po.h" )
            file( READ "${LIBGETTEXT_INCLUDE_DIR}/gettext-po.h" header )
            string( REGEX MATCH 
                    "#define[ \\t]+LIBGETTEXTPO_VERSION[ \\t]+(0x[0-9a-fA-F]+)"
                    match "${header}" )

            if( match )
                # Convert hexadecimal version
                version_convert(__version ${CMAKE_MATCH_1} STR)
                set(LIBGETTEXT_VERSION "${__version}" 
                    CACHE STRING "Gettext library version")
                unset(__version)
            endif()
        endif()
        
        # Try to find libintl version
        if( EXISTS "${LIBGETTEXT_INCLUDE_DIR}/libintl.h" )
            file( READ "${LIBGETTEXT_INCLUDE_DIR}/libintl.h" header )
            string( REGEX MATCH 
                    "#define[ \\t]+LIBINTL_VERSION[ \\t]+(0x[0-9a-fA-F]+)" 
                    match "${header}" )

            if( match )
                # Convert hexadecimal version
                version_convert(__version ${CMAKE_MATCH_1} STR)
                set(LIBGETTEXT_LIBINTL_VERSION "${__version}" 
                    CACHE STRING "Gettext Intl library version")
                unset(__version)
            endif()
        endif()
    
        set(LIBGETTEXT_LIBRARIES ${LIBGETTEXT_LIBRARIES}
            CACHE PATH "Gettext libraries" FORCE)
        set(LIBGETTEXT_FOUND TRUE)
    else()
        set(LIBGETTEXT_FOUND FALSE)
        
        if( LIBGETTEXT_FIND_REQUIRED )
            message(SEND_ERROR 
                    "Gettext libraries was not found")
        endif()
        if(NOT LIBGETTEXT_FIND_QUIETLY)
            message(STATUS "Gettext was not found")
        endif()
    endif()
endif()

