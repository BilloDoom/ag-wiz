#include "viewport_bridge.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/scene_tree.hpp>

namespace godot {

void ViewportBridge::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_viewport_manager_path", "path"), &ViewportBridge::set_viewport_manager_path);
    // New API
    ClassDB::bind_method(D_METHOD("create_scene_3d"), &ViewportBridge::create_scene_3d);
    ClassDB::bind_method(D_METHOD("create_scene_2d"), &ViewportBridge::create_scene_2d);
    ClassDB::bind_method(D_METHOD("add_camera_to_viewport", "camera_name", "port_id", "scene_id", "settings"), &ViewportBridge::add_camera_to_viewport);
    ClassDB::bind_method(D_METHOD("remove_camera", "camera_name"), &ViewportBridge::remove_camera);
    ClassDB::bind_method(D_METHOD("get_camera_node", "camera_name"), &ViewportBridge::get_camera_node);
    // Legacy API
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

// New API implementations
String ViewportBridge::create_scene_3d() {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return "";
    }

    if (manager->has_method("create_scene_3d")) {
        Variant result = manager->call("create_scene_3d");
        return result.operator String();
    } else {
        UtilityFunctions::printerr("ViewportBridge: ViewportManager missing create_scene_3d method");
        return "";
    }
}

String ViewportBridge::create_scene_2d() {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return "";
    }

    if (manager->has_method("create_scene_2d")) {
        Variant result = manager->call("create_scene_2d");
        return result.operator String();
    } else {
        UtilityFunctions::printerr("ViewportBridge: ViewportManager missing create_scene_2d method");
        return "";
    }
}

bool ViewportBridge::add_camera_to_viewport(const String& camera_name, const String& port_id, const String& scene_id, const Dictionary& settings) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return false;
    }

    if (manager->has_method("add_camera_to_viewport")) {
        Variant result = manager->call("add_camera_to_viewport", camera_name, port_id, scene_id, settings);
        return result.operator bool();
    } else {
        UtilityFunctions::printerr("ViewportBridge: ViewportManager missing add_camera_to_viewport method");
        return false;
    }
}

bool ViewportBridge::remove_camera(const String& camera_name) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return false;
    }

    if (manager->has_method("remove_camera")) {
        Variant result = manager->call("remove_camera", camera_name);
        return result.operator bool();
    } else {
        UtilityFunctions::printerr("ViewportBridge: ViewportManager missing remove_camera method");
        return false;
    }
}

Node* ViewportBridge::get_camera_node(const String& camera_name) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("get_camera_node")) {
        Variant result = manager->call("get_camera_node", camera_name);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

// Scene context implementations
bool ViewportBridge::enter_scene_context(const String& scene_id) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return false;
    }

    if (manager->has_method("enter_scene_context")) {
        Variant result = manager->call("enter_scene_context", scene_id);
        return result.operator bool();
    } else {
        UtilityFunctions::printerr("ViewportBridge: ViewportManager missing enter_scene_context method");
        return false;
    }
}

void ViewportBridge::exit_scene_context() {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return;
    }

    if (manager->has_method("exit_scene_context")) {
        manager->call("exit_scene_context");
    }
}

