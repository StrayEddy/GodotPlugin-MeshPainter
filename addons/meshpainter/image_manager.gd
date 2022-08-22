@tool
extends Control

class_name ImageManager

static func create_mpaint_file(path :String):
	var dir = Directory.new()
	if "brush" in path:
		dir.open("res://addons/meshpainter/materials/")
		dir.copy("res://addons/meshpainter/materials/blank.mpaint", path)
	elif "color" in path:
		dir.open("res://addons/meshpainter/materials/")
		dir.copy("res://addons/meshpainter/materials/white.mpaint", path)
	else:
		dir.open("res://addons/meshpainter/materials/")
		dir.copy("res://addons/meshpainter/materials/default_layer.mpaint", path)

static func mpaint_to_texture(path :String) -> ImageTexture:
	var image :Image = load(path)
	return ImageTexture.create_from_image(image)

static func texture_to_mpaint(image_tex :Texture2D, path :String):
	var image :Image = image_tex.get_image()
	if image.is_compressed():
		image.decompress()
	
	var data_size = [image.get_width(), image.get_height()]
	var data = []
	
	for y in data_size[1]:
		var row = []
		for x in data_size[0]:
			var color = image.get_pixel(x, y)
			row.append([color.r,color.g,color.b,color.a])
		data.append(row)
	
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_var(data_size)
	file.store_var(data)
	file.close()
