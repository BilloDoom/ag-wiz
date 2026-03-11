from godot import *

# --- Merge Sort Visualization ---
# Bars represent array elements. Labels are anchored in world space so they
# stay attached to their columns on resize / pan / zoom.
#
# Colours:
#   grey   - unsorted / idle
#   yellow - currently being compared
#   green  - merged into sorted position

ARRAY = [38, 27, 43, 3, 9, 82, 10, 54]

BAR_W     = 60       # pixel width of each bar
BAR_MAX_H = 300      # pixel height of the largest value
SPACING   = 10       # gap between bars
ORIGIN_X  = -280     # world-space left edge of the bar group
ORIGIN_Y  = 150      # world-space baseline (bars grow upward, Y+ is down)
MAX_VAL   = max(ARRAY)

STEP_DELAY  = 0.5    # seconds between comparison steps
MERGE_DELAY = 0.8    # seconds to hold a merged-result frame

COL_IDLE   = (0.55, 0.55, 0.55, 1.0)
COL_ACTIVE = (1.0,  0.85, 0.1,  1.0)
COL_SORTED = (0.2,  0.85, 0.4,  1.0)

# -------------------------------------------------------------------
# Scene & camera
# -------------------------------------------------------------------
scene = scene_2d()
camera("cam1", "viewport_1", scene, {})
print("Scene created, camera attached")

# -------------------------------------------------------------------
# Helper - clear and redraw all bars + labels for the current state
# -------------------------------------------------------------------
def draw_array(arr, highlight=(), sorted_indices=()):
    clear_scene(scene.scene_id)
    with scene:
        for i, val in enumerate(arr):
            h  = int((val / MAX_VAL) * BAR_MAX_H) + 10
            cx = ORIGIN_X + i * (BAR_W + SPACING)
            cy = ORIGIN_Y - h / 2      # centre of the bar rect

            if i in highlight:
                col = COL_ACTIVE
            elif i in sorted_indices:
                col = COL_SORTED
            else:
                col = COL_IDLE

            rect((BAR_W, h), (cx, cy), color=col)

            # Value label: world position just above the top of the bar
            world_label(
                f"val_{i}", str(val),
                (cx, ORIGIN_Y - h - 6),
                font_size=14, color=(1, 1, 1, 1),
                scene_id=scene.scene_id
            )

            # Index label: world position just below the baseline
            world_label(
                f"idx_{i}", f"[{i}]",
                (cx, ORIGIN_Y + 8),
                font_size=12, color=(0.7, 0.7, 0.7, 1),
                scene_id=scene.scene_id
            )

# -------------------------------------------------------------------
# Merge sort generator
# -------------------------------------------------------------------
def merge_sort_steps(arr):
    n = len(arr)

    print("Merge sort starting on: " + str(arr))
    draw_array(arr)
    world_label("title", "Merge Sort  -  initial array",
                (-260, -220), font_size=18, color=(1, 1, 1, 1),
                scene_id=scene.scene_id)
    yield wait(MERGE_DELAY)

    width = 1
    pass_num = 1
    while width < n:
        print("--- Pass %d (merge width %d) ---" % (pass_num, width))

        for left in range(0, n, width * 2):
            mid   = min(left + width,     n)
            right = min(left + width * 2, n)

            if mid >= right:
                continue

            print("  Merging subarrays [%d..%d] and [%d..%d]" % (left, mid - 1, mid, right - 1))

            draw_array(arr, highlight=set(range(left, right)))
            world_label("title",
                        "Merging [%d..%d] and [%d..%d]" % (left, mid - 1, mid, right - 1),
                        (-260, -220), font_size=18, color=(1, 0.85, 0.1, 1),
                        scene_id=scene.scene_id)
            yield wait(MERGE_DELAY)

            # Merge step
            left_part  = arr[left:mid]
            right_part = arr[mid:right]
            i = j = 0
            k = left

            while i < len(left_part) and j < len(right_part):
                lv = left_part[i]
                rv = right_part[j]
                print("    Compare %d vs %d" % (lv, rv))

                draw_array(arr, highlight={left + i, mid + j})
                world_label("title",
                            "Compare  %d  vs  %d" % (lv, rv),
                            (-260, -220), font_size=18, color=(1, 0.85, 0.1, 1),
                            scene_id=scene.scene_id)
                yield wait(STEP_DELAY)

                if lv <= rv:
                    arr[k] = lv; i += 1
                else:
                    arr[k] = rv; j += 1
                k += 1

            while i < len(left_part):
                arr[k] = left_part[i]; i += 1; k += 1
            while j < len(right_part):
                arr[k] = right_part[j]; j += 1; k += 1

            merged_slice = arr[left:right]
            print("  Merged result: " + str(merged_slice))

            draw_array(arr, sorted_indices=set(range(left, right)))
            world_label("title",
                        "Merged  ->  " + str(merged_slice),
                        (-260, -220), font_size=18, color=(0.2, 0.85, 0.4, 1),
                        scene_id=scene.scene_id)
            yield wait(MERGE_DELAY)

        width *= 2
        pass_num += 1

    print("Sort complete: " + str(arr))
    draw_array(arr, sorted_indices=set(range(n)))
    world_label("title", "Sorted!",
                (-260, -220), font_size=22, color=(0.2, 0.85, 0.4, 1),
                scene_id=scene.scene_id)

# -------------------------------------------------------------------
# Run
# -------------------------------------------------------------------
run_async(merge_sort_steps(list(ARRAY)))
