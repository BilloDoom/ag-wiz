# Test Commands

## New API (Shared World Architecture with Context Manager)

### Create a 3D Scene with Primitives

```python
from godot import create_scene_3d, add_camera, draw_box, draw_sphere, draw_cylinder, draw_torus

# Create a shared 3D scene (returns context manager)
scene = create_scene_3d()

# Add camera to viewport_1
add_camera("cam1", "viewport_1", scene, {
    "position": (10, 10, 10),
    "orbit_controls": True
})

# Use context manager to draw primitives in the scene
with scene:
    # Draw a red box
    draw_box((2, 2, 2), position=(0, 0, 0), color=(1, 0, 0, 1))

    # Draw a blue sphere
    draw_sphere(1.5, position=(5, 0, 0), color=(0, 0, 1, 1))

    # Draw a green cylinder
    draw_cylinder(0.5, 3, position=(-5, 0, 0), color=(0, 1, 0, 1))

    # Draw a yellow torus
    draw_torus(0.5, 1.5, position=(0, 0, 5), color=(1, 1, 0, 1))
```

### Multi-Viewport with Shared Scene

```python
from godot import create_scene_3d, add_camera, draw_box, draw_sphere

# Create a shared 3D scene
scene = create_scene_3d()

# Add multiple cameras viewing the same scene
add_camera("front", "viewport_1", scene, {
    "position": (10, 0, 0),
    "orbit_controls": True
})
add_camera("top", "viewport_2", scene, {
    "position": (0, 10, 0),
    "rotation": (1.57, 0, 0),  # 90 degrees in radians
    "orbit_controls": True
})

# Draw objects - they appear in ALL viewports
with scene:
    draw_box((2, 2, 2), color=(1, 0, 0, 1))
    draw_sphere(1.5, position=(3, 0, 0), color=(0, 1, 0, 1))
```

### Simple Single Viewport with Primitives

```python
from godot import create_scene_3d, add_camera, draw_box, draw_sphere

# Create scene and add one camera
scene = create_scene_3d()
add_camera("main_cam", "viewport_1", scene, {
    "position": (10, 10, 10),
    "orbit_controls": True
})

# Draw primitives using context manager
with scene:
    draw_box((1, 1, 1), position=(0, 0, 0), color=(1, 0, 0, 1))
    draw_sphere(0.5, position=(2, 0, 0), color=(0, 1, 0, 1))
```

### Primitive Reference

All primitives support these parameters:
- `position`: Tuple (x, y, z) - default (0, 0, 0)
- `color`: Tuple (r, g, b, a) - default (1, 1, 1, 1) white

**draw_box(size, position, rotation, color)**
- `size`: Tuple (width, height, depth)
- `rotation`: Tuple (x, y, z) in radians

**draw_sphere(radius, position, color)**
- `radius`: Float

**draw_cylinder(radius, height, position, rotation, color)**
- `radius`: Float
- `height`: Float
- `rotation`: Tuple (x, y, z) in radians

**draw_torus(inner_radius, outer_radius, position, rotation, color)**
- `inner_radius`: Float
- `outer_radius`: Float
- `rotation`: Tuple (x, y, z) in radians

### Remove Camera

```python
from godot import remove_camera

# Remove a specific camera
remove_camera("cam1")
```

---

## Legacy API (Old System - Deprecated)

### Create 3D Viewport

```python
from godot import configure_viewport

configure_viewport("viewport_1", "3d", {
    "camera_position": (10, 10, 10),
    "orbit_controls": True
})
```

### Create 2D Viewport

```python
from godot import configure_viewport

configure_viewport("viewport_1", "2d", {
    "zoom": 1.5
})
```

### Switch 3D to 2D

```python
from godot import configure_viewport

# Switch existing viewport to 2D
configure_viewport("viewport_1", "2d", {})
```

### Decouple Viewport

```python
from godot import decouple_viewport

# Remove scene but keep holder
decouple_viewport("viewport_1")
```
