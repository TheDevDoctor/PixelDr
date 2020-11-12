extends KinematicBody2D

var direction
var moveTo
var move = false
var SPEED = 2
var GRID = 32
var timer = 0

signal reached_pos
signal time_delay_complete

onready var animPlayer = get_node("AnimationPlayer")

func _ready():
	set_physics_process(true)
	animPlayer.get_animation("walk_left_rpt").set_loop(true)
	animPlayer.get_animation("walk_down_rpt").set_loop(true)
	animPlayer.get_animation("walk_up_rpt").set_loop(true)
	animPlayer.get_animation("walk_right_rpt").set_loop(true)
	
func _physics_process(delta):
	if move && get_position() != moveTo:
		var startPos = get_position()
		set_position(get_position() + direction * SPEED)
	else:
		move = false
		animPlayer.stop()
		emit_signal("reached_pos")
		
	
	if timer > 0.0:
		timer -= delta
		if timer <= 0:
			emit_signal("time_delay_complete")

func move_character_to(coordinate, direct):
	move = true
	moveTo = coordinate
	if direct == 0:
		direction = Vector2(0, -1)
		animPlayer.play("walk_up_rpt")
	elif direct == 1:
		direction = Vector2(1, 0)
		animPlayer.play("walk_right_rpt")
	elif direct == 2:
		direction = Vector2(0, 1)
		animPlayer.play("walk_down_rpt")
	elif direct == 3:
		direction = Vector2(-1, 0)
		animPlayer.play("walk_left_rpt")

func intro_scene():
	var GUI = get_node("/root/World/GUI")
	var player = get_node("/root/World/playerNode/Player")
	player.compAccess = false
	player.phoneAccess = false
	player.canMove = false
	player.canInteract = false
	set_position(Vector2(208, player.get_position().y))
	play_dialogue(self, "Intro1")
#	get_node("/root/World/DialogueParser").canInteract = false
#	timer = 1
#	yield(self, "time_delay_complete")
#	player.open_help_screen({"textHelp": {"pos":Vector2(1092, 515), "size": Vector2(166, 53), "text":"Press ENTER"}})
#	get_node("/root/World/DialogueParser").canInteract = true
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.canInteract = false
#	player.close_help_screen()
	move_character_to(Vector2(-48, player.get_position().y), 3)
	yield(self, "reached_pos")
	get_node("Sprite").set_frame(9)
	play_dialogue(self, "Intro2")
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	move_character_to(Vector2(-48, 304), 0)
	timer = 0.2
	yield(self, "time_delay_complete")
	player.set_follow(self, 0, Vector2(48, 144))
	yield(self, "reached_pos")
	print("move")
	move_character_to(Vector2(48, 304), 1)
	yield(self, "reached_pos")
	move_character_to(Vector2(48, 144), 0)
	yield(self, "reached_pos")
	move_character_to(Vector2(80, 144), 1)
	yield(self, "reached_pos")
	get_node("Sprite").set_frame(0)
	yield(player, "completed_follow")
	player.move_player_to(Vector2(48, 112), 0)
	yield(player, "reached_pos")
	player.get_node("Sprite").set_frame(27)
	player.bed_action("Talk")
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
#	player.open_help_screen({"textHelp": {"pos":Vector2(10, 10), "text":"Press ENTER"}})
#	yield(player, "zoomed_out")
#	print("should be playing dialogue")
	play_dialogue(self, "Intro2b")
	player.canCancel = false
	yield(player, "bed_menu_open")
#	player.close_help_screen()
	disable_buttons(["/root/World/GUI/bedMenu/Buttons/Talk", "/root/World/GUI/bedMenu/Buttons/Examine", "/root/World/GUI/bedMenu/Buttons/Use Item"])
	player.canCancel = false
	player.open_help_screen({"arrow": {"pos":Vector2(630, 144), "rot": 90}})
	yield(player, "interaction")
	player.close_help_screen()
	yield(player, "zoomed_in")
	player.canZoom = false
	player.canCancel = false
	player.open_help_screen({"arrow": {"pos":Vector2(90, 260), "rot": -90}})
	timer = 0.01
	yield(self, "time_delay_complete")
	GUI.get_node("pixelBotBox/Container/LineEdit").set_editable(false)
	yield(get_node("/root/World/DialogueParser"), "text_signal_1")
	GUI.get_node("pixelBotBox/Container/LineEdit").set_editable(true)
	player.close_help_screen()
	#add a long text option for long explanations. 
