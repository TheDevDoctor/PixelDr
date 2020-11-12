extends Node

signal global_interaction

var target = null
var scenariosCompleted = 0
var currentLoad = null
var currentPlayer = null
var url = 'https://pixeldr-test.azurewebsites.net'
var XP = 0
var currentRank = null

#bedStories holds all the data about the story component for each story. It is parsed into wards and then each bed within that ward. Each bed key contains an array of three items. array[0] is the dictionary of the story which contains the story, investigations to change, anything that should be prescribed as well as explanations for the story. 
#array[1] is the story progression, 0 = hasn't been seen, 1 = been seen but not investigated, 2 = investigated. array[2] is the time waited in seconds, should perhaps update this to minutes to save CPU.
var bedStories = {"Accident and Emergency": {"BED1": null, "BED2": null, "BED3": null, "BED4": null, "BED5": null, "BED6": null, "BED7": null, "BED8": null, "BED9": null, "BED10": null}}

#bedNotes contains the notes written for each patient by the player. Each component just corresponds to the subsequent textedit in the scene. 
var bedNotes = {"Accident and Emergency": {"BED1": null, "BED2": null, "BED3": null, "BED4": null, "BED5": null, "BED6": null, "BED7": null, "BED8": null, "BED9": null, "BED10": null}}

#bedInvestigations holds all investigations that have been ordered for the patient and is split into those that are pending (e.i. their wait time is still in progress) and complete (i.e. those that have returned).
var bedInvestigations = {"BED1": {"Complete": [], "Pending": {}}, "BED2": {"Complete": [], "Pending": {}}, "BED3": {"Complete": [], "Pending": {}}, "BED4": {"Complete": [], "Pending": {}}, "BED5": {"Complete": [], "Pending": {}}, "BED6": {"Complete": [], "Pending": {}}, "BED7": {"Complete": [], "Pending": {}}, "BED8": {"Complete": [], "Pending": {}}, "BED9": {"Complete": [], "Pending": {}}, "BED10": {"Complete": [], "Pending": {}}}

#Contains the questions asked in the history by the player. 
var bedHistory = {"Accident and Emergency": {"BED1": null, "BED2": null, "BED3": null, "BED4": null, "BED5": null, "BED6": null, "BED7": null, "BED8": null, "BED9": null, "BED10": null}}

