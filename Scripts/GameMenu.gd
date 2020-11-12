extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	$LoadScreen/SaveContainer/Load.connect("pressed", self, "load_game")
	$LoadScreen/NewGame.connect("pressed", self, "new_game_pressed")
	var buttons = get_node("Patch9Frame/VBoxContainer").get_children()
	for btn in buttons:
		btn.connect("pressed", self, "button_pressed", [btn])
#	set_process_unhandled_key_input(true)
	get_tree().set_pause(true)

#func _unhandled_key_input(key_event):
#	if key_event.is_action_pressed("ui_cancel"):
#		close_menu()

func button_pressed(btn):
	if btn.get_name() == "Performance":
		var node = preload("res://Scenes/PerformanceScreenNew.tscn").instance()
		get_node("/root/World/GUI").add_child(node)
#		set_process_unhandled_key_input(false)
	elif btn.get_name() == "Conditions":
		var node = preload("res://Scenes/Unlocks.tscn").instance()
		get_node("/root/World/GUI").add_child(node)
#		set_process_unhandled_key_input(false)
	elif btn.get_name() == "Exit":
		close_menu()
	elif btn.get_name() == "Save":
		get_node("/root/singleton").save_game(0)
	elif btn.get_name() == "Load":
		open_load_screen()

var saves = {}
func open_load_screen():
	var container = $LoadScreen/SavedGames/VBoxContainer
	$LoadScreen.show()
	saves = singleton.load_file_as_JSON("user://saved_games.json")
	for save in saves["Saves"]:
		var button = Button.new()
		button.text = save
		button.set_name(save)
		button.rect_min_size = Vector2(0, 26)
		button.connect("pressed", self, "save_selected", [button])
		container.add_child(button)

var selectedLoad = null
func save_selected(button):
	selectedLoad = button.get_name()
	$LoadScreen/SaveContainer.show()

func new_game_pressed():
	var screen = load("res://Scenes/NewGame.tscn").instance()
	get_node("/root/World/GUI").add_child(screen)

func load_game():
	singleton.load_game(saves["Saves"][selectedLoad])
	

func close_menu():
	get_tree().set_pause(false)
	queue_free()



