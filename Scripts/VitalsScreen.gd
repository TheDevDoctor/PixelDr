extends Node

signal vitals_closed

func _ready():
	pass

func set_values(bed):
	var vitals = get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][bed][0]["Vitals"]
	for vital in vitals:
		if vital == "BP":
			get_node("Patch9Frame/HBoxContainer/Labels/" + vital).set_text(str(vitals[vital]["Systolic"]) + "/" +str(vitals[vital]["Diastolic"]))
		else:
			get_node("Patch9Frame/HBoxContainer/Labels/" + vital).set_text(str(vitals[vital]))

func close_menu():
	if get_node("/root/singleton").introDone == false:
		emit_signal("vitals_closed")
	queue_free()
	$"/root/World/playerNode/Player".allow_movement()
	$"/root/World/playerNode/Player".allow_interaction()
	get_node("/root/World/playerNode/Player").menuOpen = null
	get_node("/root/World/GUI/Notes").close_notes()