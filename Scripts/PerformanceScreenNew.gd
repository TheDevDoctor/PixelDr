extends NinePatchRect

var currentSlider = null
var currentPerformance = null
var screenInt = null
var performanceDict = {}
var firstSet = false

func _ready():
	if singleton.isWeb:
		performanceDict = singleton.load_file_as_JSON("user://performance.json")
	else:
		performanceDict = singleton.load_file_as_JSON("res://JSON_files/performance.json")
	load_performances()
	set_process_input(true)
	set_process_unhandled_key_input(true)
	
	for i in range($NinePatchRect/panelButtons.get_child_count()):
		$NinePatchRect/panelButtons.get_child(i).connect("pressed", self, "panel_button_pressed", [$NinePatchRect/panelButtons.get_child(i)])
	set_screen(0)

#	if firstSet == false:
#		set_first_slider()

#func set_first_slider():
#	print("Set")
#	currentSlider = $SliderContainer.get_child(0)
#	print("ready called")
#	load_performance_data()
#	firstSet = true

func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("ui_cancel"):
		close_menu()

func _input(event):
	if event is InputEventMouseButton:
		if  (event.button_index == BUTTON_LEFT and event.pressed):
			if currentSlider != null:
				load_performance_data()

func load_performances():
	if performanceDict["Scenarios"] != null:
		for performance in performanceDict["Scenarios"]:
			var slider = load("res://Scenes/performanceSlider.tscn").instance()
			slider.set_name(performance)
			slider.set_tooltip(performance)
			slider.get_node("Label").set_text(performance)
			slider.get_node("Control/TextureProgress").value = performanceDict["Scenarios"][performance]["Scores"]["Overall"]
			slider.get_node("Control/Label").set_text(str(int(performanceDict["Scenarios"][performance]["Scores"]["Overall"])) + "%")
			slider.get_node("Sprite").set_frame(performanceDict["Scenarios"][performance]["Sprite"])
			slider.connect("mouse_entered", self, "slider_mouse_entered", [slider])
			slider.connect("mouse_exited", self, "slider_mouse_exited", [slider])
			$SliderContainer.add_child(slider)

func panel_button_pressed(button):
	set_screen(button.get_position_in_parent())

func set_screen(INT):
	if screenInt != null:
		$NinePatchRect/panelButtons.get_child(screenInt).set_pressed(false)
		$NinePatchRect/Panels.get_child(screenInt).hide()
	screenInt = INT
	$NinePatchRect/Panels.get_child(screenInt).show()

var panelVis = false
func load_performance_data():
	
	if panelVis == false:
		$NinePatchRect/panelButtons.show()
		$NinePatchRect/Panels.show()
		$NinePatchRect/Label.hide()
		panelVis = true
	
	set_blank()
	
	#change modulate of previous slider back blue:
	if currentPerformance != null:
		$SliderContainer.get_node(currentPerformance).set_self_modulate(Color(0.073486,0.343653,0.4375))

	#set current slider modulate purple:
	currentSlider.set_self_modulate(Color(0.370056,0.068237,0.671875))

	#set the current performance variable:
	currentPerformance = currentSlider.get_name()
	
	set_progress_bars()
	set_explanation()
	set_history()
	set_investigations()
	set_management()
	
	set_screen(0)
	$NinePatchRect/panelButtons/Explanation.set_pressed(true)

func set_progress_bars():
	var scores = performanceDict["Scenarios"][currentPerformance]["Scores"]
	$progressBars/Overall/TextureProgress.value = scores["Overall"]
	$progressBars/History/TextureProgress.value = scores["History"]
	$progressBars/Investigations/TextureProgress.value = scores["Investigations"]
	$progressBars/Management/TextureProgress.value = scores["Management"]["Overall"]
	
	$progressBars/Overall/Label.text = str(int(scores["Overall"])) + "%"
	$progressBars/History/Label.text = str(int(scores["History"])) + "%"
	$progressBars/Investigations/Label.text = str(int(scores["Investigations"])) + "%"
	$progressBars/Management/Label.text = str(int(scores["Management"]["Overall"])) + "%"

