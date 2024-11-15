=================================================
How to compile a new project with brainvisa-cmake
=================================================

The project must contain 2 files:

* **project_info.cmake**: describes the name and version of the project.

    * Alternatively, for a Python project, this file can be replaced by a python file, **info.py** located in a python subdirectory.

  See also the section `How to create version files with brainvisa-cmake`_.

* **CMakeLists.txt**: describes the elements which will be generated when the project will be built.

Moreover, the new project must be declared in bv_maker.cfg to enable its compilation with bv_maker.

**Example with a personal project:**

::

    [ source $HOME/brainvisa/source ]
      + standard trunk
      + perso/myself/myproject

    [ build $HOME/brainvisa/build/trunk ]
      make_options = -j8
      standard trunk $HOME/brainvisa/source
      + $HOME/brainvisa/source/perso/myself/myproject


Project_info.cmake
==================

**Example:** project_info file for ``anatomist-free`` component of anatomist project.

The following file is in ``anatomist/anatomist-free/tags/4.5/project_info.cmake``.

.. code-block:: cmake

    set( BRAINVISA_PACKAGE_NAME anatomist-free )
    set( BRAINVISA_PACKAGE_MAIN_PROJECT anatomist )
    set( BRAINVISA_PACKAGE_MAINTAINER "CEA - IFR 49" )
    set( BRAINVISA_PACKAGE_VERSION_MAJOR 4 )
    set( BRAINVISA_PACKAGE_VERSION_MINOR 5 )
    set( BRAINVISA_PACKAGE_VERSION_PATCH 0 )
    set( BRAINVISA_PACKAGE_LICENCES "CeCill-B" )

**Example:** project_info file for ``axon`` project.

The following file is in ``axon/trunk/project_info.cmake``.

.. code-block:: cmake

    set( BRAINVISA_PACKAGE_NAME axon )
    set( BRAINVISA_PACKAGE_MAIN_PROJECT axon )
    set( BRAINVISA_PACKAGE_MAINTAINER "IFR 49" )
    set( BRAINVISA_PACKAGE_VERSION_MAJOR 4 )
    set( BRAINVISA_PACKAGE_VERSION_MINOR 6 )
    set( BRAINVISA_PACKAGE_VERSION_PATCH 0 )
    set( BRAINVISA_PACKAGE_LICENCES "CeCill-V2" )

Variables
---------
A few additional optional variables may be set in project_info.cmake:

Info.py alternative
-------------------

If your project is only using the Python language, you may like to use a python file to describe this information, because it would also be usable in the project code as a python module.

Thus, alternatively to the ``project_info.cmake`` file, *brainvisa-cmake* will look for an ``info.py`` file, located:
  * in a ``<modules>`` subdirectory of the project directory.
  * or in a ``python/<modules>`` subdirectory of the project directory.

This file contains basically the same information as ``project_info.cmake`` but in pyton language:

::

    NAME = 'soma-base'
    PROJECT = 'soma'      # optional, taken as NAME if omitted
    MAINTAINER = "CEA"    # optional
    LICENSE = "CeCILL-B"
    version_major = 4
    version_minor = 5
    version_micro = 8

Other variables are of course allowed, it is a standard python files. The variables above will be translated to those of ``project_infi.cmake`` and will be available under the latter names in ``CMakeLists.txt`` files:

.. code-block:: bash

    PROJECT -> BRAINVISA_PACKAGE_MAIN_PROJECT
    NAME -> BRAINVISA_PACKAGE_NAME
    MAINTAINER -> BRAINVISA_PACKAGE_MAINTAINER
    LICENSE -> BRAINVISA_PACKAGE_LICENCES
    version_major -> BRAINVISA_PACKAGE_VERSION_MAJOR
    version_minor -> BRAINVISA_PACKAGE_VERSION_MINOR
    version_micro -> BRAINVISA_PACKAGE_VERSION_PATCH


How to create version files with brainvisa-cmake
================================================

It is possible to use *brainvisa-cmake* to generate source code containing the version stored in ``project_info.cmake``. Here is an example from old_connectomist project. There are two template files, one for C++ and one for Python:

**config/config.h.in:**

.. code-block:: c++

    #ifndef COMIST_VERSION_H
    #define COMIST_VERSION_H

    #define connectomist_version "@connectomist_VERSION@"

    #endif // ifndef COMIST_VERSION_H

