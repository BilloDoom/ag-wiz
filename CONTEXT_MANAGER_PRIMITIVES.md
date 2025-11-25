# Context Manager and Primitive Drawing System

## Overview

Added Python context manager support for scenes and primitive drawing functions. This allows you to use Python's `with` statement to draw objects into specific scenes.

## Architecture

### Scene Context Manager

When you create a scene with `create_scene_3d()` or `create_scene_2d()`, it returns a `SceneContext` object that supports Python's context manager protocol (`__enter__` and `__exit__`).

```python
scene = create_scene_3d()  # Returns SceneContext wrapper

with scene:  # Enters scene context
    draw_box((1, 1, 1))  # Draws in the scene
    # __exit__ called automatically when leaving block
```

### How It Works

1. **Scene Root Node**: Each scene has a root `Node3D` or `Node2D` where objects are added
2. **Context Tracking**: `ViewportManager` tracks the current scene context
3. **Primitive Drawing**: Drawing functions check the current context and add objects to that scene's root
4. **Shared Viewing**: All cameras viewing the same scene see the same objects

### Data Flow

```
Python: with scene:
    └─> C++ SceneContext.__enter__()
        └─> ViewportManager.enter_scene_context(scene_id)
            └─> Sets current_scene_context = scene_id

Python: draw_box(...)
    └─> C++ draw_box()
        └─> ViewportManager.draw_box()
            └─> Gets current_scene_root()
            └─> Creates MeshInstance3D + BoxMesh
            └─> Adds to scene root

Python: (exit with block)
    └─> C++ SceneContext.__exit__()
        └─> ViewportManager.exit_scene_context()
            └─> Clears current_scene_context
```

## Primitive Functions

All primitives are created using Godot's built-in mesh types:

- **BoxMesh** → `draw_box()`
- **SphereMesh** → `draw_sphere()`
- **CylinderMesh** → `draw_cylinder()`
- **TorusMesh** → `draw_torus()`

Each primitive creates:
1. `MeshInstance3D` node
2. Mesh geometry (BoxMesh, SphereMesh, etc.)
3. `StandardMaterial3D` with albedo color
4. Adds to current scene root

### GDScript Implementation (viewport_manager.gd)

```gdscript
func draw_box(size: Vector3, position: Vector3, rotation: Vector3, color: Color) -> Node3D:
    var root = get_current_scene_root()  # Gets active context scene root
    if not root:
        push_error("No scene context active")
        return null

    var mesh_instance = MeshInstance3D.new()
    var box_mesh = BoxMesh.new()
    box_mesh.size = size
    mesh_instance.mesh = box_mesh
    mesh_instance.position = position
    mesh_instance.rotation = rotation

    var material = StandardMaterial3D.new()
    material.albedo_color = color
    mesh_instance.set_surface_override_material(0, material)

    root.add_child(mesh_instance)
    return mesh_instance
```

### C++ Python Bindings (viewport_bridge.cpp)

```cpp
// SceneContext wrapper class
class SceneContextWrapper {
public:
    std::string scene_id;
    ViewportBridge* bridge_ptr;

    SceneContextWrapper enter() {
        bridge_ptr->enter_scene_context(String(scene_id.c_str()));
        return *this;
    }

    void exit(py::object exc_type, py::object exc_val, py::object exc_tb) {
        bridge_ptr->exit_scene_context();
    }
};

// Python binding
py::class_<SceneContextWrapper>(godot_module, "SceneContext")
    .def("__enter__", &SceneContextWrapper::enter)
    .def("__exit__", &SceneContextWrapper::exit);

// create_scene_3d returns SceneContext
godot_module.def("create_scene_3d", [bridge]() {
    String scene_id = bridge->create_scene_3d();
    return SceneContextWrapper(scene_id.utf8().get_data(), bridge);
});
```

## Usage Examples

### Basic Example

```python
from godot import create_scene_3d, add_camera, draw_box, draw_sphere

# Create scene and camera
scene = create_scene_3d()
add_camera("cam1", "viewport_1", scene, {
    "position": (10, 10, 10),
    "orbit_controls": True
})

# Draw primitives
with scene:
    draw_box((2, 2, 2), position=(0, 0, 0), color=(1, 0, 0, 1))
    draw_sphere(1.5, position=(5, 0, 0), color=(0, 0, 1, 1))
```

### Multi-Viewport Example

