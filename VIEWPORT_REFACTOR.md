# Viewport System Refactor - Shared World Architecture

## Overview

The viewport system has been completely refactored to support a shared World3D/World2D architecture, where multiple viewports can view the same 3D or 2D scene from different cameras.

## Key Changes

### Architecture

**Old System:**
- Each viewport had its own scene (template-based)
- One camera per viewport
- Couldn't share scenes between viewports

**New System:**
- Scenes (World3D/World2D) are created independently
- Multiple cameras can view the same scene
- Each camera is assigned to a specific viewport
- All viewports viewing the same scene share the World3D/World2D instance

### Structure

```
Scene (World3D)
  └─ Contains all 3D objects
      │
      ├─ viewport_1 (holder)
      │   └─ SubViewport (shares World3D)
      │       └─ Camera3D ("cam1")
      │
      └─ viewport_2 (holder)
          └─ SubViewport (shares World3D)
              └─ Camera3D ("cam2")
```

Both viewports render the same scene but from different camera angles.

## New Python API

### 1. Create a Scene

```python
from godot import create_scene_3d, create_scene_2d

# Create a 3D scene
scene_3d = create_scene_3d()  # Returns "scene_3d_1"

# Create a 2D scene
scene_2d = create_scene_2d()  # Returns "scene_2d_1"
```

### 2. Add Cameras to Viewports

```python
from godot import add_camera

# Add camera to viewport_1
add_camera("cam1", "viewport_1", scene_3d, {
    "position": (10, 10, 10),
    "rotation": (0, 45, 0),
    "orbit_controls": True
})

# Add camera to viewport_2 viewing the same scene
add_camera("cam2", "viewport_2", scene_3d, {
    "position": (-5, 5, 5),
    "orbit_controls": True
})
```

**Parameters:**
- `name` (String): Unique camera name
- `port` (String): Viewport ID to add camera to
- `scene` (String): Scene ID to view
- `settings` (Dict): Camera configuration

**Settings for 3D:**
- `position`: Tuple (x, y, z)
- `rotation`: Tuple (x, y, z) in radians
- `orbit_controls`: Bool - Enable orbit controls
- `msaa`: Int - MSAA level (0, 2, 4, 8)
- `taa`: Bool - Enable TAA

**Settings for 2D:**
- `position`: Tuple (x, y)
- `zoom`: Float - Zoom level
- `pan_controls`: Bool - Enable pan controls

### 3. Remove Cameras

```python
from godot import remove_camera

# Remove a specific camera
remove_camera("cam1")
```

## Example Workflows

### Single Viewport Setup

```python
from godot import create_scene_3d, add_camera

# Create scene
scene = create_scene_3d()

# Add camera to viewport_1
add_camera("main_cam", "viewport_1", scene, {
    "position": (10, 10, 10),
    "orbit_controls": True
})

# Now add 3D objects to the scene...
```

### Multi-Viewport Setup (Same Scene)

```python
from godot import create_scene_3d, add_camera

# Create one shared scene
scene = create_scene_3d()

# Add multiple cameras viewing the same scene
add_camera("front", "viewport_1", scene, {"position": (0, 0, 10)})
add_camera("top", "viewport_2", scene, {"position": (0, 10, 0), "rotation": (90, 0, 0)})
add_camera("side", "viewport_3", scene, {"position": (10, 0, 0), "rotation": (0, 90, 0)})

# All three viewports show the same scene from different angles
```

### Multi-Scene Setup

```python
from godot import create_scene_3d, create_scene_2d, add_camera

# Create different scenes
scene_3d = create_scene_3d()
scene_2d = create_scene_2d()

# Viewport 1 shows 3D scene
add_camera("cam_3d", "viewport_1", scene_3d, {"position": (10, 10, 10)})

# Viewport 2 shows 2D scene
add_camera("cam_2d", "viewport_2", scene_2d, {"zoom": 1.5})
```

