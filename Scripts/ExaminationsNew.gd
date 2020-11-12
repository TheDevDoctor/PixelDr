extends Node

signal area_selected

var examDict = {}
var adapted = {"General": "Base general text"}
var zoomArea = null
var interactArea = null
var currView = "FullViewAnterior"
var currInteract = null
var soundTimer
var pulse
var prevInteract
var cursor = null

func _ready():
	examDict = singleton.load_file_as_JSON("res://JSON_files/examinations_new.json")
	
	for i in range(0, $NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions.get_child_count()):
		$NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions.get_child(i).connect("pressed", self, "interaction_pressed", [$NinePatchRect/SpriteContainer/Panel/ScrollContainer/Interactions.get_child(i)])
	
	$NinePatchRect/SpriteContainer/rotateButton.connect("pressed", self, "rotate_pressed")
	$NinePatchRect/SpriteContainer/zoomButton.connect("pressed", self, "zoom_pressed")
	$NinePatchRect/SpriteContainer/back.connect("pressed", self, "back_pressed_examining")
	$NinePatchRect/ImageContainer/ScopeContainer/OpthalmoscopeCont/Increase.connect("pressed", self, "opthal_mag_changed", [$NinePatchRect/ImageContainer/ScopeContainer/OpthalmoscopeCont/Increase])
	$NinePatchRect/ImageContainer/ScopeContainer/OpthalmoscopeCont/Decrease.connect("pressed", self, "opthal_mag_changed", [$NinePatchRect/ImageContainer/ScopeContainer/OpthalmoscopeCont/Decrease])
	
	set_adapted_data()
	
	soundTimer = Timer.new()
	soundTimer.set_name("Timer")
	add_child(soundTimer)
	
	if singleton.target != null:
		pulse = singleton.bedStories[singleton.currentWard][singleton.target][0]["Vitals"]["HR"]
	else:
		pulse = 60
	
	$NinePatchRect/ImageContainer/AudioGraphic/PlayButton.connect("pressed", self, "audio_play_btn_pressed", [$NinePatchRect/ImageContainer/AudioGraphic/PlayButton])
	$NinePatchRect/Close.connect("pressed", self, "close_examinations_screen")
	
	#add general as base text:
	var interact = load("res://Scenes/textInteractNode.tscn").instance()
	interact.set_name("General")
	interact.get_node("VBoxContainer/Label").set_text("General")
	interact.get_node("VBoxContainer/Info").set_text(adapted["General"])
	interact.get_node("VBoxContainer").connect("resized", self, "text_interact_rect_changed", [interact.get_node("VBoxContainer")])
	$NinePatchRect/ScrollContainer/VBoxContainer.add_child(interact)
	
#	var dict = {"Text": {}, "Areas":{}}
#	for area in $NinePatchRect/SpriteContainer/Container.get_children():
#		print(area.get_name())
#		area.connect("mouse_entered", self, "print_entered", [area])
#		dict["Text"][area.get_name()] = true
#		dict["Areas"][area.get_name()] = {"Pos": [area.get_position().x, area.get_position().y], "Size": [area.get_scale().x, area.get_scale().y], "Coordinates": []}
#		var vertArray = area.get_node("CollisionPolygon2D").get_polygon()
#		for vert in vertArray:
#			dict["Areas"][area.get_name()]["Coordinates"].append([vert.x, vert.y])
##		print(dict[area.get_name()][0].x)
#	save_JSON(dict)

#	$NinePatchRect/SpriteContainer/Container/Area2D.connect("mouse_entered", self, "print_entered")

func set_adapted_data():
	if singleton.target != null:
		adapted = singleton.bedStories[singleton.currentWard][singleton.target][0]["Examinations"]

func _input(event):
	if event is InputEventMouseButton:
		if  (event.button_index == BUTTON_LEFT and event.pressed):  
			if zoomArea != null:
				zoom_to_area()
				zoomArea = null
			elif interactArea != null:
				interact_pos_selected()
#		elif (event.button_index == BUTTON_LEFT and !event.pressed):
#			mousePressed = false

func _process(delta):
	if cursor != null:
		pass
