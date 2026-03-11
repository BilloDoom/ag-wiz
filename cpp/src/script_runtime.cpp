#include "script_runtime.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <pybind11/embed.h>
#include <sstream>

namespace py = pybind11;

// ---------------------------------------------------------------------------
// Process-lifetime Python interpreter state.
//
// pybind11's scoped_interpreter must live for the entire duration that Python
// is in use.  It must be constructed exactly ONCE per process.
//
// The problem this solves: CodeRunner calls ScriptRuntime.new() on every
// script run, giving each run a fresh GDScript object – but the C++ instance
// member `python_initialized` starts false on every new object, so the old
// code tried to construct a second scoped_interpreter, which deadlocks CPython.
//
// Solution: keep interpreter and globals as process-level static pointers.
// They are allocated on first use and intentionally never freed – the OS
// reclaims memory at process exit, which is the correct shutdown path for an
// embedded CPython interpreter.
// ---------------------------------------------------------------------------
static py::scoped_interpreter* g_interpreter = nullptr;
static bool                    g_python_ready = false;
static py::dict*               g_globals      = nullptr;  // shared exec namespace

namespace godot {

void ScriptRuntime::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize_python"), &ScriptRuntime::initialize_python);
    ClassDB::bind_method(D_METHOD("execute_script", "code"), &ScriptRuntime::execute_script);
    ClassDB::bind_method(D_METHOD("get_last_output"), &ScriptRuntime::get_last_output);
    ClassDB::bind_method(D_METHOD("get_last_error"), &ScriptRuntime::get_last_error);
    ClassDB::bind_method(D_METHOD("is_python_ready"), &ScriptRuntime::is_python_ready);
    ClassDB::bind_method(D_METHOD("reset_globals"), &ScriptRuntime::reset_globals);
}

ScriptRuntime::ScriptRuntime() {
    UtilityFunctions::print("ScriptRuntime created");
}

ScriptRuntime::~ScriptRuntime() {
    // The interpreter is process-lifetime; do not shut it down here.
    UtilityFunctions::print("ScriptRuntime destroyed");
}

void ScriptRuntime::initialize_python() {
    // If the interpreter is already running (from a previous ScriptRuntime
    // instance in this process), just reuse it – do NOT construct another one.
    if (g_python_ready) {
        UtilityFunctions::print("Python already initialized (reusing existing interpreter)");
        return;
    }

    try {
        g_interpreter = new py::scoped_interpreter{};
        g_python_ready = true;

        // Seed the persistent globals namespace with __builtins__ so every
        // script execution has access to built-ins (print, range, len, …).
        g_globals = new py::dict{};
        (*g_globals)["__builtins__"] = py::module_::import("builtins");

        // ---------------------------------------------------------------
        // Sandbox: replace dangerous builtins and block restricted modules.
        //
        // Blocked builtins  : open, __import__ (for os/socket/etc.)
        // Blocked modules   : os, socket, urllib, requests, http,
        //                     subprocess, shutil, pathlib, ftplib, smtplib
        // Allowed built-ins : sys, builtins, types, abc, io (needed internally
        //                     by pybind11 – not a security risk)
        //
        // Any call to a blocked function prints a SANDBOX_WARN: sentinel
        // line which code_runner.gd intercepts and shows in magenta in the
        // in-app output panel.  The Godot console also gets a rich-colour
        // print via UtilityFunctions::print_rich.
        // ---------------------------------------------------------------
        const char* sandbox_code = R"PYEOF(
import sys as _sys
import builtins as _builtins

_BLOCKED_MODULES = {
    'os', 'os.path', 'socket', 'ssl',
    'urllib', 'urllib.request', 'urllib.parse', 'urllib.error',
    'http', 'http.client', 'http.server',
    'requests', 'httpx', 'aiohttp',
    'subprocess', 'shutil', 'pathlib',
    'ftplib', 'smtplib', 'imaplib', 'poplib',
    'paramiko', 'fabric',
    'ctypes', 'cffi', 'winreg', 'msvcrt',
    'multiprocessing', 'threading',
}

# Modules that are safe built-ins — silently allowed even though they
# might look dangerous. Pybind11 also imports these internally.
_BUILTIN_MODULES = {'sys', 'builtins', 'types', 'abc', 'io', '_io',
                    'importlib', 'importlib._bootstrap',
                    'importlib._bootstrap_external'}

def _sandbox_warn(msg):
    # Sentinel prefix for code_runner.gd to intercept
    print('SANDBOX_WARN:' + msg)

def _blocked_open(*args, **kwargs):
    _sandbox_warn('open() is not allowed – file system access is disabled.')
    return None

def _blocked_import(name, *args, **kwargs):
    top = name.split('.')[0]
    # Always allow known safe built-ins without warning
    if top in _BUILTIN_MODULES or name in _BUILTIN_MODULES:
        return _real_import(name, *args, **kwargs)
    if top in _BLOCKED_MODULES or name in _BLOCKED_MODULES:
        _sandbox_warn("import '" + name + "' is not allowed – this module is restricted.")
        # Return a dummy module so attribute access doesn't immediately crash.
        # __getattr__ on a module instance takes only the attribute name (no self).
        import types as _types
        dummy = _types.ModuleType(name)
        _n = name  # capture for closure
        def _dummy_getattr(k):
            _sandbox_warn("'" + _n + "." + k + "' is not allowed")
            return lambda *a, **kw: None
        dummy.__getattr__ = _dummy_getattr
        return dummy
    return _real_import(name, *args, **kwargs)

_real_import = _builtins.__import__
_builtins.open   = _blocked_open
_builtins.__import__ = _blocked_import

# Also shadow them in the globals dict directly so 'open(...)' at module
# level resolves to the blocked version even without going through __import__.
open = _blocked_open
)PYEOF";

        py::exec(sandbox_code, *g_globals);
        UtilityFunctions::print("Python interpreter initialized successfully");
        UtilityFunctions::print_rich("[color=cyan]Sandbox active: file I/O and network access are disabled.[/color]");
    } catch (const std::exception& e) {
        last_error = String("Failed to initialize Python: ") + e.what();
        UtilityFunctions::printerr(last_error);
    }
}

bool ScriptRuntime::execute_script(const String& code) {
    if (!g_python_ready) {
        last_error = "Python not initialized. Call initialize_python() first.";
        UtilityFunctions::printerr(last_error);
        return false;
    }

    last_output = "";
    last_error  = "";

    try {
        py::object sys = py::module_::import("sys");
        py::object io  = py::module_::import("io");

        py::object stdout_cap = io.attr("StringIO")();
        py::object stderr_cap = io.attr("StringIO")();

        sys.attr("stdout") = stdout_cap;
        sys.attr("stderr") = stderr_cap;

        // Execute in the persistent globals namespace so that names imported
        // by one call (e.g. "from godot import *") remain available in
        // subsequent calls (e.g. resume_async invocations from the async runner).
        py::exec(code.utf8().get_data(), *g_globals);

        std::string out = py::cast<std::string>(stdout_cap.attr("getvalue")());
        std::string err = py::cast<std::string>(stderr_cap.attr("getvalue")());

        last_output = String(out.c_str());

        if (!err.empty()) {
            last_error = String(err.c_str());
            UtilityFunctions::print("Script output: ", last_output);
            UtilityFunctions::printerr("Script errors: ", last_error);
        } else {
            UtilityFunctions::print("Script executed successfully. Output: ", last_output);
        }

        return err.empty();

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
    return g_python_ready;
}

void ScriptRuntime::reset_globals() {
    if (!g_python_ready) return;

    // Replace the globals dict with a fresh one containing only __builtins__.
    // This clears all user-defined names from the previous run without
    // touching the interpreter state itself.
    delete g_globals;
    g_globals = new py::dict{};
    (*g_globals)["__builtins__"] = py::module_::import("builtins");
    UtilityFunctions::print("ScriptRuntime: globals reset");
}

} // namespace godot
