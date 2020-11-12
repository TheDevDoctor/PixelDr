extends NinePatchRect

var diffArray = []
var differentials = []
var conditions = {}
var currentBed = null

func _ready():
	$diffsSearchList/Done.connect("pressed", self, "done_pressed")
	$edit.connect("pressed", self, "edit_diffs")

	conditions = get_node("/root/singleton").load_file_as_JSON("res://JSON_files/conditions.json")
	for key in conditions:
		diffArray.append(key)
	diffArray.sort()
	set_screen(0)

#	if get_node("../..").currentBed != null:
#		currentBed = get_node("../..").currentBed


func done_pressed():
	currentCont = 0
	clear_container($editDiffs/HBoxContainer/VBoxContainer)
	clear_container($editDiffs/HBoxContainer/VBoxContainer2)
	set_screen(0)
	add_diifs_to_labels()

func set_screen(type):
	if type == 0:
		$notes.show()
		$diffsSearchList.hide()
		$Label.show()
		$diffLabels.show()
		$editDiffs.hide()
	elif type == 1:
		$notes.hide()
		$diffsSearchList.show()
		$Label.hide()
		$diffLabels.hide()
		$editDiffs.show()
		create_diff_buttons(diffArray)

func create_diff_buttons(array, readd = false):
	var container = $diffsSearchList/ScrollCont/VBoxContainer
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

func add_differential(button):
	var differential = button.get_node("Label").get_text()
	add_to_edit_diffs(differential)
	singleton.bedDifferentials[singleton.currentWard][get_node("../..").currentBed].append(differential)
	if $diffsSearchList/ScrollCont/VBoxContainer.has_node(differential):
		$diffsSearchList/ScrollCont/VBoxContainer.get_node(differential).free()

func edit_diffs():
	for diff in singleton.bedDifferentials[singleton.currentWard][get_node("../..").currentBed]:
		add_to_edit_diffs(diff)
	set_screen(1)
	clear_container($diffLabels/HBoxContainer/VBoxContainer)
	clear_container($diffLabels/HBoxContainer/VBoxContainer2)

var currentCont = 0
func add_to_edit_diffs(diff):
	var patch = return_diffs_patch(diff)
	$editDiffs/HBoxContainer.get_child(currentCont).add_child(patch)
	if currentCont == 0:
		currentCont = 1
	else:
		currentCont = 0

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

func add_diifs_to_labels():
	for diff in singleton.bedDifferentials[singleton.currentWard][get_node("../..").currentBed]:
		print(diff)
		var label = Label.new()
		label.text = " - " + diff
		label.clip_text = true
		label.set_h_size_flags(3)
		label.add_color_override("font_color", Color(0.9,0.9,0.9))
		$diffLabels/HBoxContainer.get_child(currentCont).add_child(label)
		if currentCont == 0:
			currentCont = 1
		else:
			currentCont = 0
	currentCont = 0

func clear_container(cont):
	if cont.get_child_count() > 0:
		for child in cont.get_children():
			child.free()

func remove_diff(diff):
	singleton.bedDifferentials[singleton.currentWard][get_node("../..").currentBed].erase(diff.get_name())
	create_diff_buttons([diff.get_name()], true)
	diff.free()
	print(differentials)

func set_notes():
	if singleton.bedNotes[singleton.currentWard][get_node("../..").currentBed] != null:
		$notes.set_text(singleton.bedNotes[singleton.currentWard][get_node("../..").currentBed])
	else:
		$notes.set_text("")
	add_diifs_to_labels()

func save_notes():
	singleton.bedNotes[singleton.currentWard][get_node("../..").currentBed] = $notes.get_text()


