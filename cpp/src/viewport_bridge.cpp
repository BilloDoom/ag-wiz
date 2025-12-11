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

// 3D Mesh building implementations

Dictionary ViewportBridge::create_mesh_builder_3d(const Vector3& position, const Vector3& rotation) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return Dictionary();
    }

    if (manager->has_method("create_mesh_builder_3d")) {
        Variant result = manager->call("create_mesh_builder_3d", position, rotation);
        return result.operator Dictionary();
    }

    return Dictionary();
}

Node* ViewportBridge::build_mesh_3d(const Array& vertices, const Array& indices, const Array& normals, const Array& colors, const Array& uvs, const Vector3& position, const Vector3& rotation, const Color& color) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("build_mesh_3d")) {
        Variant result = manager->call("build_mesh_3d", vertices, indices, normals, colors, uvs, position, rotation, color);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

// 2D Primitive drawing implementations

Node* ViewportBridge::draw_rect_2d(const Vector2& size, const Vector2& position, float rotation, const Color& color, bool filled) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("draw_rect_2d")) {
        Variant result = manager->call("draw_rect_2d", size, position, rotation, color, filled);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

Node* ViewportBridge::draw_circle_2d(float radius, const Vector2& position, const Color& color, bool filled, int segments) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("draw_circle_2d")) {
        Variant result = manager->call("draw_circle_2d", radius, position, color, filled, segments);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

Node* ViewportBridge::draw_line_2d(const Vector2& from_pos, const Vector2& to_pos, const Color& color, float width) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("draw_line_2d")) {
        Variant result = manager->call("draw_line_2d", from_pos, to_pos, color, width);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

Node* ViewportBridge::draw_polygon_2d(const Array& points, const Vector2& position, float rotation, const Color& color, bool filled) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("draw_polygon_2d")) {
        Variant result = manager->call("draw_polygon_2d", points, position, rotation, color, filled);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

// 2D Mesh building implementation

Node* ViewportBridge::build_mesh_2d(const Array& vertices, const Array& colors, const Array& uvs, const Vector2& position, float rotation, const Color& color) {
    Node* manager = get_viewport_manager();
    if (!manager) {
        return nullptr;
    }

    if (manager->has_method("build_mesh_2d")) {
        Variant result = manager->call("build_mesh_2d", vertices, colors, uvs, position, rotation, color);
        return Object::cast_to<Node>(result.operator Object*());
    }

    return nullptr;
}

// Animation system implementations

void ViewportBridge::queue_animation(Node* object, const String& property, const Variant& end_value, float duration, float delay, const String& easing) {
    if (!is_inside_tree()) {
        UtilityFunctions::printerr("ViewportBridge: Not inside tree");
        return;
    }

    Node* anim_manager = get_node_or_null("/root/AnimationManager");
    if (!anim_manager) {
        UtilityFunctions::printerr("ViewportBridge: AnimationManager not found");
        return;
    }

    if (anim_manager->has_method("queue_animation")) {
        anim_manager->call("queue_animation", object, property, end_value, duration, delay, easing);
    }
}

void ViewportBridge::play_animations() {
    if (!is_inside_tree()) {
        UtilityFunctions::printerr("ViewportBridge: Not inside tree");
        return;
    }

    Node* anim_manager = get_node_or_null("/root/AnimationManager");
    if (!anim_manager) {
        UtilityFunctions::printerr("ViewportBridge: AnimationManager not found");
        return;
    }

    if (anim_manager->has_method("play_animations")) {
        anim_manager->call("play_animations");
    }
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

        // Node wrapper class for storing Godot Node pointers in Python
        class NodeWrapper {
        public:
            Node* node_ptr;
            NodeWrapper(Node* ptr) : node_ptr(ptr) {}
        };

        py::class_<NodeWrapper>(godot_module, "NodeWrapper")
            .def_readonly("_node_ptr", &NodeWrapper::node_ptr);

        // New API - Scene and Camera management
        // Note: create_scene_3d and create_scene_2d are defined later with context manager support

        godot_module.def("camera", [bridge](const std::string& camera_name, const std::string& port_id, py::object scene_obj, py::dict settings) {
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
        godot_module.def("scene_3d", [bridge]() {
            String scene_id = bridge->create_scene_3d();
            return SceneContextWrapper(scene_id.utf8().get_data(), bridge);
        }, "Create a new 3D scene (World3D) that can be shared across viewports");

        godot_module.def("scene_2d", [bridge]() {
            String scene_id = bridge->create_scene_2d();
            return SceneContextWrapper(scene_id.utf8().get_data(), bridge);
        }, "Create a new 2D scene (World2D) that can be shared across viewports");

        // Primitive drawing functions
        godot_module.def("box", [bridge](py::tuple size, py::tuple position, py::tuple rotation, py::tuple color) {
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

            Node* node = bridge->draw_box(size_vec, pos_vec, rot_vec, col);
            return NodeWrapper(node);
        }, "Draw a box primitive in the current scene context",
           py::arg("size"),
           py::arg("position") = py::make_tuple(0, 0, 0),
           py::arg("rotation") = py::make_tuple(0, 0, 0),
           py::arg("color") = py::make_tuple(1, 1, 1, 1));

        godot_module.def("sphere", [bridge](double radius, py::tuple position, py::tuple color) {
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

            Node* node = bridge->draw_sphere(radius, pos_vec, col);
            return NodeWrapper(node);
        }, "Draw a sphere primitive in the current scene context",
           py::arg("radius"),
           py::arg("position") = py::make_tuple(0, 0, 0),
           py::arg("color") = py::make_tuple(1, 1, 1, 1));

        godot_module.def("cylinder", [bridge](double radius, double height, py::tuple position, py::tuple rotation, py::tuple color) {
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

            Node* node = bridge->draw_cylinder(radius, height, pos_vec, rot_vec, col);
            return NodeWrapper(node);
        }, "Draw a cylinder primitive in the current scene context",
           py::arg("radius"),
           py::arg("height"),
           py::arg("position") = py::make_tuple(0, 0, 0),
           py::arg("rotation") = py::make_tuple(0, 0, 0),
           py::arg("color") = py::make_tuple(1, 1, 1, 1));

        godot_module.def("torus", [bridge](double inner_radius, double outer_radius, py::tuple position, py::tuple rotation, py::tuple color) {
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

            Node* node = bridge->draw_torus(inner_radius, outer_radius, pos_vec, rot_vec, col);
            return NodeWrapper(node);
        }, "Draw a torus primitive in the current scene context",
           py::arg("inner_radius"),
           py::arg("outer_radius"),
           py::arg("position") = py::make_tuple(0, 0, 0),
           py::arg("rotation") = py::make_tuple(0, 0, 0),
           py::arg("color") = py::make_tuple(1, 1, 1, 1));

        // 3D Mesh building functions
        godot_module.def("mesh_builder_3d", [bridge](py::tuple position, py::tuple rotation) {
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

            Dictionary builder_dict = bridge->create_mesh_builder_3d(pos_vec, rot_vec);

            // Convert Dictionary to Python dict
            py::dict result;
            Array keys = builder_dict.keys();
            for (int i = 0; i < keys.size(); i++) {
                String key = keys[i];
                Variant value = builder_dict[key];
                // Store the Callable references - Python will need to call them via helper
                result[py::str(key.utf8().get_data())] = py::cast(value);
            }

            return result;
        }, "Create a 3D mesh builder using ImmediateMesh",
           py::arg("position") = py::make_tuple(0, 0, 0),
           py::arg("rotation") = py::make_tuple(0, 0, 0));

        godot_module.def("build_mesh_3d", [bridge](py::list vertices, py::list indices, py::list normals, py::list colors, py::list uvs, py::tuple position, py::tuple rotation, py::tuple color) {
            Array vert_array;
            for (auto item : vertices) {
                py::tuple v = item.cast<py::tuple>();
                vert_array.push_back(Vector3(v[0].cast<double>(), v[1].cast<double>(), v[2].cast<double>()));
            }

            Array idx_array;
            for (auto item : indices) {
                idx_array.push_back(item.cast<int>());
            }

            Array norm_array;
            for (auto item : normals) {
                py::tuple n = item.cast<py::tuple>();
                norm_array.push_back(Vector3(n[0].cast<double>(), n[1].cast<double>(), n[2].cast<double>()));
            }

            Array col_array;
            for (auto item : colors) {
                py::tuple c = item.cast<py::tuple>();
                col_array.push_back(Color(c[0].cast<float>(), c[1].cast<float>(), c[2].cast<float>(), c.size() > 3 ? c[3].cast<float>() : 1.0f));
            }

            Array uv_array;
            for (auto item : uvs) {
                py::tuple u = item.cast<py::tuple>();
                uv_array.push_back(Vector2(u[0].cast<double>(), u[1].cast<double>()));
            }

            Vector3 pos_vec(position[0].cast<double>(), position[1].cast<double>(), position[2].cast<double>());
            Vector3 rot_vec(rotation[0].cast<double>(), rotation[1].cast<double>(), rotation[2].cast<double>());
            Color col(color[0].cast<float>(), color[1].cast<float>(), color[2].cast<float>(), color.size() > 3 ? color[3].cast<float>() : 1.0f);

            bridge->build_mesh_3d(vert_array, idx_array, norm_array, col_array, uv_array, pos_vec, rot_vec, col);
        }, "Build a custom 3D mesh from vertices",
           py::arg("vertices"),
           py::arg("indices") = py::list(),
           py::arg("normals") = py::list(),
           py::arg("colors") = py::list(),
           py::arg("uvs") = py::list(),
           py::arg("position") = py::make_tuple(0, 0, 0),
           py::arg("rotation") = py::make_tuple(0, 0, 0),
           py::arg("color") = py::make_tuple(1, 1, 1, 1));

        // 2D Drawing functions
        godot_module.def("rect", [bridge](py::tuple size, py::tuple position, double rotation, py::tuple color, bool filled) {
            Vector2 size_vec(size[0].cast<double>(), size[1].cast<double>());
            Vector2 pos_vec(position[0].cast<double>(), position[1].cast<double>());
            Color col(color[0].cast<float>(), color[1].cast<float>(), color[2].cast<float>(), color.size() > 3 ? color[3].cast<float>() : 1.0f);

            bridge->draw_rect_2d(size_vec, pos_vec, rotation, col, filled);
        }, "Draw a rectangle in 2D",
           py::arg("size"),
           py::arg("position") = py::make_tuple(0, 0),
           py::arg("rotation") = 0.0,
           py::arg("color") = py::make_tuple(1, 1, 1, 1),
           py::arg("filled") = true);

        godot_module.def("circle", [bridge](double radius, py::tuple position, py::tuple color, bool filled, int segments) {
            Vector2 pos_vec(position[0].cast<double>(), position[1].cast<double>());
            Color col(color[0].cast<float>(), color[1].cast<float>(), color[2].cast<float>(), color.size() > 3 ? color[3].cast<float>() : 1.0f);

            bridge->draw_circle_2d(radius, pos_vec, col, filled, segments);
        }, "Draw a circle in 2D",
           py::arg("radius"),
           py::arg("position") = py::make_tuple(0, 0),
           py::arg("color") = py::make_tuple(1, 1, 1, 1),
           py::arg("filled") = true,
           py::arg("segments") = 32);

        godot_module.def("line", [bridge](py::tuple from_pos, py::tuple to_pos, py::tuple color, double width) {
            Vector2 from_vec(from_pos[0].cast<double>(), from_pos[1].cast<double>());
            Vector2 to_vec(to_pos[0].cast<double>(), to_pos[1].cast<double>());
            Color col(color[0].cast<float>(), color[1].cast<float>(), color[2].cast<float>(), color.size() > 3 ? color[3].cast<float>() : 1.0f);

            bridge->draw_line_2d(from_vec, to_vec, col, width);
        }, "Draw a line in 2D",
           py::arg("from_pos"),
           py::arg("to_pos"),
           py::arg("color") = py::make_tuple(1, 1, 1, 1),
           py::arg("width") = 1.0);

        godot_module.def("polygon", [bridge](py::list points, py::tuple position, double rotation, py::tuple color, bool filled) {
            Array point_array;
            for (auto item : points) {
                py::tuple p = item.cast<py::tuple>();
                point_array.push_back(Vector2(p[0].cast<double>(), p[1].cast<double>()));
            }

            Vector2 pos_vec(position[0].cast<double>(), position[1].cast<double>());
            Color col(color[0].cast<float>(), color[1].cast<float>(), color[2].cast<float>(), color.size() > 3 ? color[3].cast<float>() : 1.0f);

            bridge->draw_polygon_2d(point_array, pos_vec, rotation, col, filled);
        }, "Draw a polygon in 2D",
           py::arg("points"),
           py::arg("position") = py::make_tuple(0, 0),
           py::arg("rotation") = 0.0,
           py::arg("color") = py::make_tuple(1, 1, 1, 1),
           py::arg("filled") = true);

        godot_module.def("build_mesh_2d", [bridge](py::list vertices, py::list colors, py::list uvs, py::tuple position, double rotation, py::tuple color) {
            Array vert_array;
            for (auto item : vertices) {
                py::tuple v = item.cast<py::tuple>();
                vert_array.push_back(Vector2(v[0].cast<double>(), v[1].cast<double>()));
            }

            Array col_array;
            for (auto item : colors) {
                py::tuple c = item.cast<py::tuple>();
                col_array.push_back(Color(c[0].cast<float>(), c[1].cast<float>(), c[2].cast<float>(), c.size() > 3 ? c[3].cast<float>() : 1.0f));
            }

            Array uv_array;
            for (auto item : uvs) {
                py::tuple u = item.cast<py::tuple>();
                uv_array.push_back(Vector2(u[0].cast<double>(), u[1].cast<double>()));
            }

            Vector2 pos_vec(position[0].cast<double>(), position[1].cast<double>());
            Color col(color[0].cast<float>(), color[1].cast<float>(), color[2].cast<float>(), color.size() > 3 ? color[3].cast<float>() : 1.0f);

            bridge->build_mesh_2d(vert_array, col_array, uv_array, pos_vec, rotation, col);
        }, "Build a custom 2D mesh",
           py::arg("vertices"),
           py::arg("colors") = py::list(),
           py::arg("uvs") = py::list(),
           py::arg("position") = py::make_tuple(0, 0),
           py::arg("rotation") = 0.0,
           py::arg("color") = py::make_tuple(1, 1, 1, 1));

        // Animation system
        godot_module.def("animate", [bridge](py::object obj, const std::string& property, py::object end_value, double duration, double delay, const std::string& easing) {
            // Extract Node* from NodeWrapper
            Node* node_ptr = nullptr;

            try {
                // Try to extract NodeWrapper
                NodeWrapper wrapper = py::cast<NodeWrapper>(obj);
                node_ptr = wrapper.node_ptr;
            } catch (...) {
                UtilityFunctions::printerr("ViewportBridge: Cannot extract Node from Python object for animation. Did you pass a drawn object?");
                return;
            }

            if (!node_ptr) {
                UtilityFunctions::printerr("ViewportBridge: Null object passed to animate()");
                return;
            }

            // Convert end_value to Variant
            Variant end_variant;
            if (py::isinstance<py::tuple>(end_value)) {
                py::tuple tuple = end_value.cast<py::tuple>();
                if (tuple.size() == 3) {
                    // Vector3
                    end_variant = Vector3(tuple[0].cast<double>(), tuple[1].cast<double>(), tuple[2].cast<double>());
                } else if (tuple.size() == 2) {
                    // Vector2
                    end_variant = Vector2(tuple[0].cast<double>(), tuple[1].cast<double>());
                }
            } else if (py::isinstance<py::float_>(end_value) || py::isinstance<py::int_>(end_value)) {
                end_variant = end_value.cast<double>();
            }

            bridge->queue_animation(node_ptr, String(property.c_str()), end_variant, duration, delay, String(easing.c_str()));
        }, "Queue an animation for an object",
           py::arg("object"),
           py::arg("property"),
           py::arg("end_value"),
           py::arg("duration") = 1.0,
           py::arg("delay") = 0.0,
           py::arg("easing") = "linear");

        godot_module.def("play", [bridge]() {
            bridge->play_animations();
        }, "Execute all queued animations");

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
