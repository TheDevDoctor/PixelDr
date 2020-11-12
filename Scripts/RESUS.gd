extends Node

var staffDict = {"BedPos1": null, "BedPos2": null, "BedPos3": null, "BedPos4": null, "TablePos": null, "FloatingPos": null}
var spawnDict = {"BedPos1": null, "BedPos2": null, "BedPos3": null, "BedPos4": null, "TablePos": null, "FloatingPos": null}
var resusStaff = {}
var currPosition = null
var spawning = true
var basePos

func _ready():
	basePos = $"/root/World/RESUSBEDS/RESUS1".get_position()
	
	resusStaff = singleton.load_file_as_JSON("res://JSON_files/resus_staff.json")
	for container in $ResusGUI/NinePatchRect/StaffList.get_children():
		container.get_node("TextureButton").connect("pressed", self, "staff_button_pressed", [container])
	
#	$PlaceButtons/BedPos1/AnimationPlayer.connect("animation_finished", self, "anim_finished")
	for bedPos in $PlaceButtons.get_children():
		if bedPos.has_node("AnimationPlayer"):
			bedPos.get_node("AnimationPlayer").connect("animation_finished", self, "anim_finished", [bedPos.get_name()])
	
	$ResusGUI/NinePatchRect/back.connect("pressed", self, "back_pressed")
	
func _process(delta):
	if spawning:
		for pos in spawnDict:
			if spawnDict[pos] != null:
				spawnDict[pos][0] -= delta
				var path = "ResusGUI/NinePatchRect/StaffList/" + pos
				get_node(path + "/TextureProgress").set_value((spawnDict[pos][0]/spawnDict[pos][1]) * 100)
				get_node(path + "/countdown").set_text(str(int(spawnDict[pos][0] + 1)))
				if spawnDict[pos][0] < 0:
					spawnDict[pos] = null
					get_node(path + "/TextureBg").hide()
					get_node(path + "/TextureProgress").hide()
					get_node(path + "/countdown").hide()
					get_node("PlaceButtons/" + pos + "/AnimationPlayer").play("spawnComplete")

func staff_button_pressed(container):
	currPosition = container.get_name()
	if staffDict[currPosition] == null:
		$ResusGUI/NinePatchRect/StaffList.hide()
		$ResusGUI/NinePatchRect/StaffSpawnList.show()
		$ResusGUI/NinePatchRect/back.show()
		print_possible_staff()

func print_possible_staff():
	for staff in resusStaff["Staff"]:
		var spawnNode = load("res://Scenes/SpawnableNode.tscn").instance()
		spawnNode.get_node("Name").set_text(staff)
		spawnNode.set_name(staff)
		spawnNode.get_node("requestTime").set_text("Request Time: " + str(resusStaff["Staff"][staff]["spawnTime"]))
		spawnNode.get_node("Spawn").connect("pressed", self, "spawn_character_pressed", [spawnNode])
		spawnNode.get_node("Abilities").connect("pressed", self, "view_abilities_pressed", [spawnNode])
		$ResusGUI/NinePatchRect/StaffSpawnList/VBoxContainer.add_child(spawnNode)
		
func spawn_character_pressed(spawnNode):
	var chosen = spawnNode.get_name()
	var path = "ResusGUI/NinePatchRect/StaffList/" + currPosition
	get_node(path + "/TextureBg").show()
	get_node(path + "/TextureProgress").show()
	get_node(path + "/countdown").show()
	get_node(path + "/staffMember").set_text(chosen)
#	get_node(path + "/staffMember").add_color_override("font_color", Color("7209d3"))
	get_node(path + "/TextureProgress").set_value(100)
	get_node(path + "/countdown").set_text(str(resusStaff["Staff"][chosen]["spawnTime"]))
	get_node("PlaceButtons/" + currPosition + "/AnimationPlayer").play("spawning")
	spawnDict[currPosition] = [resusStaff["Staff"][chosen]["spawnTime"], resusStaff["Staff"][chosen]["spawnTime"]]
	staffDict[currPosition] = chosen
	$ResusGUI/NinePatchRect/StaffList.show()
	$ResusGUI/NinePatchRect/StaffSpawnList.hide()
	singleton.clear_container($ResusGUI/NinePatchRect/StaffSpawnList/VBoxContainer)

func anim_finished(anim, bedPos):
	var charPositions = {"BedPos1": [Vector2(-48, 2), 27], "BedPos2": [Vector2(-16, 34), 0], "BedPos3": [Vector2(16, 34), 0], "BedPos4": [Vector2(48, 2), 9], "TablePos": [Vector2(-48, 66), 9], "FloatingPos": [Vector2(80, 34), 9]}
	if anim == "spawnComplete":
		get_node("ResusGUI/NinePatchRect/StaffList/" + bedPos + "/staffMember").add_color_override("font_color", Color(resusStaff["Staff"][staffDict[bedPos]]["color"]))
		get_node("ResusGUI/NinePatchRect/StaffList/" + bedPos + "/staffMember").add_font_override("font", load("res://Fonts/Nunito_extra_bold20.font"))
		var CHAR = load("res://Scenes/Character.tscn").instance()
		CHAR.get_node("KinematicBody2D").set_position(basePos + charPositions[bedPos][0])
		CHAR.get_node("KinematicBody2D/Sprite").set_texture(load(resusStaff["Staff"][staffDict[bedPos]]["graphic"]))
		CHAR.get_node("KinematicBody2D/Sprite").set_frame(charPositions[bedPos][1])
		$"/root/World/CHARACTERS".add_child(CHAR)

func view_abilities_pressed(node):
	var chosen = node.get_name()
	$ResusGUI/NinePatchRect/StaffInfo.show()
	$ResusGUI/NinePatchRect/StaffInfo/ScrollContainer/VBoxContainer/Description.set_text(resusStaff["Staff"][chosen]["description"] + "\n")
	$ResusGUI/NinePatchRect/StaffSpawnList.hide()
	$ResusGUI/NinePatchRect/StaffInfo/NinePatchRect/Sprite.set_texture(load(resusStaff["Staff"][chosen]["graphic"]))
	
	var abilityString = ""
	for i in range(0,resusStaff["Staff"][chosen]["abilities"].size()):
		var ability = resusStaff["Staff"][chosen]["abilities"][i]
		abilityString += ability + " - " + resusStaff["Abilities"][ability]
		if i < resusStaff["Staff"][chosen]["abilities"].size() - 1:
			abilityString += "\n\n"
	
	$ResusGUI/NinePatchRect/StaffInfo/ScrollContainer/VBoxContainer/Abilities.set_text(abilityString)

func back_pressed():
	if $ResusGUI/NinePatchRect/StaffInfo.is_visible():
		$ResusGUI/NinePatchRect/StaffInfo.hide()
		$ResusGUI/NinePatchRect/StaffSpawnList.show()
	elif $ResusGUI/NinePatchRect/StaffSpawnList.is_visible():
		$ResusGUI/NinePatchRect/StaffSpawnList.hide()
		$ResusGUI/NinePatchRect/StaffList.show()
		$ResusGUI/NinePatchRect/back.hide()
		singleton.clear_container($ResusGUI/NinePatchRect/StaffSpawnList/VBoxContainer)