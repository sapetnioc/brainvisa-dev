# This is the main CMakeLists.txt for compiling
# several BrainVISA projects in the same build
# tree.
cmake_minimum_required( VERSION 3.20 )
find_package( brainvisa-cmake NO_POLICY_SCOPE )
include( "${brainvisa-cmake_DIR}/brainvisa-find-components.cmake" )
