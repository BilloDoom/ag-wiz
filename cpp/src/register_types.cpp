#include <godot_cpp/core/class_db.hpp>
#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>

#include "hello_node.hpp"
#include "script_runtime.hpp"
#include "data_buffer.hpp"
#include "viewport_bridge.hpp"

using namespace godot;

static bool is_registered = false;

void initialize_wiz_extension(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    if (is_registered) {
        return;
    }

    ClassDB::register_class<HelloNode>();
    ClassDB::register_class<ScriptRuntime>();
    ClassDB::register_class<DataBuffer>();
    ClassDB::register_class<ViewportBridge>();

    is_registered = true;
}

void uninitialize_wiz_extension(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
    
    is_registered = false;
}

extern "C" {

// Entry point symbol (must match .gdextension file)
GDExtensionBool GDE_EXPORT wiz_extension_init(
    GDExtensionInterfaceGetProcAddress p_get_proc_adress,
    const GDExtensionClassLibraryPtr p_library,
    GDExtensionInitialization *r_initialization
) {
    GDExtensionBinding::InitObject init_obj(p_get_proc_adress, p_library, r_initialization);

    init_obj.register_initializer(initialize_wiz_extension);
    init_obj.register_terminator(uninitialize_wiz_extension);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

    return init_obj.init();
}

}
