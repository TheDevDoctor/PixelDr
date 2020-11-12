extends NinePatchRect

signal interaction


var examinations = {}
var examSelected = null
var optionSelected = null
var facing = null
var soundTimer
var examChange = {}

func _ready():
	#Set relevant nodes hidden:
	get_node("ExaminationContainer").hide()
	get_node("ExaminationContainer/textContainer").hide()
	
	#Set sprite facing forward:
	get_node("ExaminationContainer/Sprite").set_frame(0)
	
	#Load base examination findings:
	examinations = get_node("/root/singleton").load_file_as_JSON("res://JSON_files/examinations.json")
	
	#add all examinations to option button:
	add_to_option_button()
	
	get_node("Patch9Frame/OptionButton").connect("item_selected", self, "examination_selected")
	for btn in get_node("ExaminationContainer/Facing").get_children():
		btn.connect("pressed", self, "change_facing_direction", [btn])
		btn.set_toggle_mode(true)
		if btn.get_name() == "Anterior":
			btn.set_pressed(true)
			facing = btn.get_name()
	
	soundTimer = Timer.new()
	soundTimer.set_name("Timer")
	add_child(soundTimer)
	
	set_process_input(true)
	set_process_unhandled_key_input(true)

func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("ui_cancel") && get_node("/root/World/playerNode/Player").canCancel == true:
		close_examination_screen()

func load_examination_story_data(bed):
	examChange = get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][bed][0]["Examinations"]
	print(examChange)

func add_to_option_button():
	get_node("Patch9Frame/OptionButton").add_separator()
	for exam in examinations:
		get_node("Patch9Frame/OptionButton").add_item(exam)

func examination_selected(ID):
	stop_sound()
	hide_text_container()
	get_node("Label").hide()

	examSelected = get_node("Patch9Frame/OptionButton").get_item_text(ID)
	print(examSelected)
	if get_node("/root/singleton").introDone == false:
		if examSelected == "Abdominal":
			emit_signal("interaction")
	
	if examSelected == "Cranial Nerves":
		get_node("ExaminationContainer").hide()
		get_node("OtherContainer").show()
		add_cranial_nerves_exam()
		
	else:
		get_node("ExaminationContainer").show()
		get_node("OtherContainer").hide()
		for child in get_node("ExaminationContainer/ExamOptions").get_children():
			child.free()
		for option in examinations[examSelected]:
			var button = Button.new()
			button.set_text(option)
			button.set_name(option)
			button.set_h_size_flags(3)
			button.set_toggle_mode(true)
			button.connect("pressed", self, "exam_option_chosen", [button])
			if option == "Inspect" || option == "Look":
				button.set_pressed(true)
				optionSelected = button.get_name()
			get_node("ExaminationContainer/ExamOptions").add_child(button)
		print_interactions()

func exam_option_chosen(button):
	hide_text_container()
	if get_node("/root/singleton").introDone == false:
		emit_signal("interaction")
	for btn in get_node("ExaminationContainer/ExamOptions").get_children():
		if button.get_name() == btn.get_name():
			btn.set_pressed(true)
		else:
			btn.set_pressed(false)
	optionSelected = button.get_name()
	print_interactions()
	stop_sound()
	
