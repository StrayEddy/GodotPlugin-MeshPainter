tool
extends Control

class_name ImageManager

const size = 512

static func generate_mpaint_color(color :Color):
	return "\"" + str(color.r) + "," + str(color.g) + "," + str(color.b) + "," + str(color.a) + "\""

static func create_mpaint_file(path :String):
	var dir = Directory.new()
	if "brush" in path:
		dir.copy("res://addons/meshpainter/mpaints/blank.mpaint", path)
	else:
		dir.copy("res://addons/meshpainter/mpaints/white.mpaint", path)

static func mpaint_file_to_texture(image_path :String) -> ImageTexture:
	var image_texture :ImageTexture = load(image_path)
	return image_texture

static func texture_to_mpaint_file(params :Array):
	var tex :ImageTexture = params[0]
	var save_path :String = params[1]
	
	var image = tex.get_data()
	image.lock()

	var file = File.new()
	file.open(save_path, File.WRITE)
	# "0,0,0,0","0,0,0,0",
	# "0,0,0,0","0,0,0,0",
	for x in range(size):
		var line = ""
		for y in range(size):
			var color :Color = image.get_pixel(x, y)
			line += generate_mpaint_color(color) + ","
		file.store_line(line)
	file.close()
	
	image.unlock()
