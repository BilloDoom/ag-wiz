from godot import *

ARRAY = [38, 27, 43, 3, 9, 82, 10, 54]
N = len(ARRAY)

BAR_W     = 60
BAR_MAX_H = 300
SPACING   = 10
ORIGIN_X  = -280
ORIGIN_Y  = 150
MAX_VAL   = max(ARRAY)

ANIM_TIME   = 0.35
HOLD_TIME   = 0.15
MERGE_PAUSE = 0.6

COL_IDLE   = (0.55, 0.55, 0.55, 1.0)
COL_ACTIVE = (1.0,  0.85, 0.1,  1.0)
COL_SORTED = (0.2,  0.85, 0.4,  1.0)

scene = scene_2d()
camera("cam1", "viewport_1", scene, {})
print("Scene created, camera attached")

def col_x(slot):
    return ORIGIN_X + slot * (BAR_W + SPACING)

def bar_height(val):
    return int((val / MAX_VAL) * BAR_MAX_H) + 10

def build_scene(arr):
    slot_to_node = []
    with scene:
        for i in range(N):
            val = arr[i]
            h   = bar_height(val)
            cx  = col_x(i)
            cy  = ORIGIN_Y - h / 2

            rect((BAR_W, h), (cx, cy), color=COL_IDLE, name=f"bar_{i}")
            world_label(f"val_{i}", str(val),
                        (cx, ORIGIN_Y - h - 6),
                        font_size=14, color=(1, 1, 1, 1),
                        scene_id=scene.scene_id)
            world_label(f"idx_{i}", f"[{i}]",
                        (cx, ORIGIN_Y + 8),
                        font_size=12, color=(0.7, 0.7, 0.7, 1),
                        scene_id=scene.scene_id)
            slot_to_node.append(f"bar_{i}")
    print("Bars built: " + str(arr))
    return slot_to_node

def set_title(text, col=(1, 1, 1, 1)):
    world_label("title", text, (-260, -220),
                font_size=18, color=col, scene_id=scene.scene_id)

def node_of(slot, slot_to_node):
    return slot_to_node[slot]

def idx_suffix(node_name):
    return node_name.split("_")[1]

def highlight_slot(slot, slot_to_node, col):
    color_node(node_of(slot, slot_to_node), col, ANIM_TIME * 0.5, scene.scene_id)

def mark_sorted_slots(slots, slot_to_node):
    for s in slots:
        color_node(node_of(s, slot_to_node), COL_SORTED, ANIM_TIME, scene.scene_id)

def reset_slot_colors(slots, slot_to_node):
    for s in slots:
        color_node(node_of(s, slot_to_node), COL_IDLE, ANIM_TIME * 0.5, scene.scene_id)

def animate_swap(slot_a, slot_b, arr, slot_to_node):
    na = node_of(slot_a, slot_to_node)   # e.g. "bar_2"
    nb = node_of(slot_b, slot_to_node)   # e.g. "bar_5"
    ia = idx_suffix(na)                   # "2"
    ib = idx_suffix(nb)                   # "5"

    xa = col_x(slot_a)
    xb = col_x(slot_b)
    ha = bar_height(arr[slot_a])
    hb = bar_height(arr[slot_b])

    # Highlight
    color_node(na, COL_ACTIVE, ANIM_TIME * 0.3, scene.scene_id)
    color_node(nb, COL_ACTIVE, ANIM_TIME * 0.3, scene.scene_id)

    # Slide bars to swapped columns (Y re-centred to each bar's own height)
    move_node(na, (xb, ORIGIN_Y - ha / 2), ANIM_TIME, scene.scene_id)
    move_node(nb, (xa, ORIGIN_Y - hb / 2), ANIM_TIME, scene.scene_id)

    # Slide value labels (their Y tracks the bar top)
    move_node(f"val_{ia}", (xb, ORIGIN_Y - ha - 6), ANIM_TIME, scene.scene_id)
    move_node(f"val_{ib}", (xa, ORIGIN_Y - hb - 6), ANIM_TIME, scene.scene_id)

    # Slide index labels (fixed Y below baseline)
    move_node(f"idx_{ia}", (xb, ORIGIN_Y + 8), ANIM_TIME, scene.scene_id)
    move_node(f"idx_{ib}", (xa, ORIGIN_Y + 8), ANIM_TIME, scene.scene_id)

    return ANIM_TIME + HOLD_TIME

def commit_swap(slot_a, slot_b, arr, slot_to_node):
    arr[slot_a], arr[slot_b] = arr[slot_b], arr[slot_a]
    slot_to_node[slot_a], slot_to_node[slot_b] = slot_to_node[slot_b], slot_to_node[slot_a]

    snap_color_node(node_of(slot_a, slot_to_node), COL_IDLE, scene.scene_id)
    snap_color_node(node_of(slot_b, slot_to_node), COL_IDLE, scene.scene_id)

def merge_sort_steps(arr):
    n = len(arr)
    print("Starting merge sort: " + str(arr))

    slot_to_node = build_scene(arr)
    set_title("Merge Sort  -  initial array")
    yield wait(MERGE_PAUSE)

    width = 1
    pass_num = 1
    while width < n:
        print("--- Pass %d (merge width %d) ---" % (pass_num, width))

        for left in range(0, n, width * 2):
            mid   = min(left + width,     n)
            right = min(left + width * 2, n)
            if mid >= right:
                continue

            print("  Merging slots [%d..%d] with [%d..%d]" % (left, mid - 1, mid, right - 1))
            for s in range(left, right):
                highlight_slot(s, slot_to_node, COL_ACTIVE)
            set_title("Merging [%d..%d] and [%d..%d]" % (left, mid - 1, mid, right - 1),
                      col=(1, 0.85, 0.1, 1))
            yield wait(MERGE_PAUSE)
            reset_slot_colors(range(left, right), slot_to_node)

            # Insertion-merge: each element from right half walks left
            for k in range(mid, right):
                j = k
                while j > left and arr[j] < arr[j - 1]:
                    print("    Swap slots %d<->%d  (values %d, %d)" % (j - 1, j, arr[j - 1], arr[j]))
                    set_title("Swap  %d  <->  %d" % (arr[j - 1], arr[j]),
                              col=(1, 0.85, 0.1, 1))

                    wait_time = animate_swap(j - 1, j, arr, slot_to_node)
                    yield wait(wait_time)
                    commit_swap(j - 1, j, arr, slot_to_node)
                    j -= 1

            merged = arr[left:right]
            print("  Merged result: " + str(merged))
            mark_sorted_slots(range(left, right), slot_to_node)
            set_title("Merged  ->  " + str(merged), col=(0.2, 0.85, 0.4, 1))
            yield wait(MERGE_PAUSE)

        width *= 2
        pass_num += 1

    print("Sort complete: " + str(arr))
    mark_sorted_slots(range(n), slot_to_node)
    set_title("Sorted!", col=(0.2, 0.85, 0.4, 1))

run_async(merge_sort_steps(list(ARRAY)))
