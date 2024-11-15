# This is duplicated from cmake FindPythonInterp.cmake, 
# because it is necessary for us to fix python search method.

# - Find python interpreter
# This module finds if Python interpreter is installed and determines where the
# executables are. This code sets the following variables:
#
#  PYTHONINTERP_FOUND - Was the Python executable found
#  PYTHON_HOST_EXECUTABLE  - path to the Python interpreter
#  PYTHON_EXECUTABLE  - path to the target Python interpreter
#

#=============================================================================
# Copyright 2005-2009 Kitware, Inc.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
if(NOT CMAKE_CROSSCOMPILING AND NOT PYTHON_HOST_EXECUTABLE AND PYTHON_EXECUTABLE)
    # Sets PYTHON_HOST_EXECUTABLE from PYTHON_EXECUTABLE to keep standard 
    # compatibility
    set(PYTHON_HOST_EXECUTABLE "${PYTHON_EXECUTABLE}" 
        CACHE FILEPATH "Python executable path")
else()
    if(NOT PYTHON_HOST_EXECUTABLE OR NOT PYTHON_EXECUTABLE)
        # (To distributed this file outside of CMake, substitute the full
        #  License text for the above reference.)
        FIND_PROGRAM(PYTHON_HOST_EXECUTABLE
            NAMES python3.11 python3.10 python3.9 python3.8 python3.7 python3.6
                  python3 python
            PATHS
                [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\3.8\\InstallPath]
                [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\3.7\\InstallPath]
                [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\3.6\\InstallPath]
                [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\3.5\\InstallPath]
                [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\3.4\\InstallPath]
                [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\2.7\\InstallPath]
        )
        
        if(NOT PYTHON_EXECUTABLE)
            # Also get target python interpreter information if possible
            if(CMAKE_CROSSCOMPILING)
                find_program( PYTHON_EXECUTABLE
                    NAMES python3${CMAKE_EXECUTABLE_SUFFIX} python${CMAKE_EXECUTABLE_SUFFIX}
                    ONLY_CMAKE_FIND_ROOT_PATH
                    DOC "Target python executable path" )
            else()
                # When not cross compiling, setting PYTHON_EXECUTABLE 
                # to PYTHON_HOST_EXECUTABLE
                set(PYTHON_EXECUTABLE "${PYTHON_HOST_EXECUTABLE}" 
                    CACHE FILEPATH "Target python executable path")    
            endif()
        endif()
    endif()
endif()

# handle the QUIETLY and REQUIRED arguments and set PYTHONINTERP_FOUND to TRUE if
# all listed variables are TRUE
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(PythonInterp DEFAULT_MSG 
                                  PYTHON_HOST_EXECUTABLE 
                                  PYTHON_EXECUTABLE)

MARK_AS_ADVANCED(PYTHON_HOST_EXECUTABLE)

