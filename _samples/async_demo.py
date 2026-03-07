"""
Async Execution Demo - Algorithm Wizard
Demonstrates wait() and await_input() for step-by-step visualization
"""

from godot import *

# Create scene
scene = scene_2d()
camera("cam1", "viewport_1", scene, {"position": (0, 0), "zoom": (1.0, 1.0)})

# Generator function that uses wait() and await_input()
def animated_visualization():
    """Main visualization function - runs as generator"""

    with scene:
        # Title
        ui_label("title", "Async Execution Demo", position=(10, 10), font_size=24)
        ui_label("info", "Watch the boxes appear step-by-step!", position=(10, 40), font_size=14, color=(0.7, 0.7, 0.7, 1))

    print("Step 1: Creating first box...")

    with scene:
        rect1 = rect((100, 100), position=(-200, 0), color=(1, 0, 0, 1))
        ui_label("label1", "Red Box (Step 1)", position=(-200, -130), font_size=16)

    print("Waiting 2 seconds before next step...")
    yield wait(2.0)  # Wait 2 seconds

    print("Step 2: Creating second box...")

    with scene:
        rect2 = rect((100, 100), position=(0, 0), color=(0, 1, 0, 1))
        ui_label("label2", "Green Box (Step 2)", position=(0, -130), font_size=16)

    print("Press Continue to proceed...")
    yield await_input()  # Wait for user input

    print("Step 3: Creating third box...")

    with scene:
        rect3 = rect((100, 100), position=(200, 0), color=(0, 0, 1, 1))
        ui_label("label3", "Blue Box (Step 3)", position=(200, -130), font_size=16)

    print("Waiting 1.5 seconds...")
    yield wait(1.5)  # Wait 1.5 seconds

    print("Step 4: Adding circles...")

    with scene:
        circle1 = circle(40, position=(-200, 150), color=(1, 1, 0, 1))
        circle2 = circle(40, position=(0, 150), color=(0, 1, 1, 1))
        circle3 = circle(40, position=(200, 150), color=(1, 0, 1, 1))

        ui_label("circles", "Circles!", position=(10, 220), font_size=18, color=(1, 1, 0, 1))

    print("Press Continue to finish...")
    yield await_input()  # Wait for final confirmation

    with scene:
        ui_label("complete", "Animation Complete!", position=(10, 270), font_size=20, color=(0, 1, 0, 1))

    print("Visualization complete!")

# Start the async execution
print("Starting async visualization...")
print("The script will pause at wait() and await_input() points")
print("Watch the Continue button appear when input is needed!")
run_async(animated_visualization())
