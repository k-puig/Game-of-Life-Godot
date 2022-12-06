extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var cellMap = {}
var previouslyAliveCellArray = []
var visibleSpace = Rect2(0, 0, 0, 0)

var doDraw = true
onready var thisCamera = $"../Camera"

func _draw():
	var size = (get_viewport_rect().size * thisCamera.zoom) / 2
	var cam = thisCamera.position
	
	for cell in previouslyAliveCellArray:
		if Vector2(cell[0], cell[1]) >= visibleSpace.position and Vector2(cell[0], cell[1]) <= (visibleSpace.position + visibleSpace.size):
			draw_rect(Rect2(Vector2(cell[0] * 25, (cell[1] - 1) * 25), Vector2(25, 25)), "CCCCCC")
	
	for cell in cellMap:
		if Vector2(cell[0], cell[1]) >= visibleSpace.position and Vector2(cell[0], cell[1]) <= visibleSpace.position + visibleSpace.size:
			draw_rect(Rect2(Vector2(cell[0] * 25, (cell[1] - 1) * 25), Vector2(25, 25)), "000000")
	
	if doDraw:
		for i in range(int((cam.x - size.x) / 25) - 1, int((size.x + cam.x) / 25) + 1):
			draw_line(Vector2(i * 25, cam.y + size.y + 100), Vector2(i * 25, cam.y - size.y - 100), "555555")
		for i in range(int((cam.y - size.y) / 25) - 1, int((size.y + cam.y) / 25) + 1):
			draw_line(Vector2(cam.x + size.x + 100, i * 25), Vector2(cam.x - size.x - 100, i * 25), "555555")

func _process(delta):
	update()
