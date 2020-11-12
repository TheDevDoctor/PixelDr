extends Node

var collectablesDict = {}
var collectablesArray = []

func _ready():
	var collectablesDict = singleton.load_file_as_JSON("res://JSON_files/Collectables.json")
	for item in collectablesDict:
		collectablesArray.append(item)
	collectablesArray.sort()
	add_items()


#func _unhandled_key_input(key_event):
#	if key_event.is_action_pressed("ui_cancel"):
#		close_screen()

func add_items():
	var container = get_node("Patch9Frame/ScrollContainer/VBoxContainer")
	for item in collectablesArray:
		var node = preload("res://Scenes/InvestigationButton.tscn").instance()
		node.set_name(item)
		node.get_node("Label").set_text(item)
		node.get_node("Order/Label").set_text("Collect")
		node.get_node("Order").connect("pressed", self, "collect_item_pressed", [node])
		container.add_child(node)

func close_menu():
	queue_free()
	$"/root/World/playerNode/Player".allow_movement()
	$"/root/World/playerNode/Player".allow_interaction()
	$"/root/World/playerNode/Player".menuOpen = null


func collect_item_pressed(btn):
	get_node("/root/singleton").playerInfo["Inventory"].append(btn.get_name())
	btn.free()