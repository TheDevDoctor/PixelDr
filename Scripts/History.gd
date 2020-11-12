extends Patch9Frame

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	set_process_input(true)
	set_process_unhandled_key_input(true)

func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("ui_cancel") && get_node("/root/World/playerNode/Player").canCancel == true:
		close_history()

func set_history_data(bed):

	var history = get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][bed][0]["History"]
	var historyOrder = ["Presenting complaint", "History of presenting complaint", "Past Medical History", "Systems Review", "Drug History", "Family History", "Social History", "ICE"]
	for section in historyOrder:
		var mainPatch = return_main_patch(history, section)
		var label = Label.new()
		var mainText = RichTextLabel.new()
		get_node("ScrollContainer/VBoxContainer").add_child(mainPatch)
		print(mainPatch.get_node("labelPatch/titleLabel").get_size())
		mainPatch.get_node("labelPatch").set_margin(MARGIN_RIGHT, mainPatch.get_node("labelPatch/titleLabel").get_size().x + 16)
	
func return_main_patch(history, section):
	var mainPatch = Patch9Frame.new()
	mainPatch.set_texture(preload("res://Graphics/UI/investigationOrderNormal.png"))
	mainPatch.set_patch_margin(MARGIN_LEFT, 10)
	mainPatch.set_patch_margin(MARGIN_RIGHT, 10)
	mainPatch.set_patch_margin(MARGIN_TOP, 10)
	mainPatch.set_patch_margin(MARGIN_BOTTOM, 10)
	mainPatch.set_h_size_flags(3)
	mainPatch.set_custom_minimum_size(Vector2(10, 40))
	
	var labelPatch = Patch9Frame.new()
	labelPatch.set_texture(preload("res://Graphics/UI/ixButtonHover.png"))
	labelPatch.set_modulate(Color(0.382812,1,0))
	labelPatch.set_patch_margin(MARGIN_LEFT, 10)
	labelPatch.set_patch_margin(MARGIN_RIGHT, 10)
	labelPatch.set_patch_margin(MARGIN_TOP, 10)
	labelPatch.set_patch_margin(MARGIN_BOTTOM, 10)
	labelPatch.set_margin(MARGIN_LEFT, 2)
	labelPatch.set_margin(MARGIN_RIGHT, 170)
	labelPatch.set_margin(MARGIN_TOP, 2)
	labelPatch.set_margin(MARGIN_BOTTOM, 26)
	labelPatch.set_name("labelPatch")
	
	var titleLabel = Label.new()
	titleLabel.set_anchor_and_margin(MARGIN_BOTTOM, ANCHOR_END, 0)
	titleLabel.set_margin(MARGIN_LEFT, 6)
	titleLabel.set_margin(MARGIN_TOP, 0)
	titleLabel.set_text(section)
	titleLabel.set_name("titleLabel")
	titleLabel.set_valign(VALIGN_CENTER)
	labelPatch.add_child(titleLabel)
	
	var mainText = Label.new()
	mainText.set_margin(MARGIN_LEFT, 10)
	mainText.set_margin(MARGIN_TOP, 30)
	mainText.set_anchor_and_margin(MARGIN_RIGHT, ANCHOR_END, 10)
	mainText.set_anchor_and_margin(MARGIN_BOTTOM, ANCHOR_END, 10)
	mainText.set_autowrap(true)
	mainText.connect("item_rect_changed", self, "on_item_rect_changed", [mainText])
	mainText.set_text(history[section])
	mainText.set_name("mainText")
	
	mainPatch.add_child(labelPatch)
	mainPatch.add_child(mainText)
	return mainPatch

func on_item_rect_changed(label):
	label.set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count()))
	label.get_node("..").set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count() + 34))
	
func close_history():
	get_node("/root/World/playerNode/Player").zoom_out()
	get_node("/root/World/playerNode/Player").allow_movement()
	get_node("/root/World/GUI/notes").close_notes()
	self.hide()
	yield(get_tree().get_root().get_node("World/playerNode/Player"), "zoomed_out")
	print("entered")
	get_node("/root/World/playerNode/Player").allow_interaction()
	get_node("..").queue_free()
