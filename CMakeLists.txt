cmake_minimum_required(VERSION 3.20)
project(godot_algorithm_wizard)

set(CMAKE_CXX_STANDARD 17)

# -----------------------------
# Configure paths
# -----------------------------
set(GODOT_CPP_PATH "${CMAKE_SOURCE_DIR}/godot-cpp")
set(EXTENSION_PATH "${CMAKE_SOURCE_DIR}/cpp")

# Add godot-cpp
add_subdirectory(${GODOT_CPP_PATH})

# Add your extension's build
add_subdirectory(${EXTENSION_PATH})
