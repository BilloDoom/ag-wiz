# Viewport Management System Implementation

## Context
I'm building an algorithm visualization tool in Godot 4 using GDExtensions with Python (pybind11). Users write Python code to visualize algorithms in 3D/2D viewports. I need a viewport management system where users can create multiple named viewports that can be embedded in a grid or made floating.

## Architecture Requirements

### Core Components
1. **ViewportHolder** - A reusable wrapper class (PanelContainer) that:
   - Has a unique string ID
   - Contains a title bar with ID label, float button, and close button
   - Contains a SubViewportContainer that holds the actual viewport template
   - Can be plugged into either an embedded grid or a floating window
   - Provides access to the render root node where objects are drawn

2. **ViewportManager** - A singleton that:
   - Creates and tracks ViewportHolder instances by ID
   - Manages an embedded GridContainer (3 columns) for embedded viewports
   - Creates floating Window nodes for floating viewports
   - Handles moving holders between embedded/floating states
   - Enforces a maximum of 9 viewports
   - Provides methods: create_viewport(), toggle_floating(), close_viewport(), get_render_root()

3. **Viewport Templates** - Pre-made scenes:
   - `viewport_3d.tscn`: SubViewport (root) with Camera3D, DirectionalLight3D, WorldEnvironment, and RenderRoot (Node3D)
   - `viewport_2d.tscn`: SubViewport (root) with Camera2D and RenderRoot (Node2D)
   - Each camera has a script with `apply_settings(settings: Dictionary)` method to configure position, target, FOV, zoom, etc.

4. **Camera Controllers** (optional but recommended):
   - CameraController3D: Orbit controls (right-click drag to rotate, scroll to zoom)
   - CameraController2D: Pan and zoom controls
   - Only active when mouse is inside the viewport
   - Attached to ViewportHolder, configured based on settings

### File Structure
```
res://addons/algorithm_wizard/
├── scripts/
│   ├── viewport_holder.gd (ViewportHolder class)
│   ├── viewport_manager.gd (singleton)
│   ├── camera_controller_3d.gd
│   └── camera_controller_2d.gd
├── scenes/
│   ├── viewport_3d.tscn (template with Camera3D script)
│   └── viewport_2d.tscn (template with Camera2D script)
└── shaders/
    └── sky_shader.gdshader (dark gray background)
```

## Technical Specifications

### ViewportHolder API
```gdscript
class_name ViewportHolder extends PanelContainer

# Signals
signal close_requested(holder_id: String)
signal float_requested(holder_id: String)

# Properties
var holder_id: String
var viewport_scene: SubViewport  # The instantiated template (SubViewport is root)
var viewport_container: SubViewportContainer
var render_root: Node  # Node3D or Node2D from template
var camera: Node  # Camera3D or Camera2D
var camera_controller: Node
var is_3d: bool
var is_floating: bool

# Methods
func setup(id: String, viewport_type: String, settings: Dictionary)
func get_render_root() -> Node
func get_viewport() -> SubViewport
func get_camera() -> Node
func clear_scene()
```

### ViewportManager API
```gdscript
extends Node

const MAX_VIEWPORTS = 9

var holders: Dictionary  # id -> ViewportHolder
var embedded_grid: GridContainer
var embedded_container: Control

# Methods
func set_embedded_container(container: Control)
func create_viewport(id: String, viewport_type: String, settings: Dictionary) -> ViewportHolder
func toggle_floating(id: String)
func close_viewport(id: String)
func get_holder(id: String) -> ViewportHolder
func get_render_root(id: String) -> Node
```

### Settings Dictionary Structure
```python
{
    "floating": bool,  # Start as floating window
    "msaa": int,  # 0, 2, 4, or 8
    "taa": bool,  # Temporal anti-aliasing
    "orbit_controls": bool,  # Enable camera controls
    
    # 3D specific
    "camera_position": Vector3,
    "camera_target": Vector3,
    "fov": float,
    "near": float,
    "far": float,
    "camera_distance": float,  # For orbit controller
    
    # 2D specific
    "camera_position": Vector2,
    "zoom": float,
    
    # Visual
    "background_color": Color,
}
```