**config/config.py.in:**

::

    share = 'connectomist-@BRAINVISA_PACKAGE_VERSION_MAJOR@.@BRAINVISA_PACKAGE_VERSION_MINOR@'
    version = '@BRAINVISA_PACKAGE_VERSION_MAJOR@.@BRAINVISA_PACKAGE_VERSION_MINOR@.@BRAINVISA_PACKAGE_VERSION_PATCH@'

These config files are used in ``CMaleLists.txt`` to generate the matching ``config.h`` and ``config.py`` at configure step:

.. code-block:: cmake

    configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/config/config.py.in" "${CMAKE_BINARY_DIR}/python/connectomist/config.py" @ONLY )
    BRAINVISA_INSTALL( FILES "${CMAKE_BINARY_DIR}/python/connectomist/config.py"
                      DESTINATION "python/connectomist"
                      COMPONENT ${PROJECT_NAME} )
    configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/config/config.h.in" "${CMAKE_BINARY_DIR}/include/connectomist/config.h" @ONLY )
    BRAINVISA_INSTALL( FILES "${CMAKE_BINARY_DIR}/include/connectomist/config.h"
                      DESTINATION "include/connectomist"
                      COMPONENT ${PROJECT_NAME}-dev )


CMakeLists.txt
==============

This file is used by `CMake <http://www.cmake.org>`_ to generate the ``Makefiles`` that will be used to build the project.

This file is written in the CMake specific language. See `CMake documentation <https://cmake.org/documentation>`_ for more information.

On top of the classic CMake functions, we defined functions in *brainvisa-cmake* that help defining ``CMakeLists`` files for Brainvisa projects. These functions names start with ``BRAINVISA_`` and are defined in the file ``brainvisa-cmake-config.cmake.in`` in *brainvisa-cmake* project.

**Example:** ``CMakeLists.txt`` of *morphologist-gpl* component of the *morphologist* project.

.. code-block:: cmake

    cmake_minimum_required( VERSION 3.20 )
    find_package( brainvisa-cmake REQUIRED )
    BRAINVISA_PROJECT()

    BRAINVISA_COPY_PYTHON_DIRECTORY( "${CMAKE_CURRENT_SOURCE_DIR}/brainvisa"
                                     ${PROJECT_NAME} )

    BRAINVISA_COPY_DIRECTORY( "${CMAKE_CURRENT_SOURCE_DIR}/doc"
                              "share/doc/t1mri-${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}"
                              ${PROJECT_NAME}-usrdoc )

    BRAINVISA_CREATE_CMAKE_CONFIG_FILES()

The first 3 lines are mandatory, they check the version of cmake, search for brainvisa_cmake project and initialize the current project information reading the project_info.cmake file.

The rest of the file depends on the content of the component. In the previous example, t1mri-gpl only contains a Brainvisa toolbox (python files) and some documentation. The Brainvisa toolbox files and the documentation will be linked in the build directory.

The last line is useful only if the component is a dependency of another one. If so, you need to write 2 more files in a cmake directory: ``<component>-config.cmake.in`` and ``<component>-use.cmake.in``.


brainvisa-cmake functions
=========================

Here is a glimpse of the *brainvisa-cmake* helper functions which can be used in the ``CMakeLists.txt`` files.

C++
---

BRAINVISA_GET_FILE_LIST_FROM_PRO
++++++++++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_GET_FILE_LIST_FROM_PRO( proFilename <pro variable> <cmake variable> [<pro variable> <cmake variable>...] )

