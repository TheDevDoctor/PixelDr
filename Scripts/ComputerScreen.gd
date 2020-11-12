extends NinePatchRect

signal computer_closed
signal ix_view
signal admit_patient

var screens = ["BedsScreen", "TestsScreen", "PrescribeScreen", "InfoScreen", "DischargeScreen", "AdmitScreen"]
var ordered = {"BED1": {}, "BED2": {}, "BED3": {}, "BED4": {}, "BED5": {}, "BED6": {}, "BED7": {}, "BED8": {}, "BED9": {}, "BED10": {}}
#var diffArray = ["Atrial Fibrillation", "Supraventricular Tachycardia", "COPD", "Asthma", "Ulcerative Colitis", "Chron's Disease"]
var differentials = []
var diffArray = []

#need to remove 'data' and replace with corresponding value of these. 
var ixData = {}
var prescribingData = {}
var prescribed = []
var investigationsArray = []
var currScreen = null
var currentBed = null
var presType = null
var count = 0
var storyIxChange = {}

var diffsOpen = false
var infoOpen = false

var prescriptionDict = {}
var presArray = {"Medications": [], "Infusions": [], "Oxygen": []}

func _ready():
	OS.set_low_processor_usage_mode(true)
	#Load JSON files:
	ixData = get_node("/root/singleton").load_file_as_JSON("res://JSON_files/investigations.json")
	prescribingData = get_node("/root/singleton").load_file_as_JSON("res://JSON_files/prescribing.json")
	
	$AdmitScreen/AdmitSumBg/NinePatchRect/Wards.add_separator()
	var wards = ["Catheterisation Lab", "Respiratory Ward", "Cardiology Ward", "Geriatric Ward", "Surgical Ward", "Paediatric Ward", "Gastroenterology Ward"]
	wards.sort()
	for i in range(0, wards.size()):
		$AdmitScreen/AdmitSumBg/NinePatchRect/Wards.add_item(wards[i])
	
	#set previous data:
	prescriptionDict = get_node("/root/singleton").bedPrescriptions
	
	#BEDS set up:
	print_data()
	open_screens("Beds", null)

	#set all hidden screens to hidden:
	get_node("PrescribeScreen/PresDetails").hide()
	get_node("PrescribeScreen/Cover").hide()
	get_node("PrescribeScreen/PresDetails/FluidsAddScreen/AddDrugScreen").hide()
	get_node("InfoScreen/ViewIx").hide()
	get_node("InfoScreen/ViewIx/IxBg/ScrollContainer").hide()
	get_node("InfoScreen/ViewIx/IxBg/ImagingContainer").hide()

	#Connect all signals:
#	get_node("InfoScreen/addDiffButton/addDiffScreen/search").connect("text_changed", self, "search_diff_text_changed")
#	get_node("InfoScreen/addDiffButton").connect("pressed", self, "open_diff_screen")
	get_node("TestsScreen/StoredIx/IxBg/HBoxContainer/Clear").connect("pressed", self, "clear_ix_pressed")
	get_node("TestsScreen/StoredIx/IxBg/HBoxContainer/Order").connect("pressed", self, "order_ix_pressed")
#	get_node("DischargeScreen/DischargeSumBg/Discharge").connect("pressed", self, "discharge_patient")
	get_node("Back").connect("pressed", self, "back_pressed")
	$InfoScreen/ViewIx/IxBg/ImagingContainer/ImagingContainer/Larger.connect("pressed", self, "enlarge_image_pressed")
	var presTypeButtons = get_node("PrescribeScreen/SearchBg/Types").get_children()
	for btn in presTypeButtons:
		btn.connect("pressed", self, "pres_type_btn_pressed", [btn])
	var presDetailsOptionBtns = get_node("PrescribeScreen/PresDetails/MedsAddScreen/OptionsContainer").get_children()
	for btn in presDetailsOptionBtns:
		btn.connect("pressed", self, "pres_details_toggled", [btn])
	var presDetailsMainBts = get_node("PrescribeScreen/PresDetails/PresDetailsBtns").get_children()
	for btn in presDetailsMainBts:
		btn.connect("pressed", self, "pres_details_main_btn_pressed", [btn])
	var storedPresButtons = get_node("PrescribeScreen/StoredPres/IxBg/Buttons").get_children()
	for btn in storedPresButtons:
		btn.connect("pressed", self, "stored_pres_btn_pressed", [btn])
	var ixValuesScreenButton = get_node("InfoScreen/ViewIx/IxBg/Buttons").get_children()
	for btn in ixValuesScreenButton:
		btn.connect("pressed", self, "ix_values_screen_btn_pressed", [btn])
	var sideScreenButton = get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/sideScreenButton")
	sideScreenButton.set_toggle_mode(true)
	sideScreenButton.connect("pressed", self, "open_side_screen", [sideScreenButton])
	$DischargeScreen/DischargeSumBg/Discharge.connect("pressed", self, "discharge_pressed")
	$AdmitScreen/AdmitSumBg/Admit.connect("pressed", self, "admit_pressed")
#	var addDiffButtons = get_node("InfoScreen/addDiffButton/addDiffScreen/Patch9Frame/HBoxContainer").get_children()
#	for btn in addDiffButtons:
#		btn.connect("pressed", self, "add_diff_btn_pressed", [btn])
#	$InfoScreen/NinePatchRect/diffsSearchList/Done.connect("pressed", self, "done_pressed")
#	$InfoScreen/NinePatchRect/edit.connect("pressed", self, "edit_diffs")
	
#	var findingsText = get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen/ScrollContainer/VBoxContainer/Findings")
#	var impressionText = get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen/ScrollContainer/VBoxContainer/Impression")
#	findingsText.connect("item_rect_changed", self, "on_item_rect_changed", [findingsText])
#	impressionText.connect("item_rect_changed", self, "on_item_rect_changed", [impressionText])

func discharge_pressed():
	singleton.discharge_patient(currentBed)
	back_pressed()

func admit_pressed():
	emit_signal("admit_patient")
	singleton.admit_patient(currentBed, $AdmitScreen/AdmitSumBg/NinePatchRect/Wards.get_item_text($AdmitScreen/AdmitSumBg/NinePatchRect/Wards.get_selected_id()))
	back_pressed()

func print_data():
	var beds = get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard]
	var bedsArray = []
	for bed in beds:
		bedsArray.append(bed)
	bedsArray.sort_custom(self, "sort_beds_order")
	for bed in bedsArray:
		if beds[bed] != null:
			#add BEDS label:
			var Blabel = Label.new()
			Blabel.set_text(bed)
			Blabel.set_custom_minimum_size(Vector2(0, 27))
			Blabel.set_valign(1)
			Blabel.add_font_override("font", preload("res://Fonts/Nunito_regular20.font"))
			get_node("BedsScreen/HBoxContainer/BEDS").add_child(Blabel)
			
			#add Presenting Complaint:
			var PClabel = Label.new()
			var presentingComplaint = beds[bed][0]["PatientDetails"]["PresentingComplaint"]
			PClabel.set_custom_minimum_size(Vector2(0, 27))
			PClabel.add_font_override("font", preload("res://Fonts/Nunito_regular16.font"))
			PClabel.set_valign(1)
			PClabel.set_text(presentingComplaint)
			get_node("BedsScreen/HBoxContainer/PRESENTING COMPLAINT").add_child(PClabel)
			
			#add waited time label:
			var waitLabel = Label.new()
			waitLabel.set_custom_minimum_size(Vector2(0, 27))
			waitLabel.add_font_override("font", preload("res://Fonts/Nunito_regular20.font"))
			waitLabel.set_text("00:00")
			waitLabel.set_valign(1)
			get_node("BedsScreen/HBoxContainer/TIME WAITED").add_child(waitLabel)
			
			#add action buttons:
			var HBox = HBoxContainer.new()
			HBox.set_name(bed)
			HBox.set_custom_minimum_size(Vector2(0, 27))
			var array = ["Info", "Tests", "Prescribe", "Discharge", "Admit"]
			for option in array:
				var button = Button.new()
				button.set_text(option)
				button.set_name(option)
				button.set_h_size_flags(3)
				button.set_v_size_flags(3)
				button.connect("pressed", self, "action_chosen", [button])
				HBox.add_child(button)
			get_node("BedsScreen/HBoxContainer/ACTIONS").add_child(HBox)

