extends Node

signal time_delay_complete
signal door_open

var floorTiles
var behindTiles
var frontTiles
var player 
var timer = 0.0
var thread = Thread.new()

func _ready():
	floorTiles = $FloorTiles
	behindTiles = $BehindTiles
	frontTiles = $FrontTiles
	player = get_node("/root/World/playerNode/Player")

func _process(delta):
	if timer > 0.0:
		timer -= delta
		if timer <= 0:
			emit_signal("time_delay_complete")


func open_door(x, y):
	emit_signal("door_open")
	print(x)
	print(y)
	for i in range(4):
		print(i)
		set_timer(0.1)
		yield(self, "time_delay_complete")
		behindTiles.set_cell(x, y, behindTiles.get_cell(x, y) + 1)
		behindTiles.set_cell(x + 1, y, behindTiles.get_cell(x + 1, y) + 1)
		frontTiles.set_cell(x, y-1, frontTiles.get_cell(x, y-1) + 1)
		frontTiles.set_cell(x+1, y-1, frontTiles.get_cell(x+1, y-1) + 1)
	set_timer(5)
	yield(self, "time_delay_complete")
	door_close(x,y)

func door_close(x, y):
#	print("door_close")
	var pos = behindTiles.map_to_world(Vector2(x, y))
	print(pos)
	while player.get_position().y > pos.y && player.get_position().y < pos.y + 32:
		set_timer(0.5)
		yield(self, "time_delay_complete")
	for i in range(4):
		set_timer(0.1)
		yield(self, "time_delay_complete")
		behindTiles.set_cell(x, y, behindTiles.get_cell(x, y) - 1)
		behindTiles.set_cell(x + 1, y, behindTiles.get_cell(x + 1, y) - 1)
		frontTiles.set_cell(x, y-1, frontTiles.get_cell(x, y-1) - 1)
		frontTiles.set_cell(x+1, y-1, frontTiles.get_cell(x+1, y-1) - 1)

	set_process(false)
	

func set_timer(time):
	set_process(true)
	timer = time