func print_interactions():
	clear_interactables()
	var interactPositions = {"Right Forearm": Vector2(226, 274),"Left Forearm": Vector2(366, 274),"Right Thumb": Vector2(240, 302), "Left Thumb": Vector2(350, 302),"Right Fingers": Vector2(221, 323),"Left Fingers": Vector2(366, 323),"Right Shoulder": Vector2(241, 231),"Left Shoulder": Vector2(342, 231), "Left Sole": Vector2(263, 409), "Right Sole": Vector2(324, 409),"Right Big Toe": Vector2(267, 392),"Left Big Toe": Vector2(325, 392),"Left Knee": Vector2(326, 346),"Right Knee": Vector2(262, 346), "Left Hip": Vector2(332, 303),"Right Hip": Vector2(259, 303), "Left Ankle": Vector2(314, 367),"Right Ankle": Vector2(272, 367),"Walk": Vector2(295, 407), "Left Leg": Vector2(327, 340),"Right Leg": Vector2(261, 340),"Aortic": Vector2(278, 238), "Upper Back": Vector2(295, 245), "Sacrum": Vector2(295, 306), "Rectum": Vector2(295, 330), "LungBaseR": Vector2(319, 277), "LungBaseL": Vector2(269, 277), "Pulmonary": Vector2(306, 238), "Tricuspid": Vector2(306, 267), "Mitral": Vector2(330, 275), "Right Hand": Vector2(222, 305), "Left Hand": Vector2(372, 305), "JVP": Vector2(245, 212), "Neck": Vector2(295, 230),"Right Wrist": Vector2(222, 288), "Left Wrist": Vector2(368, 288),"Right Elbow": Vector2(228, 266),"Left Elbow": Vector2(360, 266), "Eyes": Vector2(322, 185), "Mouth": Vector2(295, 205), "Face": Vector2(295, 195),"Chest": Vector2(295, 255), "LungLUpper": Vector2(277, 224), "LungLMiddle": Vector2(276, 251), "LungLLower": Vector2(267, 280), "LungRUpper": Vector2(315, 224), "LungRMiddle": Vector2(317, 251), "LungRLower": Vector2(326, 280), "Right Arm": Vector2(228, 275), "Left Arm": Vector2(363, 275), "Right Axilla": Vector2(244, 258), "Left Axilla": Vector2(345, 258), "Left Eye": Vector2(315, 186), "Right Eye": Vector2(267, 186), "Abdomen": Vector2(294, 296), "Liver": Vector2(259, 283), "Spleen": Vector2(322, 281), "Right Kidney": Vector2(329, 287), "Left Kidney": Vector2(259, 287), "Bladder": Vector2(295, 311)}
	var interactions = examinations[examSelected][optionSelected][facing]
	for interaction in interactions:
		var interactBtn = TextureButton.new()
		interactBtn.set_name(interaction)
		interactBtn.set_tooltip(interaction)
		if optionSelected == "Inspect":
			interactBtn.set_modulate(Color(0.306062,0.992188,0.139526, 0.7))
			get_node("ExaminationContainer/textContainer").set_self_modulate(Color(0.208313,1,0.070312))
			interactBtn.set_normal_texture(preload("res://Graphics/UI/Oval.png"))
		elif optionSelected == "Palpate":
			interactBtn.set_modulate(Color(0.96875,0.192993,0.938447, 0.7))
			get_node("ExaminationContainer/textContainer").set_self_modulate(Color(1,0.136719,0.986511))
			interactBtn.set_normal_texture(preload("res://Graphics/UI/Oval.png"))
		elif optionSelected == "Auscultate" || optionSelected == "Percuss":
			interactBtn.set_modulate(Color(0.00386,0.78063,0.988281, 0.8))
			interactBtn.set_normal_texture(preload("res://Graphics/UI/examSoundPlay.png"))
			interactBtn.set_pressed_texture(preload("res://Graphics/UI/examSoundStop.png"))
			interactBtn.set_toggle_mode(true)
		else:
			interactBtn.set_modulate(Color(0.306062,0.992188,0.139526, 0.7))
			get_node("ExaminationContainer/textContainer").set_self_modulate(Color(0.208313,1,0.070312))
			interactBtn.set_normal_texture(preload("res://Graphics/UI/Oval.png"))
		interactBtn.set_position(interactPositions[interaction])
		interactBtn.connect("pressed", self, "interaction_pressed", [interactBtn])
		get_node("ExaminationContainer/Interactables").add_child(interactBtn)

func clear_interactables():
	for interact in get_node("ExaminationContainer/Interactables").get_children():
		interact.free()

func interaction_pressed(interaction):
	if get_node("/root/singleton").introDone == false:
		emit_signal("interaction")
	
	if optionSelected == "Auscultate" || optionSelected == "Percuss":
		if interaction.is_pressed():
			stop_sound()
			reset_interact_btns(interaction)
			play_sound(examinations[examSelected][optionSelected][facing][interaction.get_name()])
			if "Lung" in interaction.get_name():
				soundTimer.set_wait_time(4)
			else:
				soundTimer.set_wait_time(1)
			soundTimer.connect("timeout", self, "play_sound", [examinations[examSelected][optionSelected][facing][interaction.get_name()]])
			soundTimer.start()
		elif interaction.is_pressed() == false:
			stop_sound()

	else:
		var text
		var textContainer = get_node("ExaminationContainer/textContainer")
		textContainer.show()
		textContainer.get_node("Label").set_text(interaction.get_name() + ":")
		textContainer.set_position(return_container_pos(interaction.get_name()))
		if examChange.has(examSelected):
			if examChange[examSelected].has(optionSelected):
				if examChange[examSelected][optionSelected].has(facing):
					if examChange[examSelected][optionSelected][facing].has(interaction.get_name()):
						
						text = examChange[examSelected][optionSelected][facing][interaction.get_name()]
					else:
