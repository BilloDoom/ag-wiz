# ViewportHolder Scene Setup

## Update viewports/viewport_holder.tscn Structure

Open the scene in Godot Editor and restructure it as follows:

### Current Structure:
```
ViewportHolder (Control)
└── PanelContainer
	└── SubViewportContainer
```

### Required Structure:
```
ViewportHolder (Control) [viewport_holder.gd attached]
└── PanelContainer
	└── VBoxContainer
		├── TitleBar (PanelContainer)
		│   └── HBoxContainer
		│       ├── IDLabel (Label) - size_flags: expand_fill
		│       ├── FloatButton (Button) - text: "Float", min_size: (60, 0)
		│       └── CloseButton (Button) - text: "X", min_size: (30, 0)
		└── SubViewportContainer - size_flags: expand_fill
```

### Steps:

1. **Select PanelContainer**, add child: **VBoxContainer**
   - Size flags: Expand Fill (both)

2. **Inside VBoxContainer**, add child: **PanelContainer** (name it "TitleBar")
   - Custom minimum size: (0, 30)

3. **Inside TitleBar**, add child: **HBoxContainer**

4. **Inside HBoxContainer**, add these in order:
   - **Label** (name: "IDLabel")
	 - Text: "Viewport"
	 - Size flags horizontal: Expand Fill

   - **Button** (name: "FloatButton")
	 - Text: "Float"
	 - Custom minimum size: (60, 0)

   - **Button** (name: "CloseButton")
	 - Text: "X"
	 - Custom minimum size: (30, 0)

5. **Move SubViewportContainer** into the VBoxContainer (below TitleBar)
   - Size flags horizontal: Expand Fill
   - Size flags vertical: Expand Fill
   - Stretch: true (already set)

6. **Attach script to root ViewportHolder node**:
   - Select ViewportHolder (root)
   - Attach script: `res://scripts/viewport_holder.gd`

### Save the scene when done!
