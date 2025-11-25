# Test Commands

## Create 3D Viewport

```python
from godot import configure_viewport

configure_viewport("viewport_1", "3d", {
	"camera_position": (10, 10, 10),
	"orbit_controls": True
})
```

## Create 2D Viewport

```python
from godot import configure_viewport

configure_viewport("viewport_1", "2d", {
	"zoom": 1.5
})
```

## Switch 3D to 2D

```python
from godot import configure_viewport

# Switch existing viewport to 2D
configure_viewport("viewport_1", "2d", {})
```

## Decouple Viewport

```python
from godot import decouple_viewport

# Remove scene but keep holder
decouple_viewport("viewport_1")
```
