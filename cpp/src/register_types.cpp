#include <godot_cpp/core/class_db.hpp>
#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>

#include "hello_node.hpp"

using namespace godot;

void initialize_wiz_extension(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    ClassDB::register_class<HelloNode>();
}

void uninitialize_wiz_extension(ModuleInitializationLevel p_level) {
    // Nothing to clean up
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
