tool
extends Control

class_name ImageManager

static func generate_mpaint_color(color :Color):
	return "\"" + str(color.r) + "," + str(color.g) + "," + str(color.b) + "," + str(color.a) + "\""

static func create_mpaint_file(image_path :String, fill_color :Color):
	var file = File.new()
	file.open(image_path, File.WRITE)
	# "0,0,0,0","0,0,0,0",
	# "0,0,0,0","0,0,0,0",
	for x in range(512):
		var line = ""
		for y in range(512):
			line += generate_mpaint_color(fill_color) + ","
		file.store_line(line)
	file.close()

static func mpaint_file_to_texture(image_path :String) -> ImageTexture:
	var image_texture :ImageTexture = load(image_path)
	return image_texture

static func texture_to_mpaint_file(tex :ImageTexture, save_path :String):
	var image = tex.get_data()
	image.lock()

	var file = File.new()
	file.open(save_path, File.WRITE)
	# "0,0,0,0","0,0,0,0",
	# "0,0,0,0","0,0,0,0",
	for x in range(512):
		var line = ""
		for y in range(512):
			var color :Color = image.get_pixel(x, y)
			line += generate_mpaint_color(color) + ","
		file.store_line(line)
	file.close()

	image.unlock()