#	player.open_help_screen({"textHelpLong": {"pos":Vector2(40, 560), "size": Vector2(520, 150),"text":"To take a history simply type a question and press ENTER to send. The patient will then respond to the question. Make sure that you update the patients notes to keep a record of the history. Why not try asking what the problem is? When you have finished asking all the questions you would like, press ESC to exit."}})
	yield(GUI.get_node("pixelBotBox"), "question_sent")
	player.canCancel = false
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.canZoom = true
	print("the player can zoom")
	player.canCancel = true
	yield(player, "zoomed_out")
	play_dialogue(self, "Intro3")
	timer = 0.01
	yield(self, "time_delay_complete")
	player.canMove = false
	player.canInteract = false
	player.target = null
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.allow_movement()
	player.open_help_screen({"textHelpLong": {"pos":Vector2(10, 10), "size": Vector2(470, 50), "text":"Walk to the vitals monitor and press 'ENTER' to interact."}})
	player.add_world_arrow(Vector2(16, 40))
	yield(player, "interaction")
	player.canCancel = false
	player.close_help_screen()
	player.remove_world_arrow()
	player.open_help_screen({"arrow": {"pos":Vector2(90, 260), "rot": -90}, "textHelp": {"pos":Vector2(10, 660), "size": Vector2(353, 53), "text":"Report your findings in the notes."}})
	timer = 0.2
	yield(self, "time_delay_complete")
	yield(GUI.get_node("Notes/notesButton"), "pressed")
	player.close_help_screen()
	player.open_help_screen({"textHelp": {"pos":Vector2(10, 660), "size": Vector2(386, 53), "text":"Press 'ESC' to exit the vitals monitor."}})
	player.canCancel = true
	player.canMove = false
	yield(GUI.get_node("vitals"), "vitals_closed")
	player.canMove = false
	player.canInteract = false
	player.close_help_screen()
	timer = 0.1
	yield(self, "time_delay_complete")
	player.canMove = false
	play_dialogue(self, "Intro4")
	player.target = null
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.canMove = false
	player.canInteract = false
	player.move_player_to(Vector2(48, 112), 1)
	yield(player, "reached_pos")
	player.canInteract = true
	player.get_node("Sprite").set_frame(27)
	player.open_help_screen({"textHelp": {"pos":Vector2(10, 10), "size": Vector2(640, 53), "text":"Press ENTER to interact with the bed then press examine."}})
	player.canCancel = false
	yield(player, "bed_menu_open")
	disable_buttons(["/root/World/GUI/bedMenu/Buttons/Talk", "/root/World/GUI/bedMenu/Buttons/History", "/root/World/GUI/bedMenu/Buttons/Use Item"])
	player.close_help_screen()
	player.open_help_screen({"arrow": {"pos":Vector2(630, 176), "rot": 90}})
	yield(player, "interaction")
	player.close_help_screen()
	yield(player, "zoomed_in")
	player.canCancel = false
#	player.open_help_screen({"textHelp": {"pos":Vector2(10, 10), "size": Vector2(332, 120), "text": "Here is the examinations interface. On the right is a model where you are able to interact with the patient to collect your findings, which will appear on the left."}})
#	timer = 0.2
#	yield(self, "time_delay_complete")
	call_deferred("disable_buttons", ["/root/World/Examinations/NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions/General", "/root/World/Examinations/NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions/Inspection", "/root/World/Examinations/NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions/Palpation","/root/World/Examinations/NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions/Percussion","/root/World/Examinations/NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions/Auscultation","/root/World/Examinations/NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions/Neurotip", "/root/World/Examinations/NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions/Cotton Wool","/root/World/Examinations/NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions/Muscle", "/root/World/Examinations/NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions/Reflexes","/root/World/Examinations/NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions/Scopes", "/root/World/Examinations/NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions/Other", "/root/World/Examinations/NinePatchRect/SpriteContainer/rotateButton", "/root/World/Examinations/NinePatchRect/SpriteContainer/zoomButton", "/root/World/Examinations/NinePatchRect/Close"])
#	yield(get_node("/root/World/Examinations"), "tree_entered")
#	get_node("/root/World/Examinations/NinePatchRect/MouseStop").show()
	play_dialogue(self, "Intro4b")
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	yield(get_node("/root/World/Examinations/NinePatchRect/Close"), "pressed")
	yield(player, "zoomed_out")
	player.canMove = false
	player.target = null
	player.canCancel = true
	