## Implementation Details

### ViewportManager (viewport_manager.gd)

**New Data Structures:**
```gdscript
var scenes: Dictionary = {}  # scene_id -> {type: "3d"/"2d", world: World3D/World2D}
var cameras: Dictionary = {}  # camera_name -> {port_id, scene_id, subviewport, camera_node}
```

**New Methods:**
- `create_scene_3d() -> String`: Creates World3D, returns scene_id
- `create_scene_2d() -> String`: Creates World2D, returns scene_id
- `add_camera_to_viewport(name, port, scene, settings) -> bool`: Adds camera to viewport
- `remove_camera(name) -> bool`: Removes camera
- `get_camera_node(name) -> Node`: Gets camera node by name

### ViewportHolder (viewport_holder.gd)

**New Data Structures:**
```gdscript
var camera_subviewports: Dictionary = {}  # camera_name -> {subviewport, camera, controller}
```

**Key Changes:**
- No more template scene loading
- Dynamically creates SubViewports
- Each SubViewport shares the World3D/World2D
- Supports multiple cameras per holder (one SubViewport per camera)

**New Methods:**
- `add_camera_subviewport(name, world, type, settings) -> Dictionary`: Creates SubViewport + Camera
- `remove_camera_subviewport(name)`: Removes camera's SubViewport
- `get_camera_node(name) -> Node`: Gets camera node

### ViewportBridge (C++ viewport_bridge.cpp/hpp)

**New C++ Methods:**
- `String create_scene_3d()`
- `String create_scene_2d()`
- `bool add_camera_to_viewport(name, port, scene, settings)`
- `bool remove_camera(name)`
- `Node* get_camera_node(name)`

**New Python Bindings:**
- `godot.create_scene_3d()`
- `godot.create_scene_2d()`
- `godot.add_camera(name, port, scene, **settings)`
- `godot.remove_camera(name)`

## Benefits

1. **Memory Efficient**: Multiple viewports share the same World3D/World2D instance
2. **Synchronized Views**: All cameras see the same scene state in real-time
3. **Flexible**: Easy to add/remove cameras dynamically
4. **Named Cameras**: Reference cameras by name instead of viewport
5. **Multi-Viewport Algorithms**: Perfect for visualizing algorithms from multiple angles

## Migration from Old API

**Old Code:**
```python
from godot import configure_viewport

configure_viewport("viewport_1", "3d", {
    "camera_position": (10, 10, 10),
    "orbit_controls": True
})
```

**New Code:**
```python
from godot import create_scene_3d, add_camera

scene = create_scene_3d()
add_camera("cam1", "viewport_1", scene, {
    "position": (10, 10, 10),
    "orbit_controls": True
})
```

## Files Modified

1. **algorithm-wizard/scripts/viewport_manager.gd**
   - Added scene and camera tracking
   - Added `create_scene_3d()`, `create_scene_2d()`, `add_camera_to_viewport()`
   - Kept legacy methods for backwards compatibility

2. **algorithm-wizard/scripts/viewport_holder.gd**
   - Removed template loading
   - Added dynamic SubViewport creation
   - Added `add_camera_subviewport()`, `remove_camera_subviewport()`

3. **cpp/include/viewport_bridge.hpp**
   - Added new API method declarations

4. **cpp/src/viewport_bridge.cpp**
   - Implemented new C++ methods
   - Added Python bindings for new API
   - Kept legacy bindings

5. **TEST_COMMANDS.md**
   - Added new API examples
   - Kept legacy examples

## Backwards Compatibility

The old API (`init_3d_scene`, `configure_viewport`, etc.) is still available but marked as legacy. It's recommended to migrate to the new API for new code.

## Next Steps

1. Test new API with multiple viewports
2. Add object management API (add meshes, lights, etc. to scenes)
3. Add camera animation/interpolation support
4. Add scene cloning for comparing algorithm states
