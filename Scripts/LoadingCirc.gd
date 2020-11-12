extends Control

onready var label = $Label
onready var animPlayer = $animations



func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here.
	pass

func connection_established():
	var anim = animPlayer.get_animation('loading')
	anim.set_loop(false)
	yield(animPlayer, 'animation_finished')
	animPlayer.play('complete')
	label.set_text('Connected!')
	yield(animPlayer, 'animation_finished')
	self.queue_free()

func saving():
	$BgPanel.show()
	label.set_text('Saving...')
#	animPlayer.play('loading')
	
	
func save_successful():
	var anim = animPlayer.get_animation('loading')
	anim.set_loop(false)
	yield(animPlayer, 'animation_finished')
	animPlayer.play('complete')
	label.set_text('Success!')
	yield(animPlayer, 'animation_finished')
	self.queue_free()