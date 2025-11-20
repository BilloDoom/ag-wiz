# Viewport System Workflow

## Overview

The viewport system now supports a two-step process:
1. **Button creates empty viewport holder** (no 3D/2D assigned)
2. **Python configures the holder** as 3D or 2D

## Architecture

### Components

**MainWindow** (`main_window.gd`)
- Has "Add Viewport" button
- Calls `ViewportManager.create_empty_viewport()`
- Auto-generates unique IDs: "viewport_1", "viewport_2", etc.

**ViewportManager** (Singleton)
- Manages viewport holders in a 3x3 grid
- `create_empty_viewport(id)` - Creates unconfigured holder
- `configure_viewport(id, type, settings)` - Configures as 3D/2D
- `close_viewport(id)` - Removes holder

**ViewportHolder** (`viewport_holder.tscn`)
- Scene with title bar, float/close buttons
- Contains SubViewportContainer for 3D/2D viewport
- Handles its own close button

**ViewportBridge** (C++ Extension)
- Exposes Python API
- Bridges Python calls to ViewportManager

## Workflow

### Step 1: User Clicks "Add Viewport"

```
User clicks button
	↓
main_window.gd: _on_add_viewport_pressed()
	↓
ViewportManager.create_empty_viewport("viewport_1")
	↓
Empty holder added to grid
	↓
Holder shows in grid with title "viewport_1"
```

**Result:** Empty placeholder in grid, no 3D/2D scene yet

### Step 2: Python Configures Viewport

```python
from godot import configure_viewport

# Configure as 3D viewport
configure_viewport("viewport_1", "3d", {
	"camera_position": (10, 10, 10),
	"camera_target": (0, 0, 0),
	"msaa": 4,
	"orbit_controls": True
})
```

```
Python: configure_viewport()
	↓
ViewportBridge.configure_viewport()
	↓
ViewportManager.configure_viewport()
	↓
Holder.setup() loads 3d_viewport.tscn
	↓
3D scene appears in holder
```

**Result:** Viewport now shows 3D scene with camera/lights

## Grid Layout

### Configuration
- **Columns:** 3
- **Max Viewports:** 9 (3x3 grid)
- **Spacing:** 4px horizontal/vertical
- **Sizing:** Holders expand to fill grid equally

### Visual Layout
```
┌─────────┬─────────┬─────────┐
│ Port 1  │ Port 2  │ Port 3  │
├─────────┼─────────┼─────────┤
│ Port 4  │ Port 5  │ Port 6  │
├─────────┼─────────┼─────────┤
│ Port 7  │ Port 8  │ Port 9  │
└─────────┴─────────┴─────────┘
```

Each holder auto-sizes to fill 1/3 of grid width.

## Python API Reference

### configure_viewport()
```python
from godot import configure_viewport

# Configure as 3D
success = configure_viewport(
	"viewport_1",  # ID of existing empty viewport
	"3d",          # Type: "3d" or "2d"
	{
		"camera_position": (10, 10, 10),
		"camera_target": (0, 0, 0),
		"fov": 70.0,
		"msaa": 4,
		"orbit_controls": True
	}
)

# Configure as 2D
success = configure_viewport(
	"viewport_2",
	"2d",
	{
		"camera_position": (0, 0),
		"zoom": 1.5
	}
)
```

### init_3d_scene() / init_2d_scene()
```python
from godot import init_3d_scene

# Still available - creates AND configures in one step
init_3d_scene("main", {
	"floating": False,
	"camera_position": (10, 10, 10),
	"orbit_controls": True
})
```

**Note:** These create a new viewport if it doesn't exist, or configure an existing empty one.

### Other Functions
```python
from godot import toggle_floating, close_viewport

toggle_floating("viewport_1")  # Float/dock viewport
close_viewport("viewport_1")   # Remove viewport
```

## GDScript API

Can also be used from GDScript:

```gdscript
# Create empty holder
ViewportManager.create_empty_viewport("my_viewport")

# Configure it
ViewportManager.configure_viewport("my_viewport", "3d", {
    "camera_position": Vector3(10, 10, 10),
    "msaa": 4
})

# Close it
ViewportManager.close_viewport("my_viewport")
```

## Implementation Checklist

- [x] ViewportManager.create_empty_viewport()
- [x] ViewportManager.configure_viewport()
- [x] ViewportBridge.configure_viewport() (C++)
- [x] Python binding for configure_viewport()
- [x] main_window.gd script
- [ ] Update main_window.tscn (add button, fix grid)
- [ ] Rebuild C++ extension
- [ ] Test workflow

## Setup Steps

1. **Update main_window.tscn** (see MAIN_WINDOW_SETUP.md)
   - Replace HSplitContainer with GridContainer
   - Add "Add Viewport" button
   - Attach main_window.gd script

2. **Update viewport_holder.tscn** (see VIEWPORT_HOLDER_SETUP.md)
   - Add title bar structure
   - Attach viewport_holder.gd script

3. **Configure ViewportManager Autoload**
   - Project Settings → Autoload
   - Add `res://scripts/viewport_manager.gd` as `ViewportManager`

4. **Rebuild C++ Extension**
   ```bash
   cmake --build build --config Debug
   ```

5. **Test**
   - Click "Add Viewport" button → Empty holder appears
   - Run Python code to configure → 3D/2D scene appears

## Example Usage

### Complete Example
```python
# Python script to create multiple viewports

from godot import configure_viewport

# User clicked "Add Viewport" 3 times
# This created: viewport_1, viewport_2, viewport_3

# Configure first as 3D
configure_viewport("viewport_1", "3d", {
    "camera_position": (15, 10, 15),
    "camera_target": (0, 0, 0),
    "msaa": 4,
    "orbit_controls": True
})

# Configure second as 2D
configure_viewport("viewport_2", "2d", {
    "zoom": 2.0
})

# Configure third as 3D with different camera
configure_viewport("viewport_3", "3d", {
    "camera_position": (5, 5, 5),
    "fov": 90,
    "orbit_controls": True
})

# Now all three viewports show different scenes
```

## Benefits

✓ **Separation of Concerns**: Button creates UI, Python assigns logic
✓ **User Control**: User decides how many viewports before assigning types
✓ **Flexible**: Can create multiple empties then batch-configure
✓ **Clear Workflow**: Visual feedback at each step
✓ **Grid Management**: Auto-layout handles spacing/sizing
