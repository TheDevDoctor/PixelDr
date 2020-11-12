extends Node

var currBed = null
var diffArray = []
var differentials = []
var previousDiffs = []
var diffsOpen = false

func _ready():
	set_process_unhandled_key_input(true)
	
	var diffDict = {}
	diffDict = get_node("/root/singleton").load_file_as_JSON("res://JSON_files/conditions.json")
	
	for key in diffDict:
		diffArray.append(key)
	diffArray.sort()
	
	get_node("Container/addDiffButton").connect("pressed", self, "open_diff_screen")
	get_node("Container/addDiffButton/addDiffScreen/search").connect("text_changed", self, "search_diff_text_changed")
	var addDiffButtons = get_node("Container/addDiffButton/addDiffScreen/Patch9Frame/HBoxContainer").get_children()
	for btn in addDiffButtons:
		btn.connect("pressed", self, "add_diff_btn_pressed", [btn])
	var button = get_node("Container/TextureButton")
	button.set_toggle_mode(true)
	button.set_pressed(false)
	button.set_focus_mode(0)
	button.connect("pressed", self, "open_notes_pressed", [button])
	set_notes()
	set_labels()
	
	hide_diffs_screen()

func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("ui_cancel"):
		handle_cancel()

func open_notes_pressed(btn):
	if btn.is_pressed() == true:
		$Container.set_position(Vector2(-5, 0))
		get_node("/root/World/DialogueParser").canInteract = false
	else:
		$Container.set_position(Vector2(-5, -478))
		get_node("/root/World/DialogueParser").canInteract = true

func set_bed(bed):
	currBed = bed

func close_notes():
	save_notes()
	self.queue_free()

func save_notes():
	var textNodes = get_node("Container/ScrollContainer/Patch9Frame/textEdits").get_children()
	for i in range(3):
		var text = textNodes[i].get_text()
		get_node("/root/singleton").bedNotes[get_node("/root/singleton").currentWard][currBed][i] = text

func set_notes():
	var textNodes = get_node("Container/ScrollContainer/Patch9Frame/textEdits").get_children()
	for i in range(3):
		var text = get_node("/root/singleton").bedNotes[get_node("/root/singleton").currentWard][currBed][i]
		textNodes[i].set_text(text)

func set_labels():
	var patientDetails = get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][currBed][0]["PatientDetails"]
	get_node("Container/ScrollContainer/Patch9Frame/PatientInfo/PatientName").set_text("NAME: " + patientDetails["Forename"] + " " + patientDetails["Surname"])
	get_node("Container/ScrollContainer/Patch9Frame/PatientInfo/DateOfBirth").set_text("DOB: " + patientDetails["DateOfBirth"])
	get_node("Container/ScrollContainer/Patch9Frame/PatientInfo/HospitalNumber").set_text("HOSP. NUM: " + patientDetails["HospitalNumber"])

func open_diff_screen():
	print("enter")
	get_node("Container/addDiffButton/addDiffScreen").show()
	get_node("Container/addDiffButton/diffScreenAnimation").play("diff_screen_anim")
	create_diff_buttons(diffArray)
	diffsOpen = true
	
	
func search_diff_text_changed(text):
	var array = []
	if text.length() > 0:
		for item in diffArray:
			if text.to_upper() in item.to_upper():
				array.append(item)
	else:
		array = diffArray
	create_diff_buttons(array)

func create_diff_buttons(array):
	var container = get_node("Container/addDiffButton/addDiffScreen/Patch9Frame/ScrollContainer/VBoxContainer")
	for btn in container.get_children():
		if btn.get_name() != "Control":
			btn.free()
	for item in array:
		var button = Button.new()
		button.set_h_size_flags(3)
		button.add_font_override("font", preload("res://Fonts/Nunito_regular12.font"))
		button.set_text(item)
		button.set_name(item)
		button.set_text_align(0)
		button.set_clip_text(true)
		button.set_toggle_mode(true)
		button.connect("pressed", self, "differential_button_toggled", [button])
		if differentials.has(item):
			button.set_pressed(true)
		container.add_child(button)
	container.get_node("..").set_v_scroll(0)

func differential_button_toggled(btn):
	if btn.is_pressed():
		differentials.append(btn.get_name())
	else:
		differentials.erase(btn.get_name())
	
func add_diff_btn_pressed(btn):
	if btn.get_name() == "Add":
		if differentials.size() > 0:
			var previousDiffs = get_node("/root/singleton").bedDifferentials[get_node("/root/singleton").currentWard][currBed]
			var prevDiffsStr = create_diff_string(previousDiffs)
			var diffsStr = create_diff_string(differentials)
			#Continue from here: 
			set_diff_text(diffsStr, prevDiffsStr)
			hide_diffs_screen()
	elif btn.get_name() == "Clear":
		if differentials.size() > 0:
			clear_differentials()

func create_diff_string(array):
	if array.size() > 0:
		var string = "\n\nDifferentials:\n"
		for differential in array:
			string += "  - " + differential + "\n"
		return string
	else:
		return ""

func set_diff_text(diffString, prevDiffs):
	var currText = get_node("Container/ScrollContainer/Patch9Frame/textEdits/TextEdit").get_text()
	if prevDiffs.length() > 0:
		currText = currText.replace(prevDiffs, diffString)
		print(prevDiffs)
	else:
		currText += diffString
	get_node("Container/ScrollContainer/Patch9Frame/textEdits/TextEdit").set_text(currText)
	set_prev_diffs()

func set_prev_diffs():
	get_node("/root/singleton").bedDifferentials[get_node("/root/singleton").currentWard][currBed].clear()
	for diff in differentials:
		get_node("/root/singleton").bedDifferentials[get_node("/root/singleton").currentWard][currBed].append(diff)

func handle_cancel():
	hide_diffs_screen()

func clear_differentials():
	differentials.clear()
	search_diff_text_changed(get_node("Container/addDiffButton/addDiffScreen/search").get_text())

func hide_diffs_screen():
	get_node("Container/addDiffButton/addDiffScreen").hide()
	diffsOpen = false
