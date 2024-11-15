=====================================
Testing and monitoring infrastructure
=====================================

bv_maker allows to run tests, notify, and log the results of build, tests, and packaging operations.

Running tests
=============

Testing build directories
-------------------------

Basically, tests can be run through the :doc:`bv_maker` command:

.. code-block:: bash

    bv_maker test

Of course options may be added to restrict to some build directories for instance using the ``-d`` option (see :doc:`bv_maker options <bv_maker>` for details).

``bv_maker`` also has :ref:`options specific to the test step <test_step>`, namely the ``-t`` option which may be used to run only a part of tests. For instance:

.. code-block:: bash

    bv_maker test -t '-VV -R ^carto'

will run tests in verbose mode, and run only tests whth names starting with ``carto``.

Basically, this ``bv_maker`` command runs `ctest <https://cmake.org/cmake/help/v3.0/manual/ctest.1.html>`_ so it is also possible to go into a build directory, and run ``ctest``, or ``make test``, by hand:

.. code-block:: bash

    cd /home/brutus/build
    ctest -VV -R ^carto

These commands will do almost the same as the bv_maker variant, except that notification and logging will not take place.


Testing installed packages
--------------------------

Similarly, bv_maker allows to test installed packages, after bv_maker steps :ref:`pack <pack_step>` and :ref:`install_pack <install_pack_step>` have been successfully done. This is the :ref:`test_pack <test_pack_step>` step.

In this situation, tests are performed as configured in the corresponding build tree, but are running programs in an installed binary package.

Tests may be run in a different environment: on a different machine (through ``ssh``), or via a `docker container <http://www.docker.com>`_ for instance, or both, as configured in the ``bv_maker.cfg`` file: see `Configuring installed packages tests`_. This way, tests can be run in a realistic situation as if the software is installed on a different (and minimal) client machine.

.. code-block:: bash

    bv_maker test_pack

Here again, options are allowed to restrict to specific package directories, part of tests etc. Note that the ``-d`` option here must refer to a :ref:`package directory <package_directory>`, which may admit some fancy wildcards, and must be specified the same way. As an example, for our build system for BrainVisa, we may use:

.. code-block:: bash

    bv_maker -d '/neurospin/tmp/brainvisa/tests/repositories/public/%(version)s-%(date)s/%(os)s/packages' test_pack -t '-VV -R carto*'

.. note::

    Contrarily to build directories tests, the ``test_pack`` step cannot be run through a ``ctest`` or ``make`` command equivalent, because ``bv_maker`` has to setup tesing into the installed package before running tests, in a way that is not recorded in cmake/make configuration.


Managing test data
------------------

Some tests will work fine using internal tests or by generating tempory synthetic data to test its processing. But in some other cases, additional data will be needed. Typically:

* input data may be needed to feed processing tests which should run with "real" data. Such data may be quite large, so the test system may download data from a remote URL or get it from a given read-only directory.

* reference data: many tests will generate output (processed) data from input data. To check if the output data are OK, some reference data must be compared to tests results. Reference data can be generated through bv_maker by running tests in a special mode: :ref:`testref <testref_step>` or :ref:`testref_pack <testref_pack_step>` for package tests.

* test data: these data will be produced during regular tests. Normally they could be just temporary files which can be deleted after testing, but it is useful to store them for manual checking and debugging when tests fail.

Hence two additional :doc:`bv_maker` steps can be used to generate reference data:

* :ref:`testref <testref_step>` will run tests and write reference results for later comparison during :ref:`test <test_step>` steps
* :ref:`testref_pack <testref_pack_step>` will run tests from installed packages and write reference results for later comparison during :ref:`test_pack <test_pack_step>` steps

Data directoryes are passed to test programs through environment variables, with values that can be specified in :doc:`configuration` variables:

