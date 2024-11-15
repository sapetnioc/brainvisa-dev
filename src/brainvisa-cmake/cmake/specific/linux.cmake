
if ( "${CMAKE_SYSTEM_NAME}" STREQUAL "Linux" )
    message( STATUS "Use specific CMake code for Linux" )

    # something has changed somewhere, the ELF format is not recognized by default
    # any longer and makes install fail because of a rpath/relink step missing.
    # The solution is to force ELF format
    # see https://cmake.org/Bug/view.php?id=13934#c37157
    set(CMAKE_EXECUTABLE_FORMAT "ELF")

endif()