### Python API (will be exposed via pybind11 later)
```python
# Create viewports
init_3d_scene("main", {
    "floating": False,
    "camera_position": (10, 10, 10),
    "camera_target": (0, 0, 0),
    "msaa": 4,
    "orbit_controls": True
})

init_2d_scene("graph", {
    "floating": True,
    "zoom": 1.5
})

# Control viewports
toggle_floating("main")
close_viewport("graph")

# Access for drawing
render_root = get_render_root("main")
```

## Viewport Template Requirements

### viewport_3d.tscn Structure
```
SubViewport (root)
├── Camera3D
│   └── Script: camera_3d_setup.gd
├── DirectionalLight3D (rotation: -45, 45, 0)
├── WorldEnvironment
│   └── Environment (with sky shader)
└── RenderRoot (Node3D) - Empty, for user objects
```

### camera_3d_setup.gd
```gdscript
extends Camera3D

@export var initial_position: Vector3 = Vector3(10, 10, 10)
@export var look_at_target: Vector3 = Vector3.ZERO

func _ready():
    position = initial_position
    look_at(look_at_target)

func apply_settings(settings: Dictionary):
    # Handle camera_position, camera_target, fov, near, far
```

### viewport_2d.tscn Structure
```
SubViewport (root)
├── Camera2D
│   └── Script: camera_2d_setup.gd
└── RenderRoot (Node2D) - Empty, for user objects
```

## Camera Controller Requirements

### CameraController3D (Orbit controls)
- Right-click drag: Rotate around target (modify pitch/yaw)
- Scroll wheel: Zoom in/out (modify distance)
- Only active when mouse is inside viewport
- Configurable: sensitivity, min/max distance, min/max pitch

### CameraController2D (Pan/zoom)
- Middle-click or right-click drag: Pan camera
- Scroll wheel: Zoom in/out
- Only active when mouse is inside viewport

## Implementation Notes

1. **Viewport sizing**: 
   - SubViewportContainer should have `stretch = true`
   - Update viewport size dynamically in _process() to match container size
   - Prevents aliasing and scaling issues

2. **Anti-aliasing**:
   - Enable MSAA on SubViewport: `viewport.msaa_3d = Viewport.MSAA_4X`
   - Optionally enable TAA: `viewport.use_taa = true`

3. **Grid layout**:
   - GridContainer with 3 columns
   - ViewportHolders have `custom_minimum_size = Vector2(400, 300)`
   - Add spacing: `h_separation = 4`, `v_separation = 4`

4. **Floating windows**:
   - Create Window node with size 800x600
   - Add ViewportHolder as child
   - Connect close_requested signal to dock viewport back
   - Store window reference as metadata on holder

5. **Sky shader** (for 3D):
   - Dark gray background: `COLOR = vec3(0.15, 0.15, 0.15)`
   - Easy on eyes for long visualization sessions

## Deliverables Needed

Please create the following files with complete, production-ready implementations:

1. `viewport_holder.gd` - Complete ViewportHolder class
2. `viewport_manager.gd` - Complete singleton manager
3. `camera_controller_3d.gd` - Orbit camera controller
4. `camera_controller_2d.gd` - Pan/zoom camera controller
5. `camera_3d_setup.gd` - Camera script for 3D template
6. `camera_2d_setup.gd` - Camera script for 2D template
7. `sky_shader.gdshader` - Simple dark gray sky shader
8. Instructions for creating the .tscn template files in Godot editor

## Testing Scenario
After implementation, I should be able to:
1. Call `ViewportManager.create_viewport("main", "3d", {})` and see an embedded 3D viewport in a grid
2. Call `ViewportManager.create_viewport("detail", "3d", {"floating": true})` and see a floating window
3. Toggle between embedded/floating with `ViewportManager.toggle_floating("main")`
4. Use orbit controls in 3D viewports (right-click drag, scroll zoom)
5. Create up to 9 viewports, see them arranged in 3x3 grid
6. Close viewports and see grid reorganize

Please provide complete, working code with all edge cases handled, proper error checking, and clear comments.