#		cursor.set_global_position(get_node("/root/World").get_global_mouse_position() + Vector2(22, 26))
#		cursor.set_global_position(get_viewport().get_global_mouse_position() - Vector2(380, 224))

func interaction_pressed(interaction):
	currInteract = interaction.get_name()
	var colorDict = {"General": Color(0.337255,0.329412,0.329412), "Inspection": Color(0.031372,0.552734,0.788086), "Palpation": Color(0.795898,0.537109,0.070557), "Percussion": Color(0.689941,0.06665,0.06665), "Auscultation": Color(0.607422,0.007843,0.650879), "Neurotip": Color(0.015686,0.666504,0.129395), "Cotton Wool": Color(0.443115,0.454834,1), "Reflexes": Color(0.980392,0.286275,0.023529), "Muscle": Color(0.345098,0.117647,0.564706), "Scopes": Color(0.074219,0.07045,0.07045), "Other": Color(0.086243,0.697754,0.533203)} 
	var cursorDict = {"General": null, "Inspection": "InspectCursor.png", "Palpation": "PalpateCursor.png", "Percussion": "PercussCursor.png", "Auscultation": "AuscultationCursor.png", "Neurotip": "NeurotipCursor.png", "Cotton Wool": "CottonWoolCursor.png","Reflexes": "ReflexCursor.png", "Muscle": "MuscleCursor.png", "Scopes": "ScopesCursor.png", "Other": null} 
	if has_node("CursorSprite") == false:
		cursor = Sprite.new()
		cursor.set_name("CursorSprite")
		add_child(cursor)
	if cursorDict[currInteract] == null:
		cursor.set_texture(null)
	else:
		cursor.set_texture(load("res://Graphics/UI/Cursors/" + cursorDict[currInteract]))
		
#	if cursorDict[currInteract] == null:
#		Input.set_custom_mouse_cursor(null)
#	else:
#		Input.set_custom_mouse_cursor(load("res://Graphics/UI/Cursors/" + cursorDict[currInteract]))
	$NinePatchRect/TitleContainer/CurrentInteraction.set_texture(interaction.get_normal_texture())
	$NinePatchRect/TitleContainer/Label.set_text(currInteract)
	$NinePatchRect/TitleContainer.set_self_modulate(colorDict[currInteract])
	singleton.clear_container($NinePatchRect/SpriteContainer/Container)
#	for child in $NinePatchRect/SpriteContainer/Container.get_children():
#		if child.get_name() != "MouseCatcher":
#			child.free()
	singleton.clear_container($NinePatchRect/ScrollContainer/VBoxContainer)
	if currInteract == "General" || currInteract == "Inspection" || currInteract == "Palpation":
		$NinePatchRect/ScrollContainer.show()
		$NinePatchRect/ImageContainer.hide()
		show_sprite()
		if currInteract == "General":
			var interact = load("res://Scenes/textInteractNode.tscn").instance()
			interact.set_name("General")
			interact.get_node("VBoxContainer/Label").set_text("General")
			interact.get_node("VBoxContainer/Info").set_text(adapted["General"])
			interact.get_node("VBoxContainer").connect("resized", self, "text_interact_rect_changed", [interact.get_node("VBoxContainer")])
