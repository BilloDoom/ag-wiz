cmake_minimum_required(VERSION 3.20)
project(godot_algorithm_wizard)
set(CMAKE_CXX_STANDARD 17)

# -----------------------------
# Find Python and pybind11
# -----------------------------
find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
message(STATUS "Python3 found: ${Python3_EXECUTABLE}")
message(STATUS "Python3 version: ${Python3_VERSION}")
message(STATUS "Python3 include dirs: ${Python3_INCLUDE_DIRS}")
message(STATUS "Python3 libraries: ${Python3_LIBRARIES}")

# Find pybind11 from Python installation (if installed via pip)
execute_process(
    COMMAND "${Python3_EXECUTABLE}" -m pybind11 --cmakedir
    OUTPUT_VARIABLE pybind11_CMAKE_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE pybind11_ERROR
    RESULT_VARIABLE pybind11_FIND_RESULT
)

message(STATUS "pybind11 detection result: ${pybind11_FIND_RESULT}")
message(STATUS "pybind11 output (raw): '${pybind11_CMAKE_DIR}'")

if(pybind11_FIND_RESULT EQUAL 0 AND pybind11_CMAKE_DIR)
    # FIXED: Remove quotes that Python might add
    string(REPLACE "\"" "" pybind11_CMAKE_DIR "${pybind11_CMAKE_DIR}")
    string(STRIP "${pybind11_CMAKE_DIR}" pybind11_CMAKE_DIR)
    
    message(STATUS "pybind11 CMake dir (cleaned): ${pybind11_CMAKE_DIR}")
    
    # Add to CMAKE_PREFIX_PATH
    list(APPEND CMAKE_PREFIX_PATH "${pybind11_CMAKE_DIR}")
else()
    message(FATAL_ERROR "Could not find pybind11 via Python. Make sure it's installed: pip install pybind11")
endif()

find_package(pybind11 CONFIG REQUIRED)
message(STATUS "pybind11 version: ${pybind11_VERSION}")

# -----------------------------
# Configure paths
# -----------------------------
set(GODOT_CPP_PATH "${CMAKE_SOURCE_DIR}/godot-cpp")
set(EXTENSION_PATH "${CMAKE_SOURCE_DIR}/cpp")

# Add godot-cpp
add_subdirectory(${GODOT_CPP_PATH})

# Add your extension's build
add_subdirectory(${EXTENSION_PATH})