#bedPrescriptions contains anything that has been prescribed. 
var bedPrescriptions = {"BED1": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED2": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED3": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED4": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED5": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED6": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED7": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED8": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED9": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED10": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}}

#bedDifferentials contains an array of the differentials for each bed.
var bedDifferentials = {"Accident and Emergency": {"BED1": [], "BED2": [], "BED3": [], "BED4": [], "BED5": [], "BED6": [], "BED7": [], "BED8": [], "BED9": [], "BED10": []}}

var bedContacts = {"Accident and Emergency": {"BED1": null, "BED2": null, "BED3": null, "BED4": null, "BED5": null, "BED6": null, "BED7": null, "BED8": null, "BED9": null, "BED10": null}}

var bedProcedures = {"Accident and Emergency": {"BED1": null, "BED2": null, "BED3": null, "BED4": null, "BED5": null, "BED6": null, "BED7": null, "BED8": null, "BED9": null, "BED10": null}}

var nextScenario = {}
var scenarioCounter = 0
var callInteractions = {}
var bedBleeps = {"Accident and Emergency": {}}
var calls = {}

var currentWard = "Accident and Emergency"
var playerInfo = {"Forename": "Sarah", "Surname": "Button", "Inventory": ["Catheter"]}

var introDone = false
var playlist = []
#var currentlyPlaying = []
var isWeb

func _ready():
	if OS.get_name() == "HTML5":
		isWeb = true
	else:
		isWeb = false
	get_current_player()
	get_current_url()
	get_saved_file()
	get_performance_file()
	randomize()
	#set operating system to low processor mode. Means viewport only redraws when something happens. 
	OS.set_low_processor_usage_mode(true)
	if introDone == false:
		set_start_bed()
	callInteractions = load_file_as_JSON("res://JSON_files/bleepInteractions.json")
	var timer = Timer.new()
	timer.connect("timeout", self, "one_second")
	timer.start()
	timer.autostart = true
	timer.set_name("Timer")
	add_child(timer)
#	set_other_beds()


func set_start_bed():
	for bed in bedStories["Accident and Emergency"]: 
		if bed == "BED1":
			bedStories["Accident and Emergency"][bed] = [{}, 0, 0, 0]
			bedStories["Accident and Emergency"][bed][0] = load_file_as_JSON("res://introBedStory.json")
			$"/root/World/BEDS".get_node(bed).frame = bedStories["Accident and Emergency"][bed][0]["ScenarioDetails"]["Sprite"]

func get_current_player():
	var code="""
		readCookie("username")
		function readCookie(name) {
			var nameEQ = name + "=";
			var ca = document.cookie.split(';');
			for(var i=0;i < ca.length;i++) {
				var c = ca[i];
				while (c.charAt(0)==' ') c = c.substring(1,c.length);
			if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
			}
			return "No Cookie";
		}
		"""
	var response=JavaScript.eval(code)
	currentPlayer = str(response)

func get_current_url():
	var code="""
		readCookie("slot")
		function readCookie(name) {
			var nameEQ = name + "=";
			var ca = document.cookie.split(';');
			for(var i=0;i < ca.length;i++) {
				var c = ca[i];
				while (c.charAt(0)==' ') c = c.substring(1,c.length);
			if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
			}
			return "No Cookie";
		}
		"""
	var response=JavaScript.eval(code)
	var slot = str(response)
	
	print("The slot is " + slot)
	
	if slot == "Dev":
		url = "https://pixeldr-test.azurewebsites.net"
	elif slot == "Prod":
		url = "https://pixeldr.azurewebsites.net"
	else:
		print("No slot could be found in the dev cookie.")
	


func get_saved_file():
	var dict = {}
	if isWeb:
		var code="""
			var xmlHttp = new XMLHttpRequest();
			xmlHttp.open("PUT", '""" + url + """/gameapis/database/load-savegame/""" + currentPlayer + """', false);
			xmlHttp.setRequestHeader("Content-Type", "application/json");
			xmlHttp.send();
			xmlHttp.response;"""
		var response=JavaScript.eval(code)
		if response != null:
			response.replace("’", "'")
			dict = parse_json(response)
			var savejson = File.new()
			savejson.open("user://saved_games.json", File.WRITE)
			savejson.store_line(to_json(dict))
			savejson.close()
		else:
			print("Unable to retrieve saved file")
			return
	else:
		dict = load_file_as_JSON("res://JSON_files/saved_game.json")
		
	if dict["CurrentLoad"] == null:
		print("call_deferred")
		call_deferred("open_new_game")
	else:
		currentLoad = dict["CurrentLoad"]
		playlist = dict["Playlist"]
		load_game(dict["Saves"][dict["CurrentLoad"]])

func get_performance_file():
	var dict = {}
	if isWeb: 
		var code="""
			var xmlHttp = new XMLHttpRequest();
			xmlHttp.open("PUT", '""" + url + """/gameapis/database/load-performancerecord/""" + currentPlayer + """', false);
			xmlHttp.setRequestHeader("Content-Type", "application/json");
			xmlHttp.send();
			xmlHttp.response;"""
		var response=JavaScript.eval(code)
		if response != null:
			response.replace("’", "'")
			dict = parse_json(response)
			var savejson = File.new()
			savejson.open("user://performance.json", File.WRITE)
			savejson.store_line(to_json(dict))
			savejson.close()
	else:
		dict = load_file_as_JSON("res://JSON_files/performance.json")
		
	XP = int(dict["rankProgress"])
	currentRank = dict["rank"]

func open_new_game():
	new_game("My_Save")
#	var screen = load("res://Scenes/NewGame.tscn").instance()
#	get_node("/root/World/GUI").add_child(screen)

func new_game(name):
	bedStories = {"Accident and Emergency": {"BED1": null, "BED2": null, "BED3": null, "BED4": null, "BED5": null, "BED6": null, "BED7": null, "BED8": null, "BED9": null, "BED10": null}}
	bedNotes = {"Accident and Emergency": {"BED1": null, "BED2": null, "BED3": null, "BED4": null, "BED5": null, "BED6": null, "BED7": null, "BED8": null, "BED9": null, "BED10": null}}
	bedInvestigations = {"BED1": {"Complete": [], "Pending": {}}, "BED2": {"Complete": [], "Pending": {}}, "BED3": {"Complete": [], "Pending": {}}, "BED4": {"Complete": [], "Pending": {}}, "BED5": {"Complete": [], "Pending": {}}, "BED6": {"Complete": [], "Pending": {}}, "BED7": {"Complete": [], "Pending": {}}, "BED8": {"Complete": [], "Pending": {}}, "BED9": {"Complete": [], "Pending": {}}, "BED10": {"Complete": [], "Pending": {}}}
	bedHistory = {"Accident and Emergency": {"BED1": null, "BED2": null, "BED3": null, "BED4": null, "BED5": null, "BED6": null, "BED7": null, "BED8": null, "BED9": null, "BED10": null}}
	bedPrescriptions = {"BED1": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED2": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED3": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED4": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED5": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED6": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED7": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED8": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED9": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}, "BED10": {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}}
	bedDifferentials = {"Accident and Emergency": {"BED1": [], "BED2": [], "BED3": [], "BED4": [], "BED5": [], "BED6": [], "BED7": [], "BED8": [], "BED9": [], "BED10": []}}
	bedContacts = {"Accident and Emergency": {"BED1": null, "BED2": null, "BED3": null, "BED4": null, "BED5": null, "BED6": null, "BED7": null, "BED8": null, "BED9": null, "BED10": null}}
	bedProcedures = {"Accident and Emergency": {"BED1": null, "BED2": null, "BED3": null, "BED4": null, "BED5": null, "BED6": null, "BED7": null, "BED8": null, "BED9": null, "BED10": null}}
	bedBleeps = {"Accident and Emergency": {}}
	calls = {}
	currentWard = "Accident and Emergency"
	playerInfo = {"Forename": "", "Surname": "", "Inventory": []}
	introDone = false
	var player = $"/root/World/playerNode/Player"
	player.set_position(Vector2(-336, 592))
	player.get_node("Sprite").set_frame(27)
	get_node("/root/World/CHARACTERS/Dr Marshall/Dr Marshall").set_position(Vector2(208, player.get_position().y))
	player.canMove = true
	currentLoad = name
	currentRank = "PixelDr Foundation 1"
	set_start_bed()
	

