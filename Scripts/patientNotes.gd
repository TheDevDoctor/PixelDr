extends Node

var diffsDict = {}
var diffArray = []
var differentials = []
var currBed = "BED1"

func _ready():
	hide_notes()
	
	#Connect the buttons:
	$NinePatchRect/DifferentialsPatch/Edit.connect("pressed", self, "edit_diffs")
	$NinePatchRect/Button.connect("pressed", self, "open_notes_pressed", [$NinePatchRect/Button])
	$NinePatchRect/NinePatchRect2/DiffsScreen/LineEdit.connect("text_changed", self, "search_diff_text_changed")
	$NinePatchRect/NinePatchRect2/DiffsScreen/DoneButton.connect("pressed", self, "done_pressed")
	set_screen_modulates(0)
	set_screen(0)
	diffsDict = get_node("/root/singleton").load_file_as_JSON("res://JSON_files/conditions.json")
	for key in diffsDict:
		diffArray.append(key)
	diffArray.sort()

func open_notes_pressed(button):
	if button.is_pressed():
		open_notes()
	else:
		hide_notes()

func edit_diffs():
	set_screen_modulates(1)
	set_screen(1)
	
	
func open_notes():
	$NinePatchRect.set_position(Vector2(-3, 2))

func hide_notes():
	$NinePatchRect.set_position(Vector2(-593, 2))

func set_screen(type):
	if type == 0:
		$NinePatchRect/NinePatchRect2/TextEdit.show()
		$NinePatchRect/NinePatchRect2/DiffsScreen.hide()
		$NinePatchRect/DifferentialsPatch/LabelAdds.show()
		$NinePatchRect/DifferentialsPatch/EditDiffs.hide()
	elif type == 1:
		$NinePatchRect/NinePatchRect2/DiffsScreen.show()
		$NinePatchRect/NinePatchRect2/TextEdit.hide()
		$NinePatchRect/DifferentialsPatch/LabelAdds.hide()
		$NinePatchRect/DifferentialsPatch/EditDiffs.show()
		create_diff_buttons(diffArray)

func set_screen_modulates(type):
	if type == 0:
		$NinePatchRect/NinePatchRect2.set_self_modulate(Color(0.898438,0.898438,0.898438))
		$NinePatchRect/DifferentialsPatch.set_self_modulate(Color(0.898438,0.898438,0.898438))
	elif type == 1:
		$NinePatchRect/NinePatchRect2.set_self_modulate(Color(0.15625,0.15625,0.15625))
		$NinePatchRect/DifferentialsPatch.set_self_modulate(Color(0.15625,0.15625,0.15625))


func create_diff_buttons(array, readd = false):
	var container = $NinePatchRect/NinePatchRect2/DiffsScreen/ScrollContainer/VBoxContainer
	if readd == false:
		for btn in container.get_children():
			btn.free()
	for item in array:
		if differentials.has(item) == false:
			var button = preload("res://Scenes/InvestigationButton.tscn").instance()
			button.get_node("Label").set_text(item)
			button.set_name(item)
			button.get_node("Order/Label").set_text("Add")
			button.get_node("Order").connect("pressed", self, "add_differential", [button])
#			if differentials.has(item):
#				button.set_pressed(true)
			container.add_child(button)
	container.get_node("..").set_v_scroll(0)

var array = []
func search_diff_text_changed(text):
	array.clear()
	print(text)
	if text.length() > 0:
		for item in diffArray:
			if text.to_upper() in item.to_upper():
				array.append(item)
		create_diff_buttons(array)
	else:
		create_diff_buttons(diffArray)

func set_bed(bed):
	print("The bed being set is: " + bed)
	currBed = bed
	if singleton.bedNotes[singleton.currentWard][currBed] != null:
		$NinePatchRect/NinePatchRect2/TextEdit.set_text(singleton.bedNotes[singleton.currentWard][currBed])
	if singleton.bedDifferentials[singleton.currentWard][currBed] != null:
		differentials = singleton.bedDifferentials[singleton.currentWard][currBed]
	add_diifs_to_labels()

func add_differential(button):
	var differential = button.get_node("Label").get_text()
	add_to_edit_diffs(differential)
	differentials.append(differential)
	$NinePatchRect/NinePatchRect2/DiffsScreen/ScrollContainer/VBoxContainer.get_node(differential).free()
	print(differentials)

func add_to_edit_diffs(diff):
	var patch = return_diffs_patch(diff)
	$NinePatchRect/DifferentialsPatch/EditDiffs/VBoxContainer.add_child(patch)

func return_diffs_patch(diff):
	var patch = NinePatchRect.new()
	patch.set_texture(load("res://Graphics/UI/baseDataContainer.png"))
	patch.set_name(diff)
	patch.patch_margin_right = 8
	patch.patch_margin_left = 8
	patch.patch_margin_bottom = 8
	patch.patch_margin_top = 8
	patch.self_modulate = Color(0.25,0.25,0.25)
	patch.rect_min_size = Vector2(0,25)
	patch.set_h_size_flags(3)
	
	var cancelButton = TextureButton.new()
	cancelButton.texture_normal = load("res://Graphics/UI/DeleteButton.png")
	cancelButton.texture_hover = load("res://Graphics/UI/DeleteButtonHover.png")
	cancelButton.set_anchors_preset(11)
	cancelButton.margin_left = -25
	patch.add_child(cancelButton)
	cancelButton.connect("pressed", self, "remove_diff", [cancelButton.get_node("..")])
	
	var label = Label.new()
	label.set_anchors_preset(15)
	label.margin_right = -25
	label.margin_left = 5
	label.text = diff
	label.clip_text = true
	label.valign = VALIGN_CENTER
	patch.add_child(label)
	return patch

func done_pressed():
	set_screen(0)
	set_screen_modulates(0)
	add_diifs_to_labels()
	singleton.bedDifferentials[singleton.currentWard][currBed] = differentials

func add_diifs_to_labels():
	for diff in differentials:
		var label = Label.new()
		label.text = " - " + diff
		label.clip_text = true
		label.set_h_size_flags(3)
		label.add_color_override("font_color", Color(0.183594,0.183594,0.183594))
		$NinePatchRect/DifferentialsPatch/LabelAdds/VBoxContainer.add_child(label)

func remove_diff(diff):
	differentials.erase(diff.get_name())
	create_diff_buttons([diff.get_name()], true)
	diff.free()
	print(differentials)

func close_notes():
	save_notes()
	self.queue_free()

func save_notes():
	singleton.bedNotes[singleton.currentWard][currBed] = $NinePatchRect/NinePatchRect2/TextEdit.get_text()