* input data: *Not done yet*
* reference data: the ``bv_maker.cfg`` config file may contain in its build and package directories sections a ``test_ref_data_dir`` variable, which will specify where reference data will be written (in :ref:`testref <testref_step>`  and :ref:`test_pack <test_pack_step>` steps). The value here may contain environment variables and "python-style" variables substitution to differentiate data directories across configurations or systems. When tests are actually running, the value here will be passed to test programs through the ``BRAINVISA_TEST_REF_DATA_DIR`` environment variable.
* run test data: the ``bv_maker.cfg`` config file may contain in its build and package directories sections a ``test_run_data_dir`` variable, which will specify where reference data will be written (in :ref:`test <test_step>`  and :ref:`test_pack <test_pack_step>` steps). The value here may contain environment variables and "python-style" variables substitution to differentiate data directories across configurations or systems. When tests are actually running, the value here will be passed to test programs through the ``BRAINVISA_TEST_RUN_DATA_DIR`` environment variable. If this variable is not defined, then a temporary directory may be used for tests.


Notifying build and test executions
===================================

``bv_maker`` may use several kinds of notification  when its different steps finish, or when they fail.


Basic bv_maker output and command retuern code
----------------------------------------------

If any step fails, the :doc:`bv_maker` commend will exit with a non-null exit code, and print a summary of steps status for each build or package directory.


Email notification
------------------

Emails can be sent when a bv_maker step finishes, or only in case of failure.

Such notification and logging have to be setup in the :doc:`bv_maker.cfg configuration file <configuration>`, more precisely in the :ref:`general section <general_section>` of it:

.. code-block:: bash

    [ general ]
    email_notification_by_default = ON
    failure_email = myname@myserver.com
    success_email = myname@myserver.com
    smtp_server = mail.myserver.com
    from_email = myself@myserver.com
    reply_to_email = support@myserver.com

Note that if ``email_notification_by_default`` is not set to ``ON``, bv_maker will need to be invoked with the ``--email`` option to actually send email notification.

If ``success_email`` is not filled, notificatioon will only occur upon error.


Log file
--------

Additionally it can also maintain a file of past ``bv_maker`` executions and the status of all steps. These tools are useful for automatic build and testing, continuous integration etc.

This is setup in the :doc:`configuration` option ``global_status_file`` in the :ref:`general section <general_section>`:


.. code-block:: bash

    [ general ]
    global_status_file = /home/tests/bv_maker_log.log

See :ref:`displaying_build_status` below for how to use the log file.


Notification to a Jenkins server
--------------------------------

:doc:`bv_maker` can connect to a `Jenkins <https://jenkins.io/>`_ server to log step results, so as to allow displaying them on a server. This is not the usual way to use Jenkins, which normally operates builds and tests from the server, but here bv_maker runs in its own (typically from a unix crontab), and connects to the Jenkins server to store jobs results (using "external jobs" in Jenkins dialect). This way, builds and tests running on a private network can still log results to a server visible from the internet.

.. code-block:: bash

    [ general ]
    jenkins_build_name = brainvisa-$HOSTNAME-%(version)s-%(directory_id)s-%(project)s-%(step)s
    jenkins_server_url = http://myserver.org/builds
    jenkins_token = something_to_get_from_jenkins_server
    jenkins_username = test_login


.. _displaying_build_status:

Displaying build status
=======================

Log file
--------

When ``bv_maker`` is running, each step execution status may be logged in a single file: a line is appended to it when a step finishes. This is enabled if the ``bv_maker.cfg`` file has the :ref:`global_status_file option <general_section>` in its general section:

.. code-block:: bash

    [ general ]
    global_status_file = /home/brutus/bv_builds.log

This file is a simple text file, containing just one line per bv_maker step execution, its status, run date, and system name. For instance:

