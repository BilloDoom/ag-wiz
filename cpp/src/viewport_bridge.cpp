#include "viewport_bridge.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/scene_tree.hpp>

namespace godot {

void ViewportBridge::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_viewport_manager_path", "path"), &ViewportBridge::set_viewport_manager_path);
    ClassDB::bind_method(D_METHOD("init_3d_scene", "id", "settings"), &ViewportBridge::init_3d_scene);
    ClassDB::bind_method(D_METHOD("init_2d_scene", "id", "settings"), &ViewportBridge::init_2d_scene);
    ClassDB::bind_method(D_METHOD("configure_viewport", "id", "viewport_type", "settings"), &ViewportBridge::configure_viewport);
    ClassDB::bind_method(D_METHOD("decouple_viewport", "id"), &ViewportBridge::decouple_viewport);
    ClassDB::bind_method(D_METHOD("toggle_floating", "id"), &ViewportBridge::toggle_floating);
    ClassDB::bind_method(D_METHOD("close_viewport", "id"), &ViewportBridge::close_viewport);
    ClassDB::bind_method(D_METHOD("get_render_root", "id"), &ViewportBridge::get_render_root);
    ClassDB::bind_method(D_METHOD("setup_python_bindings"), &ViewportBridge::setup_python_bindings);
}

ViewportBridge::ViewportBridge() {
    UtilityFunctions::print("ViewportBridge created");
    viewport_manager_path = NodePath("/root/ViewportManager");
}

ViewportBridge::~ViewportBridge() {
    UtilityFunctions::print("ViewportBridge destroyed");
}

void ViewportBridge::set_viewport_manager_path(const NodePath& path) {
    viewport_manager_path = path;
}

Node* ViewportBridge::get_viewport_manager() {
    if (!is_inside_tree()) {
        UtilityFunctions::printerr("ViewportBridge: Not inside tree");
        return nullptr;
    }

    Node* manager = get_node_or_null(viewport_manager_path);
    if (!manager) {
        UtilityFunctions::printerr("ViewportBridge: ViewportManager not found at path: ", viewport_manager_path);
        return nullptr;
    }

    return manager;
}

bool ViewportBridge::init_3d_scene(const String& id, const Dictionary& settings) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return false;
    }

    // Call ViewportManager.create_viewport(id, "3d", settings)
    if (manager->has_method("create_viewport")) {
        Variant result = manager->call("create_viewport", id, String("3d"), settings);
        return result.operator Object*() != nullptr;
    } else {
        UtilityFunctions::printerr("ViewportBridge: ViewportManager missing create_viewport method");
        return false;
    }
}

bool ViewportBridge::init_2d_scene(const String& id, const Dictionary& settings) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return false;
    }

    // Call ViewportManager.create_viewport(id, "2d", settings)
    if (manager->has_method("create_viewport")) {
        Variant result = manager->call("create_viewport", id, String("2d"), settings);
        return result.operator Object*() != nullptr;
    } else {
        UtilityFunctions::printerr("ViewportBridge: ViewportManager missing create_viewport method");
        return false;
    }
}

bool ViewportBridge::configure_viewport(const String& id, const String& viewport_type, const Dictionary& settings) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return false;
    }

    // Call ViewportManager.configure_viewport(id, viewport_type, settings)
    if (manager->has_method("configure_viewport")) {
        Variant result = manager->call("configure_viewport", id, viewport_type, settings);
        return result.operator bool();
    } else {
        UtilityFunctions::printerr("ViewportBridge: ViewportManager missing configure_viewport method");
        return false;
    }
}

bool ViewportBridge::decouple_viewport(const String& id) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return false;
    }

    // Call ViewportManager.decouple_viewport(id)
    if (manager->has_method("decouple_viewport")) {
        Variant result = manager->call("decouple_viewport", id);
        return result.operator bool();
    } else {
        UtilityFunctions::printerr("ViewportBridge: ViewportManager missing decouple_viewport method");
        return false;
    }
}

void ViewportBridge::toggle_floating(const String& id) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return;
    }

    if (manager->has_method("toggle_floating")) {
        manager->call("toggle_floating", id);
    }
}

void ViewportBridge::close_viewport(const String& id) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return;
    }

    if (manager->has_method("close_viewport")) {
        manager->call("close_viewport", id);
    }
}

