# Algorithm Wizard - Sample Scripts

This directory contains example Python scripts demonstrating various features of Algorithm Wizard.

## UI System

### `ui_labels_demo.py`
Demonstrates the UI drawing system:
- **UI Labels**: Text at fixed positions
- **UI Lines**: Lines drawn on the canvas layer
- **UI Boxes**: Rectangular outlines

**Features shown:**
- Creating text labels for titles and annotations
- Drawing bounding boxes around shapes
- Drawing connection lines between labels and objects
- Manual composition of labeled diagrams

**How to run:**
1. Open Algorithm Wizard
2. Press Ctrl+O to open file dialog
3. Select `ui_labels_demo.py`
4. Press F5 to run

## Async Execution System

Algorithm Wizard supports **step-by-step execution** using `wait()` and `await_input()`:

### `wait(seconds)` - Time-based pause
Pauses execution for a specified number of seconds without freezing the app.

### `await_input()` - User input pause
Pauses execution until the user clicks the "Continue" button.

### Usage Pattern

```python
from godot import *

# Create your scene
scene = scene_2d()
camera("cam1", "viewport_1", scene)

# Define a generator function for step-by-step visualization
def my_visualization():
    with scene:
        ui_label("step1", "Step 1", position=(10, 10), font_size=20)

    print("Created first label")
    yield wait(2.0)  # Wait 2 seconds

    with scene:
        rect((100, 100), position=(0, 0), color=(1, 0, 0, 1))

    print("Created rectangle, press Continue...")
    yield await_input()  # Wait for user input

    with scene:
        ui_label("complete", "Done!", position=(10, 40), font_size=16)

    print("Visualization complete!")

# Start async execution
run_async(my_visualization())
```

### Examples

- **`async_demo.py`**: Basic async demonstration with wait() and await_input()
- **`sorting_async_demo.py`**: Interactive bubble sort visualization
- **`merge_sort_demo.py`**: Merge sort (non-async version)

## Creating Your Own Scripts

### Basic Template

```python
from godot import *

# Create a 2D scene
scene = scene_2d()
camera("cam1", "viewport_1", scene)

with scene:
    # Your visualization code here
    my_shape = rect((100, 100), position=(0, 0), color=(1, 0, 0, 1))

    # Add labels
    ui_label("title", "My Visualization", position=(10, 10), font_size=24)

print("Script loaded successfully!")
```

### Async Template

```python
from godot import *

scene = scene_2d()
camera("cam1", "viewport_1", scene)

def step_by_step_demo():
    # Your code here
    # Use: yield wait(seconds)
    # Use: yield await_input()
    pass

run_async(step_by_step_demo())
```

### Tips

1. **Always use `with scene:`**: This sets the context for drawing
2. **Store objects** if you want to label or animate them
3. **Use descriptive label IDs**: Makes debugging easier
4. **Check console output**: Helpful messages show what's happening
5. **For async**: Define generator function and use `yield` with wait() or await_input()
6. **Continue button**: Appears automatically when script calls await_input()

## Documentation

See `_info/ui-labels-2d.md` for complete documentation on the UI labels system.

## Contributing

Feel free to create your own example scripts and share them with the community!