func set_explanation():
	if performanceDict["Scenarios"][currentPerformance]["Explanation"] != null:
		$NinePatchRect/Panels/Explanation/Label.bbcode_text = performanceDict["Scenarios"][currentPerformance]["Explanation"]

func set_history():
	var attempted = performanceDict["Scenarios"][currentPerformance]["History"]["Performed"]
	var missed = performanceDict["Scenarios"][currentPerformance]["History"]["Missed"]
	var correct = performanceDict["Scenarios"][currentPerformance]["Correct"]["History"]
	
	var container = $NinePatchRect/Panels/History/Investigations/VBoxContainer/Attempted
	if attempted != null:
		for q in attempted:
			if correct.has(q):
				add_item(attempted[q], 0, container)
			else:
				add_item(attempted[q], 2, container)

	container = $NinePatchRect/Panels/History/Investigations/VBoxContainer/Missed
	for q in missed:
		add_item(missed[q], 1, container)
	
func set_investigations():
	var attempted = performanceDict["Scenarios"][currentPerformance]["Investigations"]["Performed"]
	var missed = performanceDict["Scenarios"][currentPerformance]["Investigations"]["Missed"]
	var correct = performanceDict["Scenarios"][currentPerformance]["Correct"]["Investigations"]
	
	var container = $NinePatchRect/Panels/Investigation/ScrollContainer/HBoxContainer/Attempt
	for i in range(0, attempted.size()):
		if correct.has(attempted[i]):
			add_item(attempted[i], 0, container)
		else:
			add_item(attempted[i], 2, container)
	
	container = $NinePatchRect/Panels/Investigation/ScrollContainer/HBoxContainer/Missed
	for i in range(0, missed.size()):
		add_item(missed[i], 1, container)

func set_management():
	if performanceDict["Scenarios"][currentPerformance]["Correct"]["Prescriptions"] != null:
		$NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/PrescriptionTitle.show()
		$NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions.show()
		add_prescriptions()
	#add procedures:
	if performanceDict["Scenarios"][currentPerformance]["Correct"]["Procedures"] != null:
		$NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/ProceduresTitle.show()
		$NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/ProceduresLabels.show()
		$NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Procedures.show()
		var container = $NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Procedures/Attempt
		var attempted = performanceDict["Scenarios"][currentPerformance]["Procedures"]["Performed"]
		var missed = performanceDict["Scenarios"][currentPerformance]["Procedures"]["Missed"]
		var correct = performanceDict["Scenarios"][currentPerformance]["Correct"]["Procedures"]
		for i in range(0, attempted.size()):
			if correct.has(attempted[i]):
				add_item(attempted[i], 0, container)
			else:
				add_item(attempted[i], 2, container)
				
		container = $NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Procedures/Missed
		for i in range(0, missed.size()):
			add_item(missed[i], 1, container)

	#add contacts:
	if performanceDict["Scenarios"][currentPerformance]["Correct"]["Contact"] != null:
		$NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/ContactsTitle.show()
		$NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/ContactsLabels.show()
		$NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Contacts.show()
		var container = $NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Contacts/Attempt
		var missed
		if performanceDict["Scenarios"][currentPerformance]["Contact"]["Performed"] != null:
			var attempted = performanceDict["Scenarios"][currentPerformance]["Contact"]["Performed"]
			missed = performanceDict["Scenarios"][currentPerformance]["Contact"]["Missed"]
			var correct = performanceDict["Scenarios"][currentPerformance]["Correct"]["Contact"]
			for i in range(0, attempted.size()):
				if correct.has(attempted[i]):
					add_item(attempted[i], 0, container)
				else:
					add_item(attempted[i], 2, container)
		else:
			add_item("Nothing", 2, container)
			missed = performanceDict["Scenarios"][currentPerformance]["Correct"]["Contact"]
		container = $NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Contacts/Missed
		for i in range(0, missed.size()):
			add_item(missed[i], 1, container)

