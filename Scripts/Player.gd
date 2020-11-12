extends KinematicBody2D

signal zoomed_out
signal zoomed_in
signal completed_follow
signal reached_pos
signal bed_menu_open
signal interaction
signal cancel

var direction = Vector2(0, 0)
var startPos = Vector2(0, 0)
var moving = false
var canMove = true
var world
const SPEED = 2
const GRID = 32
var camera

var resultUp
var resultDown
var resultLeft
var resultRight

var moveRight = false 
var moveLeft = false
var moveUp = false
var moveDown = false

var canZoom = true


var animPlayer
var playerSprite


var canInteract = true
var canCancel = true
var bedInteract = true
var target
var menuOpen = null
var root
var talkNotExam = false
var beginIntro = false

var zoomIn = false
var zoomOut = false

var movePlayer = false
var moveTo = null

var follow = false
var followCharacter = null
var followAxis = null
var flwAnimPlyd = false
var followFinalPos = null
var compAccess = true
var phoneAccess = true

var characters = []

func _ready():
#	set_process_input(true)
	world = get_world_2d().get_direct_space_state()
	print(world)
	animPlayer = get_node("AnimationPlayer")
	playerSprite = get_node("Sprite")
	root = get_tree().get_root().get_node("World")
	camera = get_node("Camera2D")
	for node in get_node("/root/World/CHARACTERS").get_children():
		characters.append(node.get_child(0))
	set_process_unhandled_key_input(true)
	set_physics_process(true)

func _unhandled_input(key_event):

	#This needs looking at:
	if canInteract && moving == false:
		if key_event.is_action_pressed("ui_enter"):
			var point = world.intersect_point(position + Vector2(direction * 32))
			if target != null and menuOpen == null:
				singleton.target = target.get_name()
				call_deferred("handle_interaction")
#				handle_interaction()
			elif point.size() > 0 && point[0]["collider"].get_node("../..").get_name() == "CHARACTERS":
				point[0]["collider"].play_dialogue(point[0]["collider"], "Intro9")
				canInteract = false
				canMove = false
				emit_signal("interaction")
			elif point.size() > 0 && "Tiles" in point[0]["collider"].get_name():
				var tile = get_node("/root/World/TileMaps/BehindTiles").get_cell(point[0]["metadata"].x, point[0]["metadata"].y)
				if tile == 100: 
					if singleton.playerInfo["Inventory"].has("ACCESS KEY (LEVEL 1)"):
						get_node("/root/World/TileMaps").open_door(point[0]["metadata"].x - 1, point[0]["metadata"].y)
					else:
						singleton.add_notification("You do not have access for this door", 1)
				elif tile == 120:
					get_node("/root/World/TileMaps").open_door(point[0]["metadata"].x - 1, point[0]["metadata"].y)
				elif tile == 105 :
					if singleton.playerInfo["Inventory"].has("ACCESS KEY (LEVEL 1)"):
						get_node("/root/World/TileMaps").open_door(point[0]["metadata"].x - 1, point[0]["metadata"].y)
					else:
						singleton.add_notification("You do not have access for this door", 1)
				elif tile == 125:
					get_node("/root/World/TileMaps").open_door(point[0]["metadata"].x, point[0]["metadata"].y)

		if key_event.is_action_pressed("ui_cancel"):
			if menuOpen == null:
				open_menu_screen()
	else:
		if key_event.is_action_pressed("ui_cancel") && canCancel == true:
			print("cancelling")
			if menuOpen != null:
				handle_close()
			

	if key_event.is_action_pressed("ui_up"):
		moveUp = true
	elif key_event.is_action_released("ui_up"):
		moveUp = false
	elif key_event.is_action_pressed("ui_down"):
		moveDown = true
	elif key_event.is_action_released("ui_down"):
		moveDown = false
	elif key_event.is_action_pressed("ui_left"):
		moveLeft = true
	elif key_event.is_action_released("ui_left"):
		moveLeft = false
	elif key_event.is_action_pressed("ui_right"):
		moveRight = true
	elif key_event.is_action_released("ui_right"):
		moveRight = false

