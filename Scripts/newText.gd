extends NinePatchRect

var array = ["This is the very text I want to be displayed as if the somebody is speaking a short line.", "Once you have completed your scenario you will send it to our quality assurance team to make sure it meets the educational standards expected at your scenarios given difficulty, as well as containing an adequate volume of content. If we would like you to adapt a part of your scenario or extend the content then we will return your template to you with our suggestions. If your scenario is accepted we will respond to you via email to inform you of your success. Further details of this process are included at the end of this document.", "You will find PixelDr™ exceptionally malleable to whatever scenario you wish to create. However, there is a basic structure that you must follow. The general flow of PixelDr™ is summarised in the graphic to the right."]
onready var textBox = $Text
var i = 0
var percentVis = 0.0
const printSpeed = 40.0
var charCount = 0
var write = false

func _ready():
	textBox.set_text(array[i])
	charCount = textBox.get_total_character_count()
	write = true


func _process(delta):
	if write == true:
		percentVis += (printSpeed/charCount) * delta
		textBox.set_percent_visible(percentVis)
		if textBox.get_percent_visible() == 1:
			write = false
			percentVis = 0
			$SpaceBg.show()

func _unhandled_input(event):
	if event.is_action_pressed("ui_enter"):
		if textBox.get_percent_visible() < 1:
			textBox.set_percent_visible(1)
			write = false
			percentVis = 0
			$SpaceBg.show()
#		else:
#			i+=1
#			set_next_text()

func set_next_text(text):
	textBox.set_text(text)
	change_label_height(textBox)
	charCount = textBox.get_total_character_count()
	$SpaceBg.hide()
	write = true

func change_label_height(label):
	label.set_size(Vector2(278, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count()))
	while label.get_line_count() > 4:
		label.set_size(label.get_size() + Vector2(20, 0))
	
	label.get_node("..").set_size(Vector2(label.get_size().x + 160, label.get_node("..").get_size().y))