func add_prescriptions():
	var attempted = performanceDict["Scenarios"][currentPerformance]["Prescriptions"]["Performed"]
	var missed = performanceDict["Scenarios"][currentPerformance]["Prescriptions"]["Missed"]
	var correct = performanceDict["Scenarios"][currentPerformance]["Correct"]["Prescriptions"]
	
	var container = "NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Attempt/"
	var printOrder = {"OnceOnly": ["Doses", "Routes"], "Regular": ["Doses", "Routes", "Frequency", "Duration"], "AsRequired": ["Doses", "Routes", "Frequency"], "Infusion": ["Volume", "Routes", "RunTime", "DrugsAdded"]}
	for type in attempted:
		if attempted[type].size() > 0:
			var bigLabel = return_big_label_node(type)
			get_node(container + type + "/BigLabelContainer").add_child(bigLabel)
			for med in attempted[type]:
#				for item in missed[type]:
#					if item.has(med):
#						missed[type].erase(item)
				print(med)
				var node = preload("res://Scenes/PrescriptionButton.tscn").instance()
				node.set_name(med)
				node.get_node("TextureButton/Label").set_text(med)
				node.get_node("TextureButton/Cancel").hide()
				for detail in printOrder[type]:
					var detailCont = return_detail_frame_node(detail)
					if detail != "DrugsAdded":
						if detail == "Doses":
							detailCont.get_node("detailText").set_text(attempted[type][med][detail] + " " + attempted[type][med]["Units"])
						elif detail == "Duration":
							detailCont.get_node("detailText").set_text(attempted[type][med][detail] + " " + attempted[type][med]["DurUnits"])
						elif detail == "Volume":
							detailCont.get_node("detailText").set_text(attempted[type][med][detail] + " " + attempted[type][med]["VolUnits"])
						elif detail == "RunTime":
							detailCont.get_node("detailText").set_text(attempted[type][med][detail] + " " + attempted[type][med]["RunTimeUnits"])
						else:
							detailCont.get_node("detailText").set_text(attempted[type][med][detail])
						node.get_node("DetailsContainer").add_child(detailCont)
					
					elif detail == "DrugsAdded":
						node.get_node("DrugsAddedContainer").set_hidden(false)
						for drug in attempted[type][med][detail]:
							var detailCont2 = return_detail_frame_node(detail)
							detailCont2.get_node("detailText").set_text("+ " + drug + " " + attempted[type][med][detail][drug]["Dose"] + attempted[type][med][detail][drug]["Unit"])
							node.get_node("DrugsAddedContainer").add_child(detailCont2)
					
				get_node(container + type + "/PresConatiner").add_child(node)
	print_missed_pres(missed)

