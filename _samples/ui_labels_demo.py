"""
UI Labels Demo - Algorithm Wizard
Demonstrates UI labels, boxes, and lines on the canvas layer
"""

from godot import *

# Create a 2D scene
scene = scene_2d()
camera("cam1", "viewport_1", scene, {"position": (0, 0), "zoom": (1.0, 1.0)})

with scene:
    # Draw some 2D shapes
    box1 = rect((80, 60), position=(-150, 0), color=(1, 0, 0, 1))
    circle1 = circle(40, position=(150, 0), color=(0, 1, 0, 1))

    # Create simple UI labels
    ui_label("title", "UI Labels Demo", position=(10, 10), font_size=24, color=(1, 1, 1, 1))
    ui_label("info", "Manual connections with ui_line() and ui_box()", position=(10, 40), font_size=14, color=(0.7, 0.7, 0.7, 1))

    # Manually create labels with boxes and lines
    # Rectangle label
    ui_label("box_label", "Red Rectangle", position=(50, -100), font_size=16, color=(1, 1, 1, 1))
    ui_box("box_bbox", position=(-165, -15), size=(110, 90), color=(1, 1, 0, 1), width=2.0)  # Yellow box
    ui_line("box_line", from_pos=(100, -85), to_pos=(-110, -15), color=(1, 1, 0, 1), width=2.0)  # Yellow line

    # Circle label
    ui_label("circle_label", "Green Circle", position=(200, -100), font_size=16, color=(1, 1, 1, 1))
    ui_box("circle_bbox", position=(130, -20), size=(80, 80), color=(0, 1, 1, 1), width=2.0)  # Cyan box
    ui_line("circle_line", from_pos=(250, -85), to_pos=(170, -20), color=(0, 1, 1, 1), width=2.0)  # Cyan line

print("UI Labels demo loaded successfully!")
print("You should see:")
print("- Title and info labels at the top")
print("- A red rectangle with a yellow bounding box and connecting line")
print("- A green circle with a cyan bounding box and connecting line")
