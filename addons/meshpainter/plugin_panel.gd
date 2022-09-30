# Paiting panel that contains all the modes and uniformeters for painting the mesh instance selected

@tool
extends Control
class_name PluginPanel

var plugin_cursor :PluginCursor
var editor_filesystem :EditorFileSystem
var dir_path :String

var root :Node
var mesh_instance :MeshInstance3D

# All painting types, default is albedo
enum TabMode {ALBEDO, ROUGHNESS, METALNESS, EMISSION}
var tab_mode = TabMode.ALBEDO

# Temporary nodes needed to paint on mesh
var temp_plugin_node :Node
var temp_collision :CollisionShape3D
var temp_body :StaticBody3D

# All the textures containing brush and color info, which will be passed on to PBR shader
var tex_albedo_brush :ImageTexture
var tex_albedo_color :ImageTexture
var tex_albedo_layer_0 :ImageTexture
var tex_albedo_layer_1 :ImageTexture
var tex_albedo_layer_2 :ImageTexture
var tex_albedo_layer_3 :ImageTexture

var tex_roughness_brush :ImageTexture
var tex_roughness_color :ImageTexture
var tex_roughness_layer_0 :ImageTexture
var tex_roughness_layer_1 :ImageTexture
var tex_roughness_layer_2 :ImageTexture
var tex_roughness_layer_3 :ImageTexture

var tex_metalness_brush :ImageTexture
var tex_metalness_color :ImageTexture
var tex_metalness_layer_0 :ImageTexture
var tex_metalness_layer_1 :ImageTexture
var tex_metalness_layer_2 :ImageTexture
var tex_metalness_layer_3 :ImageTexture

var tex_emission_brush :ImageTexture
var tex_emission_color :ImageTexture
var tex_emission_layer_0 :ImageTexture
var tex_emission_layer_1 :ImageTexture
var tex_emission_layer_2 :ImageTexture
var tex_emission_layer_3 :ImageTexture

# PBR shader which will receive all textures
var pbr_shader :Shader = preload("res://addons/meshpainter/materials/pbr_shader.gdshader")

var mesh_id :String

# Add collision to current mesh to retreive brush positions on mesh later on
func generate_collision():
	# Generate collision shape from mesh 
	temp_collision = CollisionShape3D.new()
	temp_collision.set_shape(mesh_instance.mesh.create_trimesh_shape())
	temp_collision.hide()
	# Add static body to use collisions
	temp_body = StaticBody3D.new()
	temp_body.add_child(temp_collision)
	temp_body.collision_layer = 32
	# Add main plugin node where body and collision shape will be
	temp_plugin_node = Node3D.new()
	temp_plugin_node.name = "MeshPainter"
	temp_plugin_node.add_child(temp_body)
	
	mesh_instance.add_child(temp_plugin_node)
	temp_collision.owner = root
	temp_body.owner = root
	temp_plugin_node.owner = root

func retrieve_material(mat :ShaderMaterial):
	var types = ["albedo", "roughness", "metalness", "emission"]
	for type in types:
		set("tex_" + type + "_brush", mat.get_shader_parameter("tex_" + type +"_brush"))
		set("tex_" + type + "_color", mat.get_shader_parameter("tex_" + type +"_color"))
		set("tex_" + type + "_layer_0", mat.get_shader_parameter("tex_" + type +"_layer_0"))
		set("tex_" + type + "_layer_1", mat.get_shader_parameter("tex_" + type +"_layer_1"))
		set("tex_" + type + "_layer_2", mat.get_shader_parameter("tex_" + type +"_layer_2"))
		set("tex_" + type + "_layer_3", mat.get_shader_parameter("tex_" + type +"_layer_3"))

func generate_id(name :String):
	randomize()
	name = get_tree().edited_scene_root.scene_file_path + name
	mesh_id = str(name.hash())

# Show panel, generate collisions for painting, setup PBR material and start with albedo mode
func show_panel(root :Node, mesh_instance :MeshInstance3D):
	show()
	self.root = root
	self.mesh_instance = mesh_instance
	generate_id(mesh_instance.name)
	setup_part_1()

