# Viewport Template Setup Instructions

## Update viewport_3d.tscn

Open `viewports/3d_viewport.tscn` in Godot Editor and make these changes:

### 1. Add Camera Script
- Select the `Camera3D` node
- In the Inspector, attach script: `res://scripts/camera_3d_setup.gd`
- Set initial_position to (10, 10, 10)
- Set look_at_target to (0, 0, 0)

### 2. Remove Demo Mesh
- Delete the `MeshInstance3D` node (this was just for testing)

### 3. Add RenderRoot Node
- Add a new child to the root SubViewport
- Type: `Node3D`
- Name: `RenderRoot`
- This is where Python code will add visualization objects

### Final Structure:
```
SubViewport (root)
├── Camera3D [camera_3d_setup.gd attached]
├── DirectionalLight3D
├── WorldEnvironment
└── RenderRoot (Node3D) - empty
```

---

## Create viewport_2d.tscn

Create a new scene: `viewports/2d_viewport.tscn`

### Root Node
- Type: `SubViewport`
- Name: `2DViewport`
- Size: Vector2i(640, 480)

### Add Children:
1. **Camera2D**
   - Attach script: `res://scripts/camera_2d_setup.gd`
   - Position: (0, 0)
   - Zoom: (1, 1)
   - Enabled: true

2. **RenderRoot**
   - Type: `Node2D`
   - Position: (0, 0)
   - This is where Python code will add 2D visualization objects

### Final Structure:
```
SubViewport (root)
├── Camera2D [camera_2d_setup.gd attached]
└── RenderRoot (Node2D) - empty
```

---

## Save and Test

After making these changes:
1. Save both scenes
2. The ViewportManager will be able to load them
3. Python code can access the RenderRoot nodes to add objects
