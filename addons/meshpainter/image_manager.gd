@tool
extends Control

class_name ImageManager

static func create_json_file(path :String):
	print("creating " + path)
	var dir = Directory.new()
	dir.open("res://addons/meshpainter/materials/")
	dir.copy("res://addons/meshpainter/materials/blank.json", path)

static func create_layer_file(path :String):
	print("creating " + path)
	var dir = Directory.new()
	dir.open("res://addons/meshpainter/materials/")
	dir.copy("res://addons/meshpainter/materials/white.png", path)

static func json_to_texture(path :String) -> ImageTexture:
	var file = File.new()
	file.open(path, File.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	var json_data :Array = json.get_data()
	var image = Image.new()
	image.create(32768, 1, false, Image.FORMAT_RGBAH)
	for x in range(json_data.size()):
		var r = json_data[x][0]
		var g = json_data[x][1]
		var b = json_data[x][2]
		var a = json_data[x][3]
		image.set_pixel(x,0,Color(r,g,b,a))
	
	return ImageTexture.create_from_image(image)

static func layer_to_texture(path :String) -> ImageTexture:
	var compressed_tex :CompressedTexture2D = load(path)
	var image :Image = compressed_tex.get_image()
	return ImageTexture.create_from_image(image)

static func texture_to_json(tex :ImageTexture, save_path :String):
	var image :Image = tex.get_image()
	var data_to_send = []
	for x in 32768:
		var color :Color = image.get_pixel(x, 0)
		data_to_send.append([color.r,color.g,color.b,color.a])
	
	var json = JSON.new()
	var json_string = json.stringify(data_to_send)
	var file = File.new()
	file.open(save_path, File.WRITE_READ)
	file.store_string(json_string)
	file.close()
