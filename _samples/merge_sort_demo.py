"""
Merge Sort Visualization - Algorithm Wizard
Demonstrates merge sort algorithm with visual array representation
"""

from godot import *
import random

# Constants
ARRAY_SIZE = 12
MIN_VALUE = 5
MAX_VALUE = 50
BAR_WIDTH = 40
BAR_SPACING = 10
START_X = -280
START_Y = 0

# Generate random array
random.seed()
array = [random.randint(MIN_VALUE, MAX_VALUE) for _ in range(ARRAY_SIZE)]

print(f"Original array: {array}")

# Create 2D scene
scene = scene_2d()
camera("cam1", "viewport_1", scene, {"position": (0, 0), "zoom": (1.0, 1.0)})

# Store bar objects for animation
bars = []

with scene:
    # Title
    ui_label("title", "Merge Sort Visualization", position=(10, 10), font_size=24)
    ui_label("array_label", f"Array: {array}", position=(10, 40), font_size=12, color=(0.8, 0.8, 0.8, 1))

    # Draw array as vertical bars
    for i, value in enumerate(array):
        x = START_X + i * (BAR_WIDTH + BAR_SPACING)
        bar_height = value * 4  # Scale height

        # Create bar
        bar = rect(
            (BAR_WIDTH, bar_height),
            position=(x, START_Y - bar_height),
            color=(0.3, 0.6, 1.0, 1)
        )
        bars.append(bar)

        # Value label above bar
        ui_label(
            f"val_{i}",
            str(value),
            position=(x + 10, -bar_height - 30),
            font_size=14,
            color=(1, 1, 1, 1)
        )

        # Index label below bar
        ui_label(
            f"idx_{i}",
            str(i),
            position=(x + 15, 20),
            font_size=12,
            color=(0.6, 0.6, 0.6, 1)
        )

# Merge sort implementation with visualization steps
def merge_sort(arr, left, right, depth=0):
    """Recursive merge sort with step tracking"""
    if left >= right:
        return

    mid = (left + right) // 2

    print(f"{'  ' * depth}Splitting [{left}:{right}] at {mid}")

    # Recursively sort halves
    merge_sort(arr, left, mid, depth + 1)
    merge_sort(arr, mid + 1, right, depth + 1)

    # Merge the sorted halves
    merge(arr, left, mid, right, depth)

def merge(arr, left, mid, right, depth):
    """Merge two sorted subarrays"""
    print(f"{'  ' * depth}Merging [{left}:{mid}] and [{mid+1}:{right}]")

    # Create temporary arrays
    left_arr = arr[left:mid+1]
    right_arr = arr[mid+1:right+1]

    i = j = 0
    k = left

    # Merge back into original array
    while i < len(left_arr) and j < len(right_arr):
        if left_arr[i] <= right_arr[j]:
            arr[k] = left_arr[i]
            i += 1
        else:
            arr[k] = right_arr[j]
            j += 1
        k += 1

    # Copy remaining elements
    while i < len(left_arr):
        arr[k] = left_arr[i]
        i += 1
        k += 1

    while j < len(right_arr):
        arr[k] = right_arr[j]
        j += 1
        k += 1

# Create a copy for sorting
sorted_array = array.copy()

# Perform merge sort
print("\n--- Starting Merge Sort ---")
merge_sort(sorted_array, 0, len(sorted_array) - 1)
print(f"\nSorted array: {sorted_array}")

# Draw sorted array below original
with scene:
    ui_label("sorted_title", "Sorted Result:", position=(10, 280), font_size=18, color=(0, 1, 0, 1))

    for i, value in enumerate(sorted_array):
        x = START_X + i * (BAR_WIDTH + BAR_SPACING)
        bar_height = value * 4

        # Create sorted bar
        rect(
            (BAR_WIDTH, bar_height),
            position=(x, 300 - bar_height),
            color=(0.2, 0.8, 0.3, 1)
        )

        # Value label
        ui_label(
            f"sorted_val_{i}",
            str(value),
            position=(x + 10, 270 - bar_height),
            font_size=14,
            color=(1, 1, 1, 1)
        )

print("\n--- Visualization Complete ---")
print("Original array displayed at top (blue bars)")
print("Sorted array displayed at bottom (green bars)")
print("Check console for merge sort steps")
