# Paiting panel that contains all the modes and parameters for painting the mesh instance selected

tool
extends Control

class_name PluginPanel

var plugin_cursor :PluginCursor
var editor_filesystem :EditorFileSystem
var dir_path :String

var root :Node
var mesh_instance :MeshInstance

# All painting types, default is albedo
enum TabMode {ALBEDO, ROUGHNESS, METALNESS, EMISSION}
var tab_mode = TabMode.ALBEDO

# Temporary nodes needed to paint on mesh
var temp_plugin_node :Spatial
var temp_collision :CollisionShape
var temp_body :StaticBody

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
var pbr_shader :Shader = preload("res://addons/meshpainter/materials/pbr_shader.shader")

# Show panel, generate collisions for painting, setup PBR material and start with albedo mode
func show_panel(root :Node, mesh_instance :MeshInstance):
	show()
	self.root = root
	self.mesh_instance = mesh_instance
	if mesh_instance.mesh:
		generate_collision()
		setup_material()
		setup_tabs()
		_on_TabContainer_tab_selected(0)

# Add collision to current mesh to retreive brush positions on mesh later on
func generate_collision():
	# Generate collision shape from mesh 
	temp_collision = CollisionShape.new()
	temp_collision.set_shape(mesh_instance.mesh.create_trimesh_shape())
	temp_collision.hide()
	# Add static body to use collisions
	temp_body = StaticBody.new()
	temp_body.add_child(temp_collision)
	temp_body.collision_layer = 32
	# Add main plugin node where body and collision shape will be
	temp_plugin_node = Spatial.new()
	temp_plugin_node.name = "MeshPainter"
	temp_plugin_node.add_child(temp_body)
	
	mesh_instance.add_child(temp_plugin_node)
	temp_collision.owner = root
	temp_body.owner = root
	temp_plugin_node.owner = root

# Edit current material if it's our custom plugin material, otherwise create a new custom PBR material
func setup_material():
	# Create new custom material
	var mat = ShaderMaterial.new()
	mat.shader = pbr_shader
	
	# Get folder which will hold that meshinstance textures
	var id :String = str(mesh_instance.get_instance_id())
	var dir :Directory = Directory.new()
	var folder :String = dir_path + "/" + id
	if not dir.dir_exists(folder):
		dir.make_dir(folder)
		folder += "/"
		
		# Create mpaint files
		create_mpaint_files(folder, "albedo")
		create_mpaint_files(folder, "roughness")
		create_mpaint_files(folder, "metalness")
		create_mpaint_files(folder, "emission")
		
		# Scan those new images
		editor_filesystem.scan_sources()
		print("Scanning sources")
	else:
		folder += "/"
	
	# Setup all textures
	setup_textures(folder)
	
	# Set all shader params
	setup_shader_textures(mat)
	mat.set_shader_param("uv1_scale", Vector3(1,1,1))
	
	# Use material for current mesh instance
	mesh_instance.mesh.surface_set_material(0, mat)

func create_mpaint_files(folder :String, type :String):
	ImageManager.create_mpaint_file(folder + type + "_brush.mpaint", Color(0,0,0,0))
	ImageManager.create_mpaint_file(folder + type + "_color.mpaint", Color(1,1,1,1))
	ImageManager.create_mpaint_file(folder + type + "_layer_0.mpaint", Color(1,1,1,1))
	ImageManager.create_mpaint_file(folder + type + "_layer_1.mpaint", Color(1,1,1,1))
	ImageManager.create_mpaint_file(folder + type + "_layer_2.mpaint", Color(1,1,1,1))
	ImageManager.create_mpaint_file(folder + type + "_layer_3.mpaint", Color(1,1,1,1))

