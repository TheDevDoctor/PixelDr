extends Node2D


func _ready():
	$GUI/Button.connect("pressed", self, "send_performance")
	
	var player = get_node("playerNode/Player")
	var interactables = get_tree().get_nodes_in_group("Interactable")
	for interactable in interactables:
		var area2d = interactable.get_node("Area2D")
		area2d.connect("body_entered", player, "_on_area2d_body_enter", [interactable])
		area2d.connect("body_exited", player, "_on_area2d_body_exit", [interactable])
	
func play_animation(animation):
	get_node("PHONES/EMERGENCY DEPARTMENT/Sprite").show()
	get_node("AnimationPlayer").play(animation)

func stop_animation():
	get_node("PHONES/EMERGENCY DEPARTMENT/Sprite").hide()
	get_node("AnimationPlayer").stop(true)

func send_performance():
	singleton.admit_patient("BED1", "surgical")
