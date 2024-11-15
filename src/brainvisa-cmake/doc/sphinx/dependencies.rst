===============================
Dependencies in brainvisa-cmake
===============================


There are two kinds of dependencies that are defined in brainvisa-cmake: compilation dependencies and packaging dependencies. Compilation dependencies are declared by standard CMake commands such as find_package. But these commands cannot be used to identify the dependencies of the runtime, development or source packages that will be distributed. For instance, if a component uses the two following lines:

.. code-block:: cmake

    find_package( libjpeg )
    find_package( doxygen )

These two compilation dependencies are identical. However, on the one hand, ``find_package( libjpeg )`` implies that the runtime package depends on a package containing ``libjpeg.so`` (assuming dynamic link) and the development package requires a package containing the headers (``*.h``) of *libjpeg*. On the other hand, ``find_package( doxygen )`` implies only that the development package requires Doxygen in order to build the development documentation.

Therefore it is necessary to explicitly define packaging dependencies in brainvisa-cmake.


Packaging dependencies
======================

Each component compiled with brainvisa-cmake can lead to several packages:

* The **runtime package** which is the main package containing all necessary files to use the component (e.g. programs, dynamic libraries, configuration files, etc.).
* The **development** package that contains supplementary files allowing to develop programs that use the component (e.g. C header files, cmake files, etc.).
* The **documentation** packages contain documentation about the component.
  The documentation itself divides into:

  * **user documentation**
  * **development documentation**
* the **test** package contains test material (scripts, programs, data)

These packages types can lead to several dependency trees.


Function BRAINVISA_DEPENDENCY
-----------------------------

*Brainvisa-cmake* defines a function in order to define the packaging dependencies of each package type:

.. code-block:: cmake

    BRAINVISA_DEPENDENCY( <pack_type> <dependency_type> <component> <component_pack_type> [ <version ranges> ] [BINARY_INDEPENDENT] ).

The package types can be: **RUN**, **DEV**, **DOC**, **USRDOC**, **DEVDOC**, **TST**.

*Brainvisa-cmake* allows to declare four different kinds of relationship between packages: **Depends**, **Recommends**, **Suggests** and **Enhances**. The meaning of these relationships is described in the `Debian Policy Manual <https://www.debian.org/doc/debian-policy/ch-relationships.html>`_.

More information about the usage of this function can be found in the section :doc:`compile_existing`.


Note about how to handle binary incompatibilities (not used yet)
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

To handle **binary incompatibilities** between packages, it is necessary to provide information to brainvisa-installer. It is possible to rely on the dependency system to code this information. When a package has to be recompiled because one of its dependencies has changed, the new package may be binary incompatible with the old one; even if the source of the component have not been changed. For instance if Aims is modified in a binary incompatible way, it is necessary to recompile Anatomist but the new compiled version will not be binary compatible with the previous one. This situation would lead to two different Anatomist packages containing the same Anatomist versions but with two different binary signatures.

If we can attach a unique number to each binary signature of a specific version of a component, we would be able to include this number into the package version. For instance, the previous example could lead to two packages ``anatomist-3.2.0-0`` and ``anatomist-3.2.0-1`` where ``3.2.0`` is Anatomist version and the fourth number identifies binary signature changes. With this version system, packages that are binary linked to another package would include a dependency with a full version, including binary signature number. But a package that requires a specific version but without binary linking (such as Python extensions) would ignore the binary signature number in their dependencies.

The number representing the binary signature can be a counter that is incremented each time a new package with the same version is compiled. The good point for this solution is that it gives easily readable versions on packages. The drawback is that we must provide a way for brainvisa-cmake to store a counter for each component. It can be hard to do if compilation is not always done on the same build tree. Another possibility would be to use compilation date with the format ``YYYYMMDD`` (assuming that there is not two releases of a component on the same day). For instance a package ``anatomist-free_3.2.0.20091011_ubuntu-9.04_i686.deb`` would mean Anatomist version ``3.2.0`` compiled on October, 11th 2009. It is much easier to implement but leads to not very good looking version strings.

Thanks to the dependencies definition, the use of this binary signature number can be completely managed by brainvisa-cmake during packaging. The developer of a component would only have to indicate, for each runtime dependency, whether there is a binary link or not. I suggest to define a binary link by default unless the **BINARY_INDEPENDENT** option is used.


Thirdparty dependencies
-----------------------

Third-party dependencies used to be packaged but this is not supported anymore starting with the container-based BrainVISA releases (BrainVISA 5.0).
