extends NinePatchRect

signal closed

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func close_menu():
	queue_free()
	$"/root/World/playerNode/Player".allow_movement()
	$"/root/World/playerNode/Player".allow_interaction()
	$"/root/World/playerNode/Player".menuOpen = null


#func free_menu():
#
#	emit_signal("closed")