func print_missed_pres(missed):
	var container = "NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Missed/"
	var printOrder = {"OnceOnly": ["Doses", "Routes"], "Regular": ["Doses", "Routes", "Frequency", "Duration"], "AsRequired": ["Doses", "Routes", "Frequency"], "Infusion": ["Volume", "Routes", "RunTime", "DrugsAdded"]}
	for type in missed:
		var hasData = false
		if missed[type].size() > 0:
			for i in range(0, missed[type].size()):
				if missed[type][i].size() > 0:
					hasData = true
				else:
					pass
			if hasData == true:
				var bigLabel = return_big_label_node(type)
				get_node(container + type + "/BigLabelContainer").add_child(bigLabel)
				for i in range(0, missed[type].size()):
					if missed[type][i].size() > 0:
						var med = return_first_med_in_dict(missed[type][i])
						var node = preload("res://Scenes/PrescriptionButton.tscn").instance()
						node.set_name(med)
						node.get_node("TextureButton/Label").set_text(med)
						node.get_node("TextureButton/Cancel").hide()
						for detail in printOrder[type]:
							var detailCont = return_detail_frame_node(detail)
							if detail != "DrugsAdded":
								var Str = ""
								if detail == "Doses" || detail == "Duration":
									if typeof(missed[type][i][med][detail]) == TYPE_ARRAY:
										if missed[type][i][med][detail].size() > 1:
											Str = missed[type][i][med][detail][0] + " - " + missed[type][i][med][detail][1] + " " + missed[type][i][med]["Units"]
										else:
											Str = missed[type][i][med][detail][0] + " " + missed[type][i][med]["Units"]
										detailCont.get_node("detailText").set_text(Str)
									else:
										Str = missed[type][i][med][detail] + " " + missed[type][i][med]["Units"]
										detailCont.get_node("detailText").set_text(Str)
								else:
									if typeof(missed[type][i][med][detail]) == TYPE_ARRAY:
										for x in range(0, missed[type][i][med][detail].size()):
											Str += missed[type][i][med][detail][x] 
											if x < missed[type][i][med][detail].size() - 1:
												Str += "/"
										if detail == "Duration":
											detailCont.get_node("detailText").set_text(Str + " " + missed[type][i][med]["DurUnits"])
										if detail == "Volume":
											detailCont.get_node("detailText").set_text(Str + " " + missed[type][i][med]["VolUnits"])
										elif detail == "RunTime":
											detailCont.get_node("detailText").set_text(Str + " " + missed[type][i][med]["RunTimeUnits"])
										else:
											detailCont.get_node("detailText").set_text(Str)
									else:
										detailCont.get_node("detailText").set_text(missed[type][i][med][detail])
								node.get_node("DetailsContainer").add_child(detailCont)
							
							elif detail == "DrugsAdded":
								node.get_node("DrugsAddedContainer").set_hidden(false)
								for drug in missed[type][i][med][detail]:
									var detailCont2 = return_detail_frame_node(detail)
									detailCont2.get_node("detailText").set_text("+ " + drug + " " + missed[type][i][med][detail][drug]["Dose"] + missed[type][i][med][detail][drug]["Unit"])
									node.get_node("DrugsAddedContainer").add_child(detailCont2)
							
						get_node(container + type + "/PresConatiner").add_child(node)

func slider_mouse_entered(slider):
	currentSlider = slider
	slider.set_self_modulate(Color(0.002686,0.623299,0.6875))
	print(slider.get_name())

func slider_mouse_exited(slider):
	if currentSlider.get_name() == currentPerformance: 
		currentSlider.set_self_modulate(Color(0.370056,0.068237,0.671875))
	else:
		slider.set_self_modulate(Color(0.073486,0.343653,0.4375))
	currentSlider = null
	print("exit")



func add_item(text, colorNum, container): 
	var colorArray = [Color(0.004059,0.519531,0), Color(0.675781,0,0), Color(0.328125,0.311462,0.311462)]
	var patchframe = NinePatchRect.new()
	var color = colorArray[colorNum]
	patchframe.set_texture(preload("res://Graphics/UI/baseDataContainer.png"))
	patchframe.set_patch_margin(MARGIN_LEFT, 8)
	patchframe.set_patch_margin(MARGIN_TOP, 8)
	patchframe.set_patch_margin(MARGIN_BOTTOM, 8)
	patchframe.set_patch_margin(MARGIN_RIGHT, 8)
	patchframe.set_h_size_flags(3)
	patchframe.set_custom_minimum_size(Vector2(0, 36))
	patchframe.set_self_modulate(color)
	
	var label = Label.new()
	label.set_valign(1)
	label.connect("item_rect_changed", self, "on_item_rect_changed", [label])
	label.set_anchor_and_margin(MARGIN_BOTTOM, 1, 0)
	label.set_anchor_and_margin(MARGIN_RIGHT, 1, 0)
	label.set_margin(MARGIN_LEFT, 10)
	label.set_autowrap(true)
	label.set_text(text)
	patchframe.add_child(label)
	
	container.add_child(patchframe)

func on_item_rect_changed(label):
	label.set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count()))
	label.get_node("..").set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count()+ 15))

