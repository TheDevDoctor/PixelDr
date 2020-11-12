extends Node

var _client = WebSocketClient.new()

func _ready():
	_client.connect("connection_succeeded", self, "_client_connected")
	_client.connect("connection_failed", self, "_client_disconnected")
	
	_client.connect("connection_established", self, "_client_connected")
	_client.connect("connection_error", self, "_client_disconnected")
	_client.connect("connection_closed", self, "_client_disconnected")
	
	_client.connect("data_received", self, "_client_received")

func connect_to_websocket(url):
	_client.connect_to_url(url)

func _client_connected(protocol):
	print("Client successfully connected")

func _client_disconnected():
	print("Client disconnected")

func _client_received():
	var packet = _client.get_peer(1).get_packet()
	var is_string = _client.get_peer(1).was_string_packet()
	get_node("..").return_data_from_bot(decode_data(packet, true))

#func encode_data(data, mode):
#	return data.to_utf8() if mode == WebSocketPeer.WRITE_MODE_TEXT else var2bytes(data)

func decode_data(data, is_string):
	return data.get_string_from_utf8() if is_string else bytes2var(data)