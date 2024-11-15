===============
CMake functions
===============

.. highlight:: cmake

``Brainvisa-cmake`` provides a set of CMake functions which help configuring Brainbisa-cmake projects. They can (should) be used within ``CMakeLists.txt`` files of peojects.


brainvisa_add_command_help
--------------------------

Add target to generate command help files

::

    BRAINVISA_ADD_COMMAND_HELP( name
                                [COMPONENT <component>]
                                [HELP_COMMAND <command>]
                                [HELP_DEPENDS <dependencies>] )


brainvisa_add_executable
------------------------

Add executable target and reference executable for the component.
Executables added with ``BRAINVISA_ADD_EXECUTABLE`` are referenced a
cache variable named ``${component}-commands``.

::

    BRAINVISA_ADD_EXECUTABLE( <name>
                              [WIN32] [MACOSX_BUNDLE] [EXCLUDE_FROM_ALL]
                              source1 ... sourceN
                              [COMPONENT <component>]
                              [IS_SCRIPT]
                              [HELP_COMMAND <command> arg1 ... argN]
                              [HELP_GENERATE On/Off]
                              [OUTPUT_NAME commandname] )

if ``OUTPUT_NAME`` is set, ``set_property( TARGET <name> PROPERTY OUTPUT_NAME <commandname> )``
is called, and the command help is set with the name ``<commandname>`` instead of ``<name>``.


brainvisa_add_sip_python_module
-------------------------------

::

    BRAINVISA_ADD_SIP_PYTHON_MODULE( <module> <directory> <mainSipFile>
                                     [ SIP_SOURCES <file> ... ]
                                     [ SIP_INCLUDE <directory> ... ]
                                     [ SIP_INSTALL <directory> ] )


brainvisa_add_pytranslation
---------------------------

Search recursively PyQt linguist source files (``*.ts``) generated from python
(PyQt) sources, in the directory source share directory
and generates the commands to create the associated ``*.qm`` files in the build
share directory and creates associated install rules.

::

    BRAINVISA_ADD_PYTRANSLATION(
      <name of the source share directory where finding the *.ts files>
      <name of the destination share directory where writing the *.qm files> <component>
      [source directory to search python files] )


brainvisa_add_translation
-------------------------

Search recursively qt linguist source files (``*.ts``) in the directory source share directory
and generates the commands to create the associated ``*.qm`` files in the build share directory
and creates associated install rules.

::

    BRAINVISA_ADD_TRANSLATION(
      <name of the source share directory where finding the *.ts files>
      <name of the destination share directory where writing the *.qm files> <component>
      [source directory to search c++ files] )


.. _brainvisa_add_test:

brainvisa_add_test
------------------

::

    BRAINVISA_ADD_TEST( NAME <name> [CONFIGURATIONS [Debug|Release|...]]
                        [WORKING_DIRECTORY dir]
                        COMMAND <command> [arg1 [arg2 ...]]
                        [TYPE Exe|Python] )

Add a test to the project with the specified arguments.
brainvisa_add_test(testname Exename arg1 arg2 ... )
If ``TYPE Python`` is given, the appropriate python interpreter is used to
start the test (i.e.: target python for cross compiling case).

ex:

.. code-block:: cmake

    brainvisa_add_test( axon-tests "${PYTHON_EXECUTABLE_NAME}"
                        -m brainvisa.tests.test_axon )


brainvisa_copy_and_install_headers
----------------------------------

::

    BRAINVISA_COPY_AND_INSTALL_HEADERS( <headers list> <include directory>
                                        <install component>
                                        [NO_SYMLINKS] )


brainvisa_copy_directory
------------------------

