from godot import *

scene = scene_3d()
camera("cam1", "viewport_1", scene, {"position": (5, 5,10), "zoom": (1.0, 1.0)})

with scene:
    cube = box((2, 2, 2), position=(0, 0, 0), color=(1, 0, 0, 1))
    animate(cube, "position", (5, 0, 0), duration=1)
    animate(cube, "position", (5, 5, 0), duration=1)
    animate(cube, "rotation", (0, 45, 0), duration=1)
    play()