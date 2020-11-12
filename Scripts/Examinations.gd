extends Node

var examData = {}

func _ready():
	get_node("/root/singleton").load_file_as_JSON("res://JSON_files/examinations.json", examData)
	print_exam_buttons()


func print_exam_buttons():
	for exam in examData:
		var button = Button.new()
		button.set_text(exam)
		button.set_custom_minimum_size(Vector2(0, 50))
		button.set_h_size_flags(3)
		button.set_clip_text(true)
		button.connect("pressed", self, "exam_selected")
		get_node("Patch9Frame/ScrollContainer/GridContainer").add_child(button)

func exam_selected():
	pass
