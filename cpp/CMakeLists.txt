cmake_minimum_required(VERSION 3.20)

# Name of your final extension library
set(TARGET_NAME "wiz_extension")

# Output directory → put binaries inside your Godot project (algorithm-wizard/bin)
# On Windows: .dll goes to RUNTIME, .lib goes to LIBRARY
# On Linux/Mac: .so/.dylib goes to LIBRARY
# Use generator expressions to handle multi-config generators (MSVC adds Debug/Release subdirs)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/algorithm-wizard/bin/$<CONFIG>)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/algorithm-wizard/bin/$<CONFIG>)

# Source files
file(GLOB_RECURSE EXT_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
)
file(GLOB_RECURSE EXT_HEADERS
    ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp
)

# Define the extension library
add_library(${TARGET_NAME} SHARED
    ${EXT_SOURCES}
    ${EXT_HEADERS}
)

# Include godot-cpp, pybind11, and Python headers
target_include_directories(${TARGET_NAME}
    PUBLIC
        ${CMAKE_SOURCE_DIR}/godot-cpp/include
        ${CMAKE_SOURCE_DIR}/godot-cpp/gen/include
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${Python3_INCLUDE_DIRS}
)

# Link against godot-cpp, pybind11, and Python libraries
target_link_libraries(${TARGET_NAME}
    PUBLIC
        godot-cpp
        pybind11::embed
        Python3::Python
)

# Platform-specific naming fix (Godot expects certain names)
if (WIN32)
    set_target_properties(${TARGET_NAME} PROPERTIES SUFFIX ".dll")

    # Copy Python DLL to output directory on Windows (required dependency)
    get_filename_component(PYTHON_DLL_DIR "${Python3_RUNTIME_LIBRARY_DIRS}" ABSOLUTE)
    if(Python3_RUNTIME_LIBRARY_DIRS)
        add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${Python3_RUNTIME_LIBRARY_DIRS}/python${Python3_VERSION_MAJOR}${Python3_VERSION_MINOR}.dll"
                "$<TARGET_FILE_DIR:${TARGET_NAME}>"
            COMMENT "Copying Python DLL to output directory"
        )
    else()
        # Fallback: try to find python DLL in standard location
        get_filename_component(PYTHON_DIR "${Python3_EXECUTABLE}" DIRECTORY)
        add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${PYTHON_DIR}/python${Python3_VERSION_MAJOR}${Python3_VERSION_MINOR}.dll"
                "$<TARGET_FILE_DIR:${TARGET_NAME}>"
            COMMENT "Copying Python DLL to output directory (fallback path)"
        )
    endif()
elseif (APPLE)
    set_target_properties(${TARGET_NAME} PROPERTIES SUFFIX ".dylib")
elseif (UNIX)
    set_target_properties(${TARGET_NAME} PROPERTIES SUFFIX ".so")
endif()
