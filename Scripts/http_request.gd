extends Node

var token


func send_data_to_server(url, extension, mode, returnNode, data = "blank"):
	var err = 0
	var http = HTTPClient.new() # Create the Client

	err = http.connect_to_host(url, 443) # Connect to host/port
	assert(err == OK) # Make sure connection was OK

	# Wait until resolved and connected
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print("Connecting..")
		yield(get_tree(), "idle_frame")

	assert(http.get_status() == HTTPClient.STATUS_CONNECTED) # Could not connect

	# Some headers
	var headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
		]
	if mode == 'start':
		headers.append("Authorization: Bearer *************************************")
	elif mode == 'send_q':
		headers.append("Authorization: Bearer " + token)
		headers.append('Content-Type: application/json')
	elif mode == 'saving':
		headers.append('Content-Type: application/json')

	err = http.request(HTTPClient.METHOD_POST, extension, headers, data) # Request a page from the site (this one was chunked..)
	assert(err == OK) # Make sure all is OK

	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling until the request is going on
		http.poll()
		print("Requesting..")
		yield(get_tree(), "idle_frame")

	assert(http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.

	print("response? ", http.has_response()) # Site might not have a response.

	if http.has_response():
		# If there is a response..

		headers = http.get_response_headers_as_dictionary() # Get response headers
		print("code: ", http.get_response_code()) # Show response code
		print("**headers:\\n", headers) # Show headers

		# Getting the HTTP Body

		if http.is_response_chunked():
			# Does it use chunks?
			print("Response is Chunked!")
		else:
			# Or just plain Content-Length
			var bl = http.get_response_body_length()
			print("Response Length: ",bl)

		# This method works for both anyway

		var rb = PoolByteArray() # Array that will hold the data

		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			var chunk = http.read_response_body_chunk() # Get a chunk
			if chunk.size() == 0:
				# Got nothing, wait for buffers to fill a bit
				yield(get_tree(), "idle_frame")
			else:
				rb = rb + chunk # Append to read buffer

		# Done!

		var response = rb.get_string_from_ascii()
		print("Response: ", response)
		
		if mode == 'start':
			var dict = parse_json(response)
			token = dict['token']
			returnNode.http_return(dict)
		
		elif mode == 'saving':
			pass
