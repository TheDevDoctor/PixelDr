extends Node

signal bleep_sent

var printString = ""
var bleepDict = {"5478": "Cath Lab", "1456":"Surgical Reg."}
var extentionDict = {"12843": "EMERGENCY DEPARTMENT"}
onready var printOutLabel = get_node("Patch9Frame/ScrollContainer/PrintOut")

func _ready():
	for btn in get_node("Patch9Frame/GridContainer").get_children():
		btn.connect("pressed", self, "number_pressed", [btn])
	for btn in get_node("Patch9Frame/HBoxContainer").get_children():
		btn.connect("pressed", self, "backClear_pressed", [btn])

	var directoryBtn = get_node("Patch9Frame/DirectoryBtn")
	directoryBtn.set_toggle_mode(true)
	directoryBtn.connect("pressed", self, "open_close_directory", [directoryBtn])
	
	set_process_unhandled_key_input(true)

func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("number_pressed"):
		printString += OS.get_scancode_string(key_event.scancode)
		set_print_out(printString)
	elif key_event.is_action_pressed("ui_delete"):
		delete_number()

func number_pressed(number):
	if number.get_name() == "#":
		if printString.length() == 9:
			retrieve_bleep()
	else:
		printString += number.get_name()
		set_print_out(printString)

func set_print_out(string):
	printOutLabel.set_text(string)

func backClear_pressed(btn):
	if btn.get_name() == "Backspace":
		delete_number()

	else:
		printString = ""
		set_print_out(printString)

func delete_number():
	var asciiString = printString.to_ascii()
	asciiString.remove(asciiString.size() - 1)
	printString = asciiString.get_string_from_ascii()
	set_print_out(printString)

func retrieve_bleep():
	var asciiString = printString.to_ascii()
	var extensionInput = PoolByteArray()
	var bleepInput = PoolByteArray()
	for i in range(5):
		extensionInput.append(asciiString[i])
	for i in range(4):
		bleepInput.append(asciiString[i + 5])
	
	check_bleep(extensionInput.get_string_from_ascii(), bleepInput.get_string_from_ascii())

func check_bleep(ext, bleep):
	if extentionDict.has(ext) && bleepDict.has(bleep):
		successful_bleep(bleepDict[bleep], extentionDict[ext])
	else:
		print("Bleed Unsuccesful")
	printString = ""

func successful_bleep(location, phone):
	printOutLabel.add_color_override("font_color", Color(0.359528,0.984375,0.18457))
	printOutLabel.set_text(location + " Success")
	get_node("Patch9Frame/ScrollContainer").set_h_scroll(1)
	add_bleep_to_singleton(location, phone)
	emit_signal("bleep_sent")

func add_bleep_to_singleton(location, phone):
	print(location)
	if get_node("/root/singleton").bedBleeps[get_node("/root/singleton").currentWard].has(location) == false:
		get_node("/root/singleton").bedBleeps[get_node("/root/singleton").currentWard][location] = [randi()%5+10, phone]
		print(get_node("/root/singleton").bedBleeps[get_node("/root/singleton").currentWard])

func open_close_directory(btn):
	if btn.is_pressed():
		get_node("Directory").show()
	else:
		get_node("Directory").hide()

func close_menu():
	$"/root/World/playerNode/Player".allow_movement()
	$"/root/World/playerNode/Player".allow_interaction()
	get_node("/root/World/playerNode/Player").menuOpen = null
	queue_free()