func return_big_label_node(type):
	var colourDict = {"OnceOnly": Color(0.992188, 0.553291, 0.127899, 1), "Regular": Color(0.070312, 1, 0.084839, 1), "AsRequired": Color(0.175781, 0.6716, 1, 1), "Infusion": Color(1, 0.179688, 0.987183, 1)}
	var bigLabel = NinePatchRect.new()
	bigLabel.set_texture(preload("res://Graphics/UI/presSideButton.png"))
	bigLabel.set_v_size_flags(3)
	bigLabel.set_patch_margin(MARGIN_LEFT, 10)
	bigLabel.set_patch_margin(MARGIN_TOP, 10)
	bigLabel.set_patch_margin(MARGIN_BOTTOM, 10)
	bigLabel.set_patch_margin(MARGIN_RIGHT, 5)
	bigLabel.set_custom_minimum_size(Vector2(40, 63))
	bigLabel.set_self_modulate(colourDict[type])
	bigLabel.set_name("bigLabel")
	return bigLabel

func return_detail_frame_node(detail):
	var detailsCont = NinePatchRect.new()
	detailsCont.set_texture(preload("res://Graphics/UI/investigationOrderNormal.png"))
	detailsCont.set_h_size_flags(3)
	detailsCont.set_patch_margin(MARGIN_LEFT, 5)
	detailsCont.set_patch_margin(MARGIN_TOP, 5)
	detailsCont.set_patch_margin(MARGIN_BOTTOM, 5)
	detailsCont.set_patch_margin(MARGIN_RIGHT, 5)
	detailsCont.set_name(detail)
	var label = Label.new()
	label.set_clip_text(true)
	label.set_valign(1)
	label.set_align(1)
	label.set_margin(MARGIN_BOTTOM, 0)
	label.set_margin(MARGIN_TOP, 0)
	label.set_margin(MARGIN_LEFT, 5)
	label.set_margin(MARGIN_RIGHT, 5)
	label.set_anchor(MARGIN_RIGHT, 1)
	label.set_anchor(MARGIN_BOTTOM, 1)
	label.set_name("detailText")
	label.add_font_override("font", preload("res://Fonts/Nunito_regular16.font"))
	detailsCont.add_child(label)
	return detailsCont

func return_first_med_in_dict(dict):
	var med
	for i in dict:
		if dict[i]["Tag"] == 1:
			med = i
	return med

func close_menu():
	queue_free()


func set_blank():
	#hide items:
	for i in range(0, $NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer.get_child_count()):
		$NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer.get_child(i).hide()
	
	#clear data:
	$NinePatchRect/Panels/Explanation/Label.bbcode_text = ""
	clear_container($NinePatchRect/Panels/History/Investigations/VBoxContainer/Attempted)
	clear_container($NinePatchRect/Panels/History/Investigations/VBoxContainer/Missed)
	clear_container($NinePatchRect/Panels/Investigation/ScrollContainer/HBoxContainer/Attempt)
	clear_container($NinePatchRect/Panels/Investigation/ScrollContainer/HBoxContainer/Missed)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Attempt/OnceOnly/BigLabelContainer)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Attempt/OnceOnly/PresConatiner)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Attempt/Regular/BigLabelContainer)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Attempt/Regular/PresConatiner)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Attempt/AsRequired/BigLabelContainer)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Attempt/AsRequired/PresConatiner)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Attempt/Infusion/BigLabelContainer)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Attempt/Infusion/PresConatiner)
	
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Missed/OnceOnly/BigLabelContainer)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Missed/OnceOnly/PresConatiner)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Missed/Regular/BigLabelContainer)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Missed/Regular/PresConatiner)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Missed/AsRequired/BigLabelContainer)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Missed/AsRequired/PresConatiner)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Missed/Infusion/BigLabelContainer)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Prescriptions/Missed/Infusion/PresConatiner)
	
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Procedures/Attempt)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Procedures/Missed)
	
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Contacts/Attempt)
	clear_container($NinePatchRect/Panels/Management/ScrollContainer/VBoxContainer/Contacts/Missed)

func clear_container(cont):
	if cont.get_child_count() > 0:
		for child in cont.get_children():
			child.free()