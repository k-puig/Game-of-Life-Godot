extends Node2D

var curMousePosition = Vector2()
var prevMousePosition = Vector2()
var prevOffset = Vector2(0, 0)
var curOffset = Vector2(0, 0)

const inputSpeedRate = 15

const zoomNumerator = 100.0
var zoomDenominator = 100.0
var generations = 0

onready var anchorCamera = $AnchorCamera
onready var thisCamera = $Camera
onready var grid = $Grid
onready var text = $GUILayer/GUI/Text

var isProcessing = false

var cellMap = {}
var previouslyAliveCellArray = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

var fastForwarding = false
var prevFrameElapsed = 0.0
var frameElapsed = 0.0

func advance_game():
	var aliveCells = []
	var deadCells = []
	
	for cell in cellMap:
		aliveCells.append(cell)
		for k in range(0, 9):
			var offset = [(k % 3) - 1, (k / 3) - 1]
			if offset[0] == 0 and offset[1] == 0:
				continue
			if !cellMap.has([cell[0] + offset[0], cell[1] + offset[1]]):
				deadCells.append([cell[0] + offset[0], cell[1] + offset[1]])
	
	var newMap = {}
	
	for cell in aliveCells:
		var liveCount = 0
		for k in range(0, 9):
			var offset = [(k % 3) - 1, (k / 3) - 1]
			if offset[0] == 0 and offset[1] == 0:
				continue
			var otherIsLive = cellMap.has([cell[0] + offset[0], cell[1] + offset[1]])
			if otherIsLive:
				liveCount += 1
		if liveCount == 2 or liveCount == 3:
			newMap[cell] = cell
	
	for cell in deadCells:
		var liveCount = 0
		for k in range(0, 9):
			var offset = [(k % 3) - 1, (k / 3) - 1]
			if offset[0] == 0 and offset[1] == 0:
				continue
			var otherIsLive = cellMap.has([cell[0] + offset[0], cell[1] + offset[1]])
			if otherIsLive:
				liveCount += 1
		if liveCount == 3:
			newMap[cell] = cell
	
	for cell in cellMap:
		if cellMap.has(cell) and !newMap.has(cell):
			previouslyAliveCellArray.append(cell)
	
	generations += 1
	
	cellMap = newMap


func get_zoom():
	return pow(zoomNumerator / zoomDenominator, 2)

func get_visible_space():
	var size = get_viewport_rect().size * thisCamera.zoom
	var cam = thisCamera.position - (get_viewport_rect().size * thisCamera.zoom) / 2
	return Rect2((cam / 25).floor(), (size / 25).ceil())

var advanceGameElapsed = 0.0
var curSpeed = 1

func randomize_cellmap():
	randomize()
	cellMap = {}
	var cell_space = get_visible_space()
	for i in range(int(ceil(cell_space.position.x)), int(floor(cell_space.position.x + cell_space.size.x))):
		for j in range(int(ceil(cell_space.position.y)), int(floor(cell_space.position.y + cell_space.size.y))):
			if randi() % 2 == 1:
				cellMap[[i, j]] = [i, j]

var speedInputElapsed = 0.0
var firstSpeedInputElapsed = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	prevMousePosition = curMousePosition
	curMousePosition = anchorCamera.get_global_mouse_position() - thisCamera.position
	
	if Input.is_action_pressed("rightclick"):
		thisCamera.position -= curMousePosition - prevMousePosition
	elif Input.is_action_just_released("rightclick"):
		anchorCamera.position = thisCamera.position
	else:
		if Input.is_action_pressed("zoom_in"):
			zoomDenominator += 50 * delta
		if Input.is_action_pressed("zoom_out"):
			zoomDenominator -= 50 * delta
		zoomDenominator = clamp(zoomDenominator, 1.0, 100.0*sqrt(5))
		thisCamera.zoom.x = get_zoom()
		thisCamera.zoom.y = get_zoom()
		
		if Input.is_action_just_pressed("fast_forward"):
			fastForwarding = !fastForwarding
		if Input.is_action_just_pressed("advance_game"):
			advance_game()
		
		if Input.is_action_just_pressed("decrease_speed"):
			curSpeed -= 1
		if Input.is_action_just_pressed("increase_speed"):
			curSpeed += 1
		
		if Input.is_action_pressed("decrease_speed"):
			firstSpeedInputElapsed += delta
			if firstSpeedInputElapsed > 0.5:
				speedInputElapsed += inputSpeedRate * delta
			while speedInputElapsed > 1.0 and firstSpeedInputElapsed > 0.5:
				speedInputElapsed -= 1.0
				curSpeed -= 1
		elif Input.is_action_pressed("increase_speed"):
			firstSpeedInputElapsed += delta
			if firstSpeedInputElapsed > 0.5:
				speedInputElapsed += inputSpeedRate * delta
			while speedInputElapsed > 1.0 and firstSpeedInputElapsed > 0.5:
				speedInputElapsed -= 1.0
				curSpeed += 1
		else:
			speedInputElapsed = 0.0
			firstSpeedInputElapsed = 0.0
		
		curSpeed = clamp(curSpeed, 1, 120)
		
		if fastForwarding:
			advanceGameElapsed += curSpeed * delta
			while advanceGameElapsed > 1.0:
				advanceGameElapsed -= 1.0
				advance_game()
			
		else: 
			advanceGameElapsed = 0.0
		
		if !fastForwarding:
			if Input.is_action_just_pressed("leftclick"):
				var mouse_cell = [int(floor(get_local_mouse_position().x / 25)), 1 + int(floor(get_local_mouse_position().y / 25))]
				if !cellMap.has(mouse_cell):
					cellMap[mouse_cell] = mouse_cell
				else:
					cellMap.erase(mouse_cell)
				
			
			if Input.is_action_just_pressed("randomize"):
				generations = 0
				randomize_cellmap()
				previouslyAliveCellArray = []
				
			if Input.is_action_just_pressed("clear"):
				generations = 0
				cellMap = {}
				previouslyAliveCellArray = []
	
	if get_zoom() >= 5.0:
		grid.doDraw = false
	else:
		grid.doDraw = true
	
	text.text = "Z:Decrease Speed, X:Increase Speed, C:Clear Screen, R:Randomize, Up:Zoom in, Down:Zoom out\nSpace:Toggle constant iteration, Right:Next iteration, LeftClick:Toggle cell, RightClick:Drag screen\n" + str(generations) + " iterations" + "\n" + str(curSpeed) + " iterations/second"
	if fastForwarding:
		text.text += " (currently iterating)"
	text.text += "\nZoom:" + str(1.0 / get_zoom()) + "x"
	
	while previouslyAliveCellArray.size() > 500:
		previouslyAliveCellArray.remove(0)
	
	grid.cellMap = cellMap
	grid.previouslyAliveCellArray = previouslyAliveCellArray
	grid.visibleSpace = get_visible_space()
