extends Node

var performanceDict = {}
var selectedScn = null

func _ready():
	performanceDict = get_node("/root/singleton").load_file_as_JSON("res://JSON_files/performance.json")
	add_scenario_buttons()
	
	get_node("Patch9Frame/Scenarios/Details/ExplanationButton").connect("pressed", self, "explanation_pressed")
	var array = ["Story", "Investigations", "Prescriptions", "KeyActions"]
	for item in array:
		var button = get_node("Patch9Frame/Scenarios/Details/StatsContainer/" + item + "/TextureButton")
		button.connect("pressed", self, "texture_button_pressed", [button])
	
	
func add_scenario_buttons():
	for scenario in performanceDict:
		var button = Button.new()
		button.set_text(scenario)
		button.set_name(scenario)
		button.set_custom_minimum_size(Vector2(0, 40))
		button.set_toggle_mode(true)
		button.connect("pressed", self, "scenario_selected", [button])
		get_node("Patch9Frame/Scenarios/List/ScrollContainer/VBoxContainer").add_child(button)

func scenario_selected(btn):
	selectedScn = btn.get_name()
	get_node("Patch9Frame/Scenarios/Details/StatsContainer").show()
	set_progress_bars(performanceDict[selectedScn]["Attempt"]["Scores"])

func set_progress_bars(data):
	var array = ["Overall", "Story", "Investigations", "Prescriptions", "KeyActions"]
	for item in array:
		get_node("Patch9Frame/Scenarios/Details/StatsContainer/" + item + "/TextureProgress").set_value((data[item] * 360) / 100)
		get_node("Patch9Frame/Scenarios/Details/StatsContainer/" + item + "/Label1").set_text(str(int(data[item])) + "%")
		get_node("Patch9Frame/Scenarios/Details/StatsContainer/" + item + "/TextureButton").set_self_modulate(return_modulate(data[item]))

func return_modulate(value):
	if value >= 75:
		return Color(0.079102,0.84375,0.108971)
	elif value <= 75 && value > 50:
		return Color(1,0.539062,0)
	else:
		return Color(0.914062,0.074982,0.074982)

func open_screen(open):
	var screenArray = ["StatsContainer", "DetailContainer", "ExplanationContainer"]
	for screen in screenArray:
		if open == screen:
			get_node("Patch9Frame/Scenarios/Details/" + screen).show()
		else:
			get_node("Patch9Frame/Scenarios/Details/" + screen).hide()

func texture_button_pressed(btn):
	set_details_data()
	open_screen("DetailContainer")

func set_details_data():
	print_investigation_detail()
	print_keyActions_detail()
	print_prescribed_list()

func print_investigation_detail():
	var container = get_node("Patch9Frame/Scenarios/Details/DetailContainer/Investigations/HBoxContainer/VBoxContainer")
	for ix in performanceDict[selectedScn]["Attempt"]["Investigations"]["Complete"]:
		if performanceDict[selectedScn]["Correct"]["Investigations"].has(ix):
			add_item(ix, 0, container)
		else:
			add_item(ix, 2, container)
	container = get_node("Patch9Frame/Scenarios/Details/DetailContainer/Investigations/HBoxContainer/VBoxContainer1")
	for ix in performanceDict[selectedScn]["Correct"]["Investigations"]:
		if performanceDict[selectedScn]["Attempt"]["Investigations"]["Complete"].has(ix) == false:
			add_item(ix, 1, container)

func print_keyActions_detail():
	var container = get_node("Patch9Frame/Scenarios/Details/DetailContainer/Key Actions/HBoxContainer/VBoxContainer")
	for ix in performanceDict[selectedScn]["Attempt"]["KeyActions"]:
		if performanceDict[selectedScn]["Correct"]["KeyActions"].has(ix):
			add_item(ix, 0, container)
		else:
			add_item(ix, 2, container)
	container = get_node("Patch9Frame/Scenarios/Details/DetailContainer/Key Actions/HBoxContainer/VBoxContainer1")
	for ix in performanceDict[selectedScn]["Correct"]["KeyActions"]:
		if performanceDict[selectedScn]["Attempt"]["KeyActions"].has(ix) == false:
			add_item(ix, 1, container)

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
	label.set_anchor_and_margin(MARGIN_BOTTOM, 1, 0)
	label.set_anchor_and_margin(MARGIN_RIGHT, 1, 0)
	label.set_margin(MARGIN_LEFT, 10)
	label.set_text(text)
	patchframe.add_child(label)
	
	container.add_child(patchframe)


func print_prescribed_list():
	var container
	var missed = performanceDict[selectedScn]["Correct"]["Prescriptions"]
	print(missed)