func load_game(saveGame):
#	var saveGame = load_file_as_JSON("res://saved_games.json")
#	saveGame = saveGame["Saves"][saveGame["CurrentLoad"]]
#	if firstLoad == true:
#		positionsDict = {"Player": Vector2(saveGame["Player"]["posx"], saveGame["Player"]["posy"])}
#	else:
	$"/root/World/playerNode/Player".set_position(Vector2(int(saveGame["Player"]["posx"]),int(saveGame["Player"]["posy"])))
	currentWard = saveGame["CurrentWard"]
	bedStories = saveGame["bedStories"]
	bedNotes = saveGame["bedNotes"]
	bedInvestigations = saveGame["bedInvestigations"]
	bedHistory = saveGame["bedHistory"]
	bedPrescriptions = saveGame["bedPrescriptions"]
	bedDifferentials = saveGame["bedDifferentials"]
	bedContacts = saveGame["bedContacts"]
	bedProcedures = saveGame["bedProcedures"]
	introDone = saveGame["introDone"] 
	scenariosCompleted = saveGame["scenariosCompleted"]
	bedBleeps = saveGame["bedBleeps"]
	calls = saveGame["calls"]
	playerInfo = saveGame["playerInfo"]
	for bed in bedStories[currentWard]:
		if bedStories[currentWard][bed] != null:
			$"/root/World/BEDS".get_node(bed).frame = bedStories[currentWard][bed][0]["ScenarioDetails"]["Sprite"]

#func load_scenario_from_database(bed):
#	pass

#temporary function for post intro scene:
func set_other_beds():
	for bed in bedStories["Accident and Emergency"]: 
		if bed == "BED2":
			bedStories["Accident and Emergency"][bed] = [{}, 0, 0, 0]
			bedStories["Accident and Emergency"][bed][0] = load_file_as_JSON("res://testCardioStory.json")
			$"/root/World/BEDS".get_node(bed).frame = bedStories["Accident and Emergency"][bed][0]["ScenarioDetails"]["Sprite"]
#		elif bed == "BED5":
#			bedStories["Accident and Emergency"][bed] = [{}, 0, 0, 0]
#			bedStories["Accident and Emergency"][bed][0] = load_file_as_JSON("res://Migraine.json")
#			$"/root/World/BEDS".get_node(bed).frame = bedStories["Accident and Emergency"][bed][0]["ScenarioDetails"]["Sprite"]
		elif bed == "BED6":
			bedStories["Accident and Emergency"][bed] = [{}, 0, 0, 0]
			bedStories["Accident and Emergency"][bed][0] = load_file_as_JSON("res://scenario-COPD.json")
			$"/root/World/BEDS".get_node(bed).frame = bedStories["Accident and Emergency"][bed][0]["ScenarioDetails"]["Sprite"]
		elif bed == "BED8":
			bedStories["Accident and Emergency"][bed] = [{}, 0, 0, 0]
			bedStories["Accident and Emergency"][bed][0] = load_file_as_JSON("res://AUR.json")
			$"/root/World/BEDS".get_node(bed).frame = int(bedStories["Accident and Emergency"][bed][0]["ScenarioDetails"]["Sprite"])

#func test_java():
#	cosmosdbtest()

func reset_bed(bed):
	bedStories["Accident and Emergency"][bed] = null
	bedInvestigations[bed]["Complete"].clear()
	bedInvestigations[bed]["Pending"].clear()
	bedPrescriptions[bed] = {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}
	bedNotes[currentWard][bed] = null
	bedDifferentials[currentWard][bed].clear()
	if bedContacts[currentWard][bed] != null:
		bedContacts[currentWard][bed].clear()
	if bedProcedures[currentWard][bed] != null:
		bedProcedures[currentWard][bed].clear()
	
	$"/root/World/BEDS".get_node(bed).frame = 0
	
	#below may need to be deleted at some point. 
	scenariosCompleted += 1
	if scenariosCompleted == 4:
		play_rival_scene()

func load_file_as_JSON(path):
	var file = File.new()
	file.open(path, file.READ)
	var content = (file.get_as_text())
	var target = parse_json(content)
	return target
	file.close()

func clear_container(cont):
	if cont.get_child_count() > 0:
		for child in cont.get_children():
			child.free()

func one_second():
	update_pending_ix()
	update_time_waited()
	update_bleeps()
#	update_key_actions()

func update_pending_ix():
	for bed in bedInvestigations:
		if bedInvestigations[bed].size() > 0:
			for ix in bedInvestigations[bed]["Pending"]:
				if bedInvestigations[bed]["Pending"][ix]["WaitLeft"] >= 1:
					bedInvestigations[bed]["Pending"][ix]["WaitLeft"] -= 1
				else:
					bedInvestigations[bed]["Complete"].append(ix)
					bedInvestigations[bed]["Pending"].erase(ix)
					add_notification(bed + ": " + ix + " complete.") 

var minTimer = 0
func update_time_waited():
	pass
#	minTimer += 1
#	if minTimer == 60:
#		for ward in bedStories:
#			for bed in bedStories[ward]:
#				bedStories[ward][bed][2] += 1
#				add_notification(bed + " has waited one minute.") 

func update_bleeps():
	for ward in bedBleeps:
		if bedBleeps[ward].size() > 0:
			for bleep in bedBleeps[ward]:
				if bedBleeps[ward][bleep][0] >= 1:
					bedBleeps[ward][bleep][0] -= 1
				else:
					bleep_returned(bleep, bedBleeps[ward][bleep][1])
					bedBleeps[ward].erase(bleep)

#func update_key_actions():
#	for ward in bedKeyActions:
#		for bed in bedKeyActions[ward]:
#			if bedKeyActions[ward][bed] != null:
#				if bedKeyActions[ward][bed].size() > 0:
#					for action in bedKeyActions[ward][bed]:
#						if bedKeyActions[ward][bed][action][0] >= 1:
#							bedKeyActions[ward][bed][action][0] -= 1
#						else:
#							key_action_incompleted()
#							bedKeyActions[ward][bed].erase(action)

