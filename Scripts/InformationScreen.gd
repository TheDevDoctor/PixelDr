extends NinePatchRect

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func add_investigation_info(ix, info):
	$NinePatchRect/Label.set_text(ix)
	$NinePatchRect/RichTextLabel.set_text(info)
