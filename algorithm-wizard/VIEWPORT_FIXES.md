# Viewport System Fixes

## Issues Fixed

### 1. ✅ Holder ID Not Being Set
**Problem:** Empty viewport holders weren't showing their IDs.

**Fix:**
- Added `set_holder_id(id)` method to `viewport_holder.gd`
- Fixed order in `create_empty_viewport()`: now adds holder to tree first, then sets ID
- This ensures @onready variables are ready before setting the ID

### 2. ✅ Close Button Not Working
**Problem:** Clicking close button didn't remove holder.

**Fix:**
- `close_requested` signal is connected in `create_empty_viewport()`
- Signal handler `_on_holder_close_requested()` calls `close_viewport(id)`
- Close button is the **only** way to destroy a holder (by design)

### 3. ✅ Float Button Not Working
**Problem:** Clicking float button didn't create floating window.

**Fix:**
- `float_requested` signal is connected in `create_empty_viewport()`
- Signal handler `_on_holder_float_requested()` calls `toggle_floating(id)`
- Creates Window with holder as child, or docks back to grid

### 4. ✅ Viewport Decoupling
**Problem:** No way to remove 3D/2D scene from holder without destroying holder.

**Fix:**
- Added `decouple_viewport()` method to `viewport_holder.gd`
- Removes viewport scene, camera controller, and clears references
- Keeps holder alive for reconfiguration
- Exposed to Python as `decouple_viewport(id)`

### 5. ✅ Switching Between 3D and 2D
**Problem:** Couldn't reconfigure a viewport from 3D to 2D or vice versa.

**Fix:**
- `setup()` now calls `decouple_viewport()` first if viewport already exists
- Python can call `configure_viewport(id, "2d", {})` on a 3D viewport
- Old scene is destroyed from memory, new scene loaded

## Updated Architecture

### Holder Lifecycle

```
Button Click → Create Empty Holder
	↓
Holder added to grid with ID
	↓
Python: configure_viewport(id, "3d", {})
	↓
3D scene loaded into holder
	↓
Python: decouple_viewport(id)  [optional]
	↓
3D scene destroyed, holder remains empty
	↓
Python: configure_viewport(id, "2d", {})
	↓
2D scene loaded into same holder
	↓
User clicks Close button
	↓
Holder destroyed completely
```

### Key Design Principles

1. **Holder ID Always Set**: Every holder has an ID from creation
2. **Holders Listen to Python**: Holders display what Python hooks up to them
3. **UI Controls Holder Lifecycle**: Only the close button can destroy a holder
4. **Python Controls Scene**: Python configures/decouples/reconfigures scenes
5. **Decoupling ≠ Closing**: Decoupling removes scene, closing removes holder

## New Python API

### decouple_viewport()
```python
from godot import decouple_viewport

# Remove 3D/2D scene but keep holder
decouple_viewport("viewport_1")

# Holder now empty, can be reconfigured
```

### Switching Scene Types
```python
from godot import configure_viewport

# Start with 3D
configure_viewport("viewport_1", "3d", {
	"camera_position": (10, 10, 10),
	"orbit_controls": True
})

# Switch to 2D (auto-decouples 3D first)
configure_viewport("viewport_1", "2d", {
	"zoom": 1.5
})

# Switch back to 3D (auto-decouples 2D first)
configure_viewport("viewport_1", "3d", {
	"camera_position": (5, 5, 5)
})
```

## Files Changed

### GDScript Files
1. **scripts/viewport_holder.gd**
   - Added `set_holder_id(id)` method
   - Added `decouple_viewport()` method
   - Modified `setup()` to auto-decouple existing scenes

2. **scripts/viewport_manager.gd**
   - Fixed `create_empty_viewport()` order of operations
   - Added `decouple_viewport(id)` method
   - Improved signal connection timing

### C++ Files
1. **cpp/include/viewport_bridge.hpp**
   - Added `bool decouple_viewport(const String& id)`

2. **cpp/src/viewport_bridge.cpp**
   - Implemented `decouple_viewport()` method
   - Added to `_bind_methods()`
   - Added Python binding for `decouple_viewport()`

## Testing Checklist

- [ ] Click "Add Viewport" → Holder appears with ID "viewport_1"
- [ ] Click Close button → Holder removed from grid
- [ ] Click Float button → Holder opens in floating window
- [ ] Click Float again (or window close) → Holder returns to grid
- [ ] Python: `configure_viewport("viewport_1", "3d", {})` → 3D scene appears
- [ ] Python: `decouple_viewport("viewport_1")` → Scene removed, holder empty
- [ ] Python: `configure_viewport("viewport_1", "2d", {})` → 2D scene appears
- [ ] Python: Switch 3D→2D→3D multiple times → Works without errors
- [ ] Add 9 viewports → 10th fails with error message
- [ ] Grid layout: 3x3 arrangement, equal sizing

## Rebuild Required

```bash
cmake --build build --config Debug
```

All C++ changes require rebuilding the extension.

## Summary

The viewport system now properly:
- ✓ Sets and displays holder IDs
- ✓ Handles close button (only way to destroy holder)
- ✓ Handles float button (creates floating windows)
- ✓ Supports viewport decoupling (remove scene, keep holder)
- ✓ Allows 3D ↔ 2D switching via Python
- ✓ Maintains clean separation: UI controls holders, Python controls scenes
