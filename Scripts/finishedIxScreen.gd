extends Node

onready var player = $"/root/World/playerNode/Player"
onready var dialogueParser = $"/root/World/DialogueParser"

func _ready():
	$Patch9Frame/VBoxContainer/Yes.connect("pressed", self, "finished_ix_pressed")
	$Patch9Frame/VBoxContainer/No.connect("pressed", self, "not_fin_ix_pressed")

func finished_ix_pressed():
	$Patch9Frame.hide()
	player.zoom_in()
	yield(player, "zoomed_in")
	singleton.bedStories[singleton.currentWard][player.target.get_name()][1] = 2
	dialogueParser.init_patient_dialogue(player.target)
	player.open_notes()
	close()


func not_fin_ix_pressed():
	$Patch9Frame.hide()
	player.zoom_in()
	yield(player, "zoomed_in")
	dialogueParser.init_patient_dialogue(player.target)
	player.open_notes()
	close()

func close():
	queue_free()