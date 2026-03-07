"""
Sorting Algorithm with Async - Algorithm Wizard
Demonstrates step-by-step sorting visualization using await_input()
"""

from godot import *
import random

# Constants
ARRAY_SIZE = 8
MIN_VALUE = 10
MAX_VALUE = 80
BAR_WIDTH = 50
BAR_SPACING = 10
START_X = -250
START_Y = 0

# Generate random array
random.seed()
array = [random.randint(MIN_VALUE, MAX_VALUE) for _ in range(ARRAY_SIZE)]

print(f"Array to sort: {array}")

# Create scene
scene = scene_2d()
camera("cam1", "viewport_1", scene, {"position": (0, 0), "zoom": (1.0, 1.0)})

# Store bar objects
bars = []
labels = []

def draw_array():
    """Draw the current state of the array"""
    with scene:
        # Clear previous bars (in a real implementation you'd update them)
        for i, value in enumerate(array):
            x = START_X + i * (BAR_WIDTH + BAR_SPACING)
            bar_height = value * 3

            # Create bar with color based on whether it's sorted
            color = (0.3, 0.6, 1.0, 1) if i > len(array) - sorted_count else (0.2, 0.8, 0.3, 1)

            bar = rect(
                (BAR_WIDTH, bar_height),
                position=(x, START_Y - bar_height),
                color=color
            )
            bars.append(bar)

            # Value label
            ui_label(
                f"val_{i}_{value}",
                str(value),
                position=(x + 10, -bar_height - 30),
                font_size=14,
                color=(1, 1, 1, 1)
            )

# Bubble sort with async visualization
def bubble_sort_visual():
    """Bubble sort with step-by-step visualization"""
    global array, sorted_count

    with scene:
        ui_label("title", "Bubble Sort - Step by Step", position=(10, 10), font_size=24)
        ui_label("instruction", "Press Continue to see each comparison", position=(10, 40), font_size=14, color=(0.8, 0.8, 0.8, 1))

    sorted_count = 0
    n = len(array)

    for i in range(n):
        swapped = False

        for j in range(0, n - i - 1):
            print(f"Comparing {array[j]} and {array[j+1]}")

            with scene:
                ui_label("status", f"Comparing: {array[j]} vs {array[j+1]}", position=(10, 70), font_size=16, color=(1, 1, 0, 1))

            # Redraw array
            draw_array()

            # Wait for user to see the comparison
            yield await_input()

            if array[j] > array[j + 1]:
                # Swap
                array[j], array[j + 1] = array[j + 1], array[j]
                swapped = True

                print(f"  Swapped! New order: {array}")

                with scene:
                    ui_label("swap", "Swapped!", position=(10, 100), font_size=14, color=(1, 0, 0, 1))

                # Redraw after swap
                draw_array()

                yield wait(0.5)  # Brief pause after swap

        sorted_count += 1

        if not swapped:
            print("Array is sorted!")
            break

    with scene:
        ui_label("complete", f"Sorting Complete! Result: {array}", position=(10, 250), font_size=18, color=(0, 1, 0, 1))

    print(f"Final sorted array: {array}")

# Global counter for sorted elements
sorted_count = 0

# Draw initial array
draw_array()

# Start async execution
print("Starting bubble sort visualization...")
print("Press Continue to step through each comparison!")
run_async(bubble_sort_visual())
