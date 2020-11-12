extends Control

onready var scrollContainer = $Container/Panel/ScrollContainer
onready var VBox = $Container/Panel/ScrollContainer/VBox
onready var lineEdit = $Container/LineEdit
var x = 0
var y = 0
var i = 0
var canSend = false
var currentQ
var asked = {}
var bedData = {}

var conversationID

func _ready():
	# connect all node signals to relevant functions:
	lineEdit.connect("text_changed", self, "question_text_changed")
	$Container/sendBtn.connect('pressed', self, 'enter_question')
	$Container/back.connect('pressed', self, 'back_pressed')
	
	# begin a conversation with the bot:
	if singleton.isWeb:
		http_request.send_data_to_server("https://directline.botframework.com", "/v3/directline/conversations", 'start', self)
	
	# set asked to previous questions asked:
	if singleton.bedHistory[singleton.currentWard][get_node("/root/World/playerNode/Player").target.get_name()] != null:
		asked = singleton.bedHistory[singleton.currentWard][get_node("/root/World/playerNode/Player").target.get_name()]

	
func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("ui_enter"):
		enter_question()

func set_bed_data(bed):
	if bed == "BED8": 
		singleton.play_cath_scene()
	bedData = singleton.bedStories[get_node("/root/singleton").currentWard][bed][0]["History"]

func enter_question(text=null):
	if canSend:
		if text == null:
			text = $Container/LineEdit.text
		
		text = text.strip_edges()
		
		# check to make sure there is text to send.
		if len(text) == 0:
			return
			print("There is not question to send a text.")
			
		add_text_to_container(text, "player")
		add_typing_box("patient")
		send_question(text)
		lineEdit.clear()
	

# this function is called when the player is typing and adds a typing node to the chat panel if the text is not empty, and removes a typing box if it is. 
func question_text_changed(text):
	print('text is: ' + text)
	if text.length() > 0:
		add_typing_box("player")
	else:
		remove_typing_box("playerTyping")

# this function adds a typing box. It acceps a string of either 'player' or 'patient' and adds the relevant typing box to the chat panel. 
func add_typing_box(typing):
	# check to to make sure that the chat panel does not already have a typing box.
	if VBox.has_node(typing + "Typing") == false:
		
		# load the base chat box scene:
		var node = preload("res://Scenes/chatBoxBotNew.tscn").instance()
		node.set_name(typing + "Typing")
		
		if typing == "patient":
			node.set_texture(load("res://Graphics/UI/patientChatBox.png"))
			node.set_patch_margin(MARGIN_RIGHT, 34)
			node.set_patch_margin(MARGIN_LEFT, 18)
			node.get_node("TextureFrame").set_margin(MARGIN_LEFT, 21)
			node.get_node("TextureFrame").set_margin(MARGIN_RIGHT, 38)
			node.get_node("TextureFrame").set_self_modulate(Color(0.106705,0.457032,0.738281))
		VBox.add_child(node)
		
		if typing == "patient":
			x = VBox.get_size().x - node.get_size().x
		else:
			x = 0
		node.set_position(Vector2(x,y))
		var height = node.get_size().y
		change_box_sizes(height, 0)

func remove_typing_box(typing):
	if VBox.has_node(typing):
		var hieght = VBox.get_node(typing).get_size().y
		change_box_sizes(hieght, 1)
		VBox.get_node(typing).free()

# this function changes the container heights by the amount 'height'. Type refers to if the height should be increased '0' or decreased '1'.
func change_box_sizes(height, type):
	var scrollHeight
	
	# ensures that the scroll box is not increased beyond the margin of the chat box container. 
	if height > (scrollContainer.get_margin(MARGIN_TOP) - 9):
		scrollHeight = scrollContainer.get_margin(MARGIN_TOP) - 9
	else:
		scrollHeight = height
		
	if type == 0:
		if scrollContainer.get_margin(MARGIN_TOP) > 9:
			scrollContainer.set_size(Vector2(scrollContainer.get_size().x, scrollContainer.get_size().y + scrollHeight))
			scrollContainer.set_position(Vector2(scrollContainer.get_position().x, scrollContainer.get_position().y - scrollHeight))
		VBox.set_custom_minimum_size(Vector2(VBox.get_custom_minimum_size().x, VBox.get_custom_minimum_size().y + height))
		y += height
	elif type == 1:
		if scrollContainer.get_margin(MARGIN_TOP) > 9:
			scrollContainer.set_size(Vector2(scrollContainer.get_size().x, scrollContainer.get_size().y - scrollHeight))
			scrollContainer.set_position(Vector2(scrollContainer.get_position().x, scrollContainer.get_position().y + scrollHeight))
		VBox.set_custom_minimum_size(Vector2(VBox.get_custom_minimum_size().x, VBox.get_custom_minimum_size().y - height))
		y -= height
	
	yield(get_tree(), "idle_frame")
	scrollContainer.set_v_scroll(10000)

# add text to the relevant chat field in the container.
func add_text_to_container(text, from):
	# get the typing box for whoever the text is returning for:
	var box
	if VBox.has_node(from + "Typing"):
		box = VBox.get_node(from + "Typing")
	else:
		add_typing_box('player')
		box = VBox.get_node(from + "Typing")
	
	# free the typing texture. 
	box.get_node("TextureFrame").free()
	var label = Label.new()
	label.set_margin(MARGIN_TOP, 14)
	label.set_margin(MARGIN_BOTTOM, 30)
	label.add_font_override('font', load('res://Fonts/Nunito_regular16.font'))
	if from == "player":
		label.set_margin(MARGIN_LEFT, 36)
		label.set_margin(MARGIN_RIGHT, 10)
	else:
		label.set_margin(MARGIN_LEFT, 15)
		label.set_margin(MARGIN_RIGHT, 36)
	label.set_text(text)
	box.add_child(label)
	i += 1
	box.set_name(text)
	check_label_size(label, from)

