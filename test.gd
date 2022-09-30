extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var data_size = [512, 512]
	var data = []
	for y in data_size[1]:
		var row = []
		for x in data_size[0]:
			row.append([1,1,1,1])
		data.append(row)
	
	save(data_size, data)
	open("res://default_layer.mpaint")

func save(data_size, data):
	var file = FileAccess.open("res://default_layer.mpaint", FileAccess.WRITE)
	file.store_var(data_size)
	file.store_var(data)

func open(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var data_size = file.get_var()
	var data = file.get_var()
