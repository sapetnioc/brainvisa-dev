# Version conversion
cmake_minimum_required (VERSION 3.20)

# VERSION_CONVERT
#   Convert version number either to hexadecimal version
#   either to string version.
#
# Usage:
#   VERSION_CONVERT( <variable> version [HEX] [STR] 
#                    [GROUP_LENGTH <number_of_bytes>] )
#   HEX: convert to hexadecimal version number
#   STR: convert to string version number (dot separated)
#   GROUP_LENGTH: specifies the number of bytes in a group
#
# Example:
#   VERSION_CONVERT( result "0x30206" STR )
#   VERSION_CONVERT( result "3.2.6" HEX GROUP_LENGTH 2 )
#
function( VERSION_CONVERT variable version )
  include(UseHexConvert)
  
  set( __args "${ARGN}" )

  # Read HEX option
  list( FIND __args HEX __result )
  if( __result EQUAL -1 )
    set( __hex FALSE )
  else()
    set( __hex TRUE )
    list( REMOVE_AT __args ${__result} )
  endif()

  # Read STR option
  list( FIND __args STR __result )
  if( __result EQUAL -1 )
    set( __str FALSE )
  else()
    set( __str TRUE )
    list( REMOVE_AT __args ${__result} )
  endif()

  # Read GROUP_LENGTH option
  list( FIND __args GROUP_LENGTH __result )
  if( __result EQUAL -1 )
    set( __byte_group_len 1 )
  else()
    list( REMOVE_AT __args ${__result} )
    list( GET __args ${__result} __byte_group_len )
  endif()
  math(EXPR __hex_group_len "${__byte_group_len} * 2")
  
  unset(__result)
  unset(__version)
  unset(__match)
  if (__str)
    string( REGEX MATCH "^0x([0-9a-fA-F]+)$" __match "${version}" )
    if( __match )
        # Convert hexadecimal values
        set(__hex_version "${CMAKE_MATCH_1}")
        unset(__version)
        string(LENGTH ${__hex_version} __len)
        
        while(__len GREATER 0)
            if(NOT(__len LESS __hex_group_len))
                math(EXPR __i "${__len}-${__hex_group_len}")
                string(SUBSTRING "${__hex_version}" 
                       ${__i} ${__hex_group_len} __hex_group)
            else()
                string(SUBSTRING "${__hex_version}" 0 ${__len} __hex_group)
            endif()
            
            # Convert by group of bytes
            hex2dec(__group "${__hex_group}")
            if(__version)
                set(__version "${__group}.${__version}")
            else()
                set(__version "${__group}")
            endif()
            #message("Version ${__version}")
            math(EXPR __len "${__len}-${__hex_group_len}")
        endwhile()
   
        unset(__i)
        unset(__len)
        unset(__group)
        unset(__hex_version)
    else()
        message(FATAL_ERROR "${version} is not a valid hexadecimal value." )
    endif()
    unset(__match)
  else()
    # Check that version string is valid
    string( REGEX MATCH "^([0-9]+[\\.])*([0-9]+)$" __match "${version}" )
    if(__match OR __match EQUAL 0)
        # Splitting string value by replacing "." with ";"
        string(REPLACE "." ";" __list ${version})
        foreach(__group ${__list})
            unset(__hex_group)
            dec2hex(__hex_group "${__group}")
            #message("__hex_group: ${__group} => ${__hex_group}")
            if(DEFINED __hex_group)
                if(DEFINED __version)
                    # Append preceding hex group filled with zeros
                    # Fill up to bytes with 0
                    string(LENGTH "${__hex_group}" __len)
                    if(__len GREATER __hex_value_len)
                        message(FATAL_ERROR "Unable to encode ${__group} value"
                                            "using ${__byte_group_len} bytes.")
                        unset(__version)
                        break()
                    endif()
                    while(__len LESS __hex_value_len)
                        set(__hex_group "0${__hex_group}")
                        math(EXPR __len "${__len} + 1")
                    endwhile()
                endif()
                set(__version "${__version}${__hex_group}")
            endif()
            #message("${__group} => ${__hex_group}")
        endforeach()
        
        if(DEFINED __version)
            set(__version "0x${__version}")
        endif()
    else()
        message(FATAL_ERROR  
                "Version string ${version} is not valid"
                "(it must only contain numbers [0-9] separated with '.')")
    endif()
    unset(__match)
  endif()

  set(${variable} "${__version}" PARENT_SCOPE)

  unset(__args)
  unset(__hex)
  unset(__str)
  unset(__byte_group_len)
  unset(__version)
endfunction()