#			this area
			$NinePatchRect/ScrollContainer/VBoxContainer.add_child(interact)
	elif currInteract == "Other":
		open_other_screen()
		$NinePatchRect/SpriteContainer/noIntLabel.hide()
	else:
		show_sprite()
		$NinePatchRect/ImageContainer.show()
		$NinePatchRect/ScrollContainer.hide()
		if currInteract == "Auscultation" || currInteract == "Percussion":
			$NinePatchRect/ImageContainer/TextureRect.margin_left = 68
			$NinePatchRect/ImageContainer/TextureRect.margin_right = -68
			$NinePatchRect/ImageContainer/TextureRect.margin_bottom = -93
			$NinePatchRect/ImageContainer/TextureRect.margin_top = 29
			$NinePatchRect/ImageContainer/AudioGraphic.show()
			$NinePatchRect/ImageContainer/TextureRect/soundAnim.show()
			$NinePatchRect/ImageContainer/ScopeContainer.hide()
			$NinePatchRect/ImageContainer/ReflexPanel.hide()
			$NinePatchRect/ImageContainer/TextureRect.show()
		elif currInteract == "Scopes":
			currView = "HeadAnterior"
			$NinePatchRect/SpriteContainer/Sprite.set_frame(8)
			$NinePatchRect/SpriteContainer/back.show()
			$NinePatchRect/ImageContainer/AudioGraphic.hide()
			$NinePatchRect/ImageContainer/TextureRect/soundAnim.hide()
			$NinePatchRect/ImageContainer/ScopeContainer.show()
			$NinePatchRect/ImageContainer/TextureRect.hide()
			$NinePatchRect/ImageContainer/ReflexPanel.hide()
		elif currInteract == "Reflexes":
			$NinePatchRect/ImageContainer/ReflexPanel.show()
			$NinePatchRect/ImageContainer/AudioGraphic.hide()
			$NinePatchRect/ImageContainer/TextureRect/soundAnim.hide()
			$NinePatchRect/ImageContainer/ScopeContainer.hide()
			$NinePatchRect/ImageContainer/TextureRect.hide()
		else:
			$NinePatchRect/ImageContainer/TextureRect.margin_left = 37
			$NinePatchRect/ImageContainer/TextureRect.margin_right = -37
			$NinePatchRect/ImageContainer/TextureRect.margin_bottom = -29
			$NinePatchRect/ImageContainer/TextureRect.margin_top = 29
			$NinePatchRect/ImageContainer/AudioGraphic.hide()
			$NinePatchRect/ImageContainer/TextureRect/soundAnim.hide()
			$NinePatchRect/ImageContainer/ScopeContainer.hide()
			$NinePatchRect/ImageContainer/ReflexPanel.hide()
			$NinePatchRect/ImageContainer/TextureRect.show()
	
	if currInteract != "Other":
		get_polys_for_interact()

func rotate_pressed():
	if $NinePatchRect/SpriteContainer/Sprite.get_frame() == 0:
		$NinePatchRect/SpriteContainer/Sprite.set_frame(1)
		currView = "FullViewPosterior"
	elif $NinePatchRect/SpriteContainer/Sprite.get_frame() == 1:
		$NinePatchRect/SpriteContainer/Sprite.set_frame(0)
		currView = "FullViewAnterior"
	elif $NinePatchRect/SpriteContainer/Sprite.get_frame() == 6:
		$NinePatchRect/SpriteContainer/Sprite.set_frame(7)
		currView = "BodyPosterior"
	elif $NinePatchRect/SpriteContainer/Sprite.get_frame() == 7:
		$NinePatchRect/SpriteContainer/Sprite.set_frame(6)
		currView = "BodyAnterior"
	elif $NinePatchRect/SpriteContainer/Sprite.get_frame() == 8:
		$NinePatchRect/SpriteContainer/Sprite.set_frame(9)
		currView = "HeadPosterior"
	elif $NinePatchRect/SpriteContainer/Sprite.get_frame() == 9:
		$NinePatchRect/SpriteContainer/Sprite.set_frame(8)
		currView = "HeadAnterior"
	singleton.clear_container($NinePatchRect/SpriteContainer/Container)
	singleton.clear_container($NinePatchRect/ScrollContainer/VBoxContainer)
	get_polys_for_interact()

func print_entered(area):
	print(area.get_name())

func save_JSON(saveFile):
	var performance = File.new()
	performance.open("res://examinePositions.json", File.WRITE)
	performance.store_line(to_json(saveFile))
	performance.close()
#	send_performance_to_cosmos(saveFile)

func zoom_pressed():
	singleton.clear_container($NinePatchRect/SpriteContainer/Container)
	for pos in examDict["ZoomAreaData"]:
		var area = print_polygon(examDict["ZoomAreaData"][pos], pos)
		area.connect("mouse_entered", self, "mouse_zoom_entered", [area])
		area.connect("mouse_exited", self, "mouse_zoom_exited", [area])

func print_polygon(dict, name):
#	for interact in array:
	var polygon = CollisionPolygon2D.new()
	
	var vectorArray = []
	for array in dict["Coordinates"]:
		vectorArray.append(Vector2(array[0], array[1]))
	polygon.set_polygon(vectorArray)
	polygon.show_behind_parent = true
	
	var area2d = Area2D.new()
	area2d.set_position(Vector2(dict["Pos"][0], dict["Pos"][1]))
	area2d.set_scale(Vector2(dict["Size"][0], dict["Size"][1]))
	area2d.add_child(polygon)
	area2d.set_name(name)
	area2d.show_behind_parent = true
	
	#For printing test polys visually:
