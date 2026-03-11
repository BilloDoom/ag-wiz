from godot import *
import random

# ─────────────────────────────────────────────────────
#  Greedy Meshing – 2D visualisation
#
#  Phase 1 – Naive mesh: every solid cell is its own
#             filled rect + black outline.
#  Phase 2 – Greedy mesh: rectangles are extended as
#             far as possible before being emitted.
#             Each merged rect appears one at a time.
#
#  Grid generated with a cellular-automata smoothing
#  pass so it looks like chunky terrain, not pure noise.
# ─────────────────────────────────────────────────────

# ── tunables ──────────────────────────────────────────
COLS        = 24
ROWS        = 16
CELL        = 28        # pixel size of one cell
SEED        = 7

ORIGIN_X    = -(COLS * CELL) / 2.0
ORIGIN_Y    = -(ROWS * CELL) / 2.0

PAUSE_PHASE = 2.0       # pause between phases
PAUSE_RECT  = 0.07      # pause per greedy rect drawn

# ── colours ───────────────────────────────────────────
COL_SOLID   = (0.35, 0.60, 0.35, 1.0)
COL_EDGE    = (0.0,  0.0,  0.0,  1.0)
COL_GREEDY  = (0.25, 0.55, 1.0,  1.0)
COL_OUTLINE = (1.0,  1.0,  1.0,  0.7)
COL_TITLE   = (1.0,  1.0,  1.0,  1.0)

# ─────────────────────────────────────────────────────
#  Scene
# ─────────────────────────────────────────────────────
scene = scene_2d()
camera("cam1", "viewport_1", scene, {})

# ─────────────────────────────────────────────────────
#  Grid generation
#  Random fill → 3 rounds of majority-rule smoothing
# ─────────────────────────────────────────────────────
def make_grid(cols, rows, seed):
    rng = random.Random(seed)
    g = [[1 if rng.random() < 0.52 else 0
          for _ in range(cols)] for _ in range(rows)]
    for _ in range(3):
        ng = [[0]*cols for _ in range(rows)]
        for r in range(rows):
            for c in range(cols):
                n = 0
                for dr in (-1, 0, 1):
                    for dc in (-1, 0, 1):
                        nr, nc = r+dr, c+dc
                        if 0 <= nr < rows and 0 <= nc < cols:
                            n += g[nr][nc]
                        else:
                            n += 1
                ng[r][c] = 1 if n >= 5 else 0
        g = ng
    return g

GRID = make_grid(COLS, ROWS, SEED)

# ─────────────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────────────
def cell_tl(c, r):
    """Top-left pixel of cell (c, r)."""
    return (ORIGIN_X + c * CELL, ORIGIN_Y + r * CELL)

def cell_centre(c, r):
    x, y = cell_tl(c, r)
    return (x + CELL * 0.5, y + CELL * 0.5)

def set_title(text):
    world_label("title", text,
                (0, ORIGIN_Y - 30),
                font_size=18, color=COL_TITLE,
                scene_id=scene.scene_id)

# ─────────────────────────────────────────────────────
#  Greedy meshing algorithm
#  Returns list of (col, row, width_cells, height_cells)
# ─────────────────────────────────────────────────────
def greedy_rects(grid, cols, rows):
    merged = [[False]*cols for _ in range(rows)]
    out = []
    for r in range(rows):
        for c in range(cols):
            if not grid[r][c] or merged[r][c]:
                continue
            # extend width
            w = 1
            while c+w < cols and grid[r][c+w] and not merged[r][c+w]:
                w += 1
            # extend height
            h = 1
            while r+h < rows:
                if all(grid[r+h][c+dc] and not merged[r+h][c+dc]
                       for dc in range(w)):
                    h += 1
                else:
                    break
            # mark covered
            for dr in range(h):
                for dc in range(w):
                    merged[r+dr][c+dc] = True
            out.append((c, r, w, h))
    return out

RECTS = greedy_rects(GRID, COLS, ROWS)
SOLID_COUNT = sum(GRID[r][c] for r in range(ROWS) for c in range(COLS))

# ─────────────────────────────────────────────────────
#  Main generator
# ─────────────────────────────────────────────────────
def greedy_viz():

    # ── Phase 1: naive ────────────────────────────────
    set_title("Naive mesh  –  %d quads" % SOLID_COUNT)
    yield wait(0.4)

    with scene:
        for r in range(ROWS):
            for c in range(COLS):
                if not GRID[r][c]:
                    continue
                cx, cy = cell_centre(c, r)
                # filled cell
                rect((CELL, CELL), (cx, cy), color=COL_SOLID)
                # outline (unfilled rect = Line2D border)
                rect((CELL, CELL), (cx, cy),
                     color=COL_EDGE, filled=False)

    yield wait(PAUSE_PHASE)

    # ── Phase 2: greedy ───────────────────────────────
    clear_scene(scene.scene_id)
    set_title("Greedy mesh  –  %d quads" % len(RECTS))
    yield wait(0.4)

    for (c, r, w, h) in RECTS:
        px_w = w * CELL
        px_h = h * CELL
        tl_x, tl_y = cell_tl(c, r)
        cx = tl_x + px_w * 0.5
        cy = tl_y + px_h * 0.5
        with scene:
            rect((px_w, px_h), (cx, cy), color=COL_GREEDY)
            rect((px_w, px_h), (cx, cy),
                 color=COL_OUTLINE, filled=False)
        yield wait(PAUSE_RECT)

    print("naive=%d  greedy=%d  reduction=%.0f%%" % (
          SOLID_COUNT, len(RECTS),
          100.0 * (1.0 - len(RECTS) / max(SOLID_COUNT, 1))))
    yield wait(2.0)


run_async(greedy_viz())