// Primitive drawing implementations
Node* ViewportBridge::draw_box(const Vector3& size, const Vector3& position, const Vector3& rotation, const Color& color) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("draw_box")) {
        Variant result = manager->call("draw_box", size, position, rotation, color);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

Node* ViewportBridge::draw_sphere(float radius, const Vector3& position, const Color& color) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("draw_sphere")) {
        Variant result = manager->call("draw_sphere", radius, position, color);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

Node* ViewportBridge::draw_cylinder(float radius, float height, const Vector3& position, const Vector3& rotation, const Color& color) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("draw_cylinder")) {
        Variant result = manager->call("draw_cylinder", radius, height, position, rotation, color);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

Node* ViewportBridge::draw_torus(float inner_radius, float outer_radius, const Vector3& position, const Vector3& rotation, const Color& color) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("draw_torus")) {
        Variant result = manager->call("draw_torus", inner_radius, outer_radius, position, rotation, color);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

// Legacy API implementations
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

        // New API - Scene and Camera management
        // Note: create_scene_3d and create_scene_2d are defined later with context manager support

        godot_module.def("add_camera", [bridge](const std::string& camera_name, const std::string& port_id, py::object scene_obj, py::dict settings) {
            // Extract scene_id from either string or SceneContext object
            std::string scene_id;
            try {
                // Try to get scene_id attribute (if it's a SceneContextWrapper)
                scene_id = scene_obj.attr("scene_id").cast<std::string>();
            } catch (...) {
                // Otherwise assume it's a string
                scene_id = scene_obj.cast<std::string>();
            }
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

            return bridge->add_camera_to_viewport(
                String(camera_name.c_str()),
                String(port_id.c_str()),
                String(scene_id.c_str()),
                godot_dict
            );
        }, "Add a camera to a viewport viewing a scene",
           py::arg("name"),
           py::arg("port"),
           py::arg("scene"),
           py::arg("settings") = py::dict());

        godot_module.def("remove_camera", [bridge](const std::string& camera_name) {
            return bridge->remove_camera(String(camera_name.c_str()));
        }, "Remove a camera from its viewport");

        // Scene context manager class - wrapper that makes scene usable with "with" statement
        class SceneContextWrapper {
        public:
            std::string scene_id;
            ViewportBridge* bridge_ptr;

            SceneContextWrapper(const std::string& id, ViewportBridge* b) : scene_id(id), bridge_ptr(b) {}

            SceneContextWrapper enter() {
                bridge_ptr->enter_scene_context(String(scene_id.c_str()));
                return *this;
            }

            void exit(py::object exc_type, py::object exc_val, py::object exc_tb) {
                bridge_ptr->exit_scene_context();
            }
        };

        py::class_<SceneContextWrapper>(godot_module, "SceneContext")
            .def("__enter__", &SceneContextWrapper::enter)
            .def("__exit__", &SceneContextWrapper::exit)
            .def_readonly("scene_id", &SceneContextWrapper::scene_id);

        // Override create_scene functions to return context wrappers
        godot_module.def("create_scene_3d", [bridge]() {
            String scene_id = bridge->create_scene_3d();
            return SceneContextWrapper(scene_id.utf8().get_data(), bridge);
        }, "Create a new 3D scene (World3D) that can be shared across viewports");

        godot_module.def("create_scene_2d", [bridge]() {
            String scene_id = bridge->create_scene_2d();
            return SceneContextWrapper(scene_id.utf8().get_data(), bridge);
        }, "Create a new 2D scene (World2D) that can be shared across viewports");

        // Primitive drawing functions
        godot_module.def("draw_box", [bridge](py::tuple size, py::tuple position, py::tuple rotation, py::tuple color) {
            Vector3 size_vec(
                size[0].cast<double>(),
                size[1].cast<double>(),
                size[2].cast<double>()
            );
            Vector3 pos_vec(
                position[0].cast<double>(),
                position[1].cast<double>(),
                position[2].cast<double>()
            );
            Vector3 rot_vec(
                rotation[0].cast<double>(),
                rotation[1].cast<double>(),
                rotation[2].cast<double>()
            );
            Color col(
                color[0].cast<float>(),
                color[1].cast<float>(),
                color[2].cast<float>(),
                color.size() > 3 ? color[3].cast<float>() : 1.0f
            );

            bridge->draw_box(size_vec, pos_vec, rot_vec, col);
        }, "Draw a box primitive in the current scene context",
           py::arg("size"),
           py::arg("position") = py::make_tuple(0, 0, 0),
           py::arg("rotation") = py::make_tuple(0, 0, 0),
           py::arg("color") = py::make_tuple(1, 1, 1, 1));

        godot_module.def("draw_sphere", [bridge](double radius, py::tuple position, py::tuple color) {
            Vector3 pos_vec(
                position[0].cast<double>(),
                position[1].cast<double>(),
                position[2].cast<double>()
            );
            Color col(
                color[0].cast<float>(),
                color[1].cast<float>(),
                color[2].cast<float>(),
                color.size() > 3 ? color[3].cast<float>() : 1.0f
            );

            bridge->draw_sphere(radius, pos_vec, col);
        }, "Draw a sphere primitive in the current scene context",
           py::arg("radius"),
           py::arg("position") = py::make_tuple(0, 0, 0),
           py::arg("color") = py::make_tuple(1, 1, 1, 1));

        godot_module.def("draw_cylinder", [bridge](double radius, double height, py::tuple position, py::tuple rotation, py::tuple color) {
            Vector3 pos_vec(
                position[0].cast<double>(),
                position[1].cast<double>(),
                position[2].cast<double>()
            );
            Vector3 rot_vec(
                rotation[0].cast<double>(),
                rotation[1].cast<double>(),
                rotation[2].cast<double>()
            );
            Color col(
                color[0].cast<float>(),
                color[1].cast<float>(),
                color[2].cast<float>(),
                color.size() > 3 ? color[3].cast<float>() : 1.0f
            );

            bridge->draw_cylinder(radius, height, pos_vec, rot_vec, col);
        }, "Draw a cylinder primitive in the current scene context",
           py::arg("radius"),
           py::arg("height"),
           py::arg("position") = py::make_tuple(0, 0, 0),
           py::arg("rotation") = py::make_tuple(0, 0, 0),
           py::arg("color") = py::make_tuple(1, 1, 1, 1));

        godot_module.def("draw_torus", [bridge](double inner_radius, double outer_radius, py::tuple position, py::tuple rotation, py::tuple color) {
            Vector3 pos_vec(
                position[0].cast<double>(),
                position[1].cast<double>(),
                position[2].cast<double>()
            );
            Vector3 rot_vec(
                rotation[0].cast<double>(),
                rotation[1].cast<double>(),
                rotation[2].cast<double>()
            );
            Color col(
                color[0].cast<float>(),
                color[1].cast<float>(),
                color[2].cast<float>(),
                color.size() > 3 ? color[3].cast<float>() : 1.0f
            );

            bridge->draw_torus(inner_radius, outer_radius, pos_vec, rot_vec, col);
        }, "Draw a torus primitive in the current scene context",
           py::arg("inner_radius"),
           py::arg("outer_radius"),
           py::arg("position") = py::make_tuple(0, 0, 0),
           py::arg("rotation") = py::make_tuple(0, 0, 0),
           py::arg("color") = py::make_tuple(1, 1, 1, 1));

        // Legacy API - kept for compatibility
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