#	var printPoly = Polygon2D.new()
#	printPoly.set_polygon(PoolVector2Array(vectorArray))
#	area2d.add_child(printPoly)
	
	$NinePatchRect/SpriteContainer/Container.add_child(area2d)
	return area2d

func mouse_zoom_entered(area):
	zoomArea = area.get_name()
	$NinePatchRect/SpriteContainer/Sprite/Control.get_node(area.get_name()).show()
	print("entered")

func mouse_zoom_exited(area):
	if area.get_name() == zoomArea:
		zoomArea = null
	$NinePatchRect/SpriteContainer/Sprite/Control.get_node(area.get_name()).hide()

func zoom_to_area():
	emit_signal("area_selected", zoomArea)
	$NinePatchRect/SpriteContainer/back.show()
	$NinePatchRect/SpriteContainer/Sprite/Control.get_node(zoomArea).hide()
	var zoomDict = {"RightArm": 2, "LeftArm": 3, "RightLeg": 4, "LeftLeg": 5, "Body": 6, "Face": 8}
	$NinePatchRect/SpriteContainer/Sprite.set_frame(zoomDict[zoomArea])
	singleton.clear_container($NinePatchRect/SpriteContainer/Container)
	singleton.clear_container($NinePatchRect/ScrollContainer/VBoxContainer)
	if zoomArea == "Body":
		if currView == "FullViewAnterior":
			currView = "BodyAnterior"
			$NinePatchRect/SpriteContainer/Sprite.set_frame(zoomDict[zoomArea])
		elif currView == "FullViewPosterior":
			currView = "BodyPosterior"
			$NinePatchRect/SpriteContainer/Sprite.set_frame(zoomDict[zoomArea] + 1)
	elif zoomArea == "Face":
		if currView == "FullViewAnterior":
			currView = "HeadAnterior"
			$NinePatchRect/SpriteContainer/Sprite.set_frame(zoomDict[zoomArea])
		elif currView == "FullViewPosterior":
			currView = "HeadPosterior"
			$NinePatchRect/SpriteContainer/Sprite.set_frame(zoomDict[zoomArea] + 1)
	else:
		currView = zoomArea
		$NinePatchRect/SpriteContainer/Sprite.set_frame(zoomDict[zoomArea])
	get_polys_for_interact()
	zoomArea = null

func back_pressed_examining():
	if currInteract == "Scopes" and $NinePatchRect/SpriteContainer/ExamImages.is_visible():
		$NinePatchRect/SpriteContainer/ExamImages.hide()
	else:
		$NinePatchRect/SpriteContainer/Sprite.set_frame(0)
		$NinePatchRect/SpriteContainer/back.hide()
		singleton.clear_container($NinePatchRect/SpriteContainer/Container)
		singleton.clear_container($NinePatchRect/ScrollContainer/VBoxContainer)
		currView = "FullViewAnterior"
		get_polys_for_interact()
		if currInteract == "Auscultation" or currInteract == "Percussion":
			stop_audio_animations()

func get_polys_for_interact():
#	print(currInteract)
#	print(currView)
	if currInteract != null && currInteract != "General":
		if examDict["NormalFindings"][currInteract].has(currView):
			$NinePatchRect/SpriteContainer/noIntLabel.hide()
			for pos in examDict["NormalFindings"][currInteract][currView]:
				var poly = print_polygon(examDict["AreaData"][currView][pos], pos)
				poly.connect("mouse_entered", self, "poly_mouse_enter", [poly])
				poly.connect("mouse_exited", self, "poly_mouse_exit", [poly])
		else:
			$NinePatchRect/SpriteContainer/noIntLabel.show()
			print("There are no positions for this")

func poly_mouse_enter(poly):
	print(poly.get_name() + "Hovering")
	interactArea = poly.get_name()

func poly_mouse_exit(poly):
	if interactArea == poly.get_name():
		interactArea = null
		print("Null")