#	print(missed)
	container = "Patch9Frame/Scenarios/Details/DetailContainer/HBoxContainer/Attempt/VBoxContainer/"
	var printOrder = {"OnceOnly": ["Doses", "Routes"], "Regular": ["Doses", "Routes", "Frequency", "Duration"], "AsRequired": ["Doses", "Routes", "Frequency"], "Infusion": ["Volume", "Routes", "RunTime", "DrugsAdded"]}
	for type in performanceDict[selectedScn]["Attempt"]["Prescriptions"]:
		if performanceDict[selectedScn]["Attempt"]["Prescriptions"][type].size() > 0:
			var bigLabel = return_big_label_node(type)
			get_node(container + type + "/BigLabelContainer").add_child(bigLabel)
			for med in performanceDict[selectedScn]["Attempt"]["Prescriptions"][type]:
				for item in missed[type]:
					if item.has(med):
						missed[type].erase(item)
				print(med)
				var node = preload("res://Scenes/PrescriptionButton.tscn").instance()
				node.set_name(med)
				node.get_node("TextureButton/Label").set_text(med)
				node.get_node("TextureButton/Cancel").hide()
				for detail in printOrder[type]:
					var detailCont = return_detail_frame_node(detail)
					if detail != "DrugsAdded":
						if detail == "Doses":
							detailCont.get_node("detailText").set_text(performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med][detail] + " " + performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med]["Units"])
						elif detail == "Duration":
							detailCont.get_node("detailText").set_text(performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med][detail] + " " + performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med]["DurUnits"])
						elif detail == "Volume":
							detailCont.get_node("detailText").set_text(performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med][detail] + " " + performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med]["VolUnits"])
						elif detail == "RunTime":
							detailCont.get_node("detailText").set_text(performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med][detail] + " " + performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med]["RunTimeUnits"])
						else:
							detailCont.get_node("detailText").set_text(performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med][detail])
						node.get_node("DetailsContainer").add_child(detailCont)
					
					elif detail == "DrugsAdded":
						node.get_node("DrugsAddedContainer").set_hidden(false)
						for drug in performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med][detail]:
							var detailCont2 = return_detail_frame_node(detail)
							detailCont2.get_node("detailText").set_text("+ " + drug + " " + performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med][detail][drug]["Dose"] + performanceDict[selectedScn]["Attempt"]["Prescriptions"][type][med][detail][drug]["Unit"])
							node.get_node("DrugsAddedContainer").add_child(detailCont2)
					
				get_node(container + type + "/PresConatiner").add_child(node)
	print_missed_pres(missed)

func print_missed_pres(missed):
	var container = "Patch9Frame/Scenarios/Details/DetailContainer/HBoxContainer/Missed/VBoxContainer/"
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
								for unit in missed[type][i][med][detail]:
									if missed[type][i][med][detail][unit].size() > 1:
										Str = missed[type][i][med][detail][unit][0] + " - " + missed[type][i][med][detail][unit][1] + " " + unit
									else:
										Str = missed[type][i][med][detail][unit][0] + unit
								detailCont.get_node("detailText").set_text(Str)
							else:
								for x in range(0, missed[type][i][med][detail].size()):
									Str += missed[type][i][med][detail][x] 
									if x < missed[type][i][med][detail].size() - 1:
										Str += "/"
#								if detail == "Duration":
#									detailCont.get_node("detailText").set_text(Str + " " + missed[type][i][med]["DurUnits"])
								if detail == "Volume":
									detailCont.get_node("detailText").set_text(Str + " " + missed[type][i][med]["VolUnits"])
								elif detail == "RunTime":
									detailCont.get_node("detailText").set_text(Str + " " + missed[type][i][med]["RunTimeUnits"])
								else:
									detailCont.get_node("detailText").set_text(Str)
							node.get_node("DetailsContainer").add_child(detailCont)
						
						elif detail == "DrugsAdded":
							node.get_node("DrugsAddedContainer").set_hidden(false)
							for drug in missed[type][i][med][detail]:
								var detailCont2 = return_detail_frame_node(detail)
								detailCont2.get_node("detailText").set_text("+ " + drug + " " + missed[type][i][med][detail][drug]["Dose"] + missed[type][i][med][detail][drug]["Unit"])
								node.get_node("DrugsAddedContainer").add_child(detailCont2)
						
					get_node(container + type + "/PresConatiner").add_child(node)

func return_first_med_in_dict(dict):
	var med
	for i in dict:
		med = i
	return med
	
	

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

func explanation_pressed():
	open_screen("ExplanationContainer")

