extends Node

signal help_node_interact

#Would be good to try and get this working
func _ready():
	$textHelp.connect("draw", self, "on_item_rect_changed", [$textHelp/Label])
	set_process_unhandled_key_input(true)

func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("ui_interact"):
		emit_signal("help_node_interact")

func on_item_rect_changed(label):
	print("resized")
#	label.set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count()))
	label.get_node("..").set_custom_minimum_size(Vector2(label.get_size().x + 38, 0))
	print(label.get_size().x)
#	label.get_node("..").set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count() + 100))