#custom sorter for beds number
func sort_beds_order(element1, element2):
	var el1 = element1.replace("BED", "")
	var el2 = element2.replace("BED", "")
	if int(el1) < int(el2):
		return true
	else:
		return false

func back_pressed():
	clear_relevant_data()
	open_screens("Beds", null)

func clear_relevant_data():
	if currScreen == "InfoScreen":
		diffArray.clear()
		clear_container($InfoScreen/compNotes/diffLabels/HBoxContainer/VBoxContainer)
		clear_container($InfoScreen/compNotes/diffLabels/HBoxContainer/VBoxContainer2)
		clear_container($InfoScreen/compNotes/editDiffs/HBoxContainer/VBoxContainer)
		clear_container($InfoScreen/compNotes/editDiffs/HBoxContainer/VBoxContainer2)
		clear_container($InfoScreen/compNotes/diffsSearchList/ScrollCont/VBoxContainer)
		clear_container($InfoScreen/PrescriptionsBg/ScrollContainer/VBoxContainer/OnceOnly/BigLabelContainer)
		clear_container($InfoScreen/PrescriptionsBg/ScrollContainer/VBoxContainer/OnceOnly/PresConatiner)
		clear_container($InfoScreen/PrescriptionsBg/ScrollContainer/VBoxContainer/Regular/BigLabelContainer)
		clear_container($InfoScreen/PrescriptionsBg/ScrollContainer/VBoxContainer/Regular/PresConatiner)
		clear_container($InfoScreen/PrescriptionsBg/ScrollContainer/VBoxContainer/AsRequired/BigLabelContainer)
		clear_container($InfoScreen/PrescriptionsBg/ScrollContainer/VBoxContainer/AsRequired/PresConatiner)
		clear_container($InfoScreen/PrescriptionsBg/ScrollContainer/VBoxContainer/Infusion/BigLabelContainer)
		clear_container($InfoScreen/PrescriptionsBg/ScrollContainer/VBoxContainer/Infusion/PresConatiner)
		clear_container($InfoScreen/InvestigationsBg/ScrollContainer/VBoxContainer)
		save_notes()
		if get_node("/root/singleton/Timer").is_connected("timeout", self, "update_time_left"):
			get_node("/root/singleton/Timer").disconnect("timeout", self, "update_time_left")
	if currScreen == "PrescribeScreen":
		clear_container($PrescribeScreen/StoredPres/IxBg/ScrollContainer/VBoxContainer/OnceOnly/BigLabelContainer)
		clear_container($PrescribeScreen/StoredPres/IxBg/ScrollContainer/VBoxContainer/OnceOnly/PresConatiner)
		clear_container($PrescribeScreen/StoredPres/IxBg/ScrollContainer/VBoxContainer/Regular/BigLabelContainer)
		clear_container($PrescribeScreen/StoredPres/IxBg/ScrollContainer/VBoxContainer/Regular/PresConatiner)
		clear_container($PrescribeScreen/StoredPres/IxBg/ScrollContainer/VBoxContainer/AsRequired/BigLabelContainer)
		clear_container($PrescribeScreen/StoredPres/IxBg/ScrollContainer/VBoxContainer/AsRequired/PresConatiner)
		clear_container($PrescribeScreen/StoredPres/IxBg/ScrollContainer/VBoxContainer/Infusion/BigLabelContainer)
		clear_container($PrescribeScreen/StoredPres/IxBg/ScrollContainer/VBoxContainer/Infusion/PresConatiner)
		clear_container($PrescribeScreen/SearchBg/ScrollContainer/DrugsSearchContainer)
		for type in presArray:
			presArray[type].clear()
	
	if currScreen == "DischargeScreen" || currScreen == "AdmitScreen":
		clear_container($BedsScreen/HBoxContainer/BEDS, "Title")
		clear_container($"BedsScreen/HBoxContainer/PRESENTING COMPLAINT", "Title")
		clear_container($"BedsScreen/HBoxContainer/TIME WAITED", "Title")
		clear_container($BedsScreen/HBoxContainer/ACTIONS, "Title")
		print_data()

func clear_container(cont, exception = null):
	if cont.get_child_count() > 0:
		if exception == null:
			for child in cont.get_children():
				child.free()
		else:
			for child in cont.get_children():
				if child.get_name() != exception:
					child.free()

#Action chosen function
func action_chosen(btn):
	currentBed = btn.get_parent().get_name()
	open_screens(btn.get_name(), currentBed)
	

func open_screens(btn, bed):
	for screen in screens:
		if (btn + "Screen") != screen:
			get_node(screen).hide()
		else:
			get_node(screen).show()
			
			currScreen = screen
			if screen != "BedsScreen":
				set_screen_data(screen, bed)
				get_node("Back").show()
			else:
				get_node("Back").hide()

var data = {}
#Load relevant screens data:
func set_screen_data(screen, bed):
	if screen == "TestsScreen":
		get_node(screen + "/Title").set_text(bed)
#		get_node("/root/singleton").load_file_as_JSON("res://JSON_files/investigations.json", data)
		investigations_to_array()
		for ix in get_node("/root/singleton").bedInvestigations[currentBed]["Pending"]:
			print_ix(ix)
		
	elif screen == "PrescribeScreen":
		get_node(screen + "/Title").set_text(bed)
		data.clear()
		presType = "Medications"
		data = get_node("/root/singleton").load_file_as_JSON("res://JSON_files/prescribing.json")
		print_prescribed_list()
		prescribing_to_array()
	
	elif screen == "InfoScreen":
		get_node(screen + "/Title").set_text(bed)
		storyIxChange = get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][bed][0]["Investigations"]
		print_investigations_for_bed(bed)
		data.clear()
		$InfoScreen/compNotes.set_notes()
#		set_labels()
		print_pres_for_bed()
#		data = get_node("/root/singleton").load_file_as_JSON("res://JSON_files/conditions.json")
#		for key in data:
#			diffArray.append(key)
#		diffArray.sort()
#		set_screen(0)
	elif screen == "AdmitScreen":
		$AdmitScreen/compNotes.set_notes()
	
	elif screen == "DischargeScreen":
		$DischargeScreen/compNotes.set_notes()

#func edit_diffs():
#	for diff in singleton.bedDifferentials[singleton.currentWard][currentBed]:
#		add_to_edit_diffs(diff)
#	set_screen(1)
#	clear_container($InfoScreen/NinePatchRect/diffLabels/HBoxContainer/VBoxContainer)
#	clear_container($InfoScreen/NinePatchRect/diffLabels/HBoxContainer/VBoxContainer2)

#func set_screen(type):
#	if type == 0:
#		$InfoScreen/NinePatchRect/notes.show()
#		$InfoScreen/NinePatchRect/diffsSearchList.hide()
#		$InfoScreen/NinePatchRect/Label.show()
#		$InfoScreen/NinePatchRect/diffLabels.show()
#		$InfoScreen/NinePatchRect/editDiffs.hide()
#	elif type == 1:
#		$InfoScreen/NinePatchRect/notes.hide()
#		$InfoScreen/NinePatchRect/diffsSearchList.show()
#		$InfoScreen/NinePatchRect/Label.hide()
#		$InfoScreen/NinePatchRect/diffLabels.hide()
#		$InfoScreen/NinePatchRect/editDiffs.show()
#		create_diff_buttons(diffArray)