#						print(interaction.get_name())
						text = examinations[examSelected][optionSelected][facing][interaction.get_name()]
				else:
					text = examinations[examSelected][optionSelected][facing][interaction.get_name()]
			else:
				text = examinations[examSelected][optionSelected][facing][interaction.get_name()]
		else:
			text = examinations[examSelected][optionSelected][facing][interaction.get_name()]
			
		textContainer.get_node("Patch9Frame/Text").set_bbcode(text)
		
	

func reset_interact_btns(interaction):
	for btn in get_node("ExaminationContainer/Interactables").get_children():
		if btn != interaction:
			btn.set_pressed(false)

func stop_sound():
	soundTimer.stop()
	if soundTimer.is_connected("timeout", self, "play_sound"):
		soundTimer.disconnect("timeout", self, "play_sound")
#	get_node("SamplePlayer").stop_all()

func return_container_pos(interaction):
	if interaction == "Hands" || interaction == "Wrist" || interaction == "Liver" || interaction == "Rectum":
		return Vector2(10, 280)
	elif interaction == "JVP" || interaction == "Elbow" || interaction == "Right Arm" || interaction == "Right Axilla":
		return Vector2(14, 165)
	elif interaction == "Eyes" || interaction == "Upper Back" || interaction == "Left Eye":
		return Vector2(407, 64)
	elif interaction == "Mouth" || interaction == "Neck" || interaction == "Spleen" || interaction == "Left Kidney":
		return Vector2(406, 140)
	elif interaction == "Chest" || interaction == "Sacrum" || interaction == "Left Arm" || interaction == "Left Axilla" || interaction == "Right Eye" || interaction == "Abdomen" || interaction == "Right Kidney" || interaction == "Bladder":
		return Vector2(419, 221)
	else:
		return Vector2(14, 165)

func play_sound(sound):
	print(sound)
	var noise = load(sound)
	get_node("AudioStreamPlayer").set_stream(noise)
	get_node("AudioStreamPlayer").play(0)

func change_facing_direction(facingButton):
	facing = facingButton.get_name()
	if facingButton.get_name() == "Anterior":
		get_node("ExaminationContainer/Sprite").set_frame(0)
		get_node("ExaminationContainer/Facing/Posterior").set_pressed(false)
	elif facingButton.get_name() == "Posterior":
		get_node("ExaminationContainer/Sprite").set_frame(1)
		get_node("ExaminationContainer/Facing/Anterior").set_pressed(false)
	print_interactions()
	hide_text_container()

func hide_text_container():
	get_node("ExaminationContainer/textContainer").hide()
	
func add_cranial_nerves_exam():
	var order = ["I", "II", "III, IV, VI", "V", "VII", "VIII", "IX, X", "XI", "XII"]
	var string = ""
	if examChange.has("Cranial Nerves"):
		for nerve in order:
			if examChange["Cranial Nerves"][nerve]:
				string += nerve + ": " + examChange["Cranial Nerves"] + "\n\n"
			else:
				string += nerve + ": " + examinations["Cranial Nerves"][nerve] + "\n\n"
	else:
		for nerve in order:
			string += nerve + ": " + examinations["Cranial Nerves"][nerve] + "\n\n"
	$OtherContainer.bbcode_text = string

func close_examination_screen():
	get_node("/root/World/playerNode/Player").allow_movement()
	get_node("/root/World/playerNode/Player").zoom_out()
	get_node("/root/World/playerNode/Player").menuOpen = null
	self.hide()
	get_node("/root/World/GUI/notes").close_notes()
	yield(get_node("/root/World/playerNode/Player"), "zoomed_out")
	get_node("/root/World/playerNode/Player").allow_interaction()
	get_node("..").queue_free()