#	print(interactArea)

func interact_pos_selected():
	if currInteract != null:
		emit_signal("area_selected", interactArea)
	if $NinePatchRect/ScrollContainer/VBoxContainer.has_node(interactArea) == false:
		if currInteract == "Inspection" || currInteract == "Palpation":
			if adapted_response() == true:
				print_text_interaction(adapted[currInteract][currView][interactArea])
			else:
				print_text_interaction(examDict["NormalFindings"][currInteract][currView][interactArea])
		elif currInteract == "Neurotip" || currInteract == "Cotton Wool":
			print_neurotip_interaction()
		elif currInteract == "Auscultation" || currInteract == "Percussion":
			play_sound()
			prevInteract = interactArea
		elif currInteract == "Reflexes":
			$NinePatchRect/ImageContainer/ReflexPanel/Reflexometer.play(examDict["NormalFindings"][currInteract][currView][interactArea])
			$NinePatchRect/ImageContainer/ReflexPanel/ReflexLabel.set_text(interactArea)
		elif currInteract == "Scopes":
			if $NinePatchRect/SpriteContainer/ExamImages.is_visible() == false:
				$NinePatchRect/SpriteContainer/ExamImages.show()
			$NinePatchRect/SpriteContainer/ExamImages.set_texture(load(examDict["NormalFindings"][currInteract][currView][interactArea]))
			if "Ear" in interactArea:
				$NinePatchRect/ImageContainer/ScopeContainer/OtoscopeCont.set_self_modulate(Color(0.058594,0.911743,1,0.21549))
				$NinePatchRect/ImageContainer/ScopeContainer/OpthalmoscopeCont.set_self_modulate(Color(0.4375,0.4375,0.4375,0.093922))
			else:
				$NinePatchRect/ImageContainer/ScopeContainer/OpthalmoscopeCont.set_self_modulate(Color(0.058594,0.911743,1,0.21549))
				$NinePatchRect/ImageContainer/ScopeContainer/OtoscopeCont.set_self_modulate(Color(0.4375,0.4375,0.4375,0.093922))

func adapted_response():
	if adapted.has(currInteract): 
		if adapted[currInteract].has(currView):
			if adapted[currInteract][currView].has(interactArea):
				return true
			else:
				return false
		else: 
			return false
	else:
		return false

func print_text_interaction(text, test = null):
	var interact = load("res://Scenes/textInteractNode.tscn").instance()
	if interactArea == null:
		interact.set_name(test)
		interact.get_node("VBoxContainer/Label").set_text(test)
		interact.get_node("VBoxContainer/Info").set_text(text)
	else:
		interact.set_name(interactArea)
		interact.get_node("VBoxContainer/Label").set_text(interactArea)
		interact.get_node("VBoxContainer/Info").set_text(text)
	interact.get_node("VBoxContainer").connect("resized", self, "text_interact_rect_changed", [interact.get_node("VBoxContainer")])
	$NinePatchRect/ScrollContainer/VBoxContainer.add_child(interact)

func text_interact_rect_changed(VBox):
	print("VBox Changed")
	VBox.get_node("..").set_custom_minimum_size(Vector2(0, (VBox.get_size().y + 10)))
#	VBox.set_custom_minimum_size(Vector2(0, (VBox.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count()))
#	label.get_node("..").set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count() + 20))
#	sizeArray.append((label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count())
#	set_reply_box(sizeArray)


func play_sound():
	var path
	var sound
	$NinePatchRect/ImageContainer/AudioGraphic/PlayButton.set_pressed(true)

	if adapted_response():
		if interactArea == null:
			path = adapted[currInteract][currView][prevInteract]
		else:
			path = adapted[currInteract][currView][interactArea]
		sound = load(path)
	else: 
		if interactArea == null:
			path = examDict["NormalFindings"][currInteract][currView][prevInteract]
		else:
			path = examDict["NormalFindings"][currInteract][currView][interactArea]
		sound = load(path)
	get_node("AudioStreamPlayer").set_stream(sound)
	get_node("AudioStreamPlayer").play(0)
	
	var rpt
	if "HeartSounds" in path:
		rpt = float(60)/float(pulse)
		rpt_sound(sound, rpt)
		set_pulse_meter(rpt)
	elif "Percussion" in path:
		rpt = 3
		rpt_sound(sound, rpt)
	set_animations(rpt)