func create_diff_buttons(array, readd = false):
	var container = $InfoScreen/NinePatchRect/diffsSearchList/ScrollCont/VBoxContainer
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
			if differentials.has(item):
				button.set_pressed(true)
			container.add_child(button)
	container.get_node("..").set_v_scroll(0)

#func add_differential(button):
#	var differential = button.get_node("Label").get_text()
#	add_to_edit_diffs(differential)
#	singleton.bedDifferentials[singleton.currentWard][currentBed].append(differential)
#	if $InfoScreen/NinePatchRect/diffsSearchList/ScrollCont/VBoxContainer.has_node(differential):
#		$InfoScreen/NinePatchRect/diffsSearchList/ScrollCont/VBoxContainer.get_node(differential).free()

#var currentCont = 0
#func add_to_edit_diffs(diff):
#	var patch = return_diffs_patch(diff)
#	$InfoScreen/NinePatchRect/editDiffs/HBoxContainer.get_child(currentCont).add_child(patch)
#	if currentCont == 0:
#		currentCont = 1
#	else:
#		currentCont = 0

#func return_diffs_patch(diff):
#	var patch = NinePatchRect.new()
#	patch.set_texture(load("res://Graphics/UI/baseDataContainer.png"))
#	patch.set_name(diff)
#	patch.patch_margin_right = 8
#	patch.patch_margin_left = 8
#	patch.patch_margin_bottom = 8
#	patch.patch_margin_top = 8
#	patch.self_modulate = Color(0.25,0.25,0.25)
#	patch.rect_min_size = Vector2(0,25)
#	patch.set_h_size_flags(3)
#
#	var cancelButton = TextureButton.new()
#	cancelButton.texture_normal = load("res://Graphics/UI/DeleteButton.png")
#	cancelButton.texture_hover = load("res://Graphics/UI/DeleteButtonHover.png")
#	cancelButton.set_anchors_preset(11)
#	cancelButton.margin_left = -25
#	patch.add_child(cancelButton)
#	cancelButton.connect("pressed", self, "remove_diff", [cancelButton.get_node("..")])
#
#	var label = Label.new()
#	label.set_anchors_preset(15)
#	label.margin_right = -25
#	label.margin_left = 5
#	label.text = diff
#	label.clip_text = true
#	label.valign = VALIGN_CENTER
#	patch.add_child(label)
#	return patch

#func remove_diff(diff):
#	singleton.bedDifferentials[singleton.currentWard][currentBed].erase(diff.get_name())
#	create_diff_buttons([diff.get_name()], true)
#	diff.free()
#	print(differentials)

#func done_pressed():
#	currentCont = 0
#	clear_container($InfoScreen/NinePatchRect/editDiffs/HBoxContainer/VBoxContainer)
#	clear_container($InfoScreen/NinePatchRect/editDiffs/HBoxContainer/VBoxContainer2)
#	set_screen(0)
#	add_diifs_to_labels()

#func add_diifs_to_labels():
#	for diff in singleton.bedDifferentials[singleton.currentWard][currentBed]:
#		print(diff)
#		var label = Label.new()
#		label.text = " - " + diff
#		label.clip_text = true
#		label.set_h_size_flags(3)
#		label.add_color_override("font_color", Color(0.9,0.9,0.9))
#		$InfoScreen/NinePatchRect/diffLabels/HBoxContainer.get_child(currentCont).add_child(label)
#		if currentCont == 0:
#			currentCont = 1
#		else:
#			currentCont = 0
#	currentCont = 0


func print_investigations_for_bed(bed):
	for child in get_node("InfoScreen/InvestigationsBg/ScrollContainer/VBoxContainer").get_children():
		child.free()
	var complete = get_node("/root/singleton").bedInvestigations[bed]["Complete"]
	var pending = get_node("/root/singleton").bedInvestigations[bed]["Pending"]

	
	for ix in complete:
		var node = return_ixComplete_texture_button(ix)
		node.connect("pressed", self, "print_ix_values", [node])
		get_node("InfoScreen/InvestigationsBg/ScrollContainer/VBoxContainer").add_child(node)
	
	if pending.size() > 0 and complete.size() > 0:
		var separator = NinePatchRect.new()
		separator.set_texture(preload("res://Graphics/UI/CompSplitter.png"))
		separator.set_patch_margin(MARGIN_LEFT, 7)
		separator.set_patch_margin(MARGIN_TOP, 7)
		separator.set_patch_margin(MARGIN_BOTTOM, 7)
		separator.set_patch_margin(MARGIN_RIGHT, 7)
		separator.set_h_size_flags(3)
		get_node("InfoScreen/InvestigationsBg/ScrollContainer/VBoxContainer").add_child(separator)
	
	for ix in pending:
		var node = preload("res://Scenes/IxOrderButton.tscn").instance()
		node.set_name(ix)
		node.get_node("Label").set_text(ix)
		node.get_node("Cancel").connect("pressed", self, "cancel_pressed", [[node]])
		node.get_node("ProgressBar/TimeBg/Label").set_text(return_as_time(int(pending[ix]["WaitLeft"])))
		node.get_node("ProgressBar").set_value(return_percent_left(pending[ix]))
		get_node("InfoScreen/InvestigationsBg/ScrollContainer/VBoxContainer").add_child(node)
	
	if pending.size() > 0 || complete.size() > 0:
		get_node("/root/singleton/Timer").connect("timeout", self, "update_time_left", [pending])

func print_pres_for_bed():
	print_prescribed_list()

func return_ixComplete_texture_button(ix):
	var button = TextureButton.new()
	var label = Label.new()
	button.set_expand(true)
	button.set_normal_texture(preload("res://Graphics/UI/investigationReturnedNormal.png"))
	button.set_hover_texture(preload("res://Graphics/UI/ixButtonHover.png"))
	button.set_pressed_texture(preload("res://Graphics/UI/ixButtonPressed.png"))
	button.set_name(ix)
	button.set_custom_minimum_size(Vector2(0, 31))
	button.set_h_size_flags(3)
	
	label.set_valign(1)
	label.set_anchor_and_margin(MARGIN_BOTTOM, 1, 0)
	label.set_anchor_and_margin(MARGIN_RIGHT, 1, 0)
	label.set_margin(MARGIN_LEFT, 10)
	label.set_text(ix)
	button.add_child(label)
	
	return button

func return_percent_left(waitTimes):
	print(waitTimes["WaitLeft"]/waitTimes["ReturnTime"]) 
	return (waitTimes["WaitLeft"]/waitTimes["ReturnTime"]) * 1000

func update_time_left(pending):
	for ix in pending:
		if pending[ix]["WaitLeft"] >= 1:
			get_node("InfoScreen/InvestigationsBg/ScrollContainer/VBoxContainer/" + ix + "/ProgressBar").set_value(return_percent_left(pending[ix]))
			get_node("InfoScreen/InvestigationsBg/ScrollContainer/VBoxContainer/" + ix + "/ProgressBar/TimeBg/Label").set_text(return_as_time(int(pending[ix]["WaitLeft"])))
		else:
			yield(get_node("/root/singleton/Timer"), "timeout")
			print_investigations_for_bed(currentBed)

func print_ix_values(ix):
	get_node("InfoScreen/ViewIx").show()
	emit_signal("ix_view")
	var data = {}
	for type in ixData:
		if ixData[type].has(ix.get_name()):
			if type == "LIST":
				print_list_values(ixData[type][ix.get_name()], ix.get_name())
			elif type == "IMAGING":
				print_imaging_values(ixData[type][ix.get_name()], ix.get_name())

