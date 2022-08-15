@tool
extends EditorImportPlugin

const size = 512

func get_importer_name():
	return "mesh.painter.plugin"

func get_visible_name():
	return "Mesh Painter"

func get_recognized_extensions():
	return ["mpaint"]

func get_save_extension():
	return "res"

func get_resource_type():
	return "ImageTexture"

func get_preset_count():
	return 1

func get_preset_name(i):
	return "Default"

func get_import_options(i):
	return [{"name": "my_option", "default_value": false}]

func get_option_visibility(option, options):
	return true

func import(source_file, save_path, options, platform_variants, gen_files):
	var image = Image.new()
	image.create(size,size,false,Image.FORMAT_RGBAH)
	image.lock()
	
	var file = File.new()
	var err = file.open(source_file, File.READ)
	if err != OK:
		return err
	
		# [0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0] 
		# [0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0]
	for x in range(size):
		var row :PackedStringArray = file.get_csv_line()
		for y in range(size):
			var channels = row[y].split(",")
			if channels.size() != 4:
				return ERR_PARSE_ERROR
			
			var color :Color = Color(channels[0].to_float(), channels[1].to_float(), channels[2].to_float(), channels[3].to_float())
			image.set_pixel(x, y, color)
	
	file.close()
	
	image.unlock()
	var image_tex = ImageTexture.new()
	image_tex.create_from_image(image)
	
	var filename = save_path + "." + get_save_extension()
	return ResourceSaver.save(filename, image_tex)