Recursively copy and install all files in <source directory> except files named
``CMakeLists.txt``, ``*~`` or ``*/.svn/*``.

::

    BRAINVISA_COPY_DIRECTORY( <source directory> <destination directory>
                              <component>
                              [IMMEDIATE]
                              [GET_TARGET <target variable>]
                              [NO_SYMLINKS] )


brainvisa_copy_files
--------------------

::

    BRAINVISA_COPY_FILES( <component> <source files>
                          [SOURCE_DIRECTORY <directory>]
                          DESTINATION <destination directory>
                          [IMMEDIATE]
                          [GET_TARGET <target variable>]
                          [TARGET <target name>]
                          [GET_OUTPUT_FILES <target variable>]
                          [NO_SYMLINKS] )


brainvisa_copy_python_directory
-------------------------------

Create targets to copy, byte compile and install all Python code
contained in a directory.

::

    BRAINVISA_COPY_PYTHON_DIRECTORY( <python directory> <component>
                                     <destination directory>
                                     [NO_SYMLINKS]
                                     [INSTALL_ONLY] )

``<python directory>``
    python directory to copy

``<component>``
    name of the component passed to ``BRAINVISA_INSTALL``.

``<destination directory>``
    directory where the wiles will be copied
    (relative to build directory).

::

    BRAINVISA_COPY_PYTHON_DIRECTORY( <python directory> <component> )

``<destination directory>`` is set to the right most directory
name in ``<python directory>``

Example:

::

    BRAINVISA_COPY_PYTHON_DIRECTORY( ${CMAKE_CURRENT_SOURCE_DIR}/python
                                     brainvisa_python )


brainvisa_dependency
--------------------

::

   BRAINVISA_DEPENDENCY( <package type> <dependency type> <component>
                         <component package type>
                         [ <version ranges> ]
                         [BINARY_INDEPENDENT] )

Examples:

.. code-block:: cmake

    BRAINVISA_DEPENDENCY( RUN DEPENDS libblitz RUN "2.0.3-4" )
    BRAINVISA_DEPENDENCY( DEV DEPENDS libblitz DEV ">= 2.0" )
    BRAINVISA_DEPENDENCY( RUN RECOMMENDS dcmtk RUN "3.1.2" )
    BRAINVISA_DEPENDENCY( DEV RECOMMENDS dcmtk DEV )
    BRAINVISA_DEPENDENCY( RUN DEPENDS soma-io RUN "3.2.4-20100908" )
    BRAINVISA_DEPENDENCY( DEV DEPENDS soma-io DEV ">= 3.2.0;<< 3.3.0" )
    BRAINVISA_DEPENDENCY( RUN DEPENDS soma-base RUN ">= 3.2.0;<< 3.3.0"
                          BINARY_INDEPENDENT )
    BRAINVISA_DEPENDENCY( DEV DEPENDS soma-base DEV ">= 3.2.0;<< 3.3.0" )


brainvisa_find_fsentry
----------------------

Find file system entries from PATHS using search PATTERNS.

::

    BRAINVISA_FIND_FSENTRY( output_variable
                            PATTERNS [ <pattern> ... ]
                            PATHS [ <path> ... ] )

Example:

::

    BRAINVISA_FIND_FSENTRY( real_files
                            PATTERNS *.so PATHS /usr/lib/ )
    foreach( file ${real_files} )
      message( "${file}" )
    endforeach()


brainvisa_generate_commands_help
--------------------------------

Add targets to generate commands help

::

    BRAINVISA_GENERATE_COMMANDS_HELP( [COMPONENT]
                                      <component_1> ... <component_N>  )


brainvisa_generate_commands_help_index
--------------------------------------

Add target to generate command help index

::

    BRAINVISA_GENERATE_COMMANDS_HELP_INDEX( COMPONENT <component> )


brainvisa_generate_docbook_doc
------------------------------

Add rules to generate docbook documentation with ``make doc`` or ``make <component>-doc``
or ``make usrdoc`` or ``make <component>-usrdoc`` if it a user manual or tutorial
or ``make devdoc`` or ``make <component>-devdoc`` if it is developer manual.

::

    BRAINVISA_GENERATE_DOCBOOK_DOC( [EXCLUDE docbook_project_name] )

.. note::

    Docbook support has been deprecated in brainvisa-cmake, Sphinx is now much preferred.


.. _brainvisa_generate_doxygen_doc:

brainvisa_generate_doxygen_doc
------------------------------

Add rules to generate doxygen documentation with "make doc" or "make devdoc".

::

    BRAINVISA_GENERATE_DOXYGEN_DOC( <input_variable>
                                    [<file to copy> ...]
                                    [INPUT_PREFIX <path>]
                                    [COMPONENT <name>] )

``<input_variable>``
    variable containing a string or a list of input sources.
    Its content will be copied in the ``INPUT`` field of the
    Doxygen configuration file.

``<file to copy>``
    file (relative to ``${CMAKE_CURRENT_SOURCE_DIR}``) to copy in
    the build tree. Files are copied in ``${DOXYGEN_BINARY_DIR}``
    if defined, otherwise they are copied in
    ``${PROJECT_BINARY_DIR}/doxygen``. The doxygen configuration
    file is generated in the same directory.

``INPUT_PREFIX``
    directory where to find input files

``COMPONENT``
    component name for this doxygen documentation. it is used to create the output directory and the tag file name.
    By default it is the ``PROJECT_NAME``. but it is useful to give an alternative name when there are several libraries documented with doxygen in the same project.

Before calling this macro, it is possible to specify values that are going to be written in doxygen configuration file by setting variable names ``DOXYFILE_<doxyfile variable name>``. For instance, in order to set project name in Doxygen, one should use:

.. code-block:: cmake

    set( DOXYFILE_PROJECT_NAME, "My wonderful project" ).

Example:

.. code-block:: cmake

    find_package( Doxygen )
    if( DOXYGEN_FOUND )
      set( component_name "cartodata" )
      set( DOXYFILE_PREDEFINED "${AIMS_DEFINITIONS}" )
      set( DOXYFILE_TAGFILES "cartobase.tag=../../cartobase-${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}/doxygen" )
      BRAINVISA_GENERATE_DOXYGEN_DOC(
        _headers
        INPUT_PREFIX "${CMAKE_BINARY_DIR}/include/${component_name}"
        COMPONENT "${component_name}" )
    endif( DOXYGEN_FOUND )


brainvisa_generate_epydoc_doc
-----------------------------

Add rules to generate epydoc documentation with ``make doc`` or ``make <component>-doc`` or ``make devdoc`` or ``make <component>-devdoc``.

::

    BRAINVISA_GENERATE_EPYDOC_DOC( <source directory>
                                   [ <source directory> ... ]
                                   <output directory>
                                   [ EXCLUDE <exclude list> ] )

.. note::

    Epydoc has been deprecated in brainvisa-cmake, Shinx is now much preferred.

Example:

::

    BRAINVISA_GENERATE_EPYDOC_DOC( "${CMAKE_BINARY_DIR}/python/soma"
      "share/doc/${PROJECT_NAME}-${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}/epydoc/html"
      EXCLUDE soma.aims* )


.. _brainvisa_generate_sphinx_doc:

brainvisa_generate_sphinx_doc
-----------------------------

Add rules to generate sphinx documentation with ``make doc`` or ``make <component>-doc`` or ``make devdoc`` or ``make <component>-devdoc``.

::

    BRAINVISA_GENERATE_SPHINX_DOC( <source directory> <output directory>
                                   [TARGET <target_name>]
                                   [USER] )

Example:

.. code-block:: cmake

    BRAINVISA_GENERATE_SPHINX_DOC( "doc/source"
      "share/doc/soma-workflow-${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}" )

if ``TARGET`` argument is not specified, the target name defaults to ``${PROJECT_NAME}-sphinx``

if ``USER`` is specified, the generated doc will be part of the usrdoc (user
documentation) global target, and included in user docs packages.
Otherwise, by default, sphinx docs are considered developer docs (devdoc)


brainvisa_generate_target_name
------------------------------

::

    BRAINVISA_GENERATE_TARGET_NAME _variableName


brainvisa_get_file_list_from_pro
--------------------------------

Retrieve one (or more) list of file names from a ``.pro`` file. This macro
exists for backward compatibility with the older ``build-config`` tool (now abandoned).

::

    BRAINVISA_GET_FILE_LIST_FROM_PRO( <pro file name> <pro variable>
                                      <cmake variable>
                                      [<pro variable> <cmake variable>...] )

Example:

.. code-block:: cmake

    BRAINVISA_GET_FILE_LIST_FROM_PRO(
      ${CMAKE_CURRENT_SOURCE_DIR}/libvip.pro "HEADERS" _h "SOURCES" _s )


brainvisa_get_spaced_quoted_list
--------------------------------


Transform a list into a string containing space separated items. Each item
is surounded by double quotes.

::

    BRAINVISA_GET_SPACED_QUOTED_LIST( <list variable> <output variable> )

Example:

::

    set( _list a b "c d" )
    BRAINVISA_GET_SPACED_QUOTED_LIST( _list _quotedList )
    # equivalent to SET( _quotedList "\"a\" \"b\" \"c d\"" )


brainvisa_install
-----------------


brainvisa_install_directory
---------------------------

Install a directory without copying it into the build tree.

::

    BRAINVISA_INSTALL_DIRECTORY( <directory> <destination> <component> )

Example:

::

    BRAINVISA_INSTALL_DIRECTORY( "/usr/lib/python2.7" "python"
                                 "brainvisa-python" )


brainvisa_install_runtime_libraries
-----------------------------------

Checks and creates install rules for the libraries of the given component.
A list of library files is given in parameter, and the function gets the absolute path of these files, check existance,
and check that it is a dynamic library. The library files are set in an install rule for the component.
The symlinks that point to the library are found and created in the install directory via a custom command attached to the install target of the component.

::

    BRAINVISA_INSTALL_RUNTIME_LIBRARIES( <component> <list of library files> )

Example:

::

    find_package(LibXml2)
    BRAINVISA_INSTALL_RUNTIME_LIBRARIES( libxml2 ${LIBXML2_LIBRARIES} )


brainvisa_project
-----------------


brainvisa_pyuic
---------------

Run ``pyside-uic`` / ``pyuic4`` / ``pyuic`` on a ``.ui`` file to generate the
corresponding ``.py`` module

::

    BRAINVISA_PYUIC( <source_ui_file> <dest_py_file> <relative_path> )


brainvisa_qt_wrap_ui
--------------------

Works like ``QT4_WRAP_UI``, but in addition, the directory of
generated files is user-defined (``<input_outdir>``).

::

    BRAINVISA_QT_WRAP_UI( <outfiles> <inputfile> <input_outdir> )


brainvisa_real_paths
--------------------

Remove all symlinks from a list of paths by applying ``get_filename_component( ... REALPATH )``
to each element of the list.

::

    BRAINVISA_REAL_PATHS( output_variable [ <path> ... ] )

Example:

::

     file( GLOB glob_result /usr/lib/*.so )
     BRAINVISA_REAL_PATHS( real_files ${glob_result} )
     foreach( file ${real_files} )
       message( "${file}" )
     endforeach()


brainvisa_resolve_symbol_libraries
----------------------------------

Resolve symbol library pathes. A list of library or symbol files is given in parameter, and the function gets the absolute path of these files,
check existance, and check that it is a symbol for dynamic library. If the file is a symbol file for dynamic library, try to find the matching
library file.

::

    BRAINVISA_RESOLVE_SYMBOL_LIBRARIES( <output_variable>
                                        PATHS <list of library files> )

Example:

::

    find_package(LibXml2)
    BRAINVISA_RESOLVE_SYMBOL_LIBRARIES( libxml2 ${LIBXML2_LIBRARIES} )


brainvisa_version_convert
-------------------------

Convert version number either to hexadecimal version either to string version.

::

    BRAINVISA_VERSION_CONVERT( <variable> version
                               [HEX] [STR] [BYTES <number_of_bytes>] )

Example:

.. code-block:: cmake

    BRAINVISA_VERSION_CONVERT( result "0x30206" STR )
    BRAINVISA_VERSION_CONVERT( result "3.2.6" HEX BYTES 2 )