func setup_part_1():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(dir_path):
		OS.alert("A folder at " + str(dir_path) + " will be created to keep all generated textures from painting.")
		dir.make_dir(dir_path)
	
	var needs_material = true
	if mesh_instance.mesh:
		generate_collision()
		if mesh_instance.mesh.surface_get_material(0) is ShaderMaterial:
			var material :ShaderMaterial = mesh_instance.mesh.surface_get_material(0)
			if material.shader == pbr_shader:
				needs_material = false
				retrieve_material(material)
				setup_part_2()
	if needs_material:
		# Create new custom material
		var mat = ShaderMaterial.new()
		mat.shader = pbr_shader
		
		# Get folder which will hold that meshinstance textures
		var folder :String = dir_path + "/" + mesh_id
		dir.make_dir(folder)
		folder += "/"
		create_material_part_1_4(mat, folder)

func setup_part_2():
	setup_tabs()
	_on_TabContainer_tab_selected(0)

# Create files
func create_material_part_1_4(mat :ShaderMaterial, folder :String):
	create_mpaint_files(folder)
	call_deferred("create_material_part_2_4", mat, folder)

# Scan files
func create_material_part_2_4(mat :ShaderMaterial, folder :String):
	editor_filesystem.scan_sources()
	while(not scan_new_files(folder)):
		await get_tree().create_timer(1.0).timeout
	call_deferred("create_material_part_3_4", mat, folder)

# Create textures from files
func create_material_part_3_4(mat :ShaderMaterial, folder :String):
	create_textures(folder)
	call_deferred("create_material_part_4_4", mat, folder)

# Finished creation of material
func create_material_part_4_4(mat :ShaderMaterial, folder :String):
	# Set all shader uniforms
	setup_shader_textures(mat)
	mat.set_shader_parameter("uv_scale", Vector3(1,1,1))
	
	# Use material for current mesh instance
	mesh_instance.mesh.surface_set_material(0, mat)
	call_deferred("setup_part_2")

func create_mpaint_files(folder :String):
	for type in ["albedo", "roughness", "metalness", "emission"]:
		var layers = ["brush", "color", "layer_0", "layer_1", "layer_2", "layer_3"]
		for i in range(layers.size()):
			var path = folder + type + "_" + layers[i] + ".mpaint"
			ImageManager.create_mpaint_file(path)

func scan_new_files(folder :String):
	var dir = DirAccess.open("res://")
	var all_files_are_ready = true
	for type in ["albedo", "roughness", "metalness", "emission"]:
		for layer in ["brush", "color", "layer_0", "layer_1", "layer_2", "layer_3"]:
			if not dir.file_exists(folder + type + "_" + layer + ".mpaint.import"):
				all_files_are_ready = false
	return all_files_are_ready

func create_textures(folder):
	for type in ["albedo", "roughness", "metalness", "emission"]:
		set("tex_" + type + "_brush", ImageManager.mpaint_to_texture(folder + type + "_brush.mpaint"))
		set("tex_" + type + "_color", ImageManager.mpaint_to_texture(folder + type + "_color.mpaint"))
		set("tex_" + type + "_layer_0", ImageManager.mpaint_to_texture(folder + type + "_layer_0.mpaint"))
		set("tex_" + type + "_layer_1", ImageManager.mpaint_to_texture(folder + type + "_layer_1.mpaint"))
		set("tex_" + type + "_layer_2", ImageManager.mpaint_to_texture(folder + type + "_layer_2.mpaint"))
		set("tex_" + type + "_layer_3", ImageManager.mpaint_to_texture(folder + type + "_layer_3.mpaint"))

func setup_shader_textures(mat :ShaderMaterial):
	for type in ["albedo", "roughness", "metalness", "emission"]:
		mat.set_shader_parameter("tex_" + type + "_brush", get("tex_" + type + "_brush"))
		mat.set_shader_parameter("tex_" + type + "_color", get("tex_" + type + "_color"))
		mat.set_shader_parameter("tex_" + type + "_layer_0", get("tex_" + type + "_layer_0"))
		mat.set_shader_parameter("tex_" + type + "_layer_1", get("tex_" + type + "_layer_1"))
		mat.set_shader_parameter("tex_" + type + "_layer_2", get("tex_" + type + "_layer_2"))
		mat.set_shader_parameter("tex_" + type + "_layer_3", get("tex_" + type + "_layer_3"))

