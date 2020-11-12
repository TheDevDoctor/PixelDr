extends Node

onready var screen = get_node("Screen")
onready var VBox = get_node("Screen/ScrollContainer/VBoxContainer")
var dropPosition = false
var countdown

func _ready():
	set_process(true)
	drop_position()
	set_process_unhandled_key_input(true)

func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("ui_interact"):
#		add_label("wdsddvv")
		pass

func _process(delta):
	if dropPosition == true:
		if screen.get_position().y < -10:
			screen.set_position(Vector2(801, screen.get_position().y + 3)) 
		else:
			dropPosition = false
	
	countdown -= delta
	if countdown < 0:
		self.queue_free()
	
func add_label(text, color):
	countdown = 6.0
	
	var label = Label.new()
	label.add_font_override("font", preload("res://Fonts/Nunito_regular16.font"))
	if color == 0:
		label.add_color_override("font_color", Color(0.164734,1,0.070312))
	elif color == 1:
		label.add_color_override("font_color", Color(1,0,0))
#	label.set_autowrap(true)
	label.set_text(text)
	VBox.add_child(label)
	VBox.move_child(label, 0)
	if VBox.get_child_count() > 1 && VBox.get_child_count() < 10:
		screen.set_size(Vector2(467, screen.get_size().y + label.get_size().y + 4))
		screen.set_position(Vector2(801, screen.get_position().y - label.get_size().y)) 
	drop_position()
	
func drop_position():
	dropPosition = true
	