func bleep_returned(bleep, phone):
	var text = bleep + " is calling " + phone + " phone"
	get_tree().get_root().get_node("World").play_animation("EmergencyDepartmentPhone1")
	if calls.has(phone) == false:
		calls[phone] = bleep
	print(calls)
	add_notification(text)
	
func add_notification(text, colour = 0):
	if get_tree().get_root().get_node("World/GUI").has_node("Notifications"):
		get_tree().get_root().get_node("World/GUI/Notifications").add_label(text, colour)
	else:
		var node = preload("res://Scenes/playerUpdateScreen.tscn").instance()
		get_tree().get_root().get_node("World/GUI").add_child(node)
		get_tree().get_root().get_node("World/GUI/Notifications").add_label(text, colour)

func key_action_incompleted():
	print("Incomplete")

#var perfomanceDict = null

func discharge_patient(bed):
	add_performance_to_JSON(bed)
	reset_bed(bed)
	save_game(1)

func admit_patient(bed, ward):
	print("performance")
	add_performance_to_JSON(bed, ward)
	print("reset_bed")
	reset_bed(bed)
	print("save_game")
	save_game(1)

var perfomanceDict = null
#code to create performance JSON. If patient was admitted ward will equal null, else ward will contain ward patient was admmited to. 
func add_performance_to_JSON(bed, ward = null):
	var name = bedStories["Accident and Emergency"][bed][0]["id"]
	perfomanceDict = {}
	if isWeb:
		perfomanceDict = load_file_as_JSON("user://performance.json")
	else:
		perfomanceDict = load_file_as_JSON("res://JSON_files/performance.json")
	
	
	if perfomanceDict["Scenarios"] == null:
		perfomanceDict["Scenarios"] = {}
	
	perfomanceDict["Scenarios"][name] = {}
	perfomanceDict["Scenarios"][name]["Sprite"] = bedStories[currentWard][bed][0]["ScenarioDetails"]["Sprite"]
	perfomanceDict["Scenarios"][name]["Explanation"] = bedStories[currentWard][bed][0]["Explanation"]
	
	var time = OS.get_datetime()
	if time["month"] < 10:
		time["month"] = "0" + str(time["month"])
	if time["day"] < 10:
		time["day"] = "0" + str(time["day"])
	if time["hour"] < 10:
		time["hour"] = "0" + str(time["hour"])
	if time["minute"] < 10:
		time["minute"] = "0" + str(time["minute"])
	if time["second"] < 10:
		time["second"] = "0" + str(time["second"])
		
	perfomanceDict["Scenarios"][name]["CompletionDate"] = str(time["year"]) + "-" + str(time["month"]) + "-" + str(time["day"]) + "T" + str(time["hour"]) + ":" + str(time["minute"]) + ":" + str(time["second"])

	perfomanceDict["Scenarios"][name]["EndAction"] = ""
	perfomanceDict["Scenarios"][name]["EndAction"] = ward
	
	#answer counter to see if size was initially 0 so score can be set to null. 
	var answerCount = bedStories[currentWard][bed][0]["Answers"]["History"].size()
	
	#form history data:
	perfomanceDict["Scenarios"][name]["History"] = {"Correct": {}, "Incorrect": {}, "Missed": {}}
	if bedHistory[currentWard][bed] == null:
		perfomanceDict["Scenarios"][name]["History"]["Missed"] = bedStories[currentWard][bed][0]["Answers"]["History"]
	else:
		for q in bedHistory[currentWard][bed]:
			if bedStories[currentWard][bed][0]["Answers"]["History"].has(q):
				print("Correct")
				perfomanceDict["Scenarios"][name]["History"]["Correct"][q] = bedHistory[currentWard][bed][q]
			else:
				print("Incorrect")
				perfomanceDict["Scenarios"][name]["History"]["Incorrect"][q] = bedHistory[currentWard][bed][q]
		for q in bedStories[currentWard][bed][0]["Answers"]["History"]:
			if bedHistory[currentWard][bed].has(q) == false:
				perfomanceDict["Scenarios"][name]["History"]["Missed"][q] = bedStories[currentWard][bed][0]["Answers"]["History"][q]
	#history score:
	var historyScore
	if answerCount == 0:
		historyScore = null
	else:
		historyScore = round((float(perfomanceDict["Scenarios"][name]["History"]["Correct"].size())/float(answerCount)) * 100.0)

	answerCount = bedStories[currentWard][bed][0]["Answers"]["Investigations"].size()
	#form investigations data
	perfomanceDict["Scenarios"][name]["Investigations"] = {"Correct": [], "Incorrect": [], "Missed": []}
	for ix in bedInvestigations[bed]["Complete"]:
		if bedStories[currentWard][bed][0]["Answers"]["Investigations"].has(ix):
			perfomanceDict["Scenarios"][name]["Investigations"]["Correct"].append(ix)
		else:
			perfomanceDict["Scenarios"][name]["Investigations"]["Incorrect"].append(ix)
	for ix in bedStories[currentWard][bed][0]["Answers"]["Investigations"]:
		if bedInvestigations[bed]["Complete"].has(ix) == false:
			perfomanceDict["Scenarios"][name]["Investigations"]["Missed"].append(ix)
	
	#investigation score
	var ixScore
	if answerCount == 0:
		ixScore = null
	else:
		ixScore = round((float(perfomanceDict["Scenarios"][name]["Investigations"]["Correct"].size())/float(answerCount)) * 100.0)
	
	#variable to allow the proper calculation of the management["overall"] field:
	var managementScoreCount = 0
	
	#form prescription data:
	answerCount = 0
	var correctPresCount = 0
	for category in bedStories[currentWard][bed][0]["Answers"]["Prescriptions"]:
		answerCount += bedStories[currentWard][bed][0]["Answers"]["Prescriptions"][category].size()
	managementScoreCount += answerCount
	perfomanceDict["Scenarios"][name]["Management"] = {}
	perfomanceDict["Scenarios"][name]["Management"]["Prescriptions"] = {"Correct": {}, "Incorrect": {}, "Missed": {}}
	for category in bedPrescriptions[bed]:
		for med in bedPrescriptions[bed][category]:
			var correct = false
			for dict in bedStories[currentWard][bed][0]["Answers"]["Prescriptions"][category]:
				if dict.has(med):
					correct = true
					correctPresCount += 1
					if perfomanceDict["Scenarios"][name]["Management"]["Prescriptions"]["Correct"].has(category) == false:
						perfomanceDict["Scenarios"][name]["Management"]["Prescriptions"]["Correct"][category] = {}
					perfomanceDict["Scenarios"][name]["Management"]["Prescriptions"]["Correct"][category][med] = bedPrescriptions[bed][category][med]
					bedStories[currentWard][bed][0]["Answers"]["Prescriptions"][category].remove(bedStories[currentWard][bed][0]["Answers"]["Prescriptions"][category].find(dict))
			if correct == false:
				if perfomanceDict["Scenarios"][name]["Management"]["Prescriptions"]["Incorrect"].has(category) == false:
					perfomanceDict["Scenarios"][name]["Management"]["Prescriptions"]["Incorrect"][category] = {}
				perfomanceDict["Scenarios"][name]["Management"]["Prescriptions"]["Incorrect"][category][med] = bedPrescriptions[bed][category][med]
	perfomanceDict["Scenarios"][name]["Management"]["Prescriptions"]["Missed"] = bedStories[currentWard][bed][0]["Answers"]["Prescriptions"]
	
	var presAnswerCount = answerCount
	var presScore
	if answerCount == 0:
		presScore = null
	else:
		presScore = round((float(correctPresCount)/float(answerCount)) * 100.0)
	var prescribingScore = 0
	
	
	#form contact data:
	answerCount = bedStories[currentWard][bed][0]["Answers"]["Contact"].size()
	managementScoreCount += answerCount
	perfomanceDict["Scenarios"][name]["Management"]["Contact"] = {"Correct": [], "Incorrect": [], "Missed": []}
	if bedContacts[currentWard][bed] != null:
		for contact in bedContacts[currentWard][bed]:
			if bedStories[currentWard][bed][0]["Answers"]["Contact"].has(contact):
				perfomanceDict["Scenarios"][name]["Management"]["Contact"]["Correct"].append(contact)
				bedStories[currentWard][bed][0]["Answers"]["Contact"].remove(bedStories[currentWard][bed][0]["Answers"]["Contact"].find(contact))
			else:
				perfomanceDict["Scenarios"][name]["Management"]["Contact"]["Incorrect"].append(contact)
	perfomanceDict["Scenarios"][name]["Management"]["Contact"]["Missed"] = bedStories[currentWard][bed][0]["Answers"]["Contact"]
	#contact score:
	var contactAnswerCount = answerCount
	var contactScore
	if answerCount == 0:
		contactScore = null
	else:
		contactScore = round((float(perfomanceDict["Scenarios"][name]["Management"]["Contact"]["Correct"].size())/float(answerCount)) * 100.0)

	#form procedure data:
	answerCount = bedStories[currentWard][bed][0]["Answers"]["Procedures"].size()
	managementScoreCount += answerCount
	perfomanceDict["Scenarios"][name]["Management"]["Procedures"] = {"Correct": [], "Incorrect": [], "Missed": []}
	if bedProcedures[currentWard][bed] != null:
		for proc in bedProcedures[bed]:
			if bedStories[currentWard][bed][0]["Answers"]["Procedures"].has(proc):
				perfomanceDict["Scenarios"][name]["Management"]["Procedures"]["Correct"].append(proc)
				bedStories[currentWard][bed][0]["Answers"]["Procedures"].remove(bedStories[currentWard][bed][0]["Answers"]["Procedures"].find(proc))
			else:
				perfomanceDict["Scenarios"][name]["Management"]["Procedures"]["Incorrect"].append(proc)
	perfomanceDict["Scenarios"][name]["Management"]["Procedures"]["Missed"] = bedStories[currentWard][bed][0]["Answers"]["Procedures"]
	var procScore
	var procAnswerCount = answerCount
	if answerCount == 0:
		procScore = null
	else:
		procScore = round((float(perfomanceDict["Scenarios"][name]["Management"]["Procedures"]["Correct"].size())/float(answerCount)) * 100.0)
	
	#add the scores:
	perfomanceDict["Scenarios"][name]["Scores"] = {"Management": {}}
	perfomanceDict["Scenarios"][name]["Scores"]["History"] = historyScore
	perfomanceDict["Scenarios"][name]["Scores"]["Investigations"] = ixScore
	perfomanceDict["Scenarios"][name]["Scores"]["Management"]["Prescribing"] = presScore
	perfomanceDict["Scenarios"][name]["Scores"]["Management"]["Procedures"] = procScore
	perfomanceDict["Scenarios"][name]["Scores"]["Management"]["Contact"] = contactScore
	perfomanceDict["Scenarios"][name]["Scores"]["Management"]["endAction"] = null
	
	var managementScore = 0.0
	var array = [presScore, procScore, contactScore]
	var array2 = [presAnswerCount, procAnswerCount, contactAnswerCount]
	var itemNotNull = 0
	for i in range(0, array.size()):
		if array[i] != null:
			managementScore += (float(array[i]) * (array2[i]/float(managementScoreCount)))
			print(str(array[i]) + " * " + str(array2[i]) + "/" + str(managementScoreCount))
			print(str(managementScore))
	
	perfomanceDict["Scenarios"][name]["Scores"]["Management"]["Overall"] = managementScore
	perfomanceDict["Scenarios"][name]["Scores"]["Overall"] = (historyScore + ixScore + managementScore)/3
	
	
	perfomanceDict["Scenarios"][name]["Notes"] = bedNotes[currentWard][bed]
	perfomanceDict["Scenarios"][name]["Differentials"] = bedDifferentials[currentWard][bed]

	
	XP += int(perfomanceDict["Scenarios"][name]["Scores"]["Overall"])
	currentRank = check_rank()
	perfomanceDict["rank"] = currentRank
	perfomanceDict["rankProgress"] = XP
	
	if perfomanceDict["Lists"]["allPrevious"] == null:
		perfomanceDict["Lists"]["allPrevious"] = []
	perfomanceDict["Lists"]["allPrevious"].append(name)

	if perfomanceDict["Lists"]["bySubject"][bedStories["Accident and Emergency"][bed][0]["topic"]] == null:
		perfomanceDict["Lists"]["bySubject"][bedStories["Accident and Emergency"][bed][0]["topic"]] = []
	perfomanceDict["Lists"]["bySubject"][bedStories["Accident and Emergency"][bed][0]["topic"]].append(name)

	update_scores(bedStories["Accident and Emergency"][bed][0]["topic"], name)
	
	save_JSON(perfomanceDict)
