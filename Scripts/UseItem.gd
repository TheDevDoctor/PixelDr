extends Node

signal closed
signal item_used 

var bedProcedures 
onready var collectablesDict = singleton.load_file_as_JSON("res://JSON_files/Collectables.json")

func _ready():
	add_inventory()
	set_process_unhandled_key_input(true)
	bedProcedures = singleton.bedStories[singleton.currentWard][singleton.target][0]["Answers"]["Procedures"]

func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("ui_cancel") && get_node("/root/World/playerNode/Player").canCancel == true:
		close_item_screen()

func add_inventory():
	var container = $Patch9Frame/ScrollContainer/VBoxContainer
	for item in singleton.playerInfo["Inventory"]:
		var button = preload("res://Scenes/InvestigationButton.tscn").instance()
		button.set_name(item)
		button.get_node("Label").set_text(item)
		button.get_node("Order/Label").set_text("Use")
		button.get_node("Order").connect("pressed", self, "use_item_pressed", [button.get_name()])
		container.add_child(button)
		

func use_item_pressed(item):
	emit_signal("item_used")
	$Patch9Frame/ScrollContainer.hide()
	$Patch9Frame/Label.hide()
	$Patch9Frame/RichTextLabel.show()
	var text = ""
	if bedProcedures.has(item):
		$Patch9Frame/RichTextLabel.bbcode_text = bedProcedures[item]
	else:
		$Patch9Frame/RichTextLabel.bbcode_text = collectablesDict[item]["Detail"]
	if singleton.bedProcedures[singleton.currentWard][$"/root/World/playerNode/Player".target.get_name()] == null:
		singleton.bedProcedures[singleton.currentWard][$"/root/World/playerNode/Player".target.get_name()] = [item]
	else:
		singleton.bedProcedures[singleton.currentWard][$"/root/World/playerNode/Player".target.get_name()].append(item)
	singleton.playerInfo["Inventory"].erase(item)

func close_item_screen():
	emit_signal("closed")
	get_node("/root/World/playerNode/Player").allow_movement()
	get_node("/root/World/playerNode/Player").zoom_out()
	get_node("/root/World/playerNode/Player").menuOpen = null
	$Patch9Frame.hide()
	get_node("/root/World/GUI/notes").close_notes()
	yield(get_node("/root/World/playerNode/Player"), "zoomed_out")
	get_node("/root/World/playerNode/Player").allow_interaction()
	queue_free()
