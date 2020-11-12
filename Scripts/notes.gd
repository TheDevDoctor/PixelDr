extends Node

onready var movePanel = $Notes/MovePanel
onready var notesPanel = $Notes
onready var resizeArea = $Notes/resizeArea
var mousePressed = false
var movable = false
var resize = false
var prevPos = Vector2(0, 0)

func _ready():
	movePanel.connect("mouse_entered", self, "on_mouse_entered")
	movePanel.connect("mouse_exited", self, "on_mouse_exited")
	resizeArea.connect("mouse_entered", self, "on_resize_entered")
	resizeArea.connect("mouse_exited", self, "on_resize_exited")
	
	$notesButton.connect("pressed", self, "on_button_pressed")
	$Notes/back.connect("pressed", self, "on_back_pressed")

func _process(delta):
	if mousePressed and movable:
		var pos = notesPanel.get_global_mouse_position()
		var panelSize = movePanel.get_size()
		if pos.x > 20 && pos.x < 1260 && pos.y > 20 && pos.y < 600:
			notesPanel.set_global_position(notesPanel.get_global_mouse_position() - (panelSize/2))
	elif mousePressed and resize:
		var panelSize = movePanel.get_size()
		var pos = get_viewport().get_mouse_position()
		if pos.x < 1260 && pos.y < 700:
			print("pos: " + str(pos) + ", notes panel pos: " + str(notesPanel.get_position()) + ", notes panel size: " + str(notesPanel.get_size()), ", notes panel end: " + str(notesPanel.get_end()))
			notesPanel.set_end(pos + Vector2(20, 20))
		
func _input(event):
	if event is InputEventMouseButton:
		if  (event.button_index == BUTTON_LEFT and event.pressed):  
			mousePressed = true
		elif  (event.button_index == BUTTON_LEFT and !event.pressed): 
			mousePressed = false

func on_mouse_entered():
	print(movePanel.get_local_mouse_position())
	movable = true
	movePanel.show_behind_parent = false
	$Notes/Label.hide()

func on_mouse_exited():
	movable = false
	movePanel.show_behind_parent = true
	$Notes/Label.show()

func on_button_pressed():
	notesPanel.show()
	$notesButton.hide()

func on_back_pressed():
	notesPanel.hide()
	$notesButton.show()

func close_notes():
	queue_free()

func on_resize_entered():
	resizeArea.set_modulate(Color(0.109804,0.407843,0.682353))
	resize = true

func on_resize_exited():
	resize = false
	resizeArea.set_modulate(Color(0.058824,0.27451,0.478431))