func print_list_values(data, ix):
	var containers = get_node("InfoScreen/ViewIx/IxBg/ScrollContainer/PrintIxContainer").get_children()
	get_node("InfoScreen/ViewIx").set_margin(MARGIN_TOP, 50)
	get_node("InfoScreen/ViewIx").set_margin(MARGIN_BOTTOM, -50)
	var array = ["Name", "Value", "Range", "Unit"]
	get_node("InfoScreen/ViewIx/IxBg/ScrollContainer").show()
	for i in range(4):
		for child in containers[i].get_children():
			child.free()
		var box = return_print_ix_box(array[i], Color(0.070312,0.070312,0.070312))
		box.set_self_modulate(Color(0.070312,0.070312,0.070312))
		box.get_node("detailText").add_font_override("font", preload("res://Fonts/Nunito_extra_bold20.font"))
		containers[i].add_child(box)

	for detail in data["Order"]:
		var value
		var color
		if storyIxChange["LIST"].has(ix):
			if storyIxChange["LIST"][ix].has(detail):
				color = check_value_within_range(float(storyIxChange["LIST"][ix][detail]), data["Data"][detail][1])
				value = return_print_ix_box(str(storyIxChange["LIST"][ix][detail]), color)
			else:
				color = check_value_within_range(data["Data"][detail][0], data["Data"][detail][1])
				value = return_print_ix_box(str(data["Data"][detail][0]), color)
		else:
			color = check_value_within_range(data["Data"][detail][0], data["Data"][detail][1])
			value = return_print_ix_box(str(data["Data"][detail][0]), color)


		var name = return_print_ix_box(detail, color)
		containers[0].add_child(name)
		containers[1].add_child(value)
		var ixRange = return_print_ix_box(data["Data"][detail][1], color)
		containers[2].add_child(ixRange)
		var unit = return_print_ix_box(data["Data"][detail][2], color)
		containers[3].add_child(unit)

func check_value_within_range(value, rangeString):
	if "+/-" in rangeString:
		var string = rangeString.replace("+/-", "")
		if value < float("-" + string) || value > float(string):
			 return Color(0.691406,0,0)
		else:
			return Color(0.085266,0.496094,0)
	elif "-" in rangeString:
		var rangeArray = rangeString.split("-")
		if value < float(rangeArray[0]) || value > float(rangeArray[1]):
			return Color(0.691406,0,0)
		else: 
			return Color(0.085266,0.496094,0)
	elif ">" in rangeString:
		var string = rangeString.replace(">", "")
		if value < float(string):
			 return Color(0.691406,0,0)
		else:
			return Color(0.085266,0.496094,0)
	elif "<" in rangeString:
		var string = rangeString.replace("<", "")
		if value > float(string):
			 return Color(0.691406,0,0)
		else:
			return Color(0.085266,0.496094,0)
	else:
		return Color(0.214844,0.214844,0.214844)

func ix_values_screen_btn_pressed(btn):
	if btn.get_name() == "Okay":
		get_node("InfoScreen/ViewIx").hide()
		get_node("InfoScreen/ViewIx/IxBg/ScrollContainer").hide()
		get_node("InfoScreen/ViewIx/IxBg/ImagingContainer").hide()

func print_imaging_values(data, ix):
#	print("enter")
	get_node("InfoScreen/ViewIx").set_margin(MARGIN_TOP, 20)
	get_node("InfoScreen/ViewIx").set_margin(MARGIN_BOTTOM, -20)
	get_node("InfoScreen/ViewIx/IxBg/ImagingContainer").show()
#	get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/ImagingContainer/TextureFrame").set_texture(load("res://Graphics/Images/" + data["Data"][0]))
	if storyIxChange["IMAGING"].has(ix):
#		get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen/ScrollContainer/VBoxContainer/Findings").set_text(storyIxChange["IMAGING"][ix]["Findings"])
#		get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen/ScrollContainer/VBoxContainer/Impression").set_text(storyIxChange["IMAGING"][ix]["Impression"])
		for entry in storyIxChange["IMAGING"][ix]["Report"]:
			var title = Label.new()
			title.set_text(entry)
			get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen/ScrollContainer/VBoxContainer").add_child(title)
			var text = Label.new()
			text.set_text(storyIxChange["IMAGING"][ix]["Report"])
			get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen/ScrollContainer/VBoxContainer").add_child(text)
			
		if storyIxChange["IMAGING"][ix]["Image"] != "NILL":
			$InfoScreen/ViewIx/IxBg/ImagingContainer/ImagingContainer/TextureFrame.set_texture(load("res://Graphics/Images/" + storyIxChange["IMAGING"][ix]["Image"]))
		else:
			$InfoScreen/ViewIx/IxBg/ImagingContainer/ImagingContainer/TextureFrame.set_texture(null)
	else:
		for entry in data["Report"]:
			var title = Label.new()
			title.set_autowrap(true)
			title.set_valign(VALIGN_CENTER)
			title.rect_min_size = Vector2(0, 30)
			title.add_font_override("font", load("res://Fonts/Nunito_extra_bold16.font"))
			title.set_text(entry)
			get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen/ScrollContainer/VBoxContainer").add_child(title)
			var text = Label.new()
			text.set_autowrap(true)
			text.set_text(data["Report"][entry])
			get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen/ScrollContainer/VBoxContainer").add_child(text)
#		get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen/ScrollContainer/VBoxContainer/Findings").set_text(data["Data"][2])
#		get_node("InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen/ScrollContainer/VBoxContainer/Impression").set_text(data["Data"][3])
#		if data["Data"][0] == "NILL":
#			$InfoScreen/ViewIx/IxBg/ImagingContainer/ImagingContainer/TextureFrame.set_texture(null)
#		else:
#			$InfoScreen/ViewIx/IxBg/ImagingContainer/ImagingContainer/TextureFrame.set_texture(load("res://Graphics/Images/" + data["Data"][0]))

func enlarge_image_pressed():
	var node = load("res://Scenes/largeImageScreen.tscn").instance()
	get_node("/root/World/GUI").add_child(node)
	node.get_node("image").set_texture($InfoScreen/ViewIx/IxBg/ImagingContainer/ImagingContainer/TextureFrame.get_texture())

func open_side_screen(btn):
	if btn.is_pressed() == true:
		$InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen.show()
		$InfoScreen/ViewIx/IxBg/ImagingContainer/sideScreenButton.set_position(Vector2(288, 1))
	else:
		$InfoScreen/ViewIx/IxBg/ImagingContainer/SideScreen.hide()
		$InfoScreen/ViewIx/IxBg/ImagingContainer/sideScreenButton.set_position(Vector2(470, 1))
	
func return_print_ix_box(text, color):
	var detailsCont = NinePatchRect.new()
	detailsCont.set_texture(preload("res://Graphics/UI/baseDataContainer.png"))
	detailsCont.set_h_size_flags(3)
	detailsCont.set_patch_margin(MARGIN_LEFT, 5)
	detailsCont.set_patch_margin(MARGIN_TOP, 5)
	detailsCont.set_patch_margin(MARGIN_BOTTOM, 5)
	detailsCont.set_patch_margin(MARGIN_RIGHT, 5)
	detailsCont.set_custom_minimum_size(Vector2(0, 30))
	detailsCont.set_self_modulate(color)
	
	var label = Label.new()
	label.set_clip_text(true)
	label.set_valign(1)
#	label.set_align(1)
	label.set_margin(MARGIN_BOTTOM, 0)
	label.set_margin(MARGIN_TOP, 2)
	label.set_margin(MARGIN_LEFT, 10)
	label.set_margin(MARGIN_RIGHT, 5)
	label.set_anchor(MARGIN_RIGHT, ANCHOR_END)
	label.set_anchor(MARGIN_BOTTOM, ANCHOR_END)
	label.set_name("detailText")
	label.set_text(text)
	detailsCont.add_child(label)
	
	return detailsCont
	