.. code-block:: text

    OK          step test: /neurospin/brainvisa/build/Mandriva-2008.0-x86_64/bug_fix, started: 2017/01/25 06:05, stopped: 2017/01/25 07:31 on i2bm-mdv-64 (linux64-glibc-2.6)
    OK          step test: /neurospin/brainvisa/build/Mandriva-2008.0-x86_64/latest_release, started: 2017/01/25 07:31, stopped: 2017/01/25 07:58 on i2bm-mdv-64 (linux64-glibc-2.6)
    OK          step test: /neurospin/brainvisa/build/Mandriva-2008.0-x86_64/trunk, started: 2017/01/25 07:58, stopped: 2017/01/25 09:21 on i2bm-mdv-64 (linux64-glibc-2.6)
    FAILED      step pack: /neurospin/tmp/brainvisa/tests/repositories/public/%(version)s-%(date)s/%(os)s/packages, started: 2017/01/25 09:21, stopped: 2017/01/25 10:21 on i2bm-mdv-64 (linux64-glibc-2.6)
    UNMET DEP   step install_pack: /neurospin/tmp/brainvisa/tests/repositories/public/%(version)s-%(date)s/%(os)s/packages on i2bm-mdv-64 (linux64-glibc-2.6)
    UNMET DEP   step test_pack: /neurospin/tmp/brainvisa/tests/repositories/public/%(version)s-%(date)s/%(os)s/packages on i2bm-mdv-64 (linux64-glibc-2.6)
    OK          step pack: /neurospin/tmp/brainvisa/tests/repositories/public/%(version)s-%(date)s/data-%(os)s/packages, started: 2017/01/25 10:21, stopped: 2017/01/25 10:34 on i2bm-mdv-64 (linux64-glibc-2.6)
    OK          step test: /mnt/neurospin/sel-poivre/brainvisa/build/CentOS-5.11-x86_64/latest_release, started: 2017/01/25 07:13, stopped: 2017/01/25 07:42 on michael (linux64-glibc-2.5)
    OK          step test: /mnt/neurospin/sel-poivre/brainvisa/build/CentOS-5.11-x86_64/bug_fix, started: 2017/01/25 07:42, stopped: 2017/01/25 09:15 on michael (linux64-glibc-2.5)
    OK          step test: /mnt/neurospin/sel-poivre/brainvisa/build/CentOS-5.11-x86_64/trunk, started: 2017/01/25 09:15, stopped: 2017/01/25 11:07 on michael (linux64-glibc-2.5)


Setting up new tests in a software project
==========================================

Tests are "just" a series of commands that are run to use the software and check if it works as expected.

In CMake
--------

``brainvisa-cmake`` relies on `cmake <http://cmake.org>`_, and on `ctest <https://cmake.org/cmake/help/v3.0/manual/ctest.1.html>`_ for testing. Adding a new test if hence a matter of specifying it in the ``CMakeLists.txt`` file of the software project sources, using the `add_test <https://cmake.org/cmake/help/v3.0/command/add_test.html>`_ command.

However ``brainvisa-cmake`` offers a light wrapper for it: :ref:`brainvisa_add_test`, which handles the runtime test environment (build tree paths, or installed package testing), and also handles invoking python in a potentially cross-compilation environment.

ex:

.. code-block:: cmake

    brainvisa_add_test( axon-tests "${PYTHON_EXECUTABLE_NAME}"
                        -m brainvisa.tests.test_axon )


In python projects
------------------

Some projects managed by ``brainvisa-cmake`` are "pure python" and do not conrtain explicit CMake instructions in a ``CMakeLists.txt`` file. Instead, they should provide a python ``info`` module in the project (loaded generally as ``import project_name.info``). This info module may provide tests, which are a list of commands to be executed and are specified in the ``test_commands`` variable. For instance, in the `CAPSUL <http://brainvisa.info/capsul/>`_ project, we have in the sources a file:

::

    capsul/info.py

which contains, amongst other things, the following:

::

    # tests to run
    test_commands = ['%s -m capsul.test.test_capsul' % sys.executable]

This ``test_commands`` variable will be interpreted by ``brainvisa-make`` to generate the appropriate ``CMakeLists.txt`` file for the project, which will integrate with ``ctest`` and ``bv_maker``.

Each test command is free to do whatever it likes, and it is a standard practice in python to use tests based on `the python unittest <https://docs.python.org/2/library/unittest.html>`_ module.


Configuring installed packages tests
====================================

Config options
--------------

``bv_maker`` can run tests of installed packages (after successful ``pack`` and ``install_pack`` steps), within the ``testref_pack`` and ``test_pack`` steps. Such tests can make use of remote or virtual machines to perform tests in a "clean", controlled, test environment, different from the build machine. Actually, to be precise, the ``install_pack`` step also uses the same mechanism and can also take place on a remote or virtual machine, in the same manner as running the tests themselves.

However tests are always triggered from the build machine, which will in turn, connect to remote or virtual test machines.

Tests configuration is part of a :ref:`package directory <package_directory>` specification of the :doc:`bv_maker.cfg configuration file <configuration>`. They are mainly controlled via the ``remote_test_host_cmd`` variable. The contents of this variable is prepended to test commands, so they can make the connection and indirection trick. For instance:

