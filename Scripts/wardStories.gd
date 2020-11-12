extends Node

signal time_delay_complete

var rivalIntro = false
var cathIntro = false
var GUI
var player
var character
var timer = 0.0

func _ready():
	set_process(true)
	GUI = get_node("/root/World/GUI")
	player = get_node("/root/World/playerNode/Player")
	character = get_node("..")


func _process(delta):
	if timer > 0.0:
		timer -= delta
		if timer <= 0:
			set_process(false)
			emit_signal("time_delay_complete")
			
	
	if rivalIntro == true:
		if player.get_position().y == 400:
			rival_scene()
			rivalIntro = false
			set_process(false)
	
	if cathIntro == true:
		if player.get_position().x == 592:
			cath_scene()
			cathIntro = false
			set_process(false)

func rival_scene():
	var marshall = get_node("/root/World/CHARACTERS/Dr Marshall/Dr Marshall")
	player.canMove = false
	player.position.y = 400
	player.direction = Vector2(0, 0)
	character.play_dialogue(character, "Intro1")
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	character.move_character_to(Vector2(player.position.x + 32, player.position.y), 3)
	yield(character, "reached_pos")
	character.get_node("Sprite").set_frame(9)
	player.get_node("Sprite").set_frame(27)
	character.play_dialogue(character, "Intro2")
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.canMove = false
	player.canInteract = false
	character.move_character_to(Vector2(464, 400), 1)
	set_timer(0.1)
	yield(self, "time_delay_complete")
	player.set_follow(character, 0, Vector2(48, 304))
	player.canInteract = false
	yield(character, "reached_pos")
	print("set_marshall")
	marshall.set_position(Vector2(48, 336))
	marshall.get_node("Sprite").set_frame(18)
	character.move_character_to(Vector2(464, 304), 0)
	yield(character, "reached_pos")
	character.move_character_to(Vector2(16, 304), 3)
	yield(player, "completed_follow")
	character.get_node("Sprite").set_frame(18)
	player.get_node("Sprite").set_frame(18)
	marshall.get_node("Sprite").set_frame(0)
	character.play_dialogue(character, "Intro3")
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.canMove = false
	character.get_node("Sprite").set_frame(27)
	player.get_node("Sprite").set_frame(9)
	player.play_alert()
	set_timer(0.3)
	yield(self, "time_delay_complete")
	character.get_node("Sprite").set_frame(18)
	player.get_node("Sprite").set_frame(18)
	set_timer(0.5)
	yield(self, "time_delay_complete")
	character.get_node("Sprite").set_frame(27)
	player.get_node("Sprite").set_frame(9)
	set_timer(0.5)
	yield(self, "time_delay_complete")
	character.get_node("Sprite").set_frame(18)
	player.get_node("Sprite").set_frame(18)
	set_timer(1.0)
	yield(self, "time_delay_complete")
	add_toBeContinued()

func cath_scene():
	player.canMove = false
	player.position.y = 528
	player.direction = Vector2(0, 0)
	character.get_node("Sprite").set_frame(27)
	character.move_character_to(Vector2(560, 528), 1)
	yield(character, "reached_pos")
	character.play_dialogue(character, "Intro1")
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	character.move_character_to(Vector2(-48, 528), 3)
	player.canMove = false
	set_timer(0.1)
	yield(self, "time_delay_complete")
	player.set_follow(character, 0, Vector2(-48, 304))
	yield(character, "reached_pos")
	character.move_character_to(Vector2(-48, 272), 0)
	yield(character, "reached_pos")
	character.get_node("Sprite").set_frame(18)
	character.play_dialogue(character, "Intro2")
	player.canInteract = false
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	if singleton.playerInfo["Inventory"].has("ACCESS KEY (LEVEL 1)") == false:
		singleton.playerInfo["Inventory"].append("ACCESS KEY (LEVEL 1)")
	character.get_node("Sprite").set_frame(0)
	get_node("/root/World/TileMaps").open_door(-3, 7)
	set_timer(0.8)
	yield(self, "time_delay_complete")
	character.move_character_to(Vector2(-48, 144), 0)
	player.canMove = false
	set_timer(0.1)
	yield(self, "time_delay_complete")
	player.set_follow(character, 1, Vector2(-112, 144))
	yield(character, "reached_pos")
	character.move_character_to(Vector2(-144, 144), 3)
	yield(character, "reached_pos")
	character.move_character_to(Vector2(-144, 112), 0)
	yield(player, "completed_follow")
	player.move_player_to(Vector2(-112, 112), 0)
	yield(player, "reached_pos")
	player.get_node("Sprite").set_frame(9)
	character.get_node("Sprite").set_frame(27)
	player.target = null
	character.play_dialogue(character, "Intro3")
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.target = $"/root/World/INTERACTABLES/COLLECT"
	player.get_node("Sprite").set_frame(0)
	player.open_help_screen({"textHelp": {"pos":Vector2(1092, 515), "size": Vector2(166, 53), "text":"Press Space"}})
	yield(player, "interaction")
	player.close_help_screen()
	yield(player, "cancel")
	character.move_character_to(Vector2(-144, 144), 2)
	yield(character, "reached_pos")
	character.move_character_to(Vector2(-80, 144), 1)
	yield(character, "reached_pos")
	character.move_character_to(Vector2(-80, 208), 2)
	yield(character, "reached_pos")
