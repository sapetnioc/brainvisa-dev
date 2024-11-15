export PATH="$PIXI_PROJECT_ROOT/src/brainvisa-cmake/bin:$PIXI_PROJECT_ROOT/build/bin:$PATH:$CONDA_PREFIX/x86_64-conda-linux-gnu/sysroot/usr/bin"
export CMAKE_LIBRARY_PATH="$CONDA_PREFIX/lib:$CONDA_PREFIX/x86_64-conda-linux-gnu/sysroot/usr/lib64"
export BRAINVISA_BVMAKER_CFG=$PIXI_PROJECT_ROOT/conf/bv_maker.cfg
export LD_LIBRARY_PATH="$PIXI_PROJECT_ROOT/build/lib:$LD_LIBRARY_PATH"
python_short=$(python -c 'import sys; print(".".join(str(i) for i in sys.version_info[0:2]))')
export PYTHONPATH="$CASA/src/brainvisa-cmake/python:$CASA/build/lib/python${python_short}/site-packages:$PYTHONPATH"
export BRAINVISA_TEST_REF_DATA_DIR="$CASA_TEST/ref"
export BRAINVISA_TEST_RUN_DATA_DIR="$CASA_TEST/test"