# this function sets the label to autowrap if the labels size is above a certain threshold. 330 in this case. If it is larger it then calls a function to resize the typing node. 
func check_label_size(label, from):
	if label.get_size().x > 330:
		label.set_autowrap(true)
		# this just actually changes width i think, ngl, i don't know why i had to do this bit considering i do it in the subsequent function, but I must have had a reason because if i take it out it no longer works:
		label.set_size(Vector2(330, label.get_size().y))
		# then need to change the height of the label and its container. 
		change_label_height(label)
	else:
		label.get_node("..").set_custom_minimum_size(Vector2(label.get_size().x + 52, label.get_size().y))
	
	if from == "patient":
		label.get_node("..").set_position(Vector2(VBox.get_size().x - label.get_node("..").get_custom_minimum_size().x, label.get_node("..").get_position().y))


func change_label_height(label):
	label.set_size(Vector2(330, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count()))
	var size = label.get_size()
	label.get_node("..").set_custom_minimum_size(Vector2(size.x + 52, size.y + 34))
	var difference = label.get_node("..").get_custom_minimum_size().y - 46
	change_box_sizes(difference, 0)
	if VBox.has_node("playerTyping"):
		VBox.get_node("playerTyping").set_position(VBox.get_node("playerTyping").get_position() + Vector2(0, difference))

func send_question(text):
	canSend = false
	
	currentQ = text
	var data = {'type': 'message', 'from': {'id': 'game-user', 'name': singleton.currentPlayer}, 'text': text}
	data = to_json(data)
	
	var extension = '/v3/directline/conversations/%s/activities' % conversationID
	http_request.send_data_to_server("https://directline.botframework.com", extension, 'send_q', self, data)
#	test_response()

#var count = 0
#func test_response():
#	print('entered')
#	var timer = Timer.new()
#	add_child(timer)
#	timer.wait_time = 1
#	timer.one_shot = true
#	timer.start()
#	print(timer.get_time_left())
#	yield(timer, "timeout")
#	print('timed out')
#	return_data_from_bot(to_json(responses[count]))
#	if count == 0:
#		count += 1
#	else:
#		count = 0
#	timer.queue_free()

# this function extracts the data needed from the bot. it accepts the json that comes from the websocket.   
func return_data_from_bot(json):
	var dict = parse_json(json)
	print(dict)
	if dict['activities'][0].has('from') == false:
		return
	if dict['activities'][0]['from'].has('name') == false:
		return
	
	if dict['activities'][0]['from']['name'] == 'PixelDr-Bot-Patients':
		var text = dict['activities'][0]['text']
		
		if len(text) > 0:
			add_text_to_container(text, "patient")
		else:
			if len(dict['activities'][0]['attachments']) > 0:
				add_options_box(dict['activities'][0]['attachments'][0]['content']['buttons'])
				
		
		canSend = true

# need to filter response properly!!!

func add_options_box(buttons):
	var optionsNode = load('res://Scenes/chatBoxOptions.tscn').instance()
	remove_typing_box('patientTyping')
	VBox.add_child(optionsNode)
	x = VBox.get_size().x - optionsNode.get_size().x
	optionsNode.set_position(Vector2(x, y))
	optionsNode.get_node('Buttons').connect('resized', self, 'options_vbox_size_changed', [optionsNode.get_node('Buttons')])
	for i in range(len(buttons)):
		var button = optionsNode.get_node('Buttons').get_child(i)
		button.set_text(buttons[i]['value'])
		button.connect('pressed', self, 'option_selected', [button])
		
	change_box_sizes(optionsNode.get_size().y, 0)

func option_selected(btn):
	var text = btn.text
	enter_question(text)

func options_vbox_size_changed(vbox):
	if vbox.get_size().x > 500:
		for button in vbox.get_children():
			button.clip_text = true
		vbox.set_custom_minimum_size(Vector2(500, vbox.get_size().y))
	
	vbox.get_node('..').set_size(Vector2(vbox.get_size().x + 40, vbox.get_node('..').get_size().y))
	x = VBox.get_size().x - vbox.get_node('..').get_size().x
	vbox.get_node('..').set_position(Vector2(x, vbox.get_node('..').get_position().y))

func http_return(dict):
	conversationID = dict['conversationId']
	$Websocket.connect_to_websocket(dict['streamUrl'])
	$Container/Loading.connection_established()
	lineEdit.editable = true
	canSend = true

func back_pressed():
	close_history_bot()

func close_history_bot():
	get_node("/root/World/playerNode/Player").zoom_out()

	if singleton.bedHistory[singleton.currentWard][get_node("/root/World/playerNode/Player").target.get_name()] == null:
		singleton.bedHistory[singleton.currentWard][get_node("/root/World/playerNode/Player").target.get_name()] = {}
		singleton.bedHistory[singleton.currentWard][get_node("/root/World/playerNode/Player").target.get_name()] = asked
	else:
		singleton.bedHistory[singleton.currentWard][get_node("/root/World/playerNode/Player").target.get_name()] = asked
	get_node("/root/World/GUI/Notes").close_notes()
	
	self.hide()
	yield(get_tree().get_root().get_node("World/playerNode/Player"), "zoomed_out")
	get_node("/root/World/playerNode/Player").allow_movement()
	get_node("/root/World/playerNode/Player").allow_interaction()
	queue_free()
	get_node("/root/World/playerNode/Player").menuOpen = null
	print("freed")
