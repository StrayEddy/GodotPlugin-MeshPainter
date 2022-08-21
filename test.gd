extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var data_to_send = []
	for x in 32768:
		data_to_send.append([1,1,1,1])
	
	var json = JSON.new()
	var json_string = json.stringify(data_to_send)
	save(json_string)
	open("res://white.json")

func save(content):
	var file = File.new()
	file.open("res://white.json", File.WRITE)
	file.store_string(content)
	file.close()

func open(path):
	var file = File.new()
	file.open(path, File.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	var data_received = json.get_data()
	if typeof(data_received) == TYPE_ARRAY:
		return data_received
	else:
		return []
