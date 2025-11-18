#include "script_runtime.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <pybind11/embed.h>
#include <sstream>

namespace py = pybind11;

namespace godot {

void ScriptRuntime::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize_python"), &ScriptRuntime::initialize_python);
    ClassDB::bind_method(D_METHOD("execute_script", "code"), &ScriptRuntime::execute_script);
    ClassDB::bind_method(D_METHOD("get_last_output"), &ScriptRuntime::get_last_output);
    ClassDB::bind_method(D_METHOD("get_last_error"), &ScriptRuntime::get_last_error);
    ClassDB::bind_method(D_METHOD("is_python_ready"), &ScriptRuntime::is_python_ready);
}

ScriptRuntime::ScriptRuntime() : python_initialized(false) {
    UtilityFunctions::print("ScriptRuntime created");
}

ScriptRuntime::~ScriptRuntime() {
    // Python interpreter cleanup happens automatically via scoped_interpreter
    UtilityFunctions::print("ScriptRuntime destroyed");
}

void ScriptRuntime::initialize_python() {
    if (python_initialized) {
        UtilityFunctions::print("Python already initialized");
        return;
    }

    try {
        // Initialize Python interpreter (static, happens once)
        static py::scoped_interpreter guard{};
        python_initialized = true;
        UtilityFunctions::print("Python interpreter initialized successfully");
    } catch (const std::exception& e) {
        last_error = String("Failed to initialize Python: ") + e.what();
        UtilityFunctions::printerr(last_error);
        python_initialized = false;
    }
}

bool ScriptRuntime::execute_script(const String& code) {
    if (!python_initialized) {
        last_error = "Python not initialized. Call initialize_python() first.";
        UtilityFunctions::printerr(last_error);
        return false;
    }

    last_output = "";
    last_error = "";

    try {
        // Redirect stdout and stderr to capture output
        py::object sys = py::module_::import("sys");
        py::object io = py::module_::import("io");

        py::object stdout_capture = io.attr("StringIO")();
        py::object stderr_capture = io.attr("StringIO")();

        sys.attr("stdout") = stdout_capture;
        sys.attr("stderr") = stderr_capture;

        // Execute the Python code
        py::exec(code.utf8().get_data());

        // Get captured output
        py::object stdout_value = stdout_capture.attr("getvalue")();
        py::object stderr_value = stderr_capture.attr("getvalue")();

        std::string output_str = py::cast<std::string>(stdout_value);
        std::string error_str = py::cast<std::string>(stderr_value);

        last_output = String(output_str.c_str());

        if (!error_str.empty()) {
            last_error = String(error_str.c_str());
            UtilityFunctions::print("Script output: ", last_output);
            UtilityFunctions::printerr("Script errors: ", last_error);
        } else {
            UtilityFunctions::print("Script executed successfully. Output: ", last_output);
        }

        return error_str.empty();

    } catch (const py::error_already_set& e) {
        last_error = String("Python execution error: ") + e.what();
        UtilityFunctions::printerr(last_error);
        return false;
    } catch (const std::exception& e) {
        last_error = String("Execution error: ") + e.what();
        UtilityFunctions::printerr(last_error);
        return false;
    }
}

String ScriptRuntime::get_last_output() const {
    return last_output;
}

String ScriptRuntime::get_last_error() const {
    return last_error;
}

bool ScriptRuntime::is_python_ready() const {
    return python_initialized;
}

} // namespace godot