#	load_new_scenario(perfomanceDict["Lists"]["allPrevious"])
	perfomanceDict = null

func update_scores(topic, name):
#	var topicScore = perfomanceDict["Scores"]["Subject"][topic]
	
	var overallScore = 0
	var overallCount = 0
	
	var overallManageScore = 0.0
	var overallManageCount = 0.0

	var history = perfomanceDict["Scores"]["Skill"]["History"]
	var investigations = perfomanceDict["Scores"]["Skill"]["Investigation"]
	var prescribing = perfomanceDict["Scores"]["Skill"]["Management"]["Prescribing"]
	var contact = perfomanceDict["Scores"]["Skill"]["Management"]["Contact"]
	var procedures = perfomanceDict["Scores"]["Skill"]["Management"]["Procedures"]
	var endAction = perfomanceDict["Scores"]["Skill"]["Management"]["endAction"]

	var size = perfomanceDict["Lists"]["allPrevious"].size()
	if perfomanceDict["Scenarios"][name]["Scores"]["History"] != null:
		history = ((history * (size - 1)) + perfomanceDict["Scenarios"][name]["Scores"]["History"]) / size
		perfomanceDict["Scores"]["Skill"]["History"] = history
#			overallScore += history
#			overallCount += 1
	if perfomanceDict["Scenarios"][name]["Scores"]["Investigations"] != null:
		investigations = ((investigations * (size - 1)) + perfomanceDict["Scenarios"][name]["Scores"]["Investigations"]) / size
		perfomanceDict["Scores"]["Skill"]["Investigation"] = investigations
