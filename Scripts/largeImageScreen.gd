extends Panel

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	$Smaller.connect("pressed", self, "smaller_pressed")

func smaller_pressed():
	self.queue_free()