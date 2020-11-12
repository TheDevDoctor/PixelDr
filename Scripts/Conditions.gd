extends NinePatchRect

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var searchArray = []
var currentCondition
var conditions
var conditionOpen = false


func _ready():
	conditions = singleton.load_file_as_JSON("res://JSON_files/conditions.json")
	$Condition/NinePatchRect/NinePatchRect2/ClinFeat/ClinFeat.bbcode_text = "this it the jsds d\n\n This should be a new line"
	#Build the search array:
	for con in conditions:
		searchArray.append(con)
	searchArray.sort()
	
	$Condition/Back.connect("pressed", self, "back_pressed")

	add_condition_buttons(searchArray)
	
	$ConditionsList/TopBar/LineEdit.connect("text_changed", self, "form_search_array")
	$ConditionsList/ScrollContainer/GridContainer.columns = (searchArray.size()/5) + 1
	
	set_process_input(true)
	set_process_unhandled_key_input(true)

func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("ui_cancel"):
		close_menu()

func _input(event):
	if event is InputEventMouseButton:
		if  (event.button_index == BUTTON_LEFT and event.pressed):
			if currentCondition != null && conditionOpen == false:
				load_condition_data()

func form_search_array(text):
	singleton.clear_container($ConditionsList/ScrollContainer/GridContainer)
	if text.length() > 0:
		var array = []
		for i in range(0, searchArray.size() - 1):
			if text.to_upper() in searchArray[i].to_upper():
				array.append(searchArray[i])
		add_condition_buttons(array)
	else:
		add_condition_buttons(searchArray)

func add_condition_buttons(array):
	for con in array:
		var patch = preload("res://Scenes/ConditionButton.tscn").instance()
		patch.get_node("Label").set_text(con)
		patch.set_name(con)
		patch.connect("mouse_entered", self, "condition_patch_entered", [patch])
		patch.connect("mouse_exited", self, "condition_patch_exited", [patch])
		$ConditionsList/ScrollContainer/GridContainer.add_child(patch)

func load_condition_data():
	#change modulate of previous slider back blue:
	if currentCondition != null:
		conditionOpen = true
		$ConditionsList/ScrollContainer/GridContainer.get_node(currentCondition).texture = preload("res://Graphics/UI/ConditionButtonPressed.png")
		set_screen(1)
		set_condition_data()

func return_patch(text, color):
	var patch = NinePatchRect.new()
	patch.texture = preload("res://Graphics/UI/baseDataContainer.png").instance()
	patch.margin_left = 8
	patch.margin_right = 8
	patch.margin_top = 8
	patch.margin_bottom = 8

func set_condition_data():
	$Condition/Label.text = currentCondition
	
	$Condition/NinePatchRect/NinePatchRect/Description.bbcode_text = conditions[currentCondition]["Description"]
	var string = ""
	var clinFeat = conditions[currentCondition]["Clinical Features"]
	for i in range(0, clinFeat.size()):
		string += "  - " + clinFeat[i]
		if i < clinFeat.size() - 1:
			string += "\n"
	$Condition/NinePatchRect/NinePatchRect2/ClinFeat/ClinFeat.bbcode_text = string
	
	var investigations = conditions[currentCondition]["Investigations"]
	print(investigations)
	for i in investigations:
		for ix in investigations[i]:
			var button = Button.new()
			button.add_style_override("normal", return_button_stylebox(Color(0.189972,0.626947,0.648438,0.392274)))
			button.add_style_override("hover", return_button_stylebox(Color(0.1763,0.81991,0.851562,0.392274)))
			button.add_style_override("pressed", return_button_stylebox(Color(0.1763,0.81991,0.851562,0.392274)))
			button.text = ix
			button.clip_text = true
			button.align = HALIGN_LEFT
			$Condition/NinePatchRect/NinePatchRect2/Investigations/Ix/VBoxContainer.add_child(button)
	
	string = ""
	var management = conditions[currentCondition]["Management"]
	for type in management:
		string += "[b]" + type + ":" + "[/b] " + management[type] + "\n\n"
	$Condition/NinePatchRect/NinePatchRect2/Management/ClinFeat.bbcode_text = string
	
	
	
	string = ""
	var comps = conditions[currentCondition]["Complications"]
	for i in range(0, comps.size()):
		string += "  - " + comps[i]
		if i < comps.size() - 1:
			string += "\n"
	$Condition/NinePatchRect/NinePatchRect2/Comps/Comps.bbcode_text = string


func return_button_stylebox(color):
	var styleBox = StyleBoxFlat.new()
	styleBox.corner_radius_top_left = 3
	styleBox.corner_radius_top_right = 3
	styleBox.corner_radius_bottom_left = 3
	styleBox.corner_radius_bottom_right = 3
	styleBox.content_margin_left = 5
	styleBox.content_margin_right = 5
	styleBox.content_margin_top = 5
	styleBox.content_margin_bottom = 5
	styleBox.bg_color = color
	styleBox.anti_aliasing_size = 3
	return styleBox


func set_screen(INT):
	if INT == 0:
		$ConditionsList.show()
		$Condition.hide()
	elif INT == 1:
		$ConditionsList.hide()
		$Condition.show()

func condition_patch_entered(patch):
	print("enter")
	currentCondition = patch.get_name()
	patch.texture = preload("res://Graphics/UI/ConditionButtonHover.png")

func condition_patch_exited(patch):
	currentCondition = null
	patch.texture = preload("res://Graphics/UI/ConditionButtonNormal.png")

func back_pressed():
	set_screen(0)
	singleton.clear_container($Condition/NinePatchRect/NinePatchRect2/Investigations/Ix/VBoxContainer)
	currentCondition = null
	conditionOpen = false

func close_menu():
	if conditionOpen:
		back_pressed()
	else:
		queue_free()