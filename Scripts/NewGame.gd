extends NinePatchRect

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	$Condition/Begin.connect("pressed", self, "begin_new_game_pressed")

func begin_new_game_pressed():
	var name = $Condition/LineEdit.get_text()
	singleton.new_game(name)
	if get_node("/root/World/GUI").has_node("GameMenu"):
		get_node("/root/World/GUI/GameMenu").close_menu()
	queue_free()
