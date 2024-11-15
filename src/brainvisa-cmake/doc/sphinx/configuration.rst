===================================
The bv_maker.cfg configuration file
===================================

You must create this file in the following directory: ``$HOME/.brainvisa/bv_maker.cfg``.

In this file you can configure several types of directories:

* **source directory**: A source directory contains the source code of a set of selected projects. This source code will be updated (to reflect the changes that occured on BioProj or GitHub servers) each time you use bv_maker sources. You can define as many source directories as you want. In a source directory configuration you can select any project and combine several versions of the same project.

* **build directory**: A build directory will contain compiled version of the projects. A build directory can contain any project but only one version per project is allowed. You can define as many source directory as you want.

A section may also contain conditional parts. See the `Conditional subsections`_ section for details.


General structure and syntax of bv_maker configuration file
===========================================================

The :doc:`bv_maker` configuration file is composed of sections delimited by a line enclosed in square brackets: ``[ ... ]``. Each section contains the definition of a directory (either a source directory, or a build directory), or a "general" section. In this file, blank lines are ignored and spaces at the begining or end of lines are also ignored. It means that you can indent and separate lines as you wish. For instance:

.. code-block:: bash

    [ source $HOME/brainvisa/source ]
      + standard trunk
      + standard bug_fix
      - communication
      + perso/myself/myproject

    [ build $HOME/brainvisa/build/bug_fix ]
      build_type = Release
      make_options = -j8
      standard bug_fix $HOME/brainvisa/source

    [ build $HOME/brainvisa/build/trunk ]
      make_options = -j8
      standard trunk $HOME/brainvisa/source
      + $HOME/brainvisa/source/perso/myself/myproject

A line begining with ``#`` or ``//`` is considered as a comment and ignored. Comments cannot be added at the end of a line. For instance the following are valid comments:

.. code-block:: bash

    # A comment
      # Another comment
    // This is also a comment !

But the following line is not valid:

.. code-block:: bash

    [ build $HOME/brainvisa/build/trunk ] # This is a syntax error

Each line in a section contains either a "variable" definition, or some section-specific declarations such as components definitions.

Option Variables
----------------

A variable declaration looks the following:

.. code-block:: bash

    variable = value

Some variables may support additive or substractive declarations, once they have been defined a first time:

.. code-block:: bash

    make_options = -j6
    make_options += VERBOSE=1

This possibility depends on the variable type (here a list), but also on the variable itself (which must be understood in bv_maker as additive)

Most variables are strings, but a few are lists: elements are separated by blank spaces.

Some variables are "dictionaries" which may contain several sub-variables. A typical example is the ``env`` variable which contains environment variables to be set during execution of the steps for the given directory section. The syntax is the following:

.. code-block:: bash

    env = PATH: /home/myself/bin:$PATH, LD_LIBRARY_PATH:/home/myself/lib:$LD_LIBRARY_PATH

or, in additive mode:

.. code-block:: bash

    env += PATH: /home/myself/bin:$PATH, LD_LIBRARY_PATH=/home/myself/lib:$LD_LIBRARY_PATH

The difference between the two above examples is that the first will override the full set of environment variables defined in bv_maker.cfg, whereas the second will only add / replace 2 entries.

The above syntax is somewhat limited. If needed a "pythonic" syntax is allowed:

.. code-block:: bash

    env += {'PATH': '/home/myself/bin:$PATH', 'LD_LIBRARY_PATH': '/home/myself/lib:$LD_LIBRARY_PATH'}


Variables substitution
----------------------

Some variables (not all) with string values support environment variables substitution (``$VARIABLE``), and / or "python-like" string substitution (``%(variable)s``)for a few variables (``date``, ``hostname``, ``time``, ``os``, a few more in some sections).
Dictionary variables do support both:

.. code-block:: bash

    env += PATH: $HOME/bin:$PATH, BRAINVISA_TEST_DIR: $HOME/tests-%(hostname)s-%(date)s

Environment variables may be set by the user, or by the system, prior to running bv_maker, or through the ``env`` variables in ``bv_maker.cfg`` sections. Additionally, bv_maker itself sets a few helpful variables:

``NCPU``:
    number of processor cores in the current machine. Useful to pass build options matching the power of the build machine:

    .. code-block:: bash

        make_options = -j$NCPU


.. _general_section:

Definition of a general section
===============================

The general section is optional, and contains variable which are independent from each other sections (or shared accross them).

The general section definition starts with a line with the following syntax:

.. code-block:: bash

    [ general ]

Option variables are stored in this section using the syntax ``option = value``. The following options are supported:

* ``env``: environment variables dictionary. Note that the ``env`` dictionary in the general section is handled a bit differently than the one in the other sections: in other sections variables defined this way are local to the current section, and only passed to the actual environment when a commandline is run (such as ``cmake``, ``make`` etc.). In the general sections variables are actually set globally to the environment, thus they are available all along the bv_maker session, including within the run of bv_maker: this means that variables which are to be used during path substitutions inside ``bv_maker.cfg`` should be defined here.
* ``email_notification_by_default``: ``ON```or ``OFF`` (default). If set to ``ON``, email notification will always be used if ``failure_email`` or ``success_email`` are provided. Otherwise, the default behavior is to use email notification only when the ``bv_maker`` commandline is invoked with the ``--email`` option.
* ``global_status_file``: if this file is specified, a line will be appended to it for each source/build directory. This line will log the build status for the given directory: OK/FAILED, last step executed, directory, start and stop date and time, machine and system. It can be parsed and displayed using the command ``bv_show_build_log``.
* ``failure_email``: email address where bv_maker outputs are sent in case of failure. If not specified, no email will be sent and bv_maker outputs will be sent to the standard output. One email will be sent for each directory and build step that fail.
* ``failure_email_by_project``: dictionary of email addresses, in a project-indexed dictionary (json or python syntax). Adresses can be lists of strings. Ex:

    .. code-block:: bash

        failure_email_by_project = {'aims': 'maintainer@aims.org', 'anatomist': ['maintainer@aims.org', 'maintainer@anatomist.org']}

* ``jenkins_build_name``: pattern to Jenkins job name used to submit to a Jenkins dashboard. Only used if ``jenkins_server_url`` is also set. The pattern here may include replacement strings specified in a python style ``"%(variable)s"``. Allowed variables are:

    * ``date``
    * ``directory_id``: ``directory_id`` specified in the current section, or directory name of the build section (short name without path)
    * ``hostname``
    * ``os``
    * ``project``
    * ``step``
    * ``time``

* ``jenkins_server_url``: URL of a `Jenkins <https://jenkins.io/>`_ server which can be used to log build and tests logs. The log will be sent to the Jenkins dashboard through client commandline interface as an external job.
* ``jenkins_token``: Jenkins API token (or password) for Jenkins server
* ``jenkins_username``: login on Jenkins server
* ``success_email``: email address where bv_maker outputs are sent in case of success. If not specified, no email will be sent and bv_maker outputs will be sent to the standard output. One email will be sent for each directory and build step that succeeds.
* ``smtp_server``: SMTP (email server) hostname to be used to send emails
* ``from_email``: displayed expeditor of sent emails. If not specified, it will be ``<user>-<hostname>@intra.cea.fr`` (the suffix is needed, and is correct for our lab)
* ``reply_to_email``: displayed reply email address in sent emails. If not specified, ``appli@saxifrage.saclay.cea.fr``.


.. _source_directory:

Definition of a source directory
================================

A source directory definition section starts with a line with the following syntax:

.. code-block:: bash

    [ source <directory> ]

where ``<directory>`` is the name of the directory that will be created and whose content will synchronized with selected source directories located in BrainVISA Subversion server. The directory name can contain environment variable substitution by using ``$VARIABLE_NAME``. For instance, on Unix systems, ``$HOME/brainvisa`` will be replaced by the brainvisa directory located in the user home directory. If the specified directory does not exist, it will be created (as well as parent directories) when the sources will be processed by bv_maker.

The content of the source directory section is composed of a set of rules to select and unselect Subversion directories to copy in the source directory. Each source directory is first associated with an empty list of subdirectories. Then, the configuration file is parsed in order to modify this list. Each line in the source directory section correspond to an action that can modify the list. These actions are executed in the order they are given. It means that you can unselect directories previously selected or the contrary. For instance if one wants to select all components but one, he will make a first action to select all components and a second one to remove the component to ignore. There are three kind of actions that can be done to modify this list of subdirectories. The syntax of the configuration rules corresponding to these actions are described in the following paragraphs.

In the source section, it is also possible to define some option variables, delcared in the syntax ``option = value``. The following options are supported:

* ``build_condition``: a condition which must be True to allow configure and build steps, otherwise they will be skipped. The condition is evaluated in **python language**, and is otherwise free: it may typically be used to restrict build to certain systems or hostnames, some dates, etc.
* ``cross_compiling_dirs``: dictionary of directories. ``cross_compiling_dirs`` contains toolchain substitutions for source directory. This is used when execution needs different path to access sources (i.e.: in windows cross compilation, for pure python components, it is necessary to access source directories through network shares, instead of NFS mount point). For instance, the following configuration line: ``i686-w64-mingw32://computer/basedir`` will replace the source directory path with the UNC path ``//computer/basedir`` in a build directory that uses the i686-w64-mingw32 ``cross_compiling_prefix``. The network share ``//computer/basedir`` must have been properly configured on ``computer`` to be accessible.
* ``directory_id``: used in Jenkins notification
* ``revision_control``: ``ON`` (default) or ``OFF``. If enabled, revision control systems (*svn*, *git*) will be used to update the sources. If OFF, the sources directory will be left as is as a fixed sources tree.
* ``default_source_dir``: ? I don't know... **FIXME**
* ``default_steps``: steps performed for this build directory when bv_maker is invoked without specifying steps (typically just ``bv_maker``). Defaults to: ``sources``.
* ``env``: environment variables dictionary
* ``ignore_git_failure``: don't stop after the sources step if one or more git repositories cannot be updated in fast-forward mode (which also occurs when working on a non-principal branch). Later steps will thus be performed, but the source step will still be reported as failed.
* ``revision_control``: ``ON`` (default) or ``OFF``. When ON, sources components will be updated using revision control systems (RCS) (svn, git...), and a list of valid components will be generated during the :ref:`sources step <sources_step>` and saved in a file, named ``components_sources.json`` in the main sources directory. If sources are only local, turning ``revision_control`` to OFF will avoid using RCS, but will still generate the list of components for building.
* ``stderr_file``: file used to redirect the standard error stream of bv_maker when email notification is used. This file is "persistant" and will not be deleted. If not specified, it will be mixed with standard output.
* ``stdout_file``: file used to redirect the standard output stream of bv_maker when email notification is used. This file is "persistant" and will not be deleted. If neither it nor ``stderr_file`` are specified, then a temporary file will be used, and erased when each step is finished.
* ``update_git_remotes``: ``ON`` (default) or ``OFF``. If ON, all git remotes will be fetched, otherwise only the current active branch in a component will be fast-forwarded. The default value in brainvisa-cmake < 3 used to be ``OFF``, but this was changed in order to make things clearer/easier and to handle git-lfs projects. The former "light" mode (no fetch + detached branch mode) has been deprecated also: it still works for repositories created usinbg bv_maker 2.x but new repositories are not initialized this way any longer. See :ref:`git_repositories`


Add components to the list
--------------------------

.. code-block:: bash

    + component_selection version_selection

A line starting with a plus will use Subversion to add some directories from the BrainVISA BioProj repository. The selections of the directories is done by selecting components according to their name and version. Once the components are selected, bv_maker is able to find the corresponding directories in BrainVISA repository. component_selection is used to select a list of components according to their name (see `Component selection`_). It is not mandatory to provide a version_selection. If it is given, it is used to further filter the list of selected components according to their version (see `Version selection`_).


Remove components from the list
-------------------------------

.. code-block:: bash

    - component_selection version_selection

A line starting with a minus is has the same syntax as the previous action but removes the selected directories from the list.


Add directories to the list
---------------------------

subversion components
+++++++++++++++++++++

.. code-block:: bash

    + repository_directory local_directory

or:

.. code-block:: bash

    brainvisa repository_directory local_directory

In order to include some directories that do not correspond to registered BrainVISA components, one can directly give the directory name in ``repository_directory``. This directory name must be given relatively to the main BrainVISA repository URL: https://bioproj.extra.cea.fr/neurosvn/brainvisa. By default, ``repository_directory`` is also used to define where this directory will be in the source directory. It is not mandatory to provide a value for local_directory. If it is given, it is used instead of repositor_directory to define the directory location relatively to the source directory.

For instance, the following configuration will link the repository directory https://bioproj.extra.cea.fr/neurosvn/brainvisa/perso/myself/myproject with the local directory ``/home/myself/brainvisa/perso/myself/myproject``.

.. code-block:: bash

    [ source /home/myself/brainvisa ]
      + perso/myself/myproject

Whereas the following configuration will link the same repository directory with the local directory ``/home/myself/brainvisa/myproject``.

.. code-block:: bash

    [ source /home/myself/brainvisa ]
      + perso/myself/myproject myproject

git components
++++++++++++++

See also :ref:`git_repositories`

.. code-block:: bash

    git https://github.com/neurospin/highres-cortex.git master highres-cortex/master


.. _build_directory:

Definition of a build directory
===============================

A build directory definition section starts with a line with the following syntax:

.. code-block:: bash

    [ build <directory> ]

where ``<directory>`` is the name of the directory where the compilation results will be written. As the source directory, the build directory name can contain environment variable substitution.

This section defines the list of components that will be built and their version and the source directory where they can be found. The components and versions are defined as they were in the source directory. It is also possible to remove components from the list with a line beginning with a minus.

Build directories control the following :doc:`bv_maker` steps:

* :ref:`configure <configure_step>`: configure build and generate Makefiles using CMake.
* :ref:`build <build_step>`: compile programs and libraries, install files (as symbolic links) in the build directory tree so as to be ready for local execution.
* :ref:`doc <doc_step>`: generate documentation for the built components.
* :ref:`testref <testref_step>`: run tests in a special mode so as to generate reference data for later tests comparisons.
* :ref:`test <test_step>`: run tests

In the build section, it is also possible to define some build options:

* ``cmake_options``: passed to cmake (ex: ``-DMY_VARIABLE=dummy``)
* ``ctest_options``: passed to ctest in the test step (ex: ``-j4 -VV -R carto*``)
* ``directory_id``: used in Jenkins notification
* ``env``: environment variables dictionary
* ``make_options``: passed to make (ex: ``-j8``)
* ``build_type``: ``Debug``, ``Release`` or none (no optimization options)
* ``build_condition``: a condition which must be True to allow configure and build steps, otherwise they will be skipped. The condition is evaluated in **python language**, and is otherwise free: it may typically be used to restrict build to certain systems or hostnames, some dates, etc.
* ``clean_build``: ``ON`` or ``OFF`` (default), if set, the build tree will be cleaned of obsolete files before the build step (using the command ``bv_clean_build_tree``)
* ``clean_config``: ``ON`` or ``OFF`` (default), if set, the build tree will be cleaned of obsolete files before the configuration step (using the command ``bv_clean_build_tree``)
* ``cross_compiling_prefix``: toolchain name to use for cross-compilation mode. If ``cross_compiling_prefix`` is set, bv_maker runs in cross-compilation mode for the build directory (i.e. it adds definitions to tell cmake to work using a specific toolchain initial cache file, a specific toolchain file and the defined ``cross_compiling_prefix``). Toolchain initial cache file must be found at ``<brainvisa_cmake_directory>/cmake/toolchain/<cross_compiling_prefix>/init-cache.cmake``. Toolchain file must be found at ``<brainvisa_cmake_directory>/cmake/toolchain/<cross_compiling_prefix>/toolchain.cmake``. For instance, if ``<brainvisa_cmake_directory>`` is ``$HOME/brainvisa/source/brainvisa-cmake`` and ``cross_compiling_prefix`` is ``i686-w64-mingw32``, searched files are ``$HOME/brainvisa/source/brainvisa-cmake/cmake/toolchain/i686-w64-mingw32/init-cache.cmake`` and ``$HOME/brainvisa/source/brainvisa-cmake/cmake/toolchain/i686-w64-mingw32/toolchain.cmake``
* ``default_steps``: steps performed for this build directory when bv_maker is invoked without specifying steps (typically just ``bv_maker``). Defaults to: ``configure build``, but may also include ``doc`` and ``test``.
* ``stderr_file``: file used to redirect the standard error stream of bv_maker when email notification is used. This file is "persistant" and will not be deleted. If not specified, it will be mixed with standard output.
* ``stdout_file``: file used to redirect the standard output stream of bv_maker when email notification is used. This file is "persistant" and will not be deleted. If neither it nor ``stderr_file`` are specified, then a temporary file will be used, and erased when each step is finished.
* ``test_ref_data_dir``: directory where reference data will be written (during :ref:`testref step <testref_step>`) and read (during :ref:`test step <test_step>`) for comparison.
* ``test_run_data_dir``: directory where data will be written during the :ref:`test step <test_step>`.

**Example**

.. code-block:: bash

    [ build $HOME/brainvisa/build/bug_fix ]
      build_type = Release
      make_options = -j8
      standard bug_fix $HOME/brainvisa/source

In the above example, the *bug_fix* version of standard components which are located in ``$HOME/brainvisa/source`` directory will be compiled in the build directory ``$HOME/brainvisa/build/bug_fix`` in ``Release`` mode with the option ``-j8`` passed to make command (compilation distributed on 8 processors).


Variants of build directories
-----------------------------

A build directory may also be a *python virtualenv* directory. To specify it the section type may be virtualenv instead of build:

.. code-block:: bash

    [ virtualenv <directory> ]

A virtualenv directory will be initialized the first time it is used, and a python virtualenv environment will be installed there. Then it will be used as a build directory in addition. This allows to use ``pip install`` commands within it with a local install, just for this build directory.


Syntax for components selection
===============================

Components can be selected according to their name and (in some context) to their version. This paragraph explain how to use component_selection and version_selection and gives some examples of their usage.

Information about the components, components groups and versions are extracted from git repository and stored in the following file: https://github.com/brainvisa/brainvisa-cmake/blob/master/python/brainvisa_cmake/components_definition.py


Component selection
-------------------

A component_selection is a string that is used to select one or more component according to their name. The following rules are used to transform this string into a list of components:

#. If component_selection is a group name, all components of this group are selected. At the time of this writing, four groups are defined:

  * **all** which contains all known components,
  * **opensource** for all open source components
  * **standard** containing only standard components of BrainVISA project
  * **anatomist** containing Anatomist and its dependencies.

#. If component_selection is a project name, all components of this project are selected
#. If component_selection is a component name, only this component is selected
#. Component selection must be a single pattern (with Unix shell-style wildcards) or two patterns separated by a colon:

  #. If there is only one pattern, all components matching this pattern are selected
  #. If there are two patterns, all components that are in a project matching the first pattern and that are matching the second pattern are selected


Version selection
-----------------

To select the version of a component or a group of component, it is possible

* to give the exact version number of a branch (4.0) or a tag (4.0.1)
* to use one of the following keywords:

  * **development**, **trunk**: trunk version in svn repository
  * **bug_fix**, **branch**, **stable** : latest stable version, the higher version number in branches directory of svn repository
  * **tag**, **latest_release**: latest tag version, the higher version number in tags directory of svn repository

* **branch:n** : the nth version in branches directory
* **tag:n** : the nth version in tags directory


Examples of components selection
--------------------------------

Select all versions of all existing components:

.. code-block:: bash

    all

Select latest release version of all components:

.. code-block:: bash

    all tag

Select latest bug fixing branch of open source components:

.. code-block:: bash

    opensource branch

Select all components in project aims with version 4.0.2:

.. code-block:: bash

    aims 4.0.2

Select development version of soma-workflow component:

.. code-block:: bash

    soma-workflow trunk

Select latest bug fixing branch of all components in anatomist project:

.. code-block:: bash

    anatomist:* bug_fix


Conditional subsections
=======================

A section of the configuration file may contain conditional parts. This allows to specialize parts of the configuration according to host system, host name, or whatever.

Condition blocks
----------------

A conditional subsection should be located inside an existing section (sources or build). It follows the syntax:

.. code-block:: bash

    [ if <expression> ]
      <config lines>
      ...
    [ else ]
      <other config lines>
    [ endif ]

The ``[ else ]`` block is of course optional, and a global section end also ends the conditional section, so the ``[ endif ]`` section may be omitted if it is at the end of the section.


Condition expressions
---------------------

The condition expression may contain substitution variables as in the shape ``%(variable)s`` syntax. The following variables are recognized:

* os
* date
* time

Other variables depend on the configuration of the section itself, which is only done later, so they are not available yet when parsing conditions.

The condition expression is then evaluated in python language (using the ``eval()`` function), thus allows all python language syntax and loaded libraries. The expression result is cast to a boolean value.

Thus a configuration may look like the following:

.. code-block:: bash

    [ build $HOME/brainvisa/build/bug_fix ]
      build_type = Release
      [ if gethostname() == 'my_machine' ]
        make_options = -j8
      [ else ]
        make_options = -j2
      [ endif ]
      standard bug_fix $HOME/brainvisa/source


Examples
========

.. warning:: TO DO

.. code-block:: bash

    [ source $HOME/brainvisa/source ]
      + standard trunk
      + standard bug_fix
      - communication
      + perso/myself/myproject

    [ build $HOME/brainvisa/build/bug_fix ]
      build_type = Release
      make_options = -j8
      standard bug_fix $HOME/brainvisa/source

    [ build $HOME/brainvisa/build/trunk ]
      make_options = -j8
      standard trunk $HOME/brainvisa/source
      - connectomist-*
      + $HOME/brainvisa/source/perso/myself/myproject


.. _build_qt5:

Compiling using Qt 5
--------------------

Add in the ``[ build ]`` section:

.. code-block:: bash

    [ build $HOME/brainvisa/build/bug_fix ]
      # ...
      cmake_options += -DDESIRED_QT_VERSION=5
      # ...


.. _build_py3:

Compiling using Python3
-----------------------

Add in the ``[ build ]`` section:

.. code-block:: bash

    [ build $HOME/brainvisa/build/bug_fix ]
      # ...
      cmake_options += -DPYTHON_EXECUTABLE=/usr/bin/python3
      # ...

Under Unix (filesystems supporting symbolic links) , after building, a link to the matching python executable will be found in ``bin/python`` so that the ``python`` command within this build tree will point to ``python3`` and will be used by all python scripts.