func rpt_sound(sound, rpt):
	soundTimer.set_wait_time(rpt)
	soundTimer.connect("timeout", self, "play_sound_rpt", [sound])
	soundTimer.start()

func play_sound_rpt(sound):
	get_node("AudioStreamPlayer").set_stream(sound)
	get_node("AudioStreamPlayer").play(0)

func set_pulse_meter(rpt):
	var speed = float(pulse)/float(60)
	$NinePatchRect/SpriteContainer/PulseMonitor/Pulse.play("Pulse", -1, speed)

func set_animations(rpt):
	print(rpt)
	var soundPositions = {"Aortic Valve": Vector2(167, 73), "Pulmonary Valve": Vector2(188, 73), "Tricuspid Valve": Vector2(188, 98), "Mitral Valve": Vector2(205, 114), "Lung Apex R": Vector2(154, 58), "Lung Apex L": Vector2(198, 58), "Lung Upper R": Vector2(157, 73), "Lung Upper L": Vector2(194, 73), "Lung Middle R": Vector2(160, 92), "Lung Middle L": Vector2(194, 92), "Lung Lower R": Vector2(159, 109), "Lung Lower L": Vector2(195, 109), "Abdomen2": Vector2(177, 153)}
	if currInteract == "Auscultation":
		if interactArea == null: 
			$NinePatchRect/ImageContainer/TextureRect/soundAnim.set_position(soundPositions[prevInteract])
		else:
			$NinePatchRect/ImageContainer/TextureRect/soundAnim.set_position(soundPositions[interactArea])
	$NinePatchRect/ImageContainer/TextureRect/soundAnim/SoundAnimator.play("AudioPlayingAnim")
	$NinePatchRect/ImageContainer/AudioGraphic/PlayAnimation/PlayAnim.play("PlayAnimation", -1, 1.0/rpt)

func hide_sprite():
	$NinePatchRect/SpriteContainer/Sprite.hide()
	$NinePatchRect/SpriteContainer/rotateButton.hide()
	$NinePatchRect/SpriteContainer/zoomButton.hide()

func show_sprite():
	$NinePatchRect/SpriteContainer/Sprite.show()
	$NinePatchRect/SpriteContainer/rotateButton.show()
	$NinePatchRect/SpriteContainer/zoomButton.show()
	$NinePatchRect/SpriteContainer/OtherContainer.hide()

func open_other_screen():
	$NinePatchRect/SpriteContainer/OtherContainer.show()
	hide_sprite()
	$NinePatchRect/ImageContainer.hide()
	$NinePatchRect/ScrollContainer.show()
	for test in examDict["NormalFindings"]["Other"]:
		var button = Button.new()
		button.set_text(test)
		button.set_name(test)
		button.rect_min_size = Vector2(0, 40)
		button.connect("pressed", self, "other_test_selected", [button])
		$NinePatchRect/SpriteContainer/OtherContainer/VBoxContainer.add_child(button)

func interact_rect_changed(interact):
	interact.rect_min_size = Vector2(0, interact.get_node("VBoxContainer").get_size().y + 9)

func other_test_selected(test):
	var testName = test.get_name()
	if adapted.has("Other"):
		if adapted["Other"].has(test.get_name()):
			print_text_interaction(adapted["Other"][testName], testName)
		else:
			print_text_interaction(examDict["NormalFindings"]["Other"][testName], testName)
	else:
		print_text_interaction(examDict["NormalFindings"]["Other"][testName], testName)

func print_neurotip_interaction():
	var direct 
	if "Post" in interactArea:
		direct = "POSTERIOR"
	else:
		direct = "ANTERIOR"
	 
	for node in $NinePatchRect/ImageContainer/TextureRect.get_children():
		if node.get_name() == direct && node.is_visible() == false:
			node.show()
			$NinePatchRect/ImageContainer/Direct.set_text(direct)
		elif node.get_name() == direct:
			pass
		else:
			node.hide()
	
	if $NinePatchRect/ImageContainer/TextureRect.get_node(direct).has_node(interactArea):
		$NinePatchRect/ImageContainer/TextureRect.get_node(direct + "/" + interactArea).show()
	elif "L5 Post" in interactArea:
		interactArea = interactArea.replace("2", "")
		print(interactArea)
		$NinePatchRect/ImageContainer/TextureRect.get_node(direct + "/" + interactArea).show()
	
	if adapted_response() == true:
		$NinePatchRect/ImageContainer/TextureRect.get_node(direct + "/" + interactArea).set_self_modulate(Color(1,0,0,0.425412))
	else:
		pass
	print("neurotip" + interactArea)