func setup_tabs():
	var folder :String = dir_path + "/" + mesh_id + "/"
	$VBoxContainer/TabContainer/E.setup(tex_emission_layer_0, tex_emission_layer_1, tex_emission_layer_2, tex_emission_layer_3, folder)
	$VBoxContainer/TabContainer/M.setup(tex_metalness_layer_0, tex_metalness_layer_1, tex_metalness_layer_2, tex_metalness_layer_3, folder)
	$VBoxContainer/TabContainer/G.setup(tex_roughness_layer_0, tex_roughness_layer_1, tex_roughness_layer_2, tex_roughness_layer_3, folder)
	$VBoxContainer/TabContainer/A.setup(tex_albedo_layer_0, tex_albedo_layer_1, tex_albedo_layer_2, tex_albedo_layer_3, folder)

# When tab selected, pass on right textures for cursor to paint on (albedo, roughness, metalness, emission)
func _on_TabContainer_tab_selected(tab: int) -> void:
	tab_mode = tab
	match tab_mode:
		TabMode.ALBEDO:
			plugin_cursor.show_cursor(root, mesh_instance, temp_plugin_node, tex_albedo_brush, tex_albedo_color)
		TabMode.ROUGHNESS:
			plugin_cursor.show_cursor(root, mesh_instance, temp_plugin_node, tex_roughness_brush, tex_roughness_color)
		TabMode.METALNESS:
			plugin_cursor.show_cursor(root, mesh_instance, temp_plugin_node, tex_metalness_brush, tex_metalness_color)
		TabMode.EMISSION:
			plugin_cursor.show_cursor(root, mesh_instance, temp_plugin_node, tex_emission_brush, tex_emission_color)

# When changing Albedo panel uniforms, pass new brush info to cursor
func _on_Albedo_values_changed(brush_color, brush_opacity, brush_size) -> void:
	plugin_cursor.set_brush_color(brush_color)
	plugin_cursor.set_brush_opacity(brush_opacity)
	plugin_cursor.set_brush_size(brush_size)

# When changing Roughness panel uniforms, pass new brush info to cursor
func _on_Roughness_values_changed(brush_color, brush_opacity, brush_size) -> void:
	plugin_cursor.set_brush_color(brush_color)
	plugin_cursor.set_brush_opacity(brush_opacity)
	plugin_cursor.set_brush_size(brush_size)

# When changing Metalness panel uniforms, pass new brush info to cursor
func _on_Metalness_values_changed(brush_color, brush_opacity, brush_size) -> void:
	plugin_cursor.set_brush_color(brush_color)
	plugin_cursor.set_brush_opacity(brush_opacity)
	plugin_cursor.set_brush_size(brush_size)

# When changing Emission panel uniforms, pass new brush info to cursor
func _on_Emission_values_changed(brush_color, brush_opacity, brush_size) -> void:
	plugin_cursor.set_brush_color(brush_color)
	plugin_cursor.set_brush_opacity(brush_opacity)
	plugin_cursor.set_brush_size(brush_size)


# Hide panel, remove added plugin nodes from tree and hide cursor
func hide_panel():
	if mesh_instance:
		$SavingPopup.popup_centered()
		await get_tree().create_timer(1.0).timeout
		save()
		$SavingPopup.hide()
		
		if temp_plugin_node:
			mesh_instance.remove_child(temp_plugin_node)
		mesh_instance = null
	
	if plugin_cursor:
		plugin_cursor.hide_cursor()
	hide()

func save():
	# Save mpaint files
	var folder :String = dir_path + "/" + mesh_id + "/"
	
	var types = ["albedo", "roughness", "metalness", "emission"]
	for type in types:
		var layers = ["brush", "color"]
		for i in range(layers.size()):
			var tex :ImageTexture = get("tex_" + type + "_" + layers[i])
			var path = folder + type + "_" + layers[i] + ".mpaint"
			ImageManager.texture_to_mpaint(tex, path)

func _on_UndoButton_pressed() -> void:
	plugin_cursor.undo()

func _on_RedoButton_pressed() -> void:
	plugin_cursor.redo()