func _physics_process(delta):
	if get_node("/root/singleton").introDone == false:
		if beginIntro == false && position.x == -80:
			get_node("/root/World/CHARACTERS/Dr Marshall/Dr Marshall").intro_scene()
			beginIntro = true
	
	for node in characters:
		if node.position.y > position.y && node.z_index == 0:
			node.z_index = 1
		elif node.position.y < position.y && node.z_index == 1:
			node.z_index = 0
	
	if !moving and canMove:
		#Check if space 32 pixels direction facing is empty
		resultUp = world.intersect_point(position + Vector2(0, -GRID), 32, [], 1)
		resultDown = world.intersect_point(position + Vector2(0, GRID), 32, [], 1)
		resultLeft = world.intersect_point(position + Vector2(-GRID, 0), 32, [], 1)
		resultRight = world.intersect_point(position + Vector2(GRID, 0), 32, [], 1)
#		print(resultUp[0]["rid"])
		if moveUp == true:
			direction = Vector2(0, -1) 
			if resultUp.empty():
				moving = true
				startPos = position
				animPlayer.play("walk_up")
			else:
				animPlayer.stop()
				playerSprite.set_frame(0)
		elif moveDown == true:
			direction = Vector2(0, 1)
			if resultDown.empty():
				moving = true 
				startPos = position
				animPlayer.play("walk_down")
			else:
				animPlayer.stop()
				playerSprite.set_frame(18)
		elif moveLeft == true:
			direction = Vector2(-1, 0) 
			if resultLeft.empty():
				moving = true
				startPos = position
				animPlayer.play("walk_left")
			else:
				animPlayer.stop()
				playerSprite.set_frame(9)
		elif moveRight == true:
			direction = Vector2(1, 0) 
			if resultRight.empty():
				moving = true
				startPos = position
				animPlayer.play("walk_right")
			else:
				animPlayer.stop()
				playerSprite.set_frame(27)
	elif canMove:
		set_position(position + direction * SPEED)
		if position == startPos + Vector2(GRID * direction.x, GRID * direction.y):
			moving = false
	
	elif movePlayer: 
		if position != moveTo:
			var startPos = position
			set_position(position + direction * SPEED)
		else:
			movePlayer = false
			animPlayer.stop()
			emit_signal("reached_pos")

	elif follow:
		if position == followFinalPos:
			follow = false
			followCharacter = null
			flwAnimPlyd = false
			followFinalPos = null
			animPlayer.stop()
			emit_signal("completed_follow")
		elif followAxis == 0:
			if position.x != followCharacter.position.x:
				if position.x > followCharacter.position.x:
					if flwAnimPlyd == false:
						direction = (Vector2(-1, 0))
						animPlayer.play("walk_left_rpt")
						flwAnimPlyd = true
				elif position.x < followCharacter.position.x:
					if flwAnimPlyd == false:
						direction = (Vector2(1, 0))
						animPlayer.play("walk_right_rpt")
						flwAnimPlyd = true
				set_position(position + direction * SPEED)
			else:
				followAxis = 1
				flwAnimPlyd = false
		elif followAxis == 1:
			if position.y != followCharacter.position.y:
				if position.y > followCharacter.position.y:
					if flwAnimPlyd == false:
						direction = (Vector2(0, -1))
						animPlayer.play("walk_up_rpt")
						flwAnimPlyd = true
					
				elif position.y < followCharacter.position.y:
					if flwAnimPlyd == false:
						direction = (Vector2(0, 1))
						animPlayer.play("walk_down_rpt")
						flwAnimPlyd = true
				set_position(position + direction * SPEED)
			else:
				followAxis = 0
				flwAnimPlyd = false
	
	if zoomIn == true:
		if camera.get_zoom() > Vector2(0.2, 0.2):
			camera.set_zoom(camera.get_zoom() - Vector2(0.01, 0.01))
			if talkNotExam == true:
				camera.set_position(Vector2(camera.position.x - 3, camera.position.y))
			else:
				camera.set_position(Vector2(camera.position.x + 6, camera.position.y))
		else:
			zoomIn = false
			emit_signal("zoomed_in")
	elif zoomOut == true:
		if camera.get_zoom() < Vector2(0.4, 0.4):
			camera.set_zoom(camera.get_zoom() + Vector2(0.01, 0.01))
			if talkNotExam == true:
				camera.set_position(Vector2(camera.position.x + 3, camera.position.y))
			else:
				camera.set_position(Vector2(camera.position.x - 6, camera.position.y))
		else:
			emit_signal("zoomed_out")
			talkNotExam = false
			zoomOut = false



