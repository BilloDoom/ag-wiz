from godot import *
import random

# ─────────────────────────────────────────────
#  Octree visualisation (3D)
#  Points are inserted one-by-one into an octree
#  whose domain is centred on the world origin.
#  Each subdivision flashes orange then reveals
#  8 child wireframe cells.
# ─────────────────────────────────────────────

# ── tunables ──────────────────────────────────
DOMAIN        = 4.0    # half-extent of root cell (full cube is 8×8×8)
MAX_DEPTH     = 5      # hard cap – prevents infinite subdivision
CAPACITY      = 1      # max points per leaf before splitting
NUM_POINTS    = 20     # total points to insert
INSERT_PAUSE  = 0.55   # seconds between insertions
SPLIT_PAUSE   = 0.22   # pause for subdivision flash
MIN_DIST      = 0.60   # minimum distance between any two generated points

# ── colours ───────────────────────────────────
COL_ROOT      = (0.35, 0.35, 0.35, 1.0)   # root wireframe (grey)
COL_CELL      = (0.25, 0.55, 1.0,  1.0)   # child cell wireframe (blue)
COL_FLASH     = (1.0,  0.45, 0.1,  1.0)   # subdivision flash (orange)
COL_POINT_NEW = (1.0,  0.85, 0.15, 1.0)   # incoming point (yellow)

# ── scene / camera ────────────────────────────
scene = scene_3d()
camera("cam1", "viewport_1", scene, {
    "position":       (8, 6, 12),   # initial camera position
    "orbit_controls": True,          # enable left-drag orbit + scroll zoom
})

# ─────────────────────────────────────────────
#  Wireframe helper – draws the 12 edges of an
#  axis-aligned cube centred at (cx, cy, cz)
#  with half-extent h, using PRIMITIVE_LINES.
# ─────────────────────────────────────────────

def draw_wire_box(cx, cy, cz, h, color):
    r, g, b, a = color
    # 8 corners
    corners = [
        (cx-h, cy-h, cz-h), (cx+h, cy-h, cz-h),
        (cx+h, cy+h, cz-h), (cx-h, cy+h, cz-h),
        (cx-h, cy-h, cz+h), (cx+h, cy-h, cz+h),
        (cx+h, cy+h, cz+h), (cx-h, cy+h, cz+h),
    ]
    # 12 edges: bottom face, top face, 4 vertical pillars
    edges = [
        (0,1),(1,2),(2,3),(3,0),   # bottom ring
        (4,5),(5,6),(6,7),(7,4),   # top ring
        (0,4),(1,5),(2,6),(3,7),   # verticals
    ]

    verts = []
    for (a_i, b_i) in edges:
        verts.append(corners[a_i])
        verts.append(corners[b_i])

    with scene:
        mb = mesh_builder_3d()
        mb["begin"](1)   # 1 = Mesh.PRIMITIVE_LINES
        mb["set_color"]((r, g, b, a))
        for (x, y, z) in verts:
            mb["add_vertex"]((x, y, z))
        mb["end"]()


# ─────────────────────────────────────────────
#  Octree data structure
# ─────────────────────────────────────────────

class OctNode:
    def __init__(self, cx, cy, cz, half, depth=0):
        self.cx, self.cy, self.cz = cx, cy, cz
        self.half     = half
        self.depth    = depth
        self.points   = []    # (x,y,z) stored here (leaf only)
        self.children = None  # list[8] once subdivided

    def is_leaf(self):
        return self.children is None

    def octant_index(self, x, y, z):
        return ((1 if x >= self.cx else 0) |
                (2 if y >= self.cy else 0) |
                (4 if z >= self.cz else 0))


def subdivide(node):
    """Split node into 8 children and migrate existing points."""
    h  = node.half / 2.0
    cx, cy, cz = node.cx, node.cy, node.cz
    node.children = []
    for i in range(8):
        dx = +h if (i & 1) else -h
        dy = +h if (i & 2) else -h
        dz = +h if (i & 4) else -h
        child = OctNode(cx+dx, cy+dy, cz+dz, h, node.depth+1)
        node.children.append(child)
    for pt in node.points:
        node.children[node.octant_index(*pt)].points.append(pt)
    node.points = []


# ─────────────────────────────────────────────
#  Point generation with minimum-distance guard
# ─────────────────────────────────────────────

def generate_points(n, domain, min_dist, seed=42):
    rng = random.Random(seed)
    pts = []
    attempts = 0
    while len(pts) < n:
        attempts += 1
        if attempts > 50000:
            print("Warning: placed only %d / %d points" % (len(pts), n))
            break
        x = rng.uniform(-domain * 0.88, domain * 0.88)
        y = rng.uniform(-domain * 0.88, domain * 0.88)
        z = rng.uniform(-domain * 0.88, domain * 0.88)
        if all(((x-px)**2+(y-py)**2+(z-pz)**2)**0.5 >= min_dist
               for (px,py,pz) in pts):
            pts.append((x, y, z))
    return pts


# ─────────────────────────────────────────────
#  Main animation generator
# ─────────────────────────────────────────────

def octree_viz():
    points = generate_points(NUM_POINTS, DOMAIN, MIN_DIST)
    print("Generated %d points" % len(points))

    # Draw root wireframe centred at origin
    root = OctNode(0.0, 0.0, 0.0, DOMAIN)
    draw_wire_box(0, 0, 0, DOMAIN, COL_ROOT)

    yield wait(INSERT_PAUSE)

    for i, (px, py, pz) in enumerate(points):
        print("Inserting point %d / %d  (%.2f, %.2f, %.2f)" % (
              i+1, len(points), px, py, pz))

        # Place incoming sphere (yellow)
        with scene:
            sphere(0.10, position=(px, py, pz), color=COL_POINT_NEW)

        yield wait(INSERT_PAUSE * 0.35)

        # Walk tree – subdivide leaves that are full
        node = root
        while True:
            if node.is_leaf():
                if len(node.points) < CAPACITY or node.depth >= MAX_DEPTH:
                    node.points.append((px, py, pz))
                    break
                # Leaf is full and not at depth cap → subdivide
                print("  Split depth=%d  c=(%.1f,%.1f,%.1f)" % (
                      node.depth, node.cx, node.cy, node.cz))
                # Flash cell orange
                draw_wire_box(node.cx, node.cy, node.cz, node.half, COL_FLASH)
                yield wait(SPLIT_PAUSE)

                subdivide(node)

                # Draw 8 child wireframes
                for child in node.children:
                    draw_wire_box(child.cx, child.cy, child.cz,
                                  child.half, COL_CELL)
                yield wait(SPLIT_PAUSE)
                # fall through to descend

            idx  = node.octant_index(px, py, pz)
            node = node.children[idx]

        yield wait(INSERT_PAUSE * 0.65)

    print("Done – all %d points inserted." % len(points))
    yield wait(1.2)


run_async(octree_viz())