#	get_node("/root/World/TileMaps").open_door(-3, 7)
	character.get_node("Sprite").set_frame(0)
	character.play_dialogue(character, "Intro4")
	player.target = null
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	character.get_node("Sprite").set_frame(18)
	yield(get_node("/root/World/TileMaps"), "door_open")
	player.canMove = false
	player.canInteract = false
	set_timer(0.6)
	yield(self, "time_delay_complete")
	character.move_character_to(Vector2(-80, 304), 2)
	yield(character, "reached_pos")
	player.set_follow(character, 1, Vector2(656, 528))
	character.move_character_to(Vector2(496, 304), 1)
	yield(character, "reached_pos")
	character.move_character_to(Vector2(496, 528), 2)
	yield(character, "reached_pos")
	character.move_character_to(Vector2(688, 528), 1)
	yield(player, "completed_follow")
	player.move_player_to(Vector2(656, 560), 2)
	yield(player, "reached_pos")
	player.move_player_to(Vector2(688, 560), 1)
	yield(player, "reached_pos")
	character.get_node("Sprite").set_frame(27)
	player.get_node("Sprite").set_frame(27)
	character.play_dialogue(character, "Intro5")
	player.target = null
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	player.target = $"/root/World/BEDS/BED8"
	player.open_help_screen({"textHelp": {"pos":Vector2(1092, 20), "size": Vector2(166, 53), "text":"Press Space"}})
	yield(player, "interaction")
	player.close_help_screen()
	player.open_help_screen({"arrow": {"pos":Vector2(630, 130), "rot": 90}, "textHelp": {"pos":Vector2(10, 10), "text":"Click 'USE ITEM'"}})
	set_timer(0.1)
	yield(self, "time_delay_complete")
	disable_buttons([GUI.get_node("bedMenu/Buttons/History"), GUI.get_node("bedMenu/Buttons/Examine"), GUI.get_node("bedMenu/Buttons/Talk")])
	yield(player, "interaction")
	player.canCancel = false
	player.close_help_screen()
	player.open_help_screen({"textHelp": {"pos":Vector2(1092, 20), "size": Vector2(166, 53), "text":"Use CATHETER"}})
	set_timer(0.1)
	yield(self, "time_delay_complete")
	yield(GUI.get_node("UseItem"), "item_used")
	player.close_help_screen()
	player.open_help_screen({"textHelpLong": {"pos":Vector2(60, 10), "size": Vector2(400, 70), "text":"Make sure to record your findings in the notes. Then press 'ESC' key to exit."}})
	player.canCancel = true
	yield(GUI.get_node("UseItem"), "closed")
	player.close_help_screen()
	character.play_dialogue(character, "Intro6")
	player.target = null
	yield(get_node("/root/World/DialogueParser"), "dialogue_done")
	character.move_character_to(Vector2(272, 528), 3)
	yield(character, "reached_pos")
	character.queue_free()

func set_timer(time):
	set_process(true)
	timer = time

func disable_buttons(buttons):
	for btn in buttons:
		btn.set_disabled(true)

func add_toBeContinued():
	var screen = load("res://tobeContDelete.tscn").instance()
	GUI.add_child(screen)
	