func handle_interaction():
#	if get_node("/root/singleton").introDone == false:
	canMove = false
	canInteract = false
	if "BEDS" in target.get_parent().get_name():
		if get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][target.get_name()] == null || bedInteract == false:
			canMove = true
			canInteract = true
		else:
			open_bed_menu()
			emit_signal("interaction")
#	elif "Marshall" in target.get_name():
#		print("interact")
#		canMove = true
#		canInteract = true
	elif "COMP" in target.get_name():
		if compAccess:
			open_computer_screen()
			emit_signal("interaction")
		else:
			allow_movement()
			allow_interaction()
	elif "COLLECT" in target.get_name():
		open_collectables()
		emit_signal("interaction")
	elif "VITALS" in target.get_parent().get_name():
		if get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][target.get_name()] == null:
			canMove = true
			canInteract = true
		else:
			open_vitals_monitor()
			emit_signal("interaction")
	elif "PHONES" in target.get_parent().get_name():
		if phoneAccess:
			emit_signal("interaction")
			print(target.get_name())
			if get_node("/root/singleton").calls.has(target.get_name()):
				root.get_node("DialogueParser").init_call_dialogue(target)
				root.stop_animation()
			else:
				open_phone_screen()
		else:
			allow_movement()
			allow_interaction()

func handle_close():
	menuOpen.close_menu()
	emit_signal("cancel")

#Open bed menu screen
func open_bed_menu():
	var screen = preload("res://Scenes/BedMenuScreen.tscn").instance()
	get_tree().get_root().get_node("World/GUI").add_child(screen)
	menuOpen = screen
	#set screen position:
	var cameraSize = (get_viewport().get_visible_rect().size) * (get_node("Camera2D").get_zoom())
	var posDiff = target.position - get_node("Camera2D").get_camera_screen_center()
	screen.set_position((get_viewport().get_visible_rect().size/2 + (posDiff * 1/0.4)) - (screen.get_size()/2) - Vector2(0, target.get_region_rect().size.y/2 * 1/0.4) + Vector2(0, -80))
	
	#connect buttons to function:
	var buttons = screen.get_node("Buttons").get_children()
	for button in buttons: 
		button.connect("pressed", self, "bed_screen_button_pressed", [button])
	
	if get_node("/root/singleton").introDone == false:
		emit_signal("bed_menu_open")

func close_bed_menu():
	menuOpen = null
	get_node("/root/World/GUI/bedMenu").free()

func open_computer_screen():
	var screen = preload("res://Scenes/ComputerScreen.tscn").instance()
	get_node("/root/World/GUI").add_child(screen)
	menuOpen = screen

func open_vitals_monitor():
	var screen = preload("res://Scenes/VitalsScreen.tscn").instance()
	get_tree().get_root().get_node("/root/World/GUI").add_child(screen)
	screen.set_values(target.get_name())
	menuOpen = screen
	open_notes()

func open_collectables():
	var screen = preload("res://Scenes/CollectItemScreen.tscn").instance()
	get_tree().get_root().get_node("World/GUI").add_child(screen)
	menuOpen = screen

func open_phone_screen():
	var screen = preload("res://Scenes/phone.tscn").instance()
	menuOpen = screen
	get_tree().get_root().get_node("World/GUI").add_child(screen)

func bed_screen_button_pressed(btn):
	print("a")
#	print(btn.get_name())
	bed_action(btn.get_name())
	print("b")
	close_bed_menu()
	print("c")

func bed_action(action):
	print("1")
#	if get_node("/root/singleton").introDone == false:
	emit_signal("interaction")
	var box = null
	canInteract = false
	if action == "Talk":
		talkNotExam = true
	elif action == "Examine":
		talkNotExam = false
	
	if action == "Use Item":
		if singleton.playerInfo["Inventory"].size() > 0:
			box = load("res://Scenes/UseItem.tscn").instance()
			var cameraSize = (get_viewport().get_visible_rect().size) * (get_node("Camera2D").get_zoom())
			var posDiff = target.position - get_node("Camera2D").get_camera_screen_center()
			box.get_node("Patch9Frame").set_position((get_viewport().get_visible_rect().size/2 + (posDiff * 1/0.4)) - (box.get_node("Patch9Frame").get_size()/2) - Vector2(0, target.get_region_rect().size.y/2 * 1/0.4) + Vector2(-195, -152))
			root.get_node("GUI").add_child(box)
			open_notes()
		else:
			singleton.add_notification("You do not have any items in your inventory")
			allow_movement()
			allow_interaction()
			
	elif action == "Talk" and singleton.bedStories[singleton.currentWard][target.get_name()][1] > 0:
		print("2")
		box = load("res://Scenes/finishedIxScreen.tscn").instance()
		print("3")
		root.get_node("GUI").add_child(box)
		print("4")
	else: 
		zoom_in()
		yield(self, "zoomed_in")
		if action == "Talk":
			root.get_node("DialogueParser").init_patient_dialogue(target)
			open_notes()
			
		elif action == "Examine":
			$Camera2D.set_zoom(Vector2(1, 1))
			$Camera2D.set_offset(Vector2(0, 0))
			box = load("res://Scenes/ExaminationsNew.tscn").instance()
			box.get_node("NinePatchRect").set_global_position(self.get_global_position() - Vector2(548, 330))
			box.get_node("NinePatchRect2").set_global_position(self.get_global_position() - Vector2(578, 360))
			get_node("/root/World/TileMaps/FrontTiles").hide()
			get_node("/root/World/CHARACTERS/ResusNurse/KinematicBody2D").hide()
#			get_node("playerNode/Player/Sprite").hide()
			root.add_child(box)
			open_notes()
			
			#old examinations screen:
#			box = load("res://Scenes/ExamineBox.tscn").instance()
#			root.get_node("GUI").add_child(box)
#			box.get_node("Patch9Frame").load_examination_story_data(target.get_name())
#			open_notes()
			
		elif action == "History":
			box = load("res://Scenes/historyBot.tscn").instance()
			root.get_node("GUI").add_child(box)
			box.set_bed_data(target.get_name())
			open_notes()

func open_notes():
	var notes = preload("res://Scenes/notes.tscn").instance()
#	notes.set_bed(target.get_name())
	root.get_node("GUI").add_child(notes)
	
func open_menu_screen():
	var menu = preload("res://Scenes/GameMenu.tscn").instance()
	root.get_node("GUI").add_child(menu)

func open_help_screen(vis):
	var screen = preload("res://Scenes/HelpNodes.tscn").instance()
	for key in vis: 
		screen.get_node(key).show()
		screen.get_node(key).set_position(vis[key]["pos"])
		screen.get_node("animPlayer").play(key)
		if vis[key].has("text"):
			screen.get_node(key + "/Label").set_text(vis[key]["text"])
		if key == "textHelpLong":
			if vis[key].has("size"):
				screen.get_node(key).set_size(vis[key]["size"])
		if vis[key].has("rot"):
			screen.get_node(key).set_rotation_degrees(vis[key]["rot"])
	root.get_node("GUI").add_child(screen)

func add_world_arrow(pos):
	var arrow = preload("res://Scenes/worldArrow.tscn").instance()
	arrow.set_position(pos)
	root.add_child(arrow)

func remove_world_arrow():
	root.get_node("arrow").free()
	
func close_help_screen():
	root.get_node("GUI/Help").free()

func allow_movement():
	canMove = true

func allow_interaction():
	canInteract = true

func zoom_in():
	if canZoom:
		zoomIn = true

func zoom_out():
	if canZoom:
		zoomOut = true

func set_follow(character, initialAxis, finalPos):
	follow = true
	followCharacter = character
	followAxis = initialAxis
	followFinalPos = finalPos

func move_player_to(coordinate, direct):
	canMove = false
	movePlayer = true
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

func play_alert():
	print("play")
	get_node("/root/World/GUI/Alert").show()
	get_node("/root/World/AnimationPlayer").play("Alert")
#	yield(animPlayer, "animation_finished")
#	get_node("/root/World/GUI/Alert").hide()

func _on_area2d_body_enter(body, obj):
	if body.get_name() == "Player":
		target = obj
		print(target.get_name())
		print(menuOpen)
	
func _on_area2d_body_exit(body, obj):
	if body.get_name() == "Player":
		target = null
