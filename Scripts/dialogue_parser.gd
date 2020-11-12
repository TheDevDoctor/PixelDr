extends Node

signal dialogue_done
signal text_signal_1

var prevAnimNode
var currentStory = {}
var dialogueBoxNode
var speakingLabel
var replyBox
var textEntry
var branch
var divert
var currentBranch
var interaction
var score = 0
var dialogueOpen = false
var replyToOpen = false
var canInteract = false
var toEnd = false
var bedStory = false
#var pos_ext_set = false
var yAxis
var xAxis
var zoomedIn = false
onready var timer = Timer.new()
var connected = null

func _ready():
	
	add_child(timer)
	set_process_input(true)
	
	get_node("/root/World/playerNode/Player").connect("zoomed_in", self, "zoomed_in_pos")
	get_node("/root/World/playerNode/Player").connect("zoomed_out", self, "zoomed_out_pos")

func _unhandled_input(event):
	if dialogueOpen == true && canInteract == true:
		if event.is_action_pressed("ui_enter") and dialogueBoxNode.write == false and connected == null:
			set_next()

func zoomed_in_pos():
	zoomedIn = true

func zoomed_out_pos():
	zoomedIn = false


func reset_params(target):
	toEnd = false
	replyToOpen = false
	canInteract = true
	bedStory = false
	
	prevAnimNode = null

	score = 0
#	var box = preload("res://Scenes/DialogueBox.tscn").instance()
	var box = preload("res://Scenes/newText.tscn").instance()
	get_node("/root/World/DialogueLayer").add_child(box)
	
	var root = get_tree().get_root().get_node("World")
	dialogueBoxNode = box
#	speakingLabel = root.get_node("GUI/DialogueBox/Dialogue/Speaking/Text")
	replyBox = root.get_node("DialogueLayer/TextContainer/Reply")
	replyBox.get_node("TextEntry/Button").connect("pressed", self, "input_text")
	replyBox.get_node("TextEntry/LineEdit").connect("text_changed", self, "line_edit_text_changed")
	replyBox.hide()
	set_reply_box_pos(target)

func set_reply_box_pos(target):
	if zoomedIn == true:
		yAxis = float(130)
		replyBox.get_node("Left").hide()
		xAxis = 135
	else:
		yAxis = float(60)
		if target.get_class() != "Node":
			if target.get_position().x > get_node("/root/World/playerNode/Player").get_position().x:
				xAxis = 20
				replyBox.get_node("Left").hide()
			elif target.get_position().x < get_node("/root/World/playerNode/Player").get_position().x:
				xAxis = 690
				replyBox.get_node("Right").hide()
		else:
			xAxis = 20
	
func init_chat_dialogue(target, b):
	reset_params(target)
	var dialogue = {}
	dialogue = get_node("/root/singleton").load_file_as_JSON("res://JSON_files/character_dialogue.json")
	interaction = target.get_name()
	branch = dialogue[interaction][b]
	print("the branch is " + b)
	var first = branch["Start"] 
	set_first(first)

var bed_phrases = {}
var caller = null
func init_call_dialogue(target):
	reset_params(target)
	interaction = target.get_name()
	caller = singleton.calls[interaction]
	print(caller)
	branch = singleton.callInteractions[caller]
	singleton.calls.erase(interaction)
	replyBox.get_node("Left").hide()
	var first = branch["Start"] 
	print(first)
	set_first(first)
	var bedStories = singleton.bedStories[singleton.currentWard]
	for bed in bedStories:
		if bedStories[bed] != null:
			var string = "Could you please come and see " +  bedStories[bed][0]["PatientDetails"]["Forename"] + " " + bedStories[bed][0]["PatientDetails"]["Surname"] + " in bed " + bed.replace("BED", "") + "."
			bed_phrases[bed] = string
			print(string)

func init_patient_dialogue(target):
	#reset params:
	reset_params(target)
	interaction = target.get_name()
	bedStory = true
	#set story needed to be parsed:
	currentStory = get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][interaction][0]
	#get the current branch and first text:
	branch = currentStory["Story"][get_branch_to_play(get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][interaction][1])]
	var first = branch["Start"] 
	set_first(first)

func set_first(first):
	#set first text:
	dialogueBoxNode.set_next_text(branch[first]["content"][0].replace("[playerSurname]", singleton.playerInfo["Surname"]))
#	speakingLabel.set_size(Vector2(0, speakingLabel.get_size().y))
#	if branch[first]["content"][1]["speaking"] == "Player":
#		speakingLabel.set_text("Dr " + get_node("/root/singleton").playerInfo["Surname"])
#	else:
#		speakingLabel.set_text(branch[first]["content"][1]["speaking"])
	
	if branch[first]["content"][1].has("other"):
		divert = first
		sort_other_interaction()
	if "question" in first:
		replyToOpen = true
		divert = first
	elif branch[first]["content"][1].has("isEnd"):
		toEnd = true
	else:
		divert = branch[first]["content"][1]["divert"]
	
	dialogueOpen = true

#continue from here!!!!!
func get_branch_to_play(number):
	var currentBranch = number
	var branches = ["Before Ix", "Repeated Text", "After Ix"]
	return branches[currentBranch]


func set_next(action = null):
	if action != null:
		print("the action is: " + action)
		check_action_correct(action)
	
	if prevAnimNode != null:
		if prevAnimNode.has_node("HighlightAnims"):
			stop_highlight_anim(prevAnimNode.get_node("HighlightAnims"))
			prevAnimNode = null
	
	if connected != null:
		for sig in connected["connections"]:
			get_node(connected["connections"][sig]).disconnect(sig, self, "set_next")
			connected = null
			
	if toEnd == false:
		if replyToOpen != true:
			dialogueBoxNode.set_next_text(branch[divert]["content"][0].replace("[playerSurname]", get_node("/root/singleton").playerInfo["Surname"]))
#		set_speaking()
		if branch[divert]["content"][1].has("other"):
			sort_other_interaction()
		
		if "question" in divert:
			if replyToOpen == true:
				open_reply_box()
				print_answers()
				replyToOpen = false
			else:
				replyToOpen = true
		elif "textEntry" in divert:
			if replyToOpen == true:
				replyToOpen = false
				open_reply_box()
				set_text_entry()
			else:
				replyToOpen = true
		else:
			if branch[divert]["content"][1].has("divert"):
				divert = branch[divert]["content"][1]["divert"]
			else: 
				toEnd = true
	else: 
		end_dialogue()

func sort_other_interaction():
	var chatInteractFuncs = {"highlight": "play_highlight_animation", "connectNext": "connect_to_set_next", "activateBtn": "active_buttons_on_dialogue", "deactivateBtn": "deactive_buttons_on_dialogue", "callFunc": "call_a_function", "emitSignal": "emit_text_signal"}
	for other in branch[divert]["content"][1]["other"]:
		call(chatInteractFuncs[other])

func call_a_function():
	print("calling a func")
	get_node(branch[divert]["content"][1]["other"]["callFunc"]["node"]).callv(branch[divert]["content"][1]["other"]["callFunc"]["func"], branch[divert]["content"][1]["other"]["callFunc"]["arguments"])

func deactive_buttons_on_dialogue():
	var buttons = []
	buttons = branch[divert]["content"][1]["other"]["deactivateBtn"]
	for btn in buttons:
		get_node(btn).set_disabled(true)

func active_buttons_on_dialogue():
	var buttons = []
	buttons = branch[divert]["content"][1]["other"]["activateBtn"]
	for btn in buttons:
		get_node(btn).set_disabled(false)

var correctAction = null
var incorrectDivert = null

func connect_to_set_next():
	connected = branch[divert]["content"][1]["other"]["connectNext"]
	for sig in connected["connections"]:
#		get_node(connected["connections"][sig]).call_deferred("connect", sig, self, "set_next")
		get_node(connected["connections"][sig]).connect(sig, self, "set_next")
	if connected.has("correctAction"):
		correctAction = connected["correctAction"]
		incorrectDivert = connected["incorrectDivert"]
	else:
		correctAction = null
		incorrectDivert = null

