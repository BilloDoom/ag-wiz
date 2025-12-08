#ifndef VIEWPORT_BRIDGE_HPP
#define VIEWPORT_BRIDGE_HPP

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <pybind11/embed.h>
#include <pybind11/stl.h>

namespace py = pybind11;

namespace godot {

class ViewportBridge : public Node {
    GDCLASS(ViewportBridge, Node)

private:
    NodePath viewport_manager_path;
    Node* get_viewport_manager();

protected:
    static void _bind_methods();

public:
    ViewportBridge();
    ~ViewportBridge();

    // Set the path to ViewportManager singleton (usually /root/ViewportManager)
    void set_viewport_manager_path(const NodePath& path);

    // Scene management (new API)
    String create_scene_3d();
    String create_scene_2d();
    bool add_camera_to_viewport(const String& camera_name, const String& port_id, const String& scene_id, const Dictionary& settings);
    bool remove_camera(const String& camera_name);
    Node* get_camera_node(const String& camera_name);

    // Scene context (for Python "with" statement)
    bool enter_scene_context(const String& scene_id);
    void exit_scene_context();

    // 3D Primitive drawing
    Node* draw_box(const Vector3& size, const Vector3& position, const Vector3& rotation, const Color& color);
    Node* draw_sphere(float radius, const Vector3& position, const Color& color);
    Node* draw_cylinder(float radius, float height, const Vector3& position, const Vector3& rotation, const Color& color);
    Node* draw_torus(float inner_radius, float outer_radius, const Vector3& position, const Vector3& rotation, const Color& color);

    // 3D Mesh building
    Dictionary create_mesh_builder_3d(const Vector3& position, const Vector3& rotation);
    Node* build_mesh_3d(const Array& vertices, const Array& indices, const Array& normals, const Array& colors, const Array& uvs, const Vector3& position, const Vector3& rotation, const Color& color);

    // 2D Primitive drawing
    Node* draw_rect_2d(const Vector2& size, const Vector2& position, float rotation, const Color& color, bool filled);
    Node* draw_circle_2d(float radius, const Vector2& position, const Color& color, bool filled, int segments);
    Node* draw_line_2d(const Vector2& from_pos, const Vector2& to_pos, const Color& color, float width);
    Node* draw_polygon_2d(const Array& points, const Vector2& position, float rotation, const Color& color, bool filled);

    // 2D Mesh building
    Node* build_mesh_2d(const Array& vertices, const Array& colors, const Array& uvs, const Vector2& position, float rotation, const Color& color);

    // Viewport management (legacy - kept for compatibility)
    bool init_3d_scene(const String& id, const Dictionary& settings);
    bool init_2d_scene(const String& id, const Dictionary& settings);
    bool configure_viewport(const String& id, const String& viewport_type, const Dictionary& settings);
    bool decouple_viewport(const String& id);
    void toggle_floating(const String& id);
    void close_viewport(const String& id);
    Node* get_render_root(const String& id);

    // Python binding setup
    void setup_python_bindings();
};

} // namespace godot

#endif // VIEWPORT_BRIDGE_HPP