#			overallScore += investigations
#			overallCount += 1
	if perfomanceDict["Scenarios"][name]["Scores"]["Management"]["Prescribing"] != null:
		prescribing = ((prescribing * (size - 1)) + perfomanceDict["Scenarios"][name]["Scores"]["Management"]["Prescribing"]) / size
		perfomanceDict["Scores"]["Skill"]["Management"]["Prescribing"] = prescribing
#			overallManageScore += prescribing
#			overallManageCount += 1
	if perfomanceDict["Scenarios"][name]["Scores"]["Management"]["Contact"] != null:
		contact = ((contact * (size - 1)) + perfomanceDict["Scenarios"][name]["Scores"]["Management"]["Contact"]) / size
		perfomanceDict["Scores"]["Skill"]["Management"]["Contact"] = contact
#			overallManageScore += contact
#			overallManageCount += 1
	if perfomanceDict["Scenarios"][name]["Scores"]["Management"]["Procedures"] != null:
		procedures = ((prescribing * (size - 1)) + perfomanceDict["Scenarios"][name]["Scores"]["Management"]["Procedures"]) / size
		perfomanceDict["Scores"]["Skill"]["Management"]["Procedures"] = procedures
#			overallManageScore += procedures
#			overallManageCount += 1
	if perfomanceDict["Scenarios"][name]["Scores"]["Management"]["endAction"] != null:
		endAction = ((endAction * (size - 1)) + perfomanceDict["Scenarios"][name]["Scores"]["Management"]["endAction"]) / size
		perfomanceDict["Scores"]["Skill"]["Management"]["endAction"] = endAction
#			overallManageScore += endAction
#			overallManageCount += 1
	
	perfomanceDict["Scores"]["Skill"]["Management"]["Overall"] = ((perfomanceDict["Scores"]["Skill"]["Management"]["Overall"] * (size - 1)) + perfomanceDict["Scenarios"][name]["Scores"]["Management"]["Overall"]) / size
	
	perfomanceDict["Scores"]["Overall"] = (history + investigations + perfomanceDict["Scores"]["Skill"]["Management"]["Overall"]) / 3
#		if perfomanceDict["Lists"]["bySubject"][topic] == null:
#			perfomanceDict["Scores"]["Subject"][topic] = perfomanceDict["Scenarios"][name]["Scores"]["Overall"]
#		else:
	perfomanceDict["Scores"]["Subject"][topic] = ((perfomanceDict["Scores"]["Subject"][topic] * (perfomanceDict["Lists"]["bySubject"][topic].size() - 1)) + perfomanceDict["Scenarios"][name]["Scores"]["Overall"]) / perfomanceDict["Lists"]["bySubject"][topic].size()

