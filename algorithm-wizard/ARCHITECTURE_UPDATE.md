# Architecture Update - Scene-Based ViewportHolder

## What Changed

The viewport system has been updated to use your pre-built scene file instead of creating UI programmatically.

### Before (Programmatic):
- `viewport_holder.gd` created all UI elements in code (`_build_ui()` method)
- `viewport_manager.gd` called `ViewportHolderScript.new()` to create instances
- Everything was built from scratch at runtime

### After (Scene-Based):
- `viewport_holder.gd` references existing nodes from `viewport_holder.tscn`
- `viewport_manager.gd` calls `ViewportHolderScene.instantiate()` to load the scene
- UI structure defined in the scene file, script just uses it

## Updated Files

### 1. `scripts/viewport_holder.gd`
**Changes:**
- Removed `_build_ui()` method entirely
- Changed from `extends PanelContainer` to `extends Control` (matches your scene root)
- Added `@onready` references to scene nodes:
  - `viewport_container` - Gets SubViewportContainer from scene
  - `id_label` - Gets label from title bar
  - `float_button` - Gets float button
  - `close_button` - Gets close button
- Removed all UI creation code
- Kept all functionality (setup, camera controls, etc.)

### 2. `scripts/viewport_manager.gd`
**Changes:**
- Changed: `const ViewportHolderScript = preload("res://scripts/viewport_holder.gd")`
- To: `const ViewportHolderScene = preload("res://viewports/viewport_holder.tscn")`
- Changed: `var holder = ViewportHolderScript.new()`
- To: `var holder = ViewportHolderScene.instantiate()`

### 3. `viewports/viewport_holder.tscn`
**Required Structure:**

Your current scene needs to be updated to match this structure:

```
ViewportHolder (Control) [viewport_holder.gd attached]
└── PanelContainer
    └── VBoxContainer
        ├── TitleBar (PanelContainer)
        │   └── HBoxContainer
        │       ├── IDLabel (Label)
        │       ├── FloatButton (Button)
        │       └── CloseButton (Button)
        └── SubViewportContainer
```

**Node Paths Expected by Script:**
- `$PanelContainer/VBoxContainer/SubViewportContainer`
- `$PanelContainer/VBoxContainer/TitleBar/HBoxContainer/IDLabel`
- `$PanelContainer/VBoxContainer/TitleBar/HBoxContainer/FloatButton`
- `$PanelContainer/VBoxContainer/TitleBar/HBoxContainer/CloseButton`

## What You Need to Do

### Step 1: Update viewport_holder.tscn

Follow the instructions in `VIEWPORT_HOLDER_SETUP.md` to add the title bar structure.

**Quick checklist:**
- [ ] Add VBoxContainer inside PanelContainer
- [ ] Add TitleBar (PanelContainer) with HBoxContainer
- [ ] Add IDLabel, FloatButton, CloseButton inside HBoxContainer
- [ ] Move SubViewportContainer into VBoxContainer
- [ ] Attach `viewport_holder.gd` to root ViewportHolder node

### Step 2: Test in Godot

Once the scene structure is updated:

1. Open Godot Editor
2. Check for errors in Output panel
3. The script should now find all required nodes via `@onready` variables
4. If you get "Invalid get index" errors, check node paths match exactly

### Step 3: Verify Functionality

Test that viewports work:

```gdscript
# In GDScript or through Python
ViewportManager.create_viewport("test", "3d", {})
```

Should create a viewport with:
- Title bar showing "test"
- Float and Close buttons working
- 3D viewport rendering properly

## Architecture Benefits

### Why Scene-Based is Better:

1. **Visual Editing**: Design UI in Godot Editor instead of code
2. **Easier Iteration**: Change layout without touching code
3. **Separation of Concerns**: Scene defines structure, script defines behavior
4. **Reusability**: Can duplicate/modify the scene file easily
5. **Performance**: Scene loading is optimized by Godot

### How It Works:

```
ViewportManager.create_viewport("main", "3d", {...})
    ↓
Loads viewport_holder.tscn
    ↓
Scene instantiated with all UI nodes
    ↓
viewport_holder.gd's @onready vars get references
    ↓
setup() loads 3d_viewport.tscn into SubViewportContainer
    ↓
Viewport ready to use
```

## Troubleshooting

### Error: "Invalid get index 'viewport_container'"
- Check that SubViewportContainer exists at path: `$PanelContainer/VBoxContainer/SubViewportContainer`
- Verify VBoxContainer was added
- Make sure SubViewportContainer is inside VBoxContainer

### Error: "Invalid get index 'id_label'"
- Check TitleBar structure exists
- Verify node names match exactly (case-sensitive)
- Ensure HBoxContainer has Label named "IDLabel"

### Buttons don't work
- Check button names: "FloatButton" and "CloseButton" (exact match)
- Verify they're inside the HBoxContainer
- Script connects signals in _ready(), check Output for errors

### Viewport not displaying
- Make sure 3d_viewport.tscn has RenderRoot node
- Check that camera scripts are attached (camera_3d_setup.gd)
- Verify MSAA/TAA settings aren't causing issues

## Migration Checklist

- [ ] Read VIEWPORT_HOLDER_SETUP.md
- [ ] Update viewport_holder.tscn structure in Godot Editor
- [ ] Attach viewport_holder.gd to root node
- [ ] Save the scene
- [ ] Reload Godot project
- [ ] Test creating a viewport
- [ ] Verify float/close buttons work
- [ ] Test camera controls (orbit with right-click)

Once complete, your viewport system will be fully scene-based and easier to maintain!
