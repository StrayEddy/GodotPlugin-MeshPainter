# Paiting panel that contains all the modes and parameters for painting the mesh instance selected

tool
extends Control

class_name PluginPanel

var plugin_cursor :PluginCursor

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
var tex_albedo_layers :TextureArray

var tex_roughness_brush :ImageTexture
var tex_roughness_color :ImageTexture
var tex_roughness_layers :TextureArray

var tex_metalness_brush :ImageTexture
var tex_metalness_color :ImageTexture
var tex_metalness_layers :TextureArray

var tex_emission_brush :ImageTexture
var tex_emission_color :ImageTexture
var tex_emission_layers :TextureArray

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

# Hide panel, remove added plugin nodes from tree and hide cursor
func hide_panel():
	if mesh_instance:
		if temp_plugin_node:
			mesh_instance.remove_child(temp_plugin_node)
		mesh_instance = null
	
	if plugin_cursor:
		plugin_cursor.hide_cursor()
	hide()

# Edit current material if it's our custom plugin material, otherwise create a new custom PBR material
func setup_material():
	var existing_material :Material = mesh_instance.mesh.surface_get_material(0)
	if existing_material:
		if existing_material is ShaderMaterial:
			if existing_material.shader == pbr_shader:
				# Edit current custom material
				# Hookup existing textures to keep painting on them
				tex_albedo_brush = existing_material.get_shader_param("tex_albedo_brush")
				tex_albedo_color = existing_material.get_shader_param("tex_albedo_color")
				tex_albedo_layers = existing_material.get_shader_param("tex_albedo_layers")
				
				tex_roughness_brush = existing_material.get_shader_param("tex_roughness_brush")
				tex_roughness_color = existing_material.get_shader_param("tex_roughness_color")
				tex_roughness_layers = existing_material.get_shader_param("tex_roughness_layers")
				
				tex_metalness_brush = existing_material.get_shader_param("tex_metalness_brush")
				tex_metalness_color = existing_material.get_shader_param("tex_metalness_color")
				tex_metalness_layers = existing_material.get_shader_param("tex_metalness_layers")
				
				tex_emission_brush = existing_material.get_shader_param("tex_emission_brush")
				tex_emission_color = existing_material.get_shader_param("tex_emission_color")
				tex_emission_layers = existing_material.get_shader_param("tex_emission_layers")
				return
	
	# Create new custom material
	var mat = ShaderMaterial.new()
	mat.shader = pbr_shader
	
	# Image used for building textures
	var temp_image = Image.new()
	temp_image.create(512,512,false,Image.FORMAT_RGBAH)
	
	# Build albedo brush texture, transparent means empty
	tex_albedo_brush = ImageTexture.new()
	temp_image.fill(Color(0,0,0,0))
	tex_albedo_brush.create_from_image(temp_image)
	tex_albedo_brush.resource_name = "Albedo brush texture"
	# Build albedo color texture, default to white
	tex_albedo_color = ImageTexture.new()
	temp_image.fill(Color(1,1,1,1))
	tex_albedo_color.create_from_image(temp_image)
	tex_albedo_color.resource_name = "Albedo color texture"
	# Build albedo array
	tex_albedo_layers = TextureArray.new()
	tex_albedo_layers.create(512, 512, 4, Image.FORMAT_RGBAH)
	temp_image.fill(Color(0,0,0,0))
	tex_albedo_layers.set_layer_data(temp_image, 0)
	tex_albedo_layers.set_layer_data(temp_image, 1)
	tex_albedo_layers.set_layer_data(temp_image, 2)
	tex_albedo_layers.set_layer_data(temp_image, 3)
	
	# Build roughness brush texture, transparent means empty
	tex_roughness_brush = ImageTexture.new()
	temp_image.fill(Color(0,0,0,0))
	tex_roughness_brush.create_from_image(temp_image)
	tex_roughness_brush.resource_name = "Roughness brush texture"
	# Build roughness color texture, default to full roughness
	tex_roughness_color = ImageTexture.new()
	temp_image.fill(Color(1,1,1,1))
	tex_roughness_color.create_from_image(temp_image)
	tex_roughness_color.resource_name = "Roughness color texture"
	# Build roughness array
	tex_roughness_layers = TextureArray.new()
	tex_roughness_layers.create(512, 512, 4, Image.FORMAT_RGBAH)
	temp_image.fill(Color(0,0,0,0))
	tex_roughness_layers.set_layer_data(temp_image, 0)
	tex_roughness_layers.set_layer_data(temp_image, 1)
	tex_roughness_layers.set_layer_data(temp_image, 2)
	tex_roughness_layers.set_layer_data(temp_image, 3)
	
	# Build metalness brush texture, transparent means empty
	tex_metalness_brush = ImageTexture.new()
	temp_image.fill(Color(0,0,0,0))
	tex_metalness_brush.create_from_image(temp_image)
	tex_metalness_brush.resource_name = "Metalness brush texture"
	# Build metalness color texture, default to no metalness
	tex_metalness_color = ImageTexture.new()
	temp_image.fill(Color(0,0,0,1))
	tex_metalness_color.create_from_image(temp_image)
	tex_metalness_color.resource_name = "Metalness color texture"
	# Build metalness array
	tex_metalness_layers = TextureArray.new()
	tex_metalness_layers.create(512, 512, 4, Image.FORMAT_RGBAH)
	temp_image.fill(Color(0,0,0,0))
	tex_metalness_layers.set_layer_data(temp_image, 0)
	tex_metalness_layers.set_layer_data(temp_image, 1)
	tex_metalness_layers.set_layer_data(temp_image, 2)
	tex_metalness_layers.set_layer_data(temp_image, 3)
	
	# Build emission brush texture, transparent means empty
	tex_emission_brush = ImageTexture.new()
	temp_image.fill(Color(0,0,0,0))
	tex_emission_brush.create_from_image(temp_image)
	tex_emission_brush.resource_name = "Emission brush texture"
	# Build emission color texture, default to no emission
	tex_emission_color = ImageTexture.new()
	temp_image.fill(Color(0,0,0,0))
	tex_emission_color.create_from_image(temp_image)
	tex_emission_color.resource_name = "Emission color texture"
	# Build emission array
	tex_emission_layers = TextureArray.new()
	tex_emission_layers.create(512, 512, 4, Image.FORMAT_RGBAH)
	temp_image.fill(Color(0,0,0,0))
	tex_emission_layers.set_layer_data(temp_image, 0)
	tex_emission_layers.set_layer_data(temp_image, 1)
	tex_emission_layers.set_layer_data(temp_image, 2)
	tex_emission_layers.set_layer_data(temp_image, 3)
	
	# Set new textures as parameters of PBR shader
	mat.set_shader_param("tex_albedo_brush", tex_albedo_brush)
	mat.set_shader_param("tex_albedo_color", tex_albedo_color)
	mat.set_shader_param("tex_albedo_layers", tex_albedo_layers)
	
	mat.set_shader_param("tex_roughness_brush", tex_roughness_brush)
	mat.set_shader_param("tex_roughness_color", tex_roughness_color)
	mat.set_shader_param("tex_roughness_layers", tex_roughness_layers)
	
	mat.set_shader_param("tex_metalness_brush", tex_metalness_brush)
	mat.set_shader_param("tex_metalness_color", tex_metalness_color)
	mat.set_shader_param("tex_metalness_layers", tex_metalness_layers)
	
	mat.set_shader_param("tex_emission_brush", tex_emission_brush)
	mat.set_shader_param("tex_emission_color", tex_emission_color)
	mat.set_shader_param("tex_emission_layers", tex_emission_layers)
	
	mat.set_shader_param("uv1_scale", Vector3(1,1,1))
	
	# Use material for current mesh instance
	mesh_instance.mesh.surface_set_material(0, mat)

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

func setup_tabs():
	$VBoxContainer/TabContainer/E.setup(tex_emission_layers)
	$VBoxContainer/TabContainer/M.setup(tex_metalness_layers)
	$VBoxContainer/TabContainer/G.setup(tex_roughness_layers)
	$VBoxContainer/TabContainer/A.setup(tex_albedo_layers)

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
