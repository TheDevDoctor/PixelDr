extends Node

var HEADERS = PoolStringArray()
var RESPONSE = 0
var HTTP = 0

func talkToServer(url, mode, data):
	# Connect to host/port
	HTTP = HTTPClient.new()

	RESPONSE = HTTP.connect_to_host("westus.api.cognitive.microsoft.com", 443, true)
	# Wait until resolved and connected
	while HTTP.get_status() == HTTPClient.STATUS_CONNECTING or HTTP.get_status() == HTTPClient.STATUS_RESOLVING:
		HTTP.poll()
		OS.delay_msec(300)

	# Error catch: Could not connect
	assert(HTTP.get_status() == HTTPClient.STATUS_CONNECTED)
	# Check for a GET or POST command
	if data == null:
		HEADERS = PoolStringArray(["Ocp-Apim-Subscription-Key: *****************************", "Content-Type: application/json", "Accept: */*"])
		RESPONSE = HTTP.request(HTTPClient.METHOD_GET, url, HEADERS)
	else:
		var js = to_json(data)
		print(js)
		HEADERS = PoolStringArray(["Ocp-Apim-Subscription-Key: *******************************", "Content-Type: application/json"])
		RESPONSE = HTTP.request(HTTPClient.METHOD_POST, url, HEADERS, js)
	# Make sure all is OK
	assert(RESPONSE == OK)
	# Keep polling until the request is going on
	while (HTTP.get_status() == HTTPClient.STATUS_REQUESTING):
		HTTP.poll()
		OS.delay_msec(300)
	# Make sure request finished
	assert(HTTP.get_status() == HTTPClient.STATUS_BODY or HTTP.get_status() == HTTPClient.STATUS_CONNECTED)
	# Set up some variables
	var RB = PoolByteArray()
	var CHUNK = 0
	var RESULT = 0
	# Raw data array
	if HTTP.has_response():
		# Get response headers
		var headers = HTTP.get_response_headers_as_dictionary()
		while HTTP.get_status() == HTTPClient.STATUS_BODY:
			HTTP.poll()
			CHUNK = HTTP.read_response_body_chunk()
			if(CHUNK.size() == 0):
				OS.delay_usec(100)
			else:
				RB = RB + CHUNK
			HTTP.close()
			RESULT = RB.get_string_from_ascii()
			# Do something with the response
			if mode == 'bot':
				print(str(RESULT))
				get_node("/root/World/GUI/pixelBotBox").return_string_from_bot(RESULT)