func investigations_to_array():
	investigationsArray.clear()
	for type in ixData:
		for ix in ixData[type]:
			if type == "LIST" or type == "IMAGING":
				investigationsArray.append(ix)
			else:
				for ix2 in ixData[type][ix]:
					investigationsArray.append(ix2)
	investigationsArray.sort()
	create_buttons(investigationsArray)

func prescribing_to_array():
	for type in data:
		for med in data[type]:
			presArray[type].append(med)
	for type in presArray:
		presArray[type].sort()
	create_pres_buttons(presArray[presType])

#Create buttons investigations search:
func create_buttons(array):
	var container = get_node("TestsScreen/SearchBg/ScrollContainer/IxSearchContainer")
	if container.get_child_count() > 0:
		for child in container.get_children():
			child.free()
	for ix in array:
		if ordered[currentBed].has(ix) == false:
			var button = preload("res://Scenes/InvestigationButton.tscn").instance()
			button.get_node("Label").set_text(ix)
			button.set_name(ix)
			button.get_node("Order").connect("pressed", self, "add_order_pressed", [button.get_name()])
			button.get_node("Info").connect("pressed", self, "ix_info_pressed", [button.get_name()])
			container.add_child(button)
			container.get_node("..").set_v_scroll(0)

func create_pres_buttons(array):
	var container = get_node("PrescribeScreen/SearchBg/ScrollContainer/DrugsSearchContainer")
	for child in container.get_children():
		child.free()
	for option in array:
		var button = preload("res://Scenes/InvestigationButton.tscn").instance()
		button.get_node("Label").set_text(option)
		button.set_name(option)
		button.get_node("Order/Label").set_text("Add")
		button.get_node("Order").connect("pressed", self, "add_prescription_details", [button.get_name()])
		button.get_node("Info").connect("pressed", self, "drug_info_pressed", [button.get_name()])
		container.add_child(button)
	container.get_node("..").set_v_scroll(0)
		
		
#Investigation search bar code:
func _on_LineEdit_text_changed( text ):

	var array = []
	if text.length() > 0:
		for item in investigationsArray:
			if (text.to_upper() in item.to_upper()) and ordered[currentBed].has(item) == false:
				array.append(item)
	else:
		for item in investigationsArray:
			if ordered[currentBed].has(item) == false:
				array.append(item)
	create_buttons(array)

#Prescribing search bar code:
func _on_LineEditPres_text_changed( text ):
	var array = []
	if text.length() > 0:
		for item in presArray[presType]:
			if (text.to_upper() in item.to_upper()) and prescribed.has(item) == false:
				array.append(item)
	else:
		array = presArray[presType]
	create_pres_buttons(array)



#var thread = Thread.new()
func add_order_pressed(ix):
	print_ix(ix)
#	add_order(ix)
	add_order(ix)
#	thread.start(self, "add_order", ix)
	
func add_order(ix):
	for type in ixData:
		if ixData[type].has(ix):
			ordered[currentBed][ix] = {"ReturnTime": ixData[type][ix]["ReturnTime"], "WaitLeft": ixData[type][ix]["ReturnTime"]}
#	print(ordered[currentBed])
#	thread.wait_to_finish()

func print_ix(ix):
	var button = preload("res://Scenes/IxOrderButton.tscn").instance()
	button.set_name(ix)
	button.get_node("Label").set_text(ix)
	button.get_node("ProgressBar/TimeBg/Label").set_text(return_wait_time(ix))
	button.get_node("Cancel").connect("pressed", self, "cancel_pressed", [[button]])
	get_node("TestsScreen/StoredIx/IxBg/ScrollContainer/IxList").add_child(button)
	if get_node("TestsScreen/SearchBg/ScrollContainer/IxSearchContainer").has_node(ix):
		pass
		#get_node("TestsScreen/SearchBg/ScrollContainer/IxSearchContainer/" + ix).free()

func return_wait_time(ix):
	var returnTime 
	for type in ixData:
		if ixData[type].has(ix):
			returnTime = int(ixData[type][ix]["ReturnTime"])
	var time = return_as_time(returnTime)
	return time
	
func return_as_time(returnTime):
	var minutes
	var seconds 
	seconds = str(returnTime % 60)
	if returnTime >= 60: 
		minutes = str((returnTime - int(seconds))/60)
	else:
		minutes = "0"
	
	if int(minutes) < 10:
		minutes = "0" + minutes 
	if int(seconds) < 10:
		seconds = "0" + seconds

	return (str(minutes) + ":" + str(seconds))

func cancel_pressed(btns):
	if currScreen == "TestsScreen":
		for btn in btns: 
			ordered[currentBed].erase(btn.get_name())
			get_node("/root/singleton").bedInvestigations[currentBed]["Pending"].erase(btn.get_name())
			_on_LineEdit_text_changed(get_node("TestsScreen/SearchBg/LineEdit").get_text())
			btn.free()
	elif currScreen == "InfoScreen":
		for btn in btns: 
			get_node("/root/singleton").bedInvestigations[currentBed]["Pending"].erase(btn.get_name())
			btn.free()

func clear_ix_pressed():
	var children = get_node("TestsScreen/StoredIx/IxBg/ScrollContainer/IxList").get_children()
	cancel_pressed(children)

func order_ix_pressed():
	print(ordered[currentBed])
	open_screens("Beds", null)
	for child in get_node("TestsScreen/StoredIx/IxBg/ScrollContainer/IxList").get_children():
		child.free()
	for ix in ordered[currentBed]:
		get_node("/root/singleton").bedInvestigations[currentBed]["Pending"][ix] = ordered[currentBed][ix]
	
	#Increase story position by 1, need to change to when orders finish but this is fine for now:
	if ordered[currentBed].size() > 0 and singleton.bedStories[singleton.currentWard][currentBed][1] == 0:
		get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][currentBed][1] = 1
	ordered[currentBed].clear()
	currentBed = null
	
#select whether medication type is fluid or medication:
func pres_type_btn_pressed(btn):
	presType = btn.get_name()
	for button in get_node("PrescribeScreen/SearchBg/Types").get_children():
		if btn != button:
			button.set_pressed(false)
	_on_LineEditPres_text_changed(get_node("PrescribeScreen/SearchBg/LineEdit").get_text())

#	if presType == "Medications":
##		get_node("PrescribeScreen/SearchBg/Types/Fluids").set_pressed(false)
#
#	elif presType == "Fluids":
#		get_node("PrescribeScreen/SearchBg/Types/Medications").set_pressed(false)
#		_on_LineEditPres_text_changed(get_node("PrescribeScreen/SearchBg/LineEdit").get_text())

var currentMed = null
func add_prescription_details(med):
	currentMed = med
	get_node("PrescribeScreen/PresDetails").show()
	get_node("PrescribeScreen/PresDetails/Title").set_text(med)
	if presType == "Medications":
		get_node("PrescribeScreen/PresDetails/MedsAddScreen").show() 
		get_node("PrescribeScreen/PresDetails/FluidsAddScreen").hide()
		get_node("PrescribeScreen/PresDetails/OxygenAddScreen").hide()
		get_node("PrescribeScreen/PresDetails").set_size(Vector2(get_node("PrescribeScreen/PresDetails").get_size().x, 146))
	elif presType == "Infusions":
		get_node("PrescribeScreen/PresDetails/FluidsAddScreen").show() 
		get_node("PrescribeScreen/PresDetails/MedsAddScreen").hide() 
		get_node("PrescribeScreen/PresDetails/OxygenAddScreen").hide()
		get_node("PrescribeScreen/PresDetails").set_size(Vector2(get_node("PrescribeScreen/PresDetails").get_size().x, 250))
		set_option_button_data(get_node("PrescribeScreen/PresDetails/FluidsAddScreen/Fluid"))
		get_node("PrescribeScreen/PresDetails/FluidsAddScreen/Fluid/AddDrug").connect("pressed", self, "open_infusion_drug_search")
	elif presType == "Oxygen":
		get_node("PrescribeScreen/PresDetails/MedsAddScreen").hide() 
		get_node("PrescribeScreen/PresDetails/FluidsAddScreen").hide()
		get_node("PrescribeScreen/PresDetails/OxygenAddScreen").show()
		get_node("PrescribeScreen/PresDetails").set_size(Vector2(get_node("PrescribeScreen/PresDetails").get_size().x, 146))
		get_node("PrescribeScreen/PresDetails/OxygenAddScreen/Oxygen/Label").set_text(med)
		set_option_button_data(get_node("PrescribeScreen/PresDetails/OxygenAddScreen/Oxygen"))
	get_node("PrescribeScreen/Cover").show()
	