This function was useful when we switched from our home made tool *build-config* to cmake because build-config used ``.pro`` files (similar to Qt's Qmake) containing the list of headers and sources files needed to build a target. With this function, existing ``.pro`` files can be reused in ``CMakeLists`` files.

**Example**

.. code-block:: cmake

    BRAINVISA_GET_FILE_LIST_FROM_PRO( "${_pro}"
                                      TARGET _target
                                      SOURCES _proSources )

*_target* variable contains the name of the lib or executable target.

*_proSources* variable contains the name of C++ source files.


BRAINVISA_COPY_AND_INSTALL_HEADERS
++++++++++++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_COPY_AND_INSTALL_HEADERS( <headers list> <include directory> <target_variable> [NO_SYMLINKS] )

Copies or creates symlinks on the header files in the include directory of the build directory.

**Example:** from anatomist library's ``CMakeLists.txt``

.. code-block:: cmake

    BRAINVISA_GET_FILE_LIST_FROM_PRO( project.pro "HEADERS" _headers "SOURCES" _sources )
    BRAINVISA_COPY_AND_INSTALL_HEADERS( _headers anatomist headersTarget )
    add_library( anatomist SHARED ${_sources} )
    add_dependencies( anatomist ${headersTarget} )

The list of header and source files is extracted from the ``project.pro`` file. The headers are linked in ``<build_directory>/include/anatomist``. The anatomist shared library is created from the source files. A dependency is added between the creation of the library and the copy of the headers.


Python
------

BRAINVISA_COPY_PYTHON_DIRECTORY
+++++++++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_COPY_PYTHON_DIRECTORY ( <python directory&gt <component> [<destination directory>] [NO_SYMLINKS] )

Create targets to copy, byte compile and install all Python code contained in a directory. If the destination directory is not set, the right most directory name in the python directory is used.

**Example:** from axon's ``CMakeLists.txt``

.. code-block:: cmake

    BRAINVISA_COPY_PYTHON_DIRECTORY( "${CMAKE_CURRENT_SOURCE_DIR}/python"
                                     ${PROJECT_NAME} )
    BRAINVISA_COPY_PYTHON_DIRECTORY( "${CMAKE_CURRENT_SOURCE_DIR}/brainvisa"
                                     ${PROJECT_NAME} )

The ``python`` directory in source directory will be linked in the ``python`` directory of the build directory.

The ``brainvisa`` directory in source directory will be linked in the ``brainvisa`` directory of the build directory.


SIP
---

BRAINVISA_ADD_SIP_PYTHON_MODULE
+++++++++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_ADD_SIP_PYTHON_MODULE( <module> <directory> <mainSipFile> [ SIP_SOURCES <file> ... ] [ SIP_INCLUDE <directory> ... ] [ SIP_INSTALL <directory> ] )

**Example:** from pyanatomist's ``CMakeLists.txt``

.. code-block:: cmake

    BRAINVISA_ADD_SIP_PYTHON_MODULE( anatomistsip
        anatomist/cpp
        "${CMAKE_BINARY_DIR}/${ANATOMIST_RELATIVE_SIP_DIRECTORY}/anatomist_VOID.sip"
        SIP_SOURCES ${_generatedSipFileList} ${_sipSources}
        SIP_INCLUDE "${CMAKE_BINARY_DIR}/${ANATOMIST_RELATIVE_SIP_DIRECTORY}"
          "${AIMS-FREE_SIP_DIRECTORY}" "${PYQT${DESIRED_QT_VERSION}_SIP_DIR}"
        SIP_INSTALL "${ANATOMIST_RELATIVE_SIP_DIRECTORY}" )

A library named *anatomistsip* will be created in ``python/anatomist/cpp`` directory in build directory from the sources files indicated.


Qt
--

BRAINVISA_ADD_MOC_FILES
+++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_ADD_MOC_FILES <result variable> <header files>

Creates a makefile target to generate the C++ code needed to replace ``Q_OBJECT`` macro. It uses the Qt Meta-Object compiler (moc).

**Example:** from anatomist library's ``CMakeLists.txt``

.. code-block:: cmake

    BRAINVISA_GET_FILE_LIST_FROM_PRO( project.pro "HEADERS" _headers "SOURCES" _sources )
    BRAINVISA_ADD_MOC_FILES( _sources ${_headers} )
    add_library( anatomist SHARED ${_sources} )

    The files generated by moc will be added to the source files used to generate anatomist library.


BRAINVISA_ADD_TRANSLATION
+++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_ADD_TRANSLATION <source_share_dir> <dest_share_dir> <component>

Searches recursively qt linguist source files (``*.ts``) in the source share directory and generates the commands to create the associated ``*.qm`` files in the build share directory and creates associated install rules.

**Example:** from anatomist-free's ``CMakeLists.txt``

.. code-block:: cmake

    BRAINVISA_ADD_TRANSLATION( "shared" "share/anatomist-${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}" ${PROJECT_NAME})


Files and directories
---------------------

BRAINVISA_COPY_FILES
++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_COPY_FILES( <component> <source files> [SOURCE_DIRECTORY <directory>] DESTINATION <destination directory> [IMMEDIATE] [GET_TARGET <target variable>][GET_OUTPUT_FILES <target variable>] [NO_SYMLINKS] )

Copies a list of files from the source directory to a directory in the build directory.

**Example:** from cartodata's ``CMakeLists.txt``

.. code-block:: cmake

    BRAINVISA_COPY_FILES(${PROJECT_NAME}-devdoc ${CMAKE_CURRENT_SOURCE_DIR}/changelog.html
        DESTINATION share/doc/cartodata-${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}/doxygen )


BRAINVISA_COPY_DIRECTORY
++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_COPY_DIRECTORY( <source directory> <destination directory> <component> [IMMEDIATE] [GET_TARGET <target variable>] [NO_SYMLINKS] )

Recursively copies and installs all files in ``<source directory>`` except files named ``CMakeLists.txt``, ``*~``, ``*/.svn/*``, ``*.odt``, ``*.odp``, ``*.doc``, ``*.sdw``, ``*.sxw``.

**Example:** from axon's ``CMakeLists.txt``

.. code-block:: cmake

    BRAINVISA_COPY_DIRECTORY( "${CMAKE_CURRENT_SOURCE_DIR}/share"
                              "share/${PROJECT_NAME}-${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}"
                              ${PROJECT_NAME} )
    BRAINVISA_COPY_DIRECTORY( "${CMAKE_CURRENT_SOURCE_DIR}/doc"
                              "share/doc/${PROJECT_NAME}-${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}"
                              ${PROJECT_NAME}-usrdoc )
    BRAINVISA_COPY_DIRECTORY( "${CMAKE_CURRENT_SOURCE_DIR}/bin"
                              bin
                              ${PROJECT_NAME} )
    BRAINVISA_COPY_DIRECTORY( "${CMAKE_CURRENT_SOURCE_DIR}/scripts"
                              scripts
                              ${PROJECT_NAME} )


Documentation
-------------

BRAINVISA_GENERATE_DOXYGEN_DOC
++++++++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_GENERATE_DOXYGEN_DOC( <input_variable> [<file to copy> ...] [INPUT_PREFIX <path>] [COMPONENT <name>] )

Adds rules to generate doxygen documentation (documentation of C++ source files) with "make doc" or "make devdoc".

* ``<input_variable>``: variable containing a string or a list of input sources.
* ``<file to copy>``: file (relative to ``${CMAKE_CURRENT_SOURCE_DIR}``) to copy in the build tree. Files are copied in ``${DOXYGEN_BINARY_DIR}`` if defined, otherwise they are copied in ``${PROJECT_BINARY_DIR}/doxygen``. The doxygen configuration file is generated in the same directory.
* ``<input prefix>``: directory where finding input files
``<component>``: component name for this doxygen documentation. it is used to create the output directory and the tag file name. By default it is the ``PROJECT_NAME``. But it is useful to give an alternative name when there are several libraries documented with doxygen in the same project.

Before calling this function, it is possible to specify values that are going to be written in doxygen configuration file by setting variable names ``DOXYFILE_<doxyfile variable name>``. For instance, in order to set project name in Doxygen, one should use:

.. code-block:: cmake

    SET( DOXYFILE_PROJECT_NAME, "My wonderful project" ).

**Example:** from cartodata's ``CMakeLists``

.. code-block:: cmake

    FIND_PACKAGE( Doxygen )
    IF ( DOXYGEN_FOUND )
        SET(component_name "cartodata")
        set( DOXYFILE_PREDEFINED "${AIMS_DEFINITIONS}")
        set(aims_version "${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}")
        set( DOXYFILE_TAGFILES "${CMAKE_BINARY_DIR}/share/doc/cartobase-${aims_version}/doxygen/cartobase.tag=../../cartobase-${aims_version}/doxygen")
        BRAINVISA_GENERATE_DOXYGEN_DOC( _headers
                                        INPUT_PREFIX "${CMAKE_BINARY_DIR}/include/${component_name}"
                                        COMPONENT "${component_name}")
        add_dependencies( ${component_name}-doxygen cartobase-doxygen )
    ENDIF ( DOXYGEN_FOUND )


BRAINVISA_GENERATE_EPYDOC_DOC
+++++++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_GENERATE_EPYDOC_DOC( <source directory> [ <source directory> ... ] <output directory> [ EXCLUDE <exclude list> ] )

Generates documentation for python source files with Epydoc. No longer used, we write sphinx doc now.


BRAINVISA_GENERATE_SPHINX_DOC
+++++++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_GENERATE_SPHINX_DOC( <source directory> <output directory> [TARGET <target_name>] )

Generates documentation for python source files with Sphinx.

**Example:** from axon's CMakeLists

.. code-block:: cmake

    BRAINVISA_GENERATE_SPHINX_DOC( "sphinxdoc/sphinx"
        "share/doc/axon-${BRAINVISA_PACKAGE_VERSION_MAJOR}.${BRAINVISA_PACKAGE_VERSION_MINOR}/sphinx" )


BRAINVISA_GENERATE_DOCBOOK_DOC
++++++++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_GENERATE_DOCBOOK_DOC( [EXCLUDE <docbook_project_name>] )

Generates docbook documentation. No longer used either, we are using sphinx.


Dependencies
------------

BRAINVISA_CREATE_CMAKE_CONFIG_FILES
+++++++++++++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_CREATE_CMAKE_CONFIG_FILES()


BRAINVISA_FIND_PACKAGE
++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_FIND_PACKAGE( <component> )


BRAINVISA_DEPENDENCY
++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_DEPENDENCY( <pack_type> <dependency_type> <component> <component_pack_type> [ <version ranges> ] [BINARY_INDEPENDENT] )

This function enables to declare that the current brainvisa component has a dependency on another component. That other component can be a Brainvisa component or a thirdparty dependency.

* ``<pack_type>``: type of package which have this dependency. Indeed, the compilation and runtime dependencies are not necessary the same. Can be ``RUN`` for runtime package, ``DEV`` for development package or ``DOC`` for documenation package.
* ``<dependency_type>``: indicates if the dependency is mandatory or not. Can be ``DEPENDS`` or ``RECOMMENDS``.
* ``<component>``: name of the dependency component.
* ``<component_pack_type>``: type of package for the dependency package: ``RUN``, ``DEV`` or ``DOC``.
* ``<version ranges>``: required version of the dependency package.
* ``BINARY_INDEPENDENT`` can be added to indicate that the component and its dependency are binary independent (dependency between python modules for example) but this information is not used currently.

At configuration time, the information declared in this function will be written in a file named ``compilation_info.py`` in the directory ``<build_directory>/python/brainvisa``. This file was used by the :doc:`bv_packaging` script to create Brainvisa packages with the needed dependencies.

**Examples** (from anatomist-free ``CMakeLists.txt``)

.. code-block:: cmake

    BRAINVISA_DEPENDENCY( RUN DEPENDS aims-gpl RUN "= ${aims-gpl_VERSION}" )
    BRAINVISA_DEPENDENCY( DEV DEPENDS aims-gpl DEV )
    BRAINVISA_DEPENDENCY( RUN DEPENDS libqtcore4 RUN ">= ${QT_VERSION}" )
    BRAINVISA_DEPENDENCY( DEV DEPENDS libqtcore4 DEV )
    BRAINVISA_DEPENDENCY( RUN DEPENDS libqwt5-qt4 RUN)


Install
-------

Be careful, if you want to use directly the ``make install`` command to install files of the build directory in another location, you'll have to specify the variable ``BRAINVISA_INSTALL_PREFIX`` in the make install command. The historical justification is that in order to be able to specify an install location when using :doc:`bv_packaging` script, we had to use a variable that have to be defined at installation step instead of the ``CMAKE_INSTALL_PREFIX`` which is defined at configuration step.

**Example**

.. code-block:: bash

    make BRAINVISA_INSTALL_PREFIX=/tmp/test install-aims-gpl


BRAINVISA_INSTALL_DIRECTORY
+++++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_INSTALL_DIRECTORY( directory destination component )


BRAINVISA_INSTALL
+++++++++++++++++

.. code-block:: cmake

    BRAINVISA_INSTALL


BRAINVISA_INSTALL_RUNTIME_LIBRARIES
+++++++++++++++++++++++++++++++++++

.. code-block:: cmake

    BRAINVISA_INSTALL_RUNTIME_LIBRARIES( component )