```python
from godot import create_scene_3d, add_camera, draw_box

# Create scene
scene = create_scene_3d()

# Add cameras to different viewports
add_camera("front", "viewport_1", scene, {"position": (10, 0, 0)})
add_camera("top", "viewport_2", scene, {"position": (0, 10, 0)})
add_camera("side", "viewport_3", scene, {"position": (0, 0, 10)})

# Draw once, appears in all viewports
with scene:
    draw_box((2, 2, 2), color=(1, 0, 0, 1))
```

### Algorithm Visualization Example

```python
from godot import create_scene_3d, add_camera, draw_sphere

scene = create_scene_3d()
add_camera("cam", "viewport_1", scene, {
    "position": (20, 20, 20),
    "orbit_controls": True
})

# Visualize sorting algorithm
array = [5, 2, 8, 1, 9]

with scene:
    for i, value in enumerate(array):
        x = i * 2
        y = value
        color = (0.2, 0.5, 1.0, 1.0)
        draw_sphere(0.5, position=(x, y, 0), color=color)
```

## Parameter Reference

### Common Parameters

All primitives support:
- `position`: Tuple `(x, y, z)` - Default `(0, 0, 0)`
- `color`: Tuple `(r, g, b, a)` - Default `(1, 1, 1, 1)` (white, opaque)

### draw_box(size, position=(0,0,0), rotation=(0,0,0), color=(1,1,1,1))

- `size`: Tuple `(width, height, depth)` - **Required**
- `rotation`: Tuple `(x, y, z)` in radians

Example:
```python
draw_box((2, 1, 3), position=(5, 0, 0), rotation=(0, 0.785, 0), color=(1, 0, 0, 1))
```

### draw_sphere(radius, position=(0,0,0), color=(1,1,1,1))

- `radius`: Float - **Required**

Example:
```python
draw_sphere(1.5, position=(0, 5, 0), color=(0, 0, 1, 1))
```

### draw_cylinder(radius, height, position=(0,0,0), rotation=(0,0,0), color=(1,1,1,1))

- `radius`: Float - **Required**
- `height`: Float - **Required**
- `rotation`: Tuple `(x, y, z)` in radians

Example:
```python
draw_cylinder(0.5, 3, position=(-5, 0, 0), color=(0, 1, 0, 1))
```

### draw_torus(inner_radius, outer_radius, position=(0,0,0), rotation=(0,0,0), color=(1,1,1,1))

- `inner_radius`: Float - **Required**
- `outer_radius`: Float - **Required**
- `rotation`: Tuple `(x, y, z)` in radians

Example:
```python
draw_torus(0.5, 1.5, position=(0, 0, 5), color=(1, 1, 0, 1))
```

## Error Handling

If you try to draw without an active scene context:

```python
draw_box((1, 1, 1))  # ERROR: No scene context active
```

Error message:
```
ViewportManager: No scene context active. Use 'with scene:' in Python
```

## Implementation Files

### GDScript Files Modified

1. **algorithm-wizard/scripts/viewport_manager.gd**
   - Added `current_scene_context` tracking
   - Added `enter_scene_context()`, `exit_scene_context()`
   - Added `get_current_scene_root()`
   - Added `draw_box()`, `draw_sphere()`, `draw_cylinder()`, `draw_torus()`
   - Modified `create_scene_3d()`, `create_scene_2d()` to create root nodes

2. **algorithm-wizard/scripts/viewport_holder.gd**
   - Modified `add_camera_subviewport()` to add scene root to SubViewport

### C++ Files Modified

1. **cpp/include/viewport_bridge.hpp**
   - Added context methods: `enter_scene_context()`, `exit_scene_context()`
   - Added primitive methods: `draw_box()`, `draw_sphere()`, `draw_cylinder()`, `draw_torus()`

2. **cpp/src/viewport_bridge.cpp**
   - Implemented C++ context and primitive methods
   - Added `SceneContextWrapper` class for Python context manager
   - Modified `create_scene_3d()`, `create_scene_2d()` to return `SceneContextWrapper`
   - Added Python bindings for all primitives with tuple parameter conversion

## Benefits

1. **Clean Syntax**: Python's `with` statement provides clean scope management
2. **Error Prevention**: Can't accidentally draw to wrong scene
3. **Multi-Scene Support**: Easily switch between different scenes
4. **Shared Viewing**: Multiple viewports can view the same scene with different cameras
5. **Algorithm Visualization**: Perfect for visualizing data structures and algorithms

## Next Steps

Potential future additions:
1. More primitives (plane, cone, prism)
2. Line drawing (`draw_line()`, `draw_polyline()`)
3. Text labels (`draw_label()`)
4. Object removal/updating (`remove_object()`, `update_object()`)
5. Animation support (`animate_object()`)
6. Material/shader customization