func drug_info_pressed(med):
	pass
	#singleton.open_info(data[presType][med]["Info"], med)

func ix_info_pressed(ix):
	infoOpen = true
	for type in ixData:
		if ixData[type].has(ix):
			singleton.open_info(0, ix, ixData[type][ix]["Info"])

func open_infusion_drug_search():
	get_node("PrescribeScreen/PresDetails/FluidsAddScreen/AddDrugScreen").show()
	var array = []
	for drug in presArray["Medications"]:
		if data["Medications"][drug]["AsInfusion"] == true:
			array.append(drug)
	print_infusion_search_list(array)

func print_infusion_search_list(array):
	var container = get_node("PrescribeScreen/PresDetails/FluidsAddScreen/AddDrugScreen/ScrollContainer/InfusionSearchList")
	for child in container.get_children():
		child.free()
	for option in array:
		var button = preload("res://Scenes/InvestigationButton.tscn").instance()
		button.get_node("Label").set_text(option)
		button.set_name(option)
		button.get_node("Order/Label").set_text("Add")
		button.get_node("Order").connect("pressed", self, "add_infusion_drug", [button.get_name()])
#		button.get_node("Info").connect("pressed", self, "drug_info_pressed", [button.get_name()])
		container.add_child(button)
		container.get_node("..").set_v_scroll(0)

var infusionDrugsAdded = []
func add_infusion_drug(drug):
	get_node("PrescribeScreen/PresDetails/FluidsAddScreen/AddDrugScreen").hide()
	infusionDrugsAdded.append(drug)
	get_node("PrescribeScreen/PresDetails/FluidsAddScreen/NoneAdded").hide()
	print_infusion_drugs()

func clear_infusion_boxes(VBoxes):
	for box in VBoxes:
		for child in box.get_children():
			child.free()

func print_infusion_drugs():
	var VBoxes = get_node("PrescribeScreen/PresDetails/FluidsAddScreen/DrugsAdded").get_children()
	clear_infusion_boxes(VBoxes)
	var VBoxNum = 0
	
	for drug in infusionDrugsAdded:
		var HBox = HBoxContainer.new()
		var Drug = Label.new()
		
		HBox.set_h_size_flags(3)
		HBox.set_custom_minimum_size(Vector2(0, 28))
		HBox.add_constant_override("separation", 10)
		HBox.set_name(drug)
		#Add drug label to HBox. 
		Drug.set_text(drug)
		Drug.set_v_size_flags(3)
		Drug.set_valign(1)
		Drug.set_custom_minimum_size(Vector2(140, 0))
		Drug.set_clip_text(true)
		HBox.add_child(Drug)
		
		var optionBtns = ["Dose", "Unit"]
		for btn in optionBtns:
			var optionButton = OptionButton.new()
			optionButton.set_h_size_flags(3)
			optionButton.add_separator()
			optionButton.set_name(btn)
			for info in data["Medications"][drug][btn + "s"]:
				optionButton.add_item(info)
			optionButton.add_item("Other")
			var DoseLabel = Label.new()
			DoseLabel.set_text(btn)
			DoseLabel.set_name("Label")
			DoseLabel.set_anchor_and_margin(MARGIN_RIGHT, ANCHOR_END, 20)
			DoseLabel.set_anchor_and_margin(MARGIN_BOTTOM, ANCHOR_END, 0)
			DoseLabel.set_margin(MARGIN_LEFT, 10)
			DoseLabel.set_valign(1)
			DoseLabel.add_color_override("font_color", Color(0.550781,0.550781,0.550781))
			optionButton.add_child(DoseLabel)
			optionButton.connect("item_selected", self, "pres_optionBtn_item_selected", [optionButton])
			
			HBox.add_child(optionButton)
		
		var button = Button.new()
		button.set_text("Cancel")
		button.set_v_size_flags(3)
		button.set_custom_minimum_size(Vector2(70, 0))
		button.connect("pressed", self, "cancel_infusion_drug", [button])
		HBox.add_child(button)
		
		VBoxes[VBoxNum].add_child(HBox)
		
		if VBoxNum < 1:
			VBoxNum += 1
		else:
			VBoxNum = 0

func cancel_infusion_drug(btn):
	var drug = btn.get_parent()
	infusionDrugsAdded.erase(drug.get_name())
	drug.free()
	print_infusion_drugs()

func close_pres_info_screen():
	get_node("Info").hide()
	
#reset the pres details screen:
func reset_pres_details_screen():
	for child in get_node("PrescribeScreen/PresDetails/MedsAddScreen/MedsAddScreen").get_children() :
		child.hide()
	get_node("PrescribeScreen/PresDetails").set_size(Vector2(get_node("PrescribeScreen/PresDetails").get_size().x, 146))
	for btn in get_node("PrescribeScreen/PresDetails/MedsAddScreen/OptionsContainer").get_children():
		btn.set_pressed(false)
	count = 0
	get_node("PrescribeScreen/PresDetails/MedsAddScreen/NoAddedLabel").show()
	get_node("PrescribeScreen/Cover").hide()


#Loads appropriate option buttons for prescribing details if presType = Medications
var activeType = []
func pres_details_toggled(btn):
	var medsPresChildren = get_node("PrescribeScreen/PresDetails/MedsAddScreen/MedsAddScreen").get_children() 
	for child in medsPresChildren:
		if btn.get_name() == child.get_name():
			if btn.is_pressed():
				activeType.append(btn.get_name())
				get_node("PrescribeScreen/PresDetails/MedsAddScreen/NoAddedLabel").hide()
				count += 1
				child.show()
				if count > 1:
					get_node("PrescribeScreen/PresDetails").set_size(Vector2(get_node("PrescribeScreen/PresDetails").get_size().x , get_node("PrescribeScreen/PresDetails").get_size().y + 36)) 
				set_option_button_data(child) 
			else:
				activeType.erase(btn.get_name())
				count -= 1
				child.hide()
				if count > 0:
					get_node("PrescribeScreen/PresDetails").set_size(Vector2(get_node("PrescribeScreen/PresDetails").get_size().x , get_node("PrescribeScreen/PresDetails").get_size().y - 36)) 
				elif count == 0:
					get_node("PrescribeScreen/PresDetails/MedsAddScreen/NoAddedLabel").show()
	print(activeType)