.. code-block:: bash

    [ package /home/brutus/tests/packages ]
    build_directory = /home/brutus/build
    installer_filename = /home/brutus/tests/brainvisa_installer
    data_repos_dir = /home/brutus/tests/data/packages
    test_install_dir = /home/brutus/tests/test_install
    remote_test_host_cmd = ssh -t -X test_machine BRAINVISA_TEST_RUN_DATA_DIR="$BRAINVISA_TEST_RUN_DATA_DIR" BRAINVISA_TEST_REF_DATA_DIR="$BRAINVISA_TEST_REF_DATA_DIR"

Note that test data directories have to be handled manually in remote machines access: bv_maker will setup **locally** the environment variables ``BRAINVISA_TEST_RUN_DATA_DIR`` and ``$BRAINVISA_TEST_REF_DATA_DIR``, but passing them through a ssh connection or to a docker machine is the responsibility of the ``remote_test_host_cmd`` configuration.


Testing through SSH
-------------------

Here, the ``ssh -t -X test_machine`` command will be prepended to tests, so that all tests will connect through ``ssh`` to the machine named ``test_machine``, and use the software installed in the directory ``/home/brutus/tests/test_install``.


Testing using Docker
--------------------

Another example using `docker <http://docker.com>`_ would look the following:

.. code-block:: bash

    remote_test_host_cmd = docker run --rm -u "$(id -u):$(id -g)" -e USER=$USER -e TMPDIR=/home/brutus/tmp:/home/brutus/tmp -v "$HOME":"$HOME" -e HOME="$HOME" -v /tmp/.X11-unix:/tmp/.X11-unix --net=host -e DISPLAY=$DISPLAY -e BRAINVISA_TEST_REF_DATA_DIR="$BRAINVISA_TEST_REF_DATA_DIR" -e BRAINVISA_TEST_RUN_DATA_DIR="$BRAINVISA_TEST_RUN_DATA_DIR" -v "$BRAINVISA_TEST_REF_DATA_DIR":"$BRAINVISA_TEST_REF_DATA_DIR" -v "$BRAINVISA_TEST_RUN_DATA_DIR":"$BRAINVISA_TEST_RUN_DATA_DIR" cati/brainvisa-test:ubuntu-16.04 xvfb-run --auto-servernum

Thus the appropriate docker command will be prepended to all tests.

Note that here we are running Docker using the same user as the host machine, and we export the home directory and X11 connection from the host machine, allowing to perform graphical display.

In addition here we run commands through `xvfb-run <https://en.wikipedia.org/wiki/Xvfb>`_: XVFB is a virtual X server which does not actually perform graphical display on screen. This is used to perform tests on non-graphical build and test machines. This xvfb indirection should replace the X11 redirection (``DISPLAY`` and ``/tmp/.X11-unix settings``) thus the latter should not be needed, however we prefer to keep them because it's easy then to remove the xvfb indirection and get real interactive graphical display to fix some tests when needed.

Last, the docker image we are using here is: ``cati/brainvisa-test:ubuntu-16.04``. This is a docker image of an Ununtu 16.04 system. It should work as is, the image is found on `dockerhub <https://hub.docker.com/>`_ so docker should find it directly and download it if it is not already installed.

This docker image is a minimal system, with minimal software installation: it contains only the libraries required to run the `Qt installer <http://doc.qt.io/qtinstallerframework/>`_ which binary installations are using, a X11 server and XVFB. Using this "smallest possible" system allows to find out missing thirdparty software dependencies in the tested software packages. The image and docker container will normally not be modified by the tests, so can be reused for later tests.


Mixing SSH and Docker
---------------------

The above example runs tests through Docker, and assumes that docker is installed and available on the host build system. However this will not always be true, since docker itself cannot run on every system:

* because it needs root permissions to be installed and available
* because it does not work on very old systems: for instance we are still performing builds on a Mandriva 2008 system, which is not compatible with Docker.

To fix this situation, we can mix the ``ssh`` and ``docker`` approaches, to make a remote machine run Docker and perform tests in it. Ex:

.. code-block:: bash

    remote_test_host_cmd = ssh -t -X test_machine docker run --rm -u "$(id -u):$(id -g)" -e USER=$USER -e TMPDIR=/home/brutus/tmp:/home/brutus/tmp -v "$HOME":"$HOME" -e HOME="$HOME" -v /tmp/.X11-unix:/tmp/.X11-unix --net=host -e DISPLAY=$DISPLAY -e BRAINVISA_TEST_REF_DATA_DIR="$BRAINVISA_TEST_REF_DATA_DIR" -e BRAINVISA_TEST_RUN_DATA_DIR="$BRAINVISA_TEST_RUN_DATA_DIR" -v "$BRAINVISA_TEST_REF_DATA_DIR":"$BRAINVISA_TEST_REF_DATA_DIR" -v "$BRAINVISA_TEST_RUN_DATA_DIR":"$BRAINVISA_TEST_RUN_DATA_DIR" cati/brainvisa-test:ubuntu-16.04 xvfb-run --auto-servernum

which essentially concatenates the config lines of the ssh and the docker variants.

.. note::

    In this ssh + docker situation, the X11 redirection does not work so easily because ssh tunnels the X11 connection and simply assigning the ``DISPLAY`` variable is not enough. There should be ways to make it work, however the xvfb option is OK.


Real life example
-----------------

Here is a more complete example of a full ``bv_maker.cfg`` file from our build systems. Only the email addresses have been changed from our actual configuration (to avoid spams).

