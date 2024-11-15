======
bv_env
======

bv_env program
==============

The **bv_env** program sets up paths to run all programs from a build tree or binary package installation of software built or installed via the *brainvisa-cmake* environment.

It sets basically ``PATH``, ``LD_LIBRARY_PATH``, ``PYTHONPATH`` and ``BRAINVISA_SHARE`` environment variables, and saves their previous values in ``BRAINVISA_UNENV_*`` variables.

When run with no arguments, ``bv_env`` just prints the environment it would set.

When run with arguments, ``bv_env`` will run the commandline specified as arguments, in the bv_env environment.

.. code-block:: bash

    /home/myself/brainvisa_install/bin/bv_env anatomist /home/myself/data/mri.nii /home/myself/data/brain_mesh.gii

The environment is set only duing the command execution time, it does not modify shell variables from the calling program or shell.

The program is relocatable, this means that if you move the install tree after it is installed, bv_env will find out from where it is run and adapt, so it will still be valid.


bv_env.sh, bv_env.csh, bv_env.bat scripts
=========================================

These scripts do the same as the bv_env program, except that they do not run a program on-the-fly, but change the calling shell environment variables. As it depends on the shell type used, there are several scripts for *sh/bash*, *csh/tcsh*, or windows *DOS* shells.

We have to admit that currently we only use *bash* shells and the other scripts are mostly untested.

In Unix shells (sh, bash, csh, tcsh), to actually modify the running environment, the scripts have to be *sourced*, not just run. Ex:

.. code-block:: bash

    . /home/myself/brainvisa_install/bin/bv_env.sh

or:

.. code-block:: bash

    source /home/myself/brainvisa_install/bin/bv_env.sh

will modify the calling shell, whereas:

.. code-block:: bash

    /home/myself/brainvisa_install/bin/bv_env.sh

will just appear to no nothing (it will modify variables internally during the script execution, but the calling shell will not be modified).

The programs are relocatable, this means that if you move the install tree after it is installed, ``bv_env.*`` scripts will find out from where it is run and adapt, so it will still be valid.

However to find out where they are run from, the scripts need to access the shell commands history, so the above commands will work in an interactive shell, but not from within a script or ``.bashrc`` configuration script.

To overcome this problem, she ``bv_env.sh`` script can be passed an argument, which is the build / install directory location:

.. code-block:: bash

    . /home/myself/brainvisa_install/bin/bv_env.sh /home/myself/brainvisa_install


bv_unenv
========

If you need to run an "external" program, a program not part of the BrainVisa package, from a program within the BrainVisa environment, it may cause environment and libraries conflict problems, because BV programs need some libraries installed within the installation directory and environment, but "external" programs need the system versions.

When running such a program, it is possible to "undo" the environment setup of *bv_env*, using the **bv_unenv** program.

It otherwise works the same way.

The **bv_unenv.sh** script is the equivalent to undo *bv_env.sh* script.

