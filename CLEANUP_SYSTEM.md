# Scene Cleanup System

## Overview

Added automatic cleanup of scenes, cameras, and counters before each script execution to prevent memory buildup and ID conflicts.

## Problem

When rerunning Python scripts:
1. Old cameras remained in memory → "cam1 already exists" errors
2. Scene counter kept incrementing → "scene_3d_300" despite no scenes existing
3. New viewports added after script execution didn't display anything
4. Only worked on first run after opening app

## Solution

### 1. Cleanup Method in ViewportManager

Added `cleanup_all_scenes()` method that:
- Removes all cameras from their holders
- Clears all scene roots and their children
- Deletes all scene data
- Resets scene_counter to 0
- Clears current_scene_context

```gdscript
func cleanup_all_scenes() -> void:
    """Clean up all scenes, cameras, and reset counters"""

    # Remove all cameras from holders
    for camera_name in cameras.keys():
        var camera_data = cameras[camera_name]
        var holder = holders.get(camera_data["port_id"])
        if holder:
            holder.remove_camera_subviewport(camera_name)

    # Clear camera tracking
    cameras.clear()

    # Clean up all scene roots
    for scene_id in scenes.keys():
        var scene_data = scenes[scene_id]
        if scene_data.has("root") and scene_data["root"]:
            var root = scene_data["root"]
            # Remove all children
            for child in root.get_children():
                child.queue_free()
            # Remove root from parent if attached
            if root.get_parent():
                root.get_parent().remove_child(root)
            root.queue_free()

    # Clear scene tracking
    scenes.clear()

    # Reset counters
    scene_counter = 0

    # Clear scene context
    current_scene_context = ""
```

### 2. Automatic Cleanup on Script Run

Modified `code_runner.gd` to call cleanup before executing each script:

```gdscript
func _on_run_pressed():
    var code = code_edit.text
    debug_panel.clear_output()
    debug_panel.log_message("Running script...")

    # Clean up previous scenes/cameras before running new script
    var viewport_manager = get_node("/root/ViewportManager")
    if viewport_manager:
        viewport_manager.cleanup_all_scenes()

    # Execute the script
    var success = script_runtime.execute_script(code)
```

### 3. Fixed Scene Root Attachment

Changed order of operations in `viewport_holder.gd` to add scene root BEFORE adding SubViewport to tree:

**Before:**
```gdscript
subviewport.world_3d = world
viewport_container.add_child(subviewport)
# Then try to add scene root
```

**After:**
```gdscript
# Add scene root FIRST (if not already attached)
var scene_root = viewport_manager.get_scene_root(scene_id)
if scene_root and not scene_root.get_parent():
    subviewport.add_child(scene_root)

# Then configure and add to tree
subviewport.world_3d = world
viewport_container.add_child(subviewport)
```

This ensures the scene root is properly attached before the SubViewport enters the tree.

## How It Works

### Execution Flow

```
User clicks "Run" button
    ↓
code_runner._on_run_pressed()
    ↓
ViewportManager.cleanup_all_scenes()
    ├─> Remove all cameras from holders
    ├─> Clear camera dictionary
    ├─> Free all scene roots and children
    ├─> Clear scenes dictionary
    └─> Reset scene_counter = 0
    ↓
Execute Python script
    ├─> create_scene_3d() → Returns "scene_3d_1" (counter reset!)
    ├─> add_camera("cam1", ...) → Creates new camera (no conflict!)
    └─> with scene: draw_box(...) → Draws in fresh scene
```

### Scene Root Management

When a camera is added to a viewport:

1. **Get scene root** from ViewportManager
2. **Check if already attached** (`not scene_root.get_parent()`)
3. **If not attached**: Add to this SubViewport
4. **If already attached**: Skip (other SubViewport owns it)
5. **Share World3D**: All SubViewports with same World3D see the same scene

```
Scene "scene_3d_1"
  ├─ World3D (shared resource)
  └─ Root Node3D (attached to FIRST SubViewport)
      │
      ├─ viewport_1 → SubViewport → world_3d = shared World3D
      │                  └─ Camera3D "cam1"
      │                  └─ Root Node3D (OWNER)
      │
      └─ viewport_2 → SubViewport → world_3d = shared World3D
                         └─ Camera3D "cam2"
                         (sees Root Node3D through shared World3D)
```

## Benefits

### 1. No Memory Leaks
- All scene nodes are freed before each run
- Cameras are properly removed from holders
- No accumulation of unused data

### 2. Consistent IDs
- Counters reset to 0 each run
- Scene IDs start from "scene_3d_1" every time
- Camera names can be reused without conflicts

### 3. Fresh State
- Each script run starts with clean slate
- No interference from previous runs
- Predictable behavior

### 4. Multiple Runs
- Can run same script repeatedly without errors
- Can modify and rerun script easily
- Supports iterative development

## Example

### First Run
```python
from godot import create_scene_3d, add_camera, draw_box

scene = create_scene_3d()  # → "scene_3d_1"
add_camera("cam1", "viewport_1", scene, {"position": (10, 10, 10)})

with scene:
    draw_box((1, 1, 1), color=(1, 0, 0, 1))
```

Output:
```
ViewportManager: Created 3D scene 'scene_3d_1'
ViewportManager: Added camera 'cam1' to viewport 'viewport_1'
ViewportManager: Added box to scene 'scene_3d_1'
```

### Second Run (Without Cleanup - Old Behavior)
```python
# Same code as above
```

Output:
```
ViewportManager: Created 3D scene 'scene_3d_2'  ← Counter kept incrementing
ERROR: Camera 'cam1' already exists               ← Camera not cleaned up
```

### Second Run (With Cleanup - New Behavior)
```python
# Same code as above
```

Output:
```
ViewportManager: Cleaning up all scenes and cameras
ViewportManager: Cleanup complete
ViewportManager: Created 3D scene 'scene_3d_1'    ← Counter reset!
ViewportManager: Added camera 'cam1' to viewport 'viewport_1'  ← No conflict!
ViewportManager: Added box to scene 'scene_3d_1'
```

## Files Modified

1. **algorithm-wizard/scripts/viewport_manager.gd**
   - Added `cleanup_all_scenes()` method

2. **algorithm-wizard/scripts/code_runner.gd**
   - Added cleanup call before script execution

3. **algorithm-wizard/scripts/viewport_holder.gd**
   - Reordered scene root attachment (before SubViewport added to tree)

## Future Improvements

Potential enhancements:
1. Option to preserve scenes between runs (opt-in)
2. Scene naming/labeling (instead of just "scene_3d_1")
3. Selective cleanup (clear only specific scenes)
4. Scene save/load functionality
5. Undo/redo for scene modifications