func check_rank():
	var xp_array = [0, 250, 500, 1000, 5000]
	var rank_array = ["PD Foundation 1", "PD Foundation 2", "PD Core 1", "PD Core 2", "PD Registrar 1"]
	var rankNum = rank_array.find(currentRank)
	if XP < xp_array[rankNum + 1]:
		return currentRank
	elif XP > xp_array[rankNum + 1]:
		return rank_array[rankNum + 1]

#func return_management_score(bed):
#	var dict = {}
##	var prescriptions = {}
#	var prescriptions = str2var(var2str(bedStories[currentWard][bed][0]["Answers"]["Prescriptions"])) 
#
#	var score = 0
#
#	var presCount = 0
#	for type in prescriptions:
#		for medDict in prescriptions[type]:
#			presCount += 1
#			for prescribed in bedPrescriptions[bed][type]:
#				if medDict.has(prescribed):
#					score += 1
#					medDict.clear()
#
#	perfomanceDict["Scenarios"][bedStories["Accident and Emergency"][bed][0]["id"]]["Prescriptions"]["Missed"] = prescriptions
#	dict["Prescribing"] = (float(score)/float(presCount)) * 100
#
#	score = 0
#	var proCount = 0
#
#	if bedStories[currentWard][bed][0]["Answers"]["Procedures"] != null:
#		var missed = []
#		for procedure in bedStories[currentWard][bed][0]["Answers"]["Procedures"]:
#			proCount += 1
#			if bedProcedures[currentWard][bed] != null:
#				if bedProcedures[currentWard][bed].has(procedure):
#					score += 1
#				else:
#					missed.append(procedure)
#			else:
#				missed = bedStories[currentWard][bed][0]["Answers"]["Procedures"]
#				proCount = bedStories[currentWard][bed][0]["Answers"]["Procedures"].size()
#		perfomanceDict["Scenarios"][bedStories["Accident and Emergency"][bed][0]["id"]]["Procedures"]["Missed"] = missed
#		dict["Procedures"] = (float(score)/float(proCount)) * 100
#	else:
#		dict["Procedures"] = null
#
#
#
#	score = 0
#	var conCount = 0
#	if bedStories[currentWard][bed][0]["Answers"]["Contact"] != null:
#		var missed = []
#		if bedContacts[currentWard][bed] != null:
#			for contact in bedStories[currentWard][bed][0]["Answers"]["Contact"]:
#				conCount += 1
#				if bedContacts[currentWard][bed].has(contact):
#					score += 1
#				else:
#					missed.append(contact)
#		else:
#			missed = bedStories[currentWard][bed][0]["Answers"]["Contact"]
#			conCount = bedStories[currentWard][bed][0]["Answers"]["Contact"].size()
#		perfomanceDict["Scenarios"][bedStories["Accident and Emergency"][bed][0]["id"]]["Contact"]["Missed"] = missed
#		dict["Contact"] = (float(score)/float(conCount)) * 100
#	else:
#		dict["Contact"] = null
#
#	var overallCount = float(presCount + conCount + proCount)
#	var overall = float(0)
#	if dict["Prescribing"] != null:
#		overall += dict["Prescribing"] * (presCount/overallCount)
#	if dict["Procedures"] != null:
#		overall += dict["Procedures"] * (proCount/overallCount)
#	if dict["Contact"] != null:
#		overall += dict["Contact"] * (conCount/overallCount)
#
#	dict["Overall"] = overall
#	return dict

#func return_ix_score(bed):
#	var count = 0
#	var score = 0
#	var missed = []
#	var toDoIx = bedStories[currentWard][bed][0]["Answers"]["Investigations"]
#	count = toDoIx.size()
#	for ix in toDoIx:
#		if bedInvestigations[bed]["Complete"].has(ix):
#			score += 1
#		else:
#			missed.append(ix)
#	perfomanceDict["Scenarios"][bedStories["Accident and Emergency"][bed][0]["id"]]["Investigations"]["Missed"] = missed
#	return (float(score)/float(count)) * 100

#func return_history_score(bed):
#	var score = 0
#	var missed = {}
#	var toAsk = bedStories[currentWard][bed][0]["Answers"]["History"]
#	if bedHistory[currentWard][bed] != null:
#		for Q in toAsk:
#			if bedHistory[currentWard][bed].has(Q):
#				score += 1
#			else:
#				missed[Q] = toAsk[Q]
#	else:
#		score = 0
#		missed = toAsk
#	perfomanceDict["Scenarios"][bedStories["Accident and Emergency"][bed][0]["id"]]["History"]["Missed"] = missed
#	return (float(score)/float(toAsk.size())) * 100

#This is currently inactive and redundant code as the story score is currently not being marked. 
#func return_story_score(bed):
#	return 0
#	var count = bedStories[currentWard][bed][0]["Answers"]["topStoryScore"]
#	var score = bedStories[currentWard][bed][3]
#	return (float(score)/float(count)) * 100

func save_JSON(saveFile):
	var performance = File.new()
	if isWeb:
		performance.open("user://performance.json", File.WRITE)
	else:
		performance.open("res://JSON_files/performance.json", File.WRITE)
	performance.store_line(to_json(saveFile))
	performance.close()
	if isWeb:
		send_performance_to_cosmos(saveFile)

func send_performance_to_cosmos(saveFile):
	print("at send")
	saveFile.erase("_etag")
	var json = to_json(saveFile)
	json = json.replace("'","’")
	json = json.replace("\\n","")
	var code="""
		var xmlHttp = new XMLHttpRequest();
		xmlHttp.open("PUT", '""" + url + """/gameapis/database/update-performancerecord/""" + currentPlayer + """', false);
		xmlHttp.setRequestHeader("Content-Type", "application/json");
		xmlHttp.send(`%s`);
		xmlHttp.response;""" % (json)
	print(code)
	var response=JavaScript.eval(code)
	print(response)