func setup_textures(folder):
	tex_albedo_brush = ImageManager.mpaint_file_to_texture(folder + "albedo_brush.mpaint")
	print(tex_albedo_brush)
	tex_albedo_color = ImageManager.mpaint_file_to_texture(folder + "albedo_color.mpaint")
	tex_albedo_layer_0 = ImageManager.mpaint_file_to_texture(folder + "albedo_layer_0.mpaint")
	tex_albedo_layer_1 = ImageManager.mpaint_file_to_texture(folder + "albedo_layer_1.mpaint")
	tex_albedo_layer_2 = ImageManager.mpaint_file_to_texture(folder + "albedo_layer_2.mpaint")
	tex_albedo_layer_3 = ImageManager.mpaint_file_to_texture(folder + "albedo_layer_3.mpaint")

	tex_roughness_brush = ImageManager.mpaint_file_to_texture(folder + "roughness_brush.mpaint")
	tex_roughness_color = ImageManager.mpaint_file_to_texture(folder + "roughness_color.mpaint")
	tex_roughness_layer_0 = ImageManager.mpaint_file_to_texture(folder + "roughness_layer_0.mpaint")
	tex_roughness_layer_1 = ImageManager.mpaint_file_to_texture(folder + "roughness_layer_1.mpaint")
	tex_roughness_layer_2 = ImageManager.mpaint_file_to_texture(folder + "roughness_layer_2.mpaint")
	tex_roughness_layer_3 = ImageManager.mpaint_file_to_texture(folder +  "roughness_layer_3.mpaint")

	tex_metalness_brush = ImageManager.mpaint_file_to_texture(folder + "metalness_brush.mpaint")
	tex_metalness_color = ImageManager.mpaint_file_to_texture(folder + "metalness_color.mpaint")
	tex_metalness_layer_0 = ImageManager.mpaint_file_to_texture(folder + "metalness_layer_0.mpaint")
	tex_metalness_layer_1 = ImageManager.mpaint_file_to_texture(folder + "metalness_layer_1.mpaint")
	tex_metalness_layer_2 = ImageManager.mpaint_file_to_texture(folder + "metalness_layer_2.mpaint")
	tex_metalness_layer_3 = ImageManager.mpaint_file_to_texture(folder + "metalness_layer_3.mpaint")

	tex_emission_brush = ImageManager.mpaint_file_to_texture(folder + "emission_brush.mpaint")
	tex_emission_color = ImageManager.mpaint_file_to_texture(folder + "emission_color.mpaint")
	tex_emission_layer_0 = ImageManager.mpaint_file_to_texture(folder + "emission_layer_0.mpaint")
	tex_emission_layer_1 = ImageManager.mpaint_file_to_texture(folder + "emission_layer_1.mpaint")
	tex_emission_layer_2 = ImageManager.mpaint_file_to_texture(folder + "emission_layer_2.mpaint")
	tex_emission_layer_3 = ImageManager.mpaint_file_to_texture(folder + "emission_layer_3.mpaint")

func setup_shader_textures(mat :ShaderMaterial):
	mat.set_shader_param("tex_albedo_brush", tex_albedo_brush)
	mat.set_shader_param("tex_albedo_color", tex_albedo_color)
	mat.set_shader_param("tex_albedo_layer_0", tex_albedo_layer_0)
	mat.set_shader_param("tex_albedo_layer_1", tex_albedo_layer_1)
	mat.set_shader_param("tex_albedo_layer_2", tex_albedo_layer_2)
	mat.set_shader_param("tex_albedo_layer_3", tex_albedo_layer_3)
	
	mat.set_shader_param("tex_roughness_brush", tex_roughness_brush)
	mat.set_shader_param("tex_roughness_color", tex_roughness_color)
	mat.set_shader_param("tex_roughness_layer_0", tex_roughness_layer_0)
	mat.set_shader_param("tex_roughness_layer_1", tex_roughness_layer_1)
	mat.set_shader_param("tex_roughness_layer_2", tex_roughness_layer_2)
	mat.set_shader_param("tex_roughness_layer_3", tex_roughness_layer_3)
	
	mat.set_shader_param("tex_metalness_brush", tex_metalness_brush)
	mat.set_shader_param("tex_metalness_color", tex_metalness_color)
	mat.set_shader_param("tex_metalness_layer_0", tex_metalness_layer_0)
	mat.set_shader_param("tex_metalness_layer_1", tex_metalness_layer_1)
	mat.set_shader_param("tex_metalness_layer_2", tex_metalness_layer_2)
	mat.set_shader_param("tex_metalness_layer_3", tex_metalness_layer_3)
	
	mat.set_shader_param("tex_emission_brush", tex_emission_brush)
	mat.set_shader_param("tex_emission_color", tex_emission_color)
	mat.set_shader_param("tex_emission_layer_0", tex_emission_layer_0)
	mat.set_shader_param("tex_emission_layer_1", tex_emission_layer_1)
	mat.set_shader_param("tex_emission_layer_2", tex_emission_layer_2)
	mat.set_shader_param("tex_emission_layer_3", tex_emission_layer_3)

func setup_tabs():
	$VBoxContainer/TabContainer/E.setup(tex_emission_layer_0, tex_emission_layer_1, tex_emission_layer_2, tex_emission_layer_3)
	$VBoxContainer/TabContainer/M.setup(tex_metalness_layer_0, tex_metalness_layer_1, tex_metalness_layer_2, tex_metalness_layer_3)
	$VBoxContainer/TabContainer/G.setup(tex_roughness_layer_0, tex_roughness_layer_1, tex_roughness_layer_2, tex_roughness_layer_3)
	$VBoxContainer/TabContainer/A.setup(tex_albedo_layer_0, tex_albedo_layer_1, tex_albedo_layer_2, tex_albedo_layer_3)

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

# When changing Albedo panel params, pass new brush info to cursor
func _on_Albedo_values_changed(brush_color, brush_opacity, brush_size) -> void:
	plugin_cursor.set_brush_color(brush_color)
	plugin_cursor.set_brush_opacity(brush_opacity)
	plugin_cursor.set_brush_size(brush_size)

# When changing Roughness panel params, pass new brush info to cursor
func _on_Roughness_values_changed(brush_color, brush_opacity, brush_size) -> void:
	plugin_cursor.set_brush_color(brush_color)
	plugin_cursor.set_brush_opacity(brush_opacity)
	plugin_cursor.set_brush_size(brush_size)

# When changing Metalness panel params, pass new brush info to cursor
func _on_Metalness_values_changed(brush_color, brush_opacity, brush_size) -> void:
	plugin_cursor.set_brush_color(brush_color)
	plugin_cursor.set_brush_opacity(brush_opacity)
	plugin_cursor.set_brush_size(brush_size)

# When changing Emission panel params, pass new brush info to cursor
func _on_Emission_values_changed(brush_color, brush_opacity, brush_size) -> void:
	plugin_cursor.set_brush_color(brush_color)
	plugin_cursor.set_brush_opacity(brush_opacity)
	plugin_cursor.set_brush_size(brush_size)


# Hide panel, remove added plugin nodes from tree and hide cursor
func hide_panel():
	
	if mesh_instance:
		save()
		if temp_plugin_node:
			mesh_instance.remove_child(temp_plugin_node)
		mesh_instance = null
	
	if plugin_cursor:
		plugin_cursor.hide_cursor()
	hide()

func save():
	# Save mpaint files
	var id :String = str(mesh_instance.get_instance_id())
	var folder :String = dir_path + "/" + id + "/"
	save_textures(folder, "albedo")
	save_textures(folder, "roughness")
	save_textures(folder, "metalness")
	save_textures(folder, "emission")
	
	# Scan those new images
#	editor_filesystem.scan_sources()
	
	# Setup stream textures
#	setup_stream_textures_to_shader(folder, "albedo")
#	setup_stream_textures_to_shader(folder, "roughness")
#	setup_stream_textures_to_shader(folder, "metalness")
#	setup_stream_textures_to_shader(folder, "emission")

func save_textures(folder, type):
	var tex_brush :ImageTexture = get("tex_" + type + "_brush")
	var tex_color :ImageTexture = get("tex_" + type + "_color")
	var tex_layer_0 :ImageTexture = get("tex_" + type + "_layer_0")
	var tex_layer_1 :ImageTexture = get("tex_" + type + "_layer_1")
	var tex_layer_2 :ImageTexture = get("tex_" + type + "_layer_2")
	var tex_layer_3 :ImageTexture = get("tex_" + type + "_layer_3")
	
	
	ImageManager.texture_to_mpaint_file(tex_brush, folder + type + "_brush.mpaint")
	ImageManager.texture_to_mpaint_file(tex_color, folder + type + "_color.mpaint")
	ImageManager.texture_to_mpaint_file(tex_layer_0, folder + type + "_layer_0.mpaint")
	ImageManager.texture_to_mpaint_file(tex_layer_1, folder + type + "_layer_1.mpaint")
	ImageManager.texture_to_mpaint_file(tex_layer_2, folder + type + "_layer_2.mpaint")
	ImageManager.texture_to_mpaint_file(tex_layer_3, folder + type + "_layer_3.mpaint")

func setup_stream_textures_to_shader(folder, type):
	var tex_brush :StreamTexture
	var tex_color :StreamTexture
	var tex_layer_0 :StreamTexture
	var tex_layer_1 :StreamTexture
	var tex_layer_2 :StreamTexture
	var tex_layer_3 :StreamTexture
	
	tex_brush = load(folder + type + "_brush.mpaint")
	tex_color = load(folder + type + "_color.mpaint")
	tex_layer_0 = load(folder + type + "_layer_0.mpaint")
	tex_layer_1 = load(folder + type + "_layer_1.mpaint")
	tex_layer_2 = load(folder + type + "_layer_2.mpaint")
	tex_layer_3 = load(folder + type + "_layer_3.mpaint")
	
	var mat :ShaderMaterial = mesh_instance.mesh.surface_get_material(0)
	mat.set_shader_param("tex_" + type + "_brush", tex_brush)
	mat.set_shader_param("tex_" + type + "_color", tex_color)
	mat.set_shader_param("tex_" + type + "_layer_0", tex_layer_0)
	mat.set_shader_param("tex_" + type + "_layer_1", tex_layer_1)
	mat.set_shader_param("tex_" + type + "_layer_2", tex_layer_2)
	mat.set_shader_param("tex_" + type + "_layer_3", tex_layer_3)