.. code-block:: bash

    [ general ]
      global_status_file = /neurospin/brainvisa/build/builds.log
      failure_email = brainvisa-build-notification@cea.fr
      smtp_server = mx.intra.cea.fr
      from_email = brainvisa-build-notification@cea.fr
      reply_to_email = brainvisa-build-notification@cea.fr

    [ source /neurospin/brainvisa/sources ]
      build_condition = gethostname() == 'is220756'
      + all trunk
      + all bug_fix
      + all tag
      + catidb trunk
      + catidb bug_fix
      - ptk:* trunk
      + brainvisa/development/build-config/trunk development/build-config/trunk
      - qualicati trunk
      + brainvisa/casa casa

    [ build /neurospin/brainvisa/build/$I2BM_OSID/bug_fix ]
      default_steps = configure build doc test
      make_options = -j4
      build_type = Release
      clean_config = ON
      clean_build = ON
      all bug_fix /neurospin/brainvisa/sources
      - connectomist-*
      - nuclear_processing:*
      - longitudinal_pipelines
      - sandbox
      - famis
      - ptk:*
      - axon_web

    # data packages and repository (no installer)
    [ package /neurospin/tmp/brainvisa/tests/repositories/public/%(version)s-%(date)s/data-%(os)s/packages ]
      build_directory = /neurospin/brainvisa/build/$I2BM_OSID/bug_fix
      packaging_options = --data --repository-only
      init_components_from_build_dir = OFF
      build_condition = (gethostname() != 'michael') or os.environ.get('BRAINVISA_FORCE_PACKAGING', 'OFF') == 'ON'
      default_steps = pack
      brainvisa-share bug_fix /neurospin/brainvisa/sources
      sulci-models bug_fix /neurospin/brainvisa/sources

    # software packages and repository (with installer and testing)
    [ package /neurospin/tmp/brainvisa/tests/repositories/public/%(version)s-%(date)s/%(os)s/packages ]
      build_directory = /neurospin/brainvisa/build/$I2BM_OSID/bug_fix
      packaging_options = --online-only
      installer_filename = /neurospin/tmp/brainvisa/tests/repositories/public/%(version)s-%(date)s/%(os)s/brainvisa-installer/brainvisa_installer-%(version)s-%(os)s-%(online)s
      data_repos_dir = /neurospin/tmp/brainvisa/tests/repositories/public/%(version)s-%(date)s/data-%(os)s/packages
      test_install_dir = /neurospin/tmp/brainvisa/tests/repositories/public/%(version)s-%(date)s/%(os)s/test_install
      # build every 5 days, and not on michael (Qt installer is not installed on michael)
    #  build_condition = gethostname() != 'michael' and (time.localtime()[2] % 5 == 1 or os.environ.get('BRAINVISA_FORCE_PACKAGING', 'OFF') == 'ON')
      build_condition = gethostname() != 'michael'
      default_steps = pack install_pack test_pack
      [ if gethostname() in ('is208611.intra.cea.fr', 'is220756') ]
        # tests need fixing
        default_steps = pack install_pack
      [ endif ]
      [ if gethostname() == 'i2bm-fdr4-32' ]
        # needs fixing
        default_steps = pack install_pack
      [ endif ]
      [ if gethostname() in ('is208611.intra.cea.fr', 'is220756') ]
        # run in docker, on same host
        remote_test_host_cmd = docker run --rm -v /neurospin/brainvisa:/neurospin/brainvisa -v /neurospin/tmp/brainvisa:/neurospin/tmp/brainvisa -u "$(id -u):$(id -g)" -e USER=$USER -v /volatile/a-sac-ns-brainvisa:/volatile/a-sac-ns-brainvisa -e TMPDIR=/volatile/a-sac-ns-brainvisa/tmp -v "$HOME":"$HOME" -e HOME="$HOME" -v /tmp/.X11-unix:/tmp/.X11-unix --net=host -e DISPLAY=$DISPLAY -e BRAINVISA_TESTS_DIR="$BRAINVISA_TESTS_DIR" -e BRAINVISA_TEST_REF_DATA_DIR="$BRAINVISA_TEST_REF_DATA_DIR" -e BRAINVISA_TEST_RUN_DATA_DIR="$BRAINVISA_TEST_RUN_DATA_DIR" -e QT_X11_NO_MITSHM=1 --privileged cati/brainvisa-test:ubuntu-16.04 xvfb-run --auto-servernum
      [ endif ]
      [ if gethostname() in ('i2bm-mdv-64', 'michael', 'i2bm-ub1204') ]
        # run in docker, through a ssh connection to is220756,
        # reference for tests: ubuntu 14 (host machine)
        remote_test_host_cmd = ssh -t -X is220756 docker run --rm -v /neurospin/brainvisa:/neurospin/brainvisa -v /neurospin/tmp/brainvisa:/neurospin/tmp/brainvisa -u "$(id -u):$(id -g)" -e USER=$USER -v /volatile/a-sac-ns-brainvisa:/volatile/a-sac-ns-brainvisa -e TMPDIR=/volatile/a-sac-ns-brainvisa/tmp -v "$HOME":"$HOME" -e HOME="$HOME" -v /tmp/.X11-unix:/tmp/.X11-unix -e BRAINVISA_TESTS_DIR="$BRAINVISA_TESTS_DIR"-test_pack -e BRAINVISA_TEST_REF_DATA_DIR="$BRAINVISA_TEST_REF_DATA_DIR" -e BRAINVISA_TEST_RUN_DATA_DIR="$BRAINVISA_TEST_RUN_DATA_DIR" --net=host -e DISPLAY=$DISPLAY -e QT_X11_NO_MITSHM=1 --privileged cati/brainvisa-test:ubuntu-16.04 xvfb-run --auto-servernum
      [ endif ]
      # remaining hosts (i2bm-fdr4-32) insall/test on themselves
      [ if gethostname() == 'is144451' ]
        # run via ssh on the other Mac: wake the VM and ssh to the VM inside the mac
      #  remote_test_host_cmd = ssh -t is229812 /i2bm/brainvisa/wake_vm && ssh -t -X macvm BRAINVISA_TESTS_DIR="$BRAINVISA_TESTS_DIR"-test_pack
      remote_test_host_cmd = ssh -t -X is229812 BRAINVISA_TESTS_DIR="$BRAINVISA_TESTS_DIR"-test_pack BRAINVISA_TEST_RUN_DATA_DIR="$BRAINVISA_TEST_RUN_DATA_DIR" BRAINVISA_TEST_REF_DATA_DIR="$BRAINVISA_TEST_REF_DATA_DIR"
      - preclinical_imaging_iam
      [ endif ]
      test_ref_data_dir = /neurospin/brainvisa/tests/$I2BM_OSID/ref/bug_fix-test-pack
      test_run_data_dir = /neurospin/brainvisa/tests/$I2BM_OSID/test/bug_fix-test-pack
      - sulci-data
      - communication
      - brainvisa-share
      - brain_segmentation_comparison-private
      - brain_segmentation_comparison-gpl
      - highres-cortex