# save the game. Mode stands for if saving is an autosave or save done by the player.
func save_game(mode):
#	if javaScript:
	print("current load is :" + currentLoad)
	var save_file = {}
	if isWeb:
		save_file = singleton.load_file_as_JSON("user://saved_games.json")
	else:
		save_file = singleton.load_file_as_JSON("res://JSON_files/saved_game.json")
#	print(save_file)
	var save_dict = return_current_save()
	save_file["CurrentLoad"] = currentLoad
	save_file["Playlist"] = playlist
	save_file["CurrentlyPlaying"] = []
	for bed in bedStories["Accident and Emergency"]:
		if bedStories["Accident and Emergency"][bed] != null:
			save_file["CurrentlyPlaying"].append(bedStories["Accident and Emergency"][bed][0]["id"])
	if save_file["Saves"] == null:
		save_file["Saves"] = {}
		save_file["Saves"][currentLoad] = save_dict
	else:
		save_file["Saves"][currentLoad] = save_dict
	
	if isWeb:
		send_save_file(save_file)

	if mode == 0:
		var node = load('res://Scenes/LoadingCirc.tscn').instance()
		$"/root/World/GUI".add_child(node)
		node.saving()
		
	var save_game = File.new()
	if isWeb:
		save_game.open("user://saved_games.json", File.WRITE)
	else:
		save_game.open("res://JSON_files/saved_game.json", File.WRITE)

	save_game.store_line(to_json(save_file))
	save_game.close()

func load_new_scenario(previous):
	if playlist.size() > 0:
		load_specific_scenario(playlist[0])
	else:
		load_scenario_by_topic()

func load_specific_scenario(scenarioName):
	var code="""
		var xmlHttp = new XMLHttpRequest();
		xmlHttp.open("PUT", '""" + url + """/gameapis/databasev2/get-scenario-by-id/""" + scenarioName + """', false);
		xmlHttp.setRequestHeader("Content-Type", "application/json");
		xmlHttp.send();
		xmlHttp.response;"""
	var response=JavaScript.eval(code)
	if response != null:
		var dict = {}
		dict = parse_json(response)
		nextScenario = dict[0]

func load_scenario_by_topic():
	pass

func send_save_file(save_file):
	save_file.erase("_etag")
	var json = to_json(save_file)
	json = json.replace("'","’")
	json = json.replace("\\n","")
	http_request.send_data_to_server(url, '/gameapis/database/update-savegame/' + currentPlayer, 'saving', $'/root/World/GUI/Loading', json)
	
	
#	currentPlayer = "Stubbsy345"
	var code="""
		var xmlHttp = new XMLHttpRequest();
		xmlHttp.open("PUT", '""" + url + """/gameapis/database/update-savegame/""" + currentPlayer + """', true);
		xmlHttp.setRequestHeader("Content-Type", "application/json");
		xmlHttp.send(`%s`);
		xmlHttp.response;""" % (json)
	print(code)
	var response=JavaScript.eval(code)
	print(response)

func return_current_save():
	var player = get_node("/root/World/playerNode/Player")
	var save_dict = {}
	save_dict["Player"] = {
		posx = player.get_position().x,
		posy = player.get_position().y
	}
	save_dict["CurrentWard"] = currentWard
	save_dict["bedStories"] = bedStories
	save_dict["bedNotes"] = bedNotes
	save_dict["bedInvestigations"] = bedInvestigations
	save_dict["bedHistory"] = bedHistory
	save_dict["bedPrescriptions"] = bedPrescriptions
	save_dict["bedDifferentials"] = bedDifferentials
	save_dict["bedContacts"] = bedContacts
	save_dict["bedProcedures"] = bedProcedures
	save_dict["introDone"] = introDone
	save_dict["scenariosCompleted"] = scenariosCompleted
	save_dict["bedBleeps"] = bedBleeps 
	save_dict["calls"] = calls
	save_dict["playerInfo"] = playerInfo
	return save_dict

func open_info(type, name, info):
	var screen = load("res://Scenes/InformationScreen.tscn").instance()
	$"/root/World/GUI".add_child(screen)
	if type == 0:
		screen.add_investigation_info(name, info)

func play_rival_scene():
	var character = load("res://Scenes/Character.tscn").instance()
	var node = Node.new()
	node.set_script(load("res://Scripts/wardStories.gd"))
	node.set_name("Node")
	node.rivalIntro = true
	character.get_node("KinematicBody2D").add_child(node)

	character.get_node("KinematicBody2D").set_position(Vector2(560, 400))
	character.get_node("KinematicBody2D/Sprite").set_texture(load("res://Graphics/Characters/rival.png"))
	character.get_node("KinematicBody2D").set_name("Rival")
	$"/root/World/CHARACTERS".add_child(character)

func play_cath_scene():
	var character = load("res://Scenes/Character.tscn").instance()
	var node = Node.new()
	node.set_script(load("res://Scripts/wardStories.gd"))
	node.set_name("Node")
	node.cathIntro = true
	character.get_node("KinematicBody2D").add_child(node)

	character.get_node("KinematicBody2D").set_position(Vector2(240, 528))
	character.get_node("KinematicBody2D/Sprite").set_texture(load("res://Graphics/Characters/old_greyHair_male.png"))
	character.get_node("KinematicBody2D").set_name("Dr Bentham")
	$"/root/World/CHARACTERS".add_child(character)
