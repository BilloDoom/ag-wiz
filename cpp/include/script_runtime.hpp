#ifndef SCRIPT_RUNTIME_HPP
#define SCRIPT_RUNTIME_HPP

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class ScriptRuntime : public Node {
    GDCLASS(ScriptRuntime, Node)

private:
    // Per-instance output/error buffers only.
    // The interpreter and globals are process-level statics in script_runtime.cpp.
    String last_output;
    String last_error;

protected:
    static void _bind_methods();

public:
    ScriptRuntime();
    ~ScriptRuntime();

    // Initialize Python interpreter
    void initialize_python();

    // Execute Python code
    bool execute_script(const String& code);

    // Get output/errors from last execution
    String get_last_output() const;
    String get_last_error() const;

    // Check if Python is initialized
    bool is_python_ready() const;

    // Reset the persistent globals namespace (call before each new user script run)
    void reset_globals();
};

} // namespace godot

#endif // SCRIPT_RUNTIME_HPP