func set_option_button_data(TypeHBox):
	var children = TypeHBox.get_children()
	for child in children:
		if child.get_class() == "OptionButton":
			child.get_node("Label").show()
			child.clear()
			child.add_separator()
			child.connect("item_selected", self, "pres_optionBtn_item_selected", [child])
			if data[presType][currentMed].has(child.get_name()):
				for item in data[presType][currentMed][child.get_name()]:
					child.add_item(item)
				child.add_item("Other")
			else:
				var array = []
				if child.get_name() == "Routes":
					array = ["PO", "IV", "SC", "IM", "SL", "Spray"]
				elif child.get_name() == "Frequency":
					array = ["OD", "BD", "TDS", "QDS", "ON"]
				elif child.get_name() == "Duration":
					array = range(21)
				elif child.get_name() == "DurUnits":
					array = ["Hours", "Days", "Weeks", "Months"]
				elif child.get_name() == "Volume":
					array = ["1", "2", "3", "4", "5", "50", "100", "150", "200", "250", "500", "1000"]
				elif child.get_name() == "VolUnits":
					array = ["ml", "L"]
				elif child.get_name() == "RunTime":
					array = range(25)
				elif child.get_name() == "RunTimeUnits":
					array = ["Seconds", "Minutes", "Hours"]
				elif child.get_name() == "Given":
					array = ["Continuous", "W"]
				elif child.get_name() == "Target Sats":
					array = ["88 - 92%", "94 - 98%"]
				elif child.get_name() == "Flow Rate":
					array = []
					for i in range(1, 16):
						array.append(str(i) + "L")
				for item in array:
					if str(item) != str(0):
						child.add_item(str(item))
				child.add_item("Other")

#Hide option button label on prescribing details screen. 
func pres_optionBtn_item_selected(ID, optionButton):
	optionButton.get_node("Label").hide()
	if optionButton.get_item_text(ID) == "Other":
		optionButton.hide()
		var pos = optionButton.get_position_in_parent()
		var name = optionButton.get_name()
		var placeholder = optionButton.get_node("Label").get_text()
		var parent = optionButton.get_parent()
		var otherNode = load("res://Scenes/nodeForOther.tscn").instance()
		otherNode.set_name(name + "eonxeon")
		otherNode.get_node("remove").connect("pressed", self, "cancel_other_node", [otherNode])
		otherNode.get_node("LineEdit").set_placeholder(placeholder)
		parent.add_child(otherNode)
		parent.move_child(otherNode, pos)

func cancel_other_node(otherNode):
	var optionBtnName = otherNode.get_name().replace("eonxeon", "")
	var optionButton = otherNode.get_parent().get_node(optionBtnName)
	optionButton.show()
	optionButton.select(0)
	optionButton.get_node("Label").show()
	otherNode.free()

func pres_details_main_btn_pressed(btn):
	if btn.get_name() == "Cancel":
		close_pres_details_screen()
		if presType == "Infusions":
			clear_infusion_boxes(get_node("PrescribeScreen/PresDetails/FluidsAddScreen/DrugsAdded").get_children())
			infusionDrugsAdded.clear()
	elif btn.get_name() == "Prescribe":
		add_to_prescribed()
		close_pres_details_screen()

func add_to_prescribed():
	if presType == "Medications":
		var children = get_node("PrescribeScreen/PresDetails/MedsAddScreen/MedsAddScreen").get_children()
		for child in children:
			if activeType.has(child.get_name()):
				prescriptionDict[currentBed][child.get_name()][currentMed] = {}
				for node in child.get_children():
					if node.get_class() == "OptionButton":
						if node.is_visible():
							prescriptionDict[currentBed][child.get_name()][currentMed][node.get_name()] = node.get_item_text(node.get_selected())
						else:
							var name = node.get_name() + "eonxeon"
							prescriptionDict[currentBed][child.get_name()][currentMed][node.get_name()] = child.get_node(name + "/LineEdit").get_text()

	elif presType == "Infusions":
		var children = get_node("PrescribeScreen/PresDetails/FluidsAddScreen/Fluid").get_children()
		var drugsString = ""
		var infusionDrugArray = []
		if infusionDrugsAdded.size() > 0:
			for drug in infusionDrugsAdded:
				drugsString += drug
			for node in get_node("PrescribeScreen/PresDetails/FluidsAddScreen/DrugsAdded").get_children():
				for drug in node.get_children():
					infusionDrugArray.append(drug)
		print(drugsString)
		print(infusionDrugArray)
		prescriptionDict[currentBed]["Infusion"][currentMed + drugsString] = {}
		for node in children:
			if node.get_class() == "OptionButton":
				if node.is_visible():
					prescriptionDict[currentBed]["Infusion"][currentMed  + drugsString][node.get_name()] = node.get_item_text(node.get_selected())
				else:
					var name = node.get_name() + "eonxeon"
					prescriptionDict[currentBed]["Infusion"][currentMed  + drugsString][node.get_name()] = node.get_node("../" + name + "/LineEdit").get_text()
		if infusionDrugsAdded.size() > 0:
			prescriptionDict[currentBed]["Infusion"][currentMed  + drugsString]["DrugsAdded"] = {}
			for drug in infusionDrugArray:
				var drugDose
				var drugUnit
				if drug.get_node("Dose").is_visible():
					drugDose = drug.get_node("Dose").get_item_text(drug.get_node("Dose").get_selected())
				else:
					var name = drug.get_node("Dose").get_name() + "eonxeon"
					drugDose = drug.get_node(name + "/LineEdit").get_text()
				if drug.get_node("Unit").is_visible():
					drugUnit = drug.get_node("Unit").get_item_text(drug.get_node("Unit").get_selected())
				else:
					var name = drug.get_node("Unit").get_name() + "eonxeon"
					drugUnit = drug.get_node(name + "/LineEdit").get_text()
				
				prescriptionDict[currentBed]["Infusion"][currentMed  + drugsString]["DrugsAdded"][drug.get_name()] = {"Dose": drugDose, "Unit": drugUnit}

	elif presType == "Oxygen":
		var children = get_node("PrescribeScreen/PresDetails/OxygenAddScreen/Oxygen").get_children()
		prescriptionDict[currentBed]["Oxygen"][currentMed] = {}
		for node in children:
			if node.get_class() == "OptionButton":
				if node.is_visible():
					prescriptionDict[currentBed]["Oxygen"][currentMed][node.get_name()] = node.get_item_text(node.get_selected())
				else:
					var name = node.get_name() + "eonxeon"
					prescriptionDict[currentBed]["Oxygen"][currentMed][node.get_name()] = node.get_node("../" + name + "/LineEdit").get_text()

	print(prescriptionDict[currentBed])
	print_prescribed_list()

func print_prescribed_list():
	var container
	if currScreen == "PrescribeScreen":
		container = "PrescribeScreen/StoredPres/IxBg/ScrollContainer/VBoxContainer/"
	elif currScreen == "InfoScreen":
		container = "InfoScreen/PrescriptionsBg/ScrollContainer/VBoxContainer/"
	clear_prescribed_list(container)
	var printOrder = {"OnceOnly": ["Doses", "Routes"], "Regular": ["Doses", "Routes", "Frequency", "Duration"], "AsRequired": ["Doses", "Routes", "Frequency"], "Infusion": ["Volume", "Routes", "RunTime", "DrugsAdded"], "Oxygen": ["Flow Rate", "Target Sats", "Given"]}
	for type in prescriptionDict[currentBed]:
		if prescriptionDict[currentBed][type].size() > 0:
			var bigLabel = return_big_label_node(type)
			get_node(container + type + "/BigLabelContainer").add_child(bigLabel)
			for med in prescriptionDict[currentBed][type]:
				var node = preload("res://Scenes/PrescriptionButton.tscn").instance()
				node.set_name(med)
				node.get_node("TextureButton/Label").set_text(med)
				node.get_node("TextureButton/Cancel").connect("pressed", self, "remove_prescription", [node])
				for detail in printOrder[type]:
					var detailCont = return_detail_frame_node(detail)
					if detail != "DrugsAdded":
						if detail == "Doses":
							detailCont.get_node("detailText").set_text(prescriptionDict[currentBed][type][med][detail] + " " + prescriptionDict[currentBed][type][med]["Units"])
						elif detail == "Duration":
							detailCont.get_node("detailText").set_text(prescriptionDict[currentBed][type][med][detail] + " " + prescriptionDict[currentBed][type][med]["DurUnits"])
						elif detail == "Volume":
							detailCont.get_node("detailText").set_text(prescriptionDict[currentBed][type][med][detail] + " " + prescriptionDict[currentBed][type][med]["VolUnits"])
						elif detail == "RunTime":
							detailCont.get_node("detailText").set_text(prescriptionDict[currentBed][type][med][detail] + " " + prescriptionDict[currentBed][type][med]["RunTimeUnits"])
						else:
							detailCont.get_node("detailText").set_text(prescriptionDict[currentBed][type][med][detail])
						node.get_node("DetailsContainer").add_child(detailCont)
					
					elif detail == "DrugsAdded":
						if prescriptionDict[currentBed][type][med].has("DrugsAdded"):
							node.get_node("DrugsAddedContainer").show()
							for drug in prescriptionDict[currentBed][type][med][detail]:
								var detailCont2 = return_detail_frame_node(detail)
								detailCont2.get_node("detailText").set_text("+ " + drug + " " + prescriptionDict[currentBed][type][med][detail][drug]["Dose"] + prescriptionDict[currentBed][type][med][detail][drug]["Unit"])
								node.get_node("DrugsAddedContainer").add_child(detailCont2)
					
				get_node(container + type + "/PresConatiner").add_child(node)

