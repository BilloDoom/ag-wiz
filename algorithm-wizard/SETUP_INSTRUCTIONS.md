# Algorithm Wizard - Viewport System Setup Instructions

## 1. Configure ViewportManager as Singleton

### In Godot Editor:
1. Go to **Project → Project Settings → Autoload**
2. Click the folder icon next to "Path"
3. Navigate to: `res://scripts/viewport_manager.gd`
4. Set Node Name: `ViewportManager`
5. Click **Add**

This makes ViewportManager available globally as `/root/ViewportManager`

---

## 2. Update Main Window Scene

Open `scenes/main_window.tscn` in Godot Editor:

### Add Viewport Container
1. Select the root `MainWindow` node
2. Add a new child node: `PanelContainer`
3. Name it: `ViewportContainer`
4. Configure layout:
   - Anchors Preset: **Full Rect** (fills entire window)
   - Or position it where you want embedded viewports to appear
5. In the _ready() of your main script or ViewportManager, call:
   ```gdscript
   ViewportManager.set_embedded_container($ViewportContainer)
   ```

### Alternative: Set Container in Script
Add this to a main window script's `_ready()`:
```gdscript
func _ready():
    # Find or create viewport container
    var viewport_container = $ViewportContainer
    ViewportManager.set_embedded_container(viewport_container)
```

---

## 3. Update Viewport Templates (IMPORTANT!)

Follow instructions in `VIEWPORT_SETUP_INSTRUCTIONS.md`:
- Add Camera scripts to viewport_3d.tscn
- Remove demo MeshInstance3D
- Add RenderRoot nodes
- Create viewport_2d.tscn

---

## 4. Rebuild C++ Extension

The ViewportBridge class has been added to expose Python API.

### Windows:
```bash
cmake --build build --config Debug
cmake --build build --config Release
```

### Verify DLL is updated:
- Check `bin/Debug/wiz_extension.dll` timestamp
- python314.dll should also be present

---

## 5. Test the System

### Test in GDScript (optional):
```gdscript
func _ready():
    # Create a 3D viewport
    ViewportManager.create_viewport("main", "3d", {
        "floating": false,
        "msaa": 4,
        "orbit_controls": true
    })

    # Create a 2D viewport
    ViewportManager.create_viewport("graph", "2d", {
        "floating": false
    })

    # Get render root to add objects
    var render_root = ViewportManager.get_render_root("main")
    if render_root:
        var cube = MeshInstance3D.new()
        cube.mesh = BoxMesh.new()
        render_root.add_child(cube)
```

### Test in Python:
Run this code in the CodeEdit panel:
```python
from godot import init_3d_scene, init_2d_scene, toggle_floating, close_viewport

# Create 3D viewport
init_3d_scene("main", {
    "floating": False,
    "camera_position": (10, 10, 10),
    "camera_target": (0, 0, 0),
    "msaa": 4,
    "orbit_controls": True
})

# Create another viewport
init_3d_scene("detail", {
    "floating": True  # Opens in floating window
})

# Toggle between embedded/floating
toggle_floating("main")

# Close viewport
close_viewport("detail")
```

---

## 6. Project Structure Summary

After setup, your project should look like:

```
algorithm-wizard/
├── scripts/
│   ├── viewport_holder.gd ✓
│   ├── viewport_manager.gd ✓ (Autoload singleton)
│   ├── camera_controller_3d.gd ✓
│   ├── camera_controller_2d.gd ✓
│   ├── camera_3d_setup.gd ✓
│   ├── camera_2d_setup.gd ✓
│   ├── code_runner.gd ✓ (updated)
│   └── debug_panel.gd ✓
│
├── viewports/
│   ├── 3d_viewport.tscn (update with camera script + RenderRoot)
│   └── 2d_viewport.tscn (create new)
│
├── scenes/
│   └── main_window.tscn (add ViewportContainer)
│
└── bin/
    ├── Debug/wiz_extension.dll ✓
    └── Release/wiz_extension.dll ✓
```

---

## 7. Troubleshooting

### "ViewportManager not found" error
- Check Autoload is configured correctly
- Verify Node Name is exactly `ViewportManager`
- Restart Godot Editor

### "create_viewport method not found"
- Verify `viewport_manager.gd` was saved
- Check the script has no syntax errors
- Reload the project

### Python viewport functions not available
- Verify ViewportBridge is registered in `register_types.cpp`
- Rebuild C++ extension
- Check `setup_python_bindings()` is called in code_runner.gd

### Viewport appears black/empty
- Check viewport template structure (RenderRoot exists)
- Verify Camera and Light nodes are present
- Enable MSAA in viewport settings

---

## Next Steps

Once setup is complete, you can:
1. Create viewports from Python code
2. Add 3D/2D objects to render roots
3. Implement algorithm visualizations
4. Use camera controls to navigate scenes
5. Toggle viewports between embedded grid and floating windows

For examples, see `info.md` Python API section.
