# Main Window Setup - Viewport Grid

## Update scenes/main_window.tscn Structure

Open the scene in Godot Editor and make these changes:

### Current ViewportContainer Structure:
```
ViewportContainer (PanelContainer)
└── HSplitContainer
    ├── ColorRect (pink)
    └── ColorRect2 (cyan)
```

### Required Structure:
```
ViewportContainer (PanelContainer)
└── ViewportGrid (GridContainer) [name it exactly "ViewportGrid"]
    [Empty - holders will be added here]
```

### Steps:

1. **Delete the ColorRects and HSplitContainer**
   - Select `Panel/ViewportContainer/HSplitContainer`
   - Delete it (and its children)

2. **Add GridContainer**
   - Select `Panel/ViewportContainer`
   - Add child: **GridContainer**
   - Name it: **ViewportGrid** (exact name)

3. **Configure ViewportGrid**
   - Columns: 3
   - H Separation: 4
   - V Separation: 4
   - Size Flags Horizontal: **Expand Fill**
   - Size Flags Vertical: **Expand Fill**

4. **Add "Add Viewport" Button**
   - Select `Panel` node
   - Add child: **Button**
   - Name it: **AddViewportBtn**
   - Position it in the UI (top-left corner or wherever you want)
   - Text: "Add Viewport"
   - Suggested position:
     - Offset Left: 10
     - Offset Top: 10
     - Offset Right: 120
     - Offset Bottom: 40

5. **Attach script to MainWindow root**
   - Select `MainWindow` (root Control node)
   - Attach script: `res://scripts/main_window.gd` (create new)

### Save the scene when done!