Node* ViewportBridge::get_render_root(const String& id) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("get_render_root")) {
        Variant result = manager->call("get_render_root", id);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

void ViewportBridge::setup_python_bindings() {
    // Prevent duplicate registration
    static bool bindings_registered = false;
    if (bindings_registered) {
        UtilityFunctions::print("ViewportBridge: Python bindings already registered, skipping");
        return;
    }

    try {
        // Get or create the 'godot' module in Python
        py::module_ sys = py::module_::import("sys");
        py::dict modules = sys.attr("modules");

        py::module_ godot_module;
        if (modules.contains("godot")) {
            godot_module = modules["godot"].cast<py::module_>();
        } else {
            godot_module = py::module_::create_extension_module("godot", nullptr, new PyModuleDef());
            modules["godot"] = godot_module;
        }

        // Capture 'this' pointer for Python callbacks
        ViewportBridge* bridge = this;

        // Define Python functions that call back to this C++ instance
        godot_module.def("init_3d_scene", [bridge](const std::string& id, py::dict settings) {
            Dictionary godot_dict;

            // Convert Python dict to Godot Dictionary
            for (auto item : settings) {
                std::string key = py::str(item.first);

                // Handle different value types
                py::object value = item.second.cast<py::object>();

                if (py::isinstance<py::bool_>(value)) {
                    godot_dict[String(key.c_str())] = value.cast<bool>();
                } else if (py::isinstance<py::int_>(value)) {
                    godot_dict[String(key.c_str())] = value.cast<int64_t>();
                } else if (py::isinstance<py::float_>(value)) {
                    godot_dict[String(key.c_str())] = value.cast<double>();
                } else if (py::isinstance<py::str>(value)) {
                    godot_dict[String(key.c_str())] = String(value.cast<std::string>().c_str());
                } else if (py::isinstance<py::tuple>(value)) {
                    // Handle tuples as Vector3/Vector2
                    py::tuple tuple = value.cast<py::tuple>();
                    if (tuple.size() == 3) {
                        godot_dict[String(key.c_str())] = Vector3(
                            tuple[0].cast<double>(),
                            tuple[1].cast<double>(),
                            tuple[2].cast<double>()
                        );
                    } else if (tuple.size() == 2) {
                        godot_dict[String(key.c_str())] = Vector2(
                            tuple[0].cast<double>(),
                            tuple[1].cast<double>()
                        );
                    }
                }
            }

            return bridge->init_3d_scene(String(id.c_str()), godot_dict);
        }, "Create a 3D viewport", py::arg("id"), py::arg("settings") = py::dict());

        godot_module.def("init_2d_scene", [bridge](const std::string& id, py::dict settings) {
            Dictionary godot_dict;

            // Convert Python dict to Godot Dictionary
            for (auto item : settings) {
                std::string key = py::str(item.first);
                py::object value = item.second.cast<py::object>();

                if (py::isinstance<py::bool_>(value)) {
                    godot_dict[String(key.c_str())] = value.cast<bool>();
                } else if (py::isinstance<py::int_>(value)) {
                    godot_dict[String(key.c_str())] = value.cast<int64_t>();
                } else if (py::isinstance<py::float_>(value)) {
                    godot_dict[String(key.c_str())] = value.cast<double>();
                } else if (py::isinstance<py::str>(value)) {
                    godot_dict[String(key.c_str())] = String(value.cast<std::string>().c_str());
                } else if (py::isinstance<py::tuple>(value)) {
                    py::tuple tuple = value.cast<py::tuple>();
                    if (tuple.size() == 2) {
                        godot_dict[String(key.c_str())] = Vector2(
                            tuple[0].cast<double>(),
                            tuple[1].cast<double>()
                        );
                    }
                }
            }

            return bridge->init_2d_scene(String(id.c_str()), godot_dict);
        }, "Create a 2D viewport", py::arg("id"), py::arg("settings") = py::dict());

        godot_module.def("configure_viewport", [bridge](const std::string& id, const std::string& viewport_type, py::dict settings) {
            Dictionary godot_dict;

            // Convert Python dict to Godot Dictionary
            for (auto item : settings) {
                std::string key = py::str(item.first);
                py::object value = item.second.cast<py::object>();

                if (py::isinstance<py::bool_>(value)) {
                    godot_dict[String(key.c_str())] = value.cast<bool>();
                } else if (py::isinstance<py::int_>(value)) {
                    godot_dict[String(key.c_str())] = value.cast<int64_t>();
                } else if (py::isinstance<py::float_>(value)) {
                    godot_dict[String(key.c_str())] = value.cast<double>();
                } else if (py::isinstance<py::str>(value)) {
                    godot_dict[String(key.c_str())] = String(value.cast<std::string>().c_str());
                } else if (py::isinstance<py::tuple>(value)) {
                    py::tuple tuple = value.cast<py::tuple>();
                    if (tuple.size() == 3) {
                        godot_dict[String(key.c_str())] = Vector3(
                            tuple[0].cast<double>(),
                            tuple[1].cast<double>(),
                            tuple[2].cast<double>()
                        );
                    } else if (tuple.size() == 2) {
                        godot_dict[String(key.c_str())] = Vector2(
                            tuple[0].cast<double>(),
                            tuple[1].cast<double>()
                        );
                    }
                }
            }

            return bridge->configure_viewport(String(id.c_str()), String(viewport_type.c_str()), godot_dict);
        }, "Configure an existing viewport as 3d or 2d", py::arg("id"), py::arg("viewport_type"), py::arg("settings") = py::dict());

        godot_module.def("decouple_viewport", [bridge](const std::string& id) {
            return bridge->decouple_viewport(String(id.c_str()));
        }, "Remove the 3D/2D scene from a viewport, keeping the holder alive");

        godot_module.def("toggle_floating", [bridge](const std::string& id) {
            bridge->toggle_floating(String(id.c_str()));
        }, "Toggle viewport between embedded and floating");

        godot_module.def("close_viewport", [bridge](const std::string& id) {
            bridge->close_viewport(String(id.c_str()));
        }, "Close a viewport");

        // Mark bindings as registered
        bindings_registered = true;
        UtilityFunctions::print("ViewportBridge: Python bindings setup successfully");

    } catch (const py::error_already_set& e) {
        UtilityFunctions::printerr("ViewportBridge: Python binding error: ", String(e.what()));
    } catch (const std::exception& e) {
        UtilityFunctions::printerr("ViewportBridge: Error setting up Python bindings: ", String(e.what()));
    }
}

} // namespace godot