#old exam screen intro:
	
#	yield(GUI.get_node("Examinations/Patch9Frame"), "interaction")
#	player.close_help_screen()
#	player.open_help_screen({"arrow": {"pos":Vector2(807, 437), "rot": 90}, "textHelpLong": {"pos":Vector2(273, 210), "size": Vector2(317, 250), "text": "In the examinations screen you are able to investigate the patient as per usual examination protocols. You are also able to examine the anterior and posterior of the patient. Make sure you don't miss important findings on the back of the patient. As well as being split as per exam protocol, the findings are in turn split into body location. Press on the HANDS now to reveal findings."}})
#	yield(GUI.get_node("Examinations/Patch9Frame"), "interaction")
#	player.close_help_screen()
#	player.open_help_screen({"textHelpLong": {"pos":Vector2(273, 260), "size": Vector2(317, 146), "text": "Great. Now continue through the rest of the examination. Remember to report your findings in the notes as you go through. When you're finished press 'ESC' to close the examinations screen."}})
#	yield(GUI.get_node("Examinations/Patch9Frame"), "interaction")
#	player.canCancel = true
#	player.close_help_screen()
#	yield(player, "zoomed_out")
#	player.canMove = false
#	player.target = null

	play_dialogue(self, "Intro5")
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.canMove = false
	move_character_to(Vector2(80, 176), 2)
	yield(self, "reached_pos")
	move_character_to(Vector2(48, 176), 3)
	yield(self, "reached_pos")
	move_character_to(Vector2(48, 368), 2)
	player.set_follow(self, 1, Vector2(48, 368))
	yield(self, "reached_pos")
	move_character_to(Vector2(16, 368), 3)
	yield(player, "completed_follow")
	get_node("Sprite").set_frame(27)
	player.get_node("Sprite").set_frame(9)
	play_dialogue(self, "Intro6")
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	move_character_to(Vector2(16, 400), 2)
	yield(self, "reached_pos")
	move_character_to(Vector2(304, 400), 1)
	timer = 0.4
	yield(self, "time_delay_complete")
	player.set_follow(self, 1, Vector2(272, 400))
	yield(self, "reached_pos")
	move_character_to(Vector2(304, 368), 0)
	yield(player, "completed_follow")
	player.move_player_to(Vector2(272, 368), 0)
	yield(player, "reached_pos")
	get_node("Sprite").set_frame(9)
	player.get_node("Sprite").set_frame(27)
	play_dialogue(self, "Intro7")
	player.target = null
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.canMove = false
	player.get_node("Sprite").set_frame(0)
	timer = 0.1
	yield(self, "time_delay_complete")
	player.target = get_node("/root/World/COMPUTERS/COMP1")
	player.compAccess = true
	player.open_help_screen({"textHelpLong": {"pos":Vector2(10, 10), "size": Vector2(280, 70), "text":"Press 'ENTER' to interact with the computer."}})
	yield(player, "interaction")
	player.canCancel = false
	player.close_help_screen()
	timer = 0.01
	yield(self, "time_delay_complete")
	GUI.get_node("ComputerScreen/Cover").show()
	player.open_help_screen({"textHelpLong": {"pos":Vector2(352, 296), "size": Vector2(576, 128), "text":"This is Pixel Hospitals main computer interface. This is where you will come to order investigations, prescribe medications, as well as admit patients to the ward or dischage them. It's also a good place to come to observe what is happening on the ward as the main screen has a list of all your patients present. Press enter to begin using the system."}})
	yield(GUI.get_node("Help"), "help_node_interact")
	GUI.get_node("ComputerScreen/Cover").hide()
	disable_buttons(["/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Info", "/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Prescribe", "/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Discharge", "/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Admit", "/root/World/GUI/ComputerScreen/Back", "/root/World/GUI/ComputerScreen/TestsScreen/StoredIx/IxBg/HBoxContainer/Clear"])
	timer = 0.01
	yield(self, "time_delay_complete")
	player.close_help_screen()
	player.open_help_screen({"arrow": {"pos":Vector2(710, 235), "rot": 90}, "textHelpLong": {"pos":Vector2(721, 114), "size": Vector2(437, 50), "text":"Click on the tests button for Mr McGuinness (BED1)."}})
	yield(GUI.get_node("ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Tests"), "pressed")
	player.close_help_screen()
	player.open_help_screen({"arrow": {"pos":Vector2(118, 200), "rot": 90}, "textHelpLong": {"pos":Vector2(100, 7), "size": Vector2(1080, 89), "text":"Order the tests: full blood count, liver function tests, CRP, urea and electrolytes, abdominal ultrasound. You can search for them in the search bar to make this easier. Clicking the 'Info' button will give you a short explanation about the test. Clicking the order button will add the investigation to your order list. When you have added all investigations needed to order list press 'ENTER' to continue."}})
	disable_buttons(["/root/World/GUI/ComputerScreen/TestsScreen/StoredIx/IxBg/HBoxContainer/Order", "/root/World/GUI/ComputerScreen/TestsScreen/StoredIx/IxBg/HBoxContainer/Clear"])
	yield(GUI.get_node("Help"), "help_node_interact")
	timer = 0.01
	yield(self, "time_delay_complete")
	player.close_help_screen()
	player.open_help_screen({"arrow": {"pos":Vector2(1016, 488), "rot": 180}, "textHelpLong": {"pos":Vector2(191, 437), "size": Vector2(414, 106), "text":"Once you have all of the investigations added to your order list make sure you click 'Order' in the bottom left to send the requests to the Pixel Lab. Press 'ENTER' to close help and continue."}})
	GUI.get_node("ComputerScreen/TestsScreen/StoredIx/IxBg/HBoxContainer/Order").set_disabled(false)
	yield(GUI.get_node("ComputerScreen/TestsScreen/StoredIx/IxBg/HBoxContainer/Order"), "pressed")
	player.close_help_screen()
	GUI.get_node("ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Tests").set_disabled(true)
	GUI.get_node("ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Info").set_disabled(false)
	player.open_help_screen({"arrow": {"pos":Vector2(605, 233), "rot": 90}, "textHelp": {"pos":Vector2(100, 36), "size": Vector2(559, 53), "text":"Now click the 'Info' button for Mr McGuinness (BED1)."}})
	yield(GUI.get_node("ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Info"), "pressed")
	player.close_help_screen()
	player.open_help_screen({"textHelpLong": {"pos":Vector2(100, 20), "size": Vector2(1080, 68), "text":"The is the patient information screen. Here you can see which investigations you have ordered, the patient's notes, as well as anything that you have prescribed. Press 'ENTER' to continue."}})
	yield(GUI.get_node("Help"), "help_node_interact")
	timer = 0.1
	yield(self, "time_delay_complete")
	player.close_help_screen()
	player.open_help_screen({"arrow": {"pos":Vector2(892, 101), "rot": 180}, "textHelpLong": {"pos":Vector2(321, 20), "size": Vector2(638, 68), "text":"Here is the investigations panel. All investigations take some time to come back as you can see counting down now. Let's speed them up. Press 'ENTER'."}})
	yield(GUI.get_node("Help"), "help_node_interact")
	timer = 0.1
	yield(self, "time_delay_complete")
	player.close_help_screen()
	for ix in get_node("/root/singleton").bedInvestigations["BED1"]["Pending"]:
		get_node("/root/singleton").bedInvestigations["BED1"]["Pending"][ix]["WaitLeft"] = 0
	player.open_help_screen({"arrow": {"pos":Vector2(641, 166), "rot": 90}, "textHelpLong": {"pos":Vector2(699, 428), "size": Vector2(406, 106), "text":"Once the return time is complete you are able to view the results by clicking on the investigation. Remember to document all your findings in the notes and update differentials as necessary."}})
	yield(GUI.get_node("ComputerScreen"), "ix_view")
	player.close_help_screen()
	yield(GUI.get_node("ComputerScreen/InfoScreen/ViewIx/IxBg/Buttons/Okay"), "pressed")
	player.canCancel = true
	GUI.get_node("ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Info").set_disabled(true)
	player.open_help_screen({"textHelp": {"pos":Vector2(100, 36), "size": Vector2(414, 53), "text":"Press 'ESC' to exit the computer screen"}})
	player.target = null
	yield(GUI.get_node("ComputerScreen"), "computer_closed")
	timer = 0.2
	yield(self, "time_delay_complete")
	player.close_help_screen()
	player.canInteract = false
	player.canMove = false
	play_dialogue(self, "Intro8")
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.allow_movement()
	player.allow_interaction()
	yield(player, "bed_menu_open")
	player.canCancel = false
	player.open_help_screen({"arrow": {"pos":Vector2(630, 110), "rot": 90}, "textHelp": {"pos":Vector2(10, 10), "text":"Click 'TALK'"}})
	disable_buttons(["/root/World/GUI/bedMenu/Buttons/History", "/root/World/GUI/bedMenu/Buttons/Examine", "/root/World/GUI/bedMenu/Buttons/Use Item"])
	yield(GUI.get_node("bedMenu/Buttons/Talk"), "pressed")
	player.close_help_screen()
	timer = 0.1
	yield(self, "time_delay_complete")
	GUI.get_node("FinishedIx/Patch9Frame/VBoxContainer/No").set_disabled(true)
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.canCancel = true
	player.open_help_screen({"textHelp": {"pos":Vector2(10, 10), "size":Vector2(288, 53), "text":"Go and talk to Dr Marshall"}})
	player.bedInteract = false
	player.allow_movement()
	set_position(Vector2(336, 464))
	get_node("Sprite").set_frame(18)
	yield(player, "interaction")
	player.close_help_screen()
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	if player.get_position().x == get_position().x:
		move_character_to(Vector2(304, 464), 3)
		yield(self, "reached_pos")
		move_character_to(Vector2(304, 432), 0)
		yield(self, "reached_pos")
		move_character_to(Vector2(176, 432), 3)
		timer = 0.2
		yield(self, "time_delay_complete")
		player.move_player_to(Vector2(176, 432), 3)
		yield(self, "reached_pos")
		move_character_to(Vector2(176, 400), 0)
	else:
		move_character_to(Vector2(336, 432), 0)
		yield(self, "reached_pos")
		move_character_to(Vector2(176, 432), 3)
		timer = 0.7
		yield(self, "time_delay_complete")
		player.move_player_to(Vector2(304, 432), 0)
		yield(player, "reached_pos")
		player.move_player_to(Vector2(176, 432), 3)
		yield(self, "reached_pos")
		move_character_to(Vector2(176, 400), 0)
	yield(player, "reached_pos")
	player.get_node("Sprite").set_frame(0)
	get_node("Sprite").set_frame(18)
	play_dialogue(self, "Intro10")
	player.canInteract = false
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.phoneAccess = true
	timer = 0.01
	yield(self, "time_delay_complete")
	player.open_help_screen({"textHelp": {"pos":Vector2(10, 10), "size": Vector2(437, 53), "text":"Press 'ENTER' to interact with the phone."}})
	yield(player, "interaction")
	player.close_help_screen()
	player.get_node("Sprite").set_frame(9)
	player.open_help_screen({"textHelpLong": {"pos":Vector2(40, 130), "size": Vector2(426, 304),"text":"This is the phone screen. From here you can contact all of the registrars in the hospital as well as certain labs.  Press on the directory to see all the possible bleeps. In order to bleep someone you must first type the extension number immediately followed by there bleep number and send the bleep by pressing #. For example, in this case we must bleep the surgical reg (1456) from the phone with the extension 12843. Therefore in order to bleep this person you must type 128431456#. Once you have sent the bleep you can go about other tasks and you will be informed when the registrar is contacting you back. Once successful press 'ESC' to exit the phone screen."}})
	player.canCancel = false
	timer = 0.01
	yield(self, "time_delay_complete")
	yield(GUI.get_node("phone"), "bleep_sent")
	print("bleep sent")
	player.canCancel = true
	player.canInteract = false
	yield(player, "cancel")
	get_node("/root/singleton").bedBleeps[get_node("/root/singleton").currentWard]["Surgical Reg."][0] = 10000
	player.close_help_screen()
	play_dialogue(self, "Intro11")
	player.target = null
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
#	player.canInteract = false
	player.canMove = false
	move_character_to(Vector2(304, 400), 1)
	timer = 0.2
	yield(self, "time_delay_complete")
	player.set_follow(self, 1, Vector2(272, 400))
	yield(self, "reached_pos")
	move_character_to(Vector2(304, 368), 0)
	yield(player, "completed_follow")
	player.move_player_to(Vector2(272, 368), 0)
	yield(player, "reached_pos")
	player.get_node("Sprite").set_frame(0)
	get_node("Sprite").set_frame(0)
	player.open_help_screen({"textHelp": {"pos":Vector2(10, 10), "size": Vector2(471, 53), "text":"Press 'ENTER' to interact with the Computer"}})
	yield(player, "interaction")
	player.close_help_screen()
	disable_buttons(["/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Info", "/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Discharge", "/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Tests", "/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Admit", "/root/World/GUI/ComputerScreen/Back"])
	player.open_help_screen({"arrow": {"pos":Vector2(815, 232), "rot": 90}})
	timer = 0.01
	yield(self, "time_delay_complete")
	yield(GUI.get_node("ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Prescribe"), "pressed")
	player.close_help_screen()
	player.open_help_screen({"textHelpLong": {"pos":Vector2(100, 9), "size": Vector2(1080, 88),"text":"This is the prescribing screen. You order most medications under the 'Medications' tab. However, if you would like to order fluid/infusions click on the tab then choose the fluid you would like to use. Try prescribing PARACETAMOL 1g PO as once only and PARACETAMOL 1g PO QDS as a  regular prescription. When added click prescribe in the bottom right."}})
	yield(GUI.get_node("ComputerScreen/PrescribeScreen/StoredPres/IxBg/Buttons/Order"), "pressed")
	player.close_help_screen()
	GUI.get_node("ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Prescribe").set_disabled(true)
	player.open_help_screen({"textHelp": {"pos":Vector2(100, 36), "size": Vector2(414, 53), "text":"Press 'ESC' to exit the computer screen"}})
	yield(player, "cancel")
	player.compAccess = false
	player.close_help_screen()
	player.target = null
	player.canMove = false
	get_node("/root/singleton").bedBleeps[get_node("/root/singleton").currentWard]["Surgical Reg."][0] = 1
	timer = 1
	yield(self, "time_delay_complete")
	play_dialogue(self, "Intro12")
	player.canMove = false
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.allow_movement()
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.canMove = false
	player.canInteract = false
	move_character_to(Vector2(304, 432), 2)
	yield(self, "reached_pos")
	move_character_to(Vector2(208, 432), 3)
	yield(self, "reached_pos")
	play_dialogue(self, "Intro13")
	player.get_node("Sprite").set_frame(27)
	get_node("Sprite").set_frame(9)
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.canMove = false
	player.canInteract = false
	move_character_to(Vector2(208, 400), 0)
	yield(self, "reached_pos")
	move_character_to(Vector2(16, 400), 3)
	yield(self, "reached_pos")
	move_character_to(Vector2(16, 624), 2)
	player.allow_movement()
	player.allow_interaction()
	player.compAccess = true
	player.open_help_screen({"textHelp": {"pos":Vector2(10, 10), "size":Vector2(288, 53), "text":"Go and open the computer"}})
	yield(player, "interaction")
	hide()
	player.canCancel = false
	player.close_help_screen()
	timer = 0.1
	yield(self, "time_delay_complete")
	player.open_help_screen({"arrow": {"pos":Vector2(980, 233), "rot": 90}, "textHelp": {"pos":Vector2(10, 10), "size":Vector2(200, 53), "text":"Click 'ADMIT'"}})
	disable_buttons(["/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Info", "/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Discharge", "/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Tests", "/root/World/GUI/ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Prescribe", "/root/World/GUI/ComputerScreen/Back"])
	yield(GUI.get_node("ComputerScreen/BedsScreen/HBoxContainer/ACTIONS/BED1/Admit"), "pressed")
	player.close_help_screen()
	player.open_help_screen({"arrow": {"pos":Vector2(770, 174), "rot": 90}, "textHelpLong": {"pos":Vector2(700, 40), "size": Vector2(490, 50), "text":"Fill in the report and admit the patient to the surgical ward."}})
	yield(GUI.get_node("ComputerScreen"), "admit_patient")
	player.close_help_screen()
	singleton.set_other_beds()
	player.canCancel = true
	singleton.introDone = true
	player.bedInteract = true
	player.compAccess = true
	player.phoneAccess = true
	move_character_to(Vector2(16, 624), 2)
	set_position(Vector2(-272, 496))
	get_node("Sprite").set_frame(9)

func isolate_section():
	var player = get_node("/root/World/playerNode/Player")

func disable_buttons(buttons):
	for btn in buttons:
		get_node(btn).set_disabled(true)
#		print(btn.get_name())

func activate_buttons(buttons):
	for btn in buttons:
		get_node(btn).set_disabled(false)
#		print(btn.get_name())

func play_dialogue(character, branch):
	get_node("/root/World/DialogueParser").init_chat_dialogue(character, branch)

func yield_deferred(object, SIGNAL):
	yield(get_node(object), SIGNAL)

