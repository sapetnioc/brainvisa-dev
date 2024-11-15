=================================
How to compile BrainVISA projects
=================================

How to setup a developement environement for BrainVISA projects

There are several possibilities to compile a series of BrainVISA components. One can use a standard CMake procedure where each component have its own build directory and links between components are done via CMake cache variables. But at the time of this writing, there are 44 components in 21 BrainVISA project. Configuring and compiling all of them manualy can be a hard work. This is why bv_maker script have been developped in order to easily create a complete source synchronization and compilation pipeline for a selected set of projects or components. This document describes the use of bv_maker.


First time configuration
========================

1) Install dependencies on your system
--------------------------------------

You must have the following software on your system:

* Subversion. The command svnadmin must also be installed on your system. On some Linux distributions it is not in the subversion package (for instance in Ubuntu you must install subversion-tools package).
* Git
* CMake (version >= 2.6.4)
* Python (version >= 2.7)
* Make
* Other dependencies depends on the components you want to build.

If you work at the I2BM (Neurospin, MirCen or SHFJ), you can call the bash function *bv_setup_devel* in your ``.bashrc`` file. This will add ``/i2bm/brainvisa`` paths in your environment variables where some useful dependencies for the development environment are installed.


2) Get an up-to-date working copy of bv_maker
---------------------------------------------

bv_maker is part of the brainvisa-cmake project. Since you need bv_maker to download the sources and do the first build directory, you may have to download a temporary version with the following code:

For Linux and MacOS:
####################

.. code-block:: bash

    git clone https://github.com/brainvisa/brainvisa-cmake.git /tmp/brainvisa-cmake
    cd /tmp/brainvisa-cmake
    cmake -DCMAKE_INSTALL_PREFIX=. .
    make install

For Windows:
############

Compiling on Windows or cross-compiling is not supported any longer. We had to drop support for if, not for pure technical reasons but because our team is too small to support it and the additional complexity was too heavy to maintain.
To use or build BrainVisa on Windows now, please use WSL2 and a Linux build, or a virtual machine running Linux.


3) Edit bv_maker configuration file
-----------------------------------

You must create this file in the following directory: ``$HOME/.brainvisa/bv_maker.cfg``. In this file you can configure mainly two types of directory:

* source directory: A source directory contains the source code of a set of selected projects. This source code will be updated (to reflect the changes that occured on BioProj server) each time you use bv_maker configure. You can define as many source directory as you want. In a source directory configuration you can select any project and combine several versions of the same project.
* build directory: A build directory will contain compiled version of the projects. A build directory can contain any project but only one version per project is allowed. You can define as many build directory as you want.

See :doc:`bv_maker configuration syntax <configuration>` for a complete documentation with examples.

Typical configuration:
######################

.. code-block:: bash

    # definition of the source directory: open-source projects in bug_fix version (i.e. the branch with the highest version) except web project because it takes space
    [ source $HOME/brainvisa/source ]
      + opensource bug_fix
      - web

    # definition of the build directory: build open-source projects from the source directory except anatomist-gpl and anatomist-private components
    [ build $HOME/brainvisa/build/bug_fix ]
      make_options = -j4
      build_type = Release
      opensource bug_fix $HOME/brainvisa/source
      - anatomist-*
      - communication:web

.. warning::
    The option ``build_type`` is very important, the execution can be two to three times slower if the build is not in Release mode.

.. note::
    To compile using Qt5 or / and Python3, it is possible to add in the ``build`` sections appropriate ``cmake_options`` variables. Read :ref:`build_qt5` and :ref:`build_py3`.


4) Download sources
-------------------

.. code-block:: bash

    /tmp/brainvisa-cmake/bin/bv_env bv_maker sources


5) Configure build directories with CMake
-----------------------------------------

.. code-block:: bash

    /tmp/brainvisa-cmake/bin/bv_env bv_maker configure

(look at the section `In case of problems`_ for troubleshooting)

After this step, you have a version of ``brainvisa-cmake`` installed in each build directory you have defined. You can therefore find :doc:`bv_maker <bv_maker>` in ``<build_directory>/bin/bv_maker``.


6) Compile in build directories with make
-----------------------------------------

.. code-block:: bash

    /tmp/brainvisa-cmake/bin/bv_env bv_maker build


7) Remove directory created in step 2
-------------------------------------

You should now remove the temporary bv_maker that have been downloaded in step 2 and use the one installed in your build directory: ``<build_directory>/bin/bv_maker``.

.. code-block:: bash

    rm -Rf /tmp/brainvisa-cmake

If you want to use all your build directory, set the following environment variables: ``PATH``, ``LD_LIBRARY_PATH``, ``PYTHONPATH`` and ``BRAINVISA_SHARE``. To make it easier, we provide a program called :doc:`bv_env <bv_env>` that sets up the required environment variables:

.. code-block:: bash

    . <build_directory>/bin/bv_env.sh <build_directory>


8) Build documentation (docbook, doxygen, epydoc)
-------------------------------------------------

.. code-block:: bash

  bv_maker doc


In case of problems
===================

* **CMake has caches**. They sometimes keep erroneous values. Do not hesitate to remove the ``CMakeCache.txt`` file at the root of the build trees before reconfiguring. It sometimes solves incomprehensible configure problems.

.. _git_repositories:

Git repositories and bv_maker
=============================

.. note::

    See also the `contributors doc <https://brainvisa.github.io/contributing.html>`_ of the `BrainVisa developers doc <https://brainvisa.github.io>`_ project

in the ``[source]`` section of ``bv_maker.cfg``:

.. code-block:: bash

  git https://github.com/neurospin/highres-cortex.git master highres-cortex/master


Remotes and forks
-----------------

see `the BrainVISA developers doc here <https://brainvisa.github.io/contributing.html#feature_branch>`_.


Credentials
-----------

see `the password issue in the developers doc <https://brainvisa.github.io/contributing.html#remote_credentials>`_.