func emit_text_signal():
	emit_signal(branch[divert]["content"][1]["other"]["emitSignal"])

func set_speaking():
	if branch[divert]["content"][1]["speaking"] == "Player":
		speakingLabel.set_text(get_node("/root/singleton").playerInfo["Surname"])
	else:
		speakingLabel.set_text(branch[divert]["content"][1]["speaking"])

func check_action_correct(action):
	if correctAction == null:
		return
	else:
		if action == correctAction:
			return
		else:
			divert = incorrectDivert
			if "[incorrectAction]" in branch[divert]["content"][0]:
				branch[divert]["content"][0] = branch[divert]["content"][0].replace("[incorrectAction]", action)

var x = 0
var sizeArray = []

func print_answers():
	replyBox.get_node("ScrollContainer").show()
	replyBox.get_node("TextEntry").hide()
	var container = replyBox.get_node("ScrollContainer/VBoxContainer")
	for btn in container.get_children():
		btn.free()
	var y = 0
	if branch[divert]["content"][1].has("adapted"):
		for bed in bed_phrases:
			add_option(bed, 1, 0)
			y += 40
		add_option("No", 2, 0)
	else:
		for i in range(branch[divert]["content"].size() - 2):
			var option = branch[divert]["content"][i + 2]
			add_option(option["option"], 0, i)
			y += 40
			
	replyBox.set_size(Vector2(replyBox.get_size().x, y + 100))
	set_replyBox_pos()
	print("y =" + str(y))

#print the branches. type 0 = normal, type 1 = bed phrases. 
func add_option(option, type, i):
	var container = replyBox.get_node("ScrollContainer/VBoxContainer")
	var button = Button.new()
	if type == 0:
		button.set_name(str(i + 2))
	elif type == 1 || 2:
		button.set_name(option)
	button.set_custom_minimum_size(Vector2(0, 40))
	
	var label = Label.new()
	if type == 0:
		label.set_text(option)
	elif type == 1:
		label.set_text(bed_phrases[option])
	elif type == 2:
		label.set_text("Actually, sorry, that's all I need.")
	label.set_valign(1)
	label.set_autowrap(true)
	label.set_margin(MARGIN_BOTTOM, -5)
	label.set_margin(MARGIN_TOP, 5)
	label.set_margin(MARGIN_LEFT, 10)
	label.set_margin(MARGIN_RIGHT, -10)
	label.set_anchor(MARGIN_RIGHT, 1)
	label.set_anchor(MARGIN_BOTTOM, 1)
	button.add_child(label)
	label.connect("item_rect_changed", self, "on_item_rect_changed", [label])
	
	if type == 0:
		button.connect("pressed", self, "option_selected", [button])
	elif type == 1 || type == 2:
		button.connect("pressed", self, "bed_phrase_selected", [button])
	container.add_child(button)

func set_replyBox_pos():
	replyBox.set_position(Vector2(xAxis - 100, ((get_viewport().get_visible_rect().size.y/2) - (replyBox.get_size().y/2) - yAxis) - 520))
#	(get_viewport().get_visible_rect().size.y/2)))
	print(xAxis)
	print("y axis = " + str(get_viewport().get_visible_rect().size.y/2))
#	 

#Below is a faff of a work around to resize the reply box depending on button size. Obvious coding solutions don't seem to work but this does. 
func set_reply_box(array):
	var x = 0
	while array.size() > replyBox.get_node("ScrollContainer/VBoxContainer").get_children().size():
		array.remove(0)
	for num in array:
		x += num + 20
	replyBox.set_size(Vector2(598, x + 70))
	print("reply box size: " + str(replyBox.get_size()))

