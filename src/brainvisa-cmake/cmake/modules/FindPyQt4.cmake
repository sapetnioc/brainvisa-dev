# The bulk of this script comes from kdelibs's repository
# (https://quickgit.kde.org/ under [kdelibs.git]/cmake/modules/FindPyQt4.cmake)
#
# Find PyQt4
# ~~~~~~~~~~
#
# PyQt4 website: http://www.riverbankcomputing.co.uk/pyqt/index.php
#
# Find the installed version of PyQt4. FindPyQt4 should only be called after
# Python has been found.
#
# This file defines the following variables, which can also be overriden by
# users:
#
# PYQT4_VERSION - The version of PyQt4 found expressed as a 6 digit hex number
#     suitable for comparison as a string
#
# PYQT4_VERSION_STR - The version of PyQt4 as a human readable string.
#
# PYQT4_VERSION_TAG - The Qt4 version tag used by PyQt's sip files.
#
# PYQT4_SIP_DIR - The directory holding the PyQt4 .sip files. This can be unset
# if PyQt4 was built using its new build system and pyqtconfig.py is not
# present on the system, as in this case its value cannot be determined
# automatically.
#
# PYQT4_SIP_FLAGS - The SIP flags used to build PyQt.
#
#
# Copyright (c) 2007-2008, Simon Edwards <simon@simonzone.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products 
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

IF(PYQT4_VERSION)
  # Already in cache, be silent
  SET(PYQT4_FOUND TRUE)
ELSE(PYQT4_VERSION)
  find_package(PythonInterp)
  FIND_FILE(_find_pyqt_py FindPyQt.py
                          HINTS ${CMAKE_MODULE_PATH}
                          CMAKE_FIND_ROOT_PATH_BOTH)
  set(_tmp ${_find_pyqt_py})
  unset(_find_pyqt_py CACHE)
  set(_find_pyqt_py ${_tmp})
  unset(_tmp)

  SET(_python_executable ${PYTHON_HOST_EXECUTABLE})
  IF(CMAKE_CROSSCOMPILING)
    IF(WIN32)
        find_package(Wine)
    ENDIF()
    IF(NOT CMAKE_CROSSCOMPILING_RUNNABLE)
      MESSAGE(STATUS "PyQt4: needs runnable target python interpreter to find version of package. If it is not possible to run target python interpreter on the build platform, it is necessary to manually set PYQT4_VERSION, PYQT4_VERSION_STR, PYQT4_VERSION_TAG, PYQT4_SIP_DIR and PYQT4_SIP_FLAGS to valid values")
    ENDIF()
  ENDIF()

  EXECUTE_PROCESS(COMMAND ${CMAKE_TARGET_SYSTEM_PREFIX} ${PYTHON_EXECUTABLE} ${_find_pyqt_py} 
                  OUTPUT_VARIABLE pyqt_config)
  
  IF(pyqt_config)
    STRING(REGEX MATCH "^pyqt_version:([^\n]+).*$" _dummy ${pyqt_config})
    SET(PYQT4_VERSION "${CMAKE_MATCH_1}" CACHE STRING "PyQt4's version as a 6-digit hexadecimal number")

    STRING(REGEX MATCH ".*\npyqt_version_str:([^\n]+).*$" _dummy ${pyqt_config})
    SET(PYQT4_VERSION_STR "${CMAKE_MATCH_1}" CACHE STRING "PyQt4's version as a human-readable string")

    STRING(REGEX MATCH ".*\npyqt_version_tag:([^\n]+).*$" _dummy ${pyqt_config})
    SET(PYQT4_VERSION_TAG "${CMAKE_MATCH_1}" CACHE STRING "The Qt4 version tag used by PyQt4's .sip files")

    STRING(REGEX MATCH ".*\npyqt_sip_dir:([^\n]+).*$" _dummy ${pyqt_config})
    SET(PYQT4_SIP_DIR "${CMAKE_MATCH_1}" CACHE PATH "The base directory where PyQt4's .sip files are installed")

    STRING(REGEX MATCH ".*\npyqt_sip_flags:([^\n]+).*$" _dummy ${pyqt_config})
    SET(PYQT4_SIP_FLAGS "${CMAKE_MATCH_1}" CACHE STRING "The SIP flags used to build PyQt4")

    IF(NOT IS_DIRECTORY "${PYQT4_SIP_DIR}")
      MESSAGE(WARNING "The base directory where PyQt4's SIP files are installed could not be determined. This usually means PyQt4 was built with its new build system and pyqtconfig.py is not present.\n"
                      "Please set the PYQT4_SIP_DIR variable manually.")
    ELSE(NOT IS_DIRECTORY "${PYQT4_SIP_DIR}")
      SET(PYQT4_FOUND TRUE)
    ENDIF(NOT IS_DIRECTORY "${PYQT4_SIP_DIR}")
  ENDIF(pyqt_config)

  IF(PYQT4_FOUND)
    IF(NOT PYQT4_FIND_QUIETLY)
      MESSAGE(STATUS "Found PyQt4 version: ${PYQT4_VERSION_STR}")
    ENDIF(NOT PYQT4_FIND_QUIETLY)
  ELSE(PYQT4_FOUND)
    IF(PYQT4_FIND_REQUIRED)
      MESSAGE(FATAL_ERROR "Could not find Python")
    ENDIF(PYQT4_FIND_REQUIRED)
  ENDIF(PYQT4_FOUND)
ENDIF(PYQT4_VERSION)

# -----------------------------------------------------------------------------
# end of FindPyQt4.cmake from kdelib.
#
# Below are BrainVISA-specific additions:

if (WIN32)
  # Windows 7 does not authorize pylupdate and pylupdate4
  # to be run using account that is not administrator.
  # So it was necessary to copy it to pylactualize.
  # No comment ...
  set( WIN_PYLUPDATE pylactualize )
endif()
find_program( PYQT4_PYLUPDATE_EXECUTABLE NAMES "${WIN_PYLUPDATE}" pylupdate4 pylupdate
  DOC "pylupdate program path" )
find_program( PYUIC NAMES pyuic4 pyuic DOC "pyuic program path" )
