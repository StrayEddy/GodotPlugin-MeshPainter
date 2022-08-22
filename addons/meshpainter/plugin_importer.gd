@tool
extends EditorImportPlugin
class_name PluginImporter

const size = 512

func _get_importer_name():
	return "mesh.painter.plugin"

func _get_visible_name():
	return "Mesh Painter"

func _get_recognized_extensions():
	return ["mpaint"]

func _get_save_extension():
	return "res"

func _get_resource_type():
	return "Image"

func _get_preset_count():
	return 1

func _get_preset_name(i):
	return "Default"

func _get_priority():
	return 1.0;

func _get_import_order():
	return 0

func _get_import_options(path: String, preset_index: int):
	return [{"name": "my_option", "default_value": false}]

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary):
	return true

func _import(source_file, save_path, options, platform_variants, gen_files):
	var file = File.new()
	file.open(source_file, File.READ)
	var data_size = file.get_var()
	var data = file.get_var()
	file.close()
	
	var image = Image.new()
	if data_size[1] == 1:
		image.create(data_size[0], data_size[1], false, Image.FORMAT_RGBAH)
	else:
		image.create(data_size[0], data_size[1], false, Image.FORMAT_RGBA4444)
		
	for y in data_size[1]:
		var row = []
		for x in data_size[0]:
			var r = data[y][x][0]
			var g = data[y][x][1]
			var b = data[y][x][2]
			var a = data[y][x][3]
			image.set_pixel(x,y,Color(r,g,b,a))
	
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(image, filename)