func on_item_rect_changed(label):
	label.set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count()))
	label.get_node("..").set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count() + 20))
	sizeArray.append((label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count())
	set_reply_box(sizeArray)

func option_selected(chosen):
	close_reply_box()
	if branch[divert]["content"][int(chosen.get_name())].has("Answer"):
		if branch[divert]["content"][int(chosen.get_name())]["Answer"] == true:
			score += 1
	divert = branch[divert]["content"][int(chosen.get_name())]["linkPath"]
	set_next()

func bed_phrase_selected(chosen):
	close_reply_box()
	if chosen.get_name() != "No":
		divert = branch[divert]["content"][1]["linkPath"]
		if singleton.bedContacts[singleton.currentWard][chosen.get_name()] == null:
			bed_phrases.erase(chosen.get_name())
			singleton.bedContacts[singleton.currentWard][chosen.get_name()] = []
			singleton.bedContacts[singleton.currentWard][chosen.get_name()].append(caller)
		print(singleton.bedContacts[singleton.currentWard])
		set_next()
	else:
		divert = branch[divert]["content"][1]["linkPath2"]
		set_next()

func text_entered(text):
	if branch[divert]["content"][1]["textToEnter"] == "First Name":
		get_node("/root/singleton").playerInfo["Forename"] = text
	elif branch[divert]["content"][1]["textToEnter"] == "Surname":
		get_node("/root/singleton").playerInfo["Surname"] = text
	close_reply_box()
	divert = branch[divert]["content"][1]["divert"]
	replyBox.get_node("TextEntry/LineEdit").clear()
	set_next()

func line_edit_text_changed(text):
	if text.length() == 0:
		replyBox.get_node("TextEntry/Button").set_disabled(true)
	else:
		if replyBox.get_node("TextEntry/Button").is_disabled():
			replyBox.get_node("TextEntry/Button").set_disabled(false)

func end_dialogue():
	if singleton.introDone == true:
		get_tree().get_root().get_node("World/playerNode/Player").allow_movement()
	dialogueOpen = false
	if bedStory == true:
		get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][interaction][3] += score
		get_node("/root/World/GUI/Notes").close_notes()
		if get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][interaction][1] == 0:
			get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][interaction][1] += 1
	get_tree().get_root().get_node("World/playerNode/Player").zoom_out()
	dialogueBoxNode.free()
	if get_tree().get_root().get_node("World/playerNode/Player").canZoom:
		yield(get_tree().get_root().get_node("World/playerNode/Player"), "zoomed_out")
		get_tree().get_root().get_node("World/playerNode/Player").allow_interaction()
	emit_signal("dialogue_done")
	

func set_text_entry():
	replyBox.get_node("ScrollContainer").hide()
	replyBox.get_node("TextEntry").show()
	replyBox.get_node("TextEntry/Button").set_disabled(true)
	replyBox.set_size(Vector2(580,86))
	replyBox.get_node("TextEntry/LineEdit").set_placeholder(branch[divert]["content"][1]["placeholder"])
	replyBox.get_node("TextEntry/LineEdit").grab_focus()
	set_replyBox_pos()

func input_text():
	var text = replyBox.get_node("TextEntry/LineEdit").get_text()
	text_entered(text)

func open_reply_box():
	replyBox.show()
	canInteract = false

func close_reply_box():
	replyBox.hide()
	canInteract = true


func play_highlight_animation():
	var animDetails = branch[divert]["content"][1]["other"]["highlight"]

	if prevAnimNode != null:
		if prevAnimNode.has_node("HighlightAnims"):
			stop_highlight_anim(prevAnimNode.get_node("HighlightAnims"))
			prevAnimNode = null
	
	var animator = load("res://Scenes/HighlightAnims.tscn").instance()
	prevAnimNode = get_node(animDetails["node"])
	get_node(animDetails["node"]).add_child(animator)
	animator.play(animDetails["animation"])
	timer.set_wait_time(animDetails["length"])
	timer.connect("timeout", self, "stop_highlight_anim", [animator])
	timer.start()

func stop_highlight_anim(animator):
	animator.seek(1, true)
	timer.disconnect("timeout", self, "stop_highlight_anim")
	animator.stop()
	animator.free()