func audio_play_btn_pressed(btn):
	if btn.is_pressed():
		play_sound()
		print("play")
	else: 
		stop_audio_animations()
		print("stop")

func stop_audio_animations():
	$NinePatchRect/ImageContainer/TextureRect/soundAnim/SoundAnimator.stop()
	$NinePatchRect/ImageContainer/AudioGraphic/PlayAnimation/PlayAnim.stop()
	$AudioStreamPlayer.stop()
	if soundTimer.is_connected("timeout", self, "play_sound_rpt"):
		soundTimer.disconnect("timeout", self, "play_sound_rpt")
	if $NinePatchRect/SpriteContainer/PulseMonitor/Pulse.is_playing():
		$NinePatchRect/SpriteContainer/PulseMonitor/Pulse.stop()

var num = 0
var labelValue
func opthal_mag_changed(arrow):
	var numLabel = $NinePatchRect/ImageContainer/ScopeContainer/OpthalmoscopeCont/Opthalmoscope/Label
	var shader = $NinePatchRect/SpriteContainer/ExamImages/BlurShader.get_material()
	if arrow.get_name() == "Increase":
		if num == 0:
			$NinePatchRect/ImageContainer/ScopeContainer/OpthalmoscopeCont/Opthalmoscope/Sprite.set_self_modulate(Color(0,0.554688,0.008667))
		if num < 10:
			num += 1
		if num < 0 and num > -10:
			labelValue = int(numLabel.get_text()) - 1
			numLabel.set_text(str(labelValue))
		elif num > 0 and num < 10:
			labelValue = int(numLabel.get_text()) + 1
			numLabel.set_text(str(labelValue))
		elif num == 0:
			labelValue = 0
			numLabel.set_text("0")
			$NinePatchRect/ImageContainer/ScopeContainer/OpthalmoscopeCont/Opthalmoscope/Sprite.set_self_modulate(Color(0.257812,0.257812,0.257812))
		elif num == 10:
			labelValue = 10
			numLabel.set_text(str(labelValue))
	else:
		if num == 0:
			$NinePatchRect/ImageContainer/ScopeContainer/OpthalmoscopeCont/Opthalmoscope/Sprite.set_self_modulate(Color(0.78125,0,0))
#			numLabel.set_text("0")
		if num > -10:
			num -= 1
		if num > 0 and num < 10:
			labelValue = int(numLabel.get_text()) - 1
			numLabel.set_text(str(labelValue))
		elif num < 0 and num > -10:
			labelValue = int(numLabel.get_text()) + 1
			numLabel.set_text(str(labelValue))
		elif num == 0:
			labelValue = 0
			numLabel.set_text("0")
			$NinePatchRect/ImageContainer/ScopeContainer/OpthalmoscopeCont/Opthalmoscope/Sprite.set_self_modulate(Color(0.257812,0.257812,0.257812))
		elif num == -10:
			labelValue = 10
			numLabel.set_text(str(labelValue))
	shader.set_shader_param("blurSize", labelValue * 2.5)
	
func close_examinations_screen():
	get_node("/root/World/playerNode/Player/Camera2D").set_zoom(Vector2(0.2, 0.2))
	get_node("/root/World/TileMaps/FrontTiles").show()
	get_node("/root/World/CHARACTERS/ResusNurse/KinematicBody2D").show()
	get_node("/root/World/playerNode/Player").allow_movement()
	get_node("/root/World/playerNode/Player").allow_interaction()
	get_node("/root/World/playerNode/Player/Sprite").show()
	get_node("/root/World/playerNode/Player").zoom_out()
	queue_free()

func set_interaction(interact):
	print("interaction changed:" + str(interact))
	currInteract = interact