func return_big_label_node(type):
	var colourDict = {"OnceOnly": Color(0.992188, 0.553291, 0.127899, 1), "Regular": Color(0.070312, 1, 0.084839, 1), "AsRequired": Color(0.175781, 0.6716, 1, 1), "Infusion": Color(1, 0.179688, 0.987183, 1), "Oxygen": Color(1, 1, 1, 1)}
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
	label.set_anchor(MARGIN_RIGHT, ANCHOR_END)
	label.set_anchor(MARGIN_BOTTOM, ANCHOR_END)
	label.set_name("detailText")
	label.add_font_override("font", preload("res://Fonts/Nunito_regular16.font"))
	detailsCont.add_child(label)
	return detailsCont

func remove_prescription(node):
	var type = node.get_node("../..").get_name()
	prescriptionDict[currentBed][type].erase(node.get_name())
	node.free()
	print_prescribed_list()
	if currScreen == "PrescribeScreen":
		get_node("PrescribeScreen/StoredPres/IxBg/ScrollContainer").hide()
		get_node("PrescribeScreen/StoredPres/IxBg/ScrollContainer").show()
	elif currScreen == "InfoScreen":
		get_node("InfoScreen/PrescriptionsBg/ScrollContainer").hide()
		get_node("InfoScreen/PrescriptionsBg/ScrollContainer").show()
	

func clear_prescribed_list(container):
	for type in prescriptionDict[currentBed]:
		if prescriptionDict[currentBed][type].size() > 0:
			for label in get_node(container + type + "/BigLabelContainer").get_children():
				label.free()
			for prescribed in get_node(container + type + "/PresConatiner").get_children():
				prescribed.free()
		
		
func close_pres_details_screen():
	get_node("PrescribeScreen/PresDetails").hide()
	activeType.clear()
	reset_pres_details_screen()

func stored_pres_btn_pressed(btn):
	if btn.get_name() == "Clear":
		clear_prescribed_list("PrescribeScreen/StoredPres/IxBg/ScrollContainer/VBoxContainer/")
		for type in prescriptionDict[currentBed]:
			prescriptionDict[currentBed][type].clear()
	elif btn.get_name() == "Order":
		clear_relevant_data()
		get_node("/root/singleton").bedPrescriptions[currentBed] = prescriptionDict[currentBed]
		open_screens("Beds", null)
		currentBed = null

func on_item_rect_changed(label):
	label.set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count()))
	label.get_node("..").set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count() + 34))


#func set_labels():
#	var patientDetails = get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][currentBed][0]["PatientDetails"]
#	get_node("InfoScreen/Container/ScrollContainer/Patch9Frame/PatientInfo/PatientName").set_text("NAME: " + patientDetails["Forename"] + " " + patientDetails["Surname"])
#	get_node("InfoScreen/Container/ScrollContainer/Patch9Frame/PatientInfo/DateOfBirth").set_text("DOB: " + patientDetails["DateOfBirth"])
#	get_node("InfoScreen/Container/ScrollContainer/Patch9Frame/PatientInfo/HospitalNumber").set_text("HOSP. NUM: " + patientDetails["HospitalNumber"])

func open_diff_screen():
	get_node("InfoScreen/addDiffButton/addDiffScreen").show()
	get_node("InfoScreen/addDiffButton/diffScreenAnimation").play("diff_screen_anim")
	create_diff_buttons(diffArray)
	diffsOpen = true

#func create_diff_buttons(array):
#	var container = get_node("InfoScreen/addDiffButton/addDiffScreen/Patch9Frame/ScrollContainer/VBoxContainer")
#	for btn in container.get_children():
#		if btn.get_name() != "Control":
#			btn.free()
#	for item in array:
#		var button = Button.new()
#		button.set_h_size_flags(3)
#		button.add_font_override("font", preload("res://Fonts/Nunito_regular12.font"))
#		button.set_text(item)
#		button.set_name(item)
#		button.set_text_align(0)
#		button.set_clip_text(true)
#		button.set_toggle_mode(true)
#		button.connect("pressed", self, "differential_button_toggled", [button])
#		if differentials.has(item):
#			button.set_pressed(true)
#		container.add_child(button)
#	container.get_node("..").set_v_scroll(0)

func differential_button_toggled(btn):
	if btn.is_pressed():
		differentials.append(btn.get_name())
	else:
		differentials.erase(btn.get_name())

func add_diff_btn_pressed(btn):
	if btn.get_name() == "Add":
		if differentials.size() > 0:
			var previousDiffs = get_node("/root/singleton").bedDifferentials[get_node("/root/singleton").currentWard][currentBed]
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
	var currText = get_node("InfoScreen/Container/ScrollContainer/Patch9Frame/textEdits/TextEdit").get_text()
	if prevDiffs.length() > 0:
		currText = currText.replace(prevDiffs, diffString)

	else:
		currText += diffString
	get_node("InfoScreen/Container/ScrollContainer/Patch9Frame/textEdits/TextEdit").set_text(currText)
	set_prev_diffs()

func set_prev_diffs():
	get_node("/root/singleton").bedDifferentials[get_node("/root/singleton").currentWard][currentBed].clear()
	for diff in differentials:
		get_node("/root/singleton").bedDifferentials[get_node("/root/singleton").currentWard][currentBed].append(diff)

func hide_diffs_screen():
	get_node("InfoScreen/addDiffButton/addDiffScreen").hide()
	diffsOpen = false

func clear_differentials():
	differentials.clear()
	search_diff_text_changed(get_node("InfoScreen/addDiffButton/addDiffScreen/search").get_text())

func search_diff_text_changed(text):
	var array = []
	if text.length() > 0:
		for item in diffArray:
			if text.to_upper() in item.to_upper():
				array.append(item)
	else:
		array = diffArray
	create_diff_buttons(array)

func save_notes():
	$InfoScreen/compNotes.save_notes()

#func set_notes():
#	if singleton.bedNotes[singleton.currentWard][currentBed] != null:
#		$InfoScreen/NinePatchRect/notes.set_text(singleton.bedNotes[singleton.currentWard][currentBed])
#	add_diifs_to_labels()
#	for diff in singleton.bedDifferentials[singleton.currentWard][currentBed]:
#		add_to_edit_diffs(diff)
	

#func discharge_patient():
#	get_node("/root/singleton").reset_bed(currentBed)


func close_menu():
	if infoOpen:
		$"../InformationScreen".free()
		infoOpen = false
	elif currScreen != "BedsScreen":
		back_pressed()
	else:
		emit_signal("computer_closed")
		$"/root/World/playerNode/Player".allow_movement()
		$"/root/World/playerNode/Player".allow_interaction()
		get_node("/root/World/playerNode/Player").menuOpen = null
		queue_free()
