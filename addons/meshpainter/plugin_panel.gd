tool
extends Control

class_name PluginPanel

enum TabMode {ALBEDO, ROUGHNESS, METALNESS, EMISSION}

var plugin_cursor :PluginCursor

var root :Node
var mesh_instance :MeshInstance

var tab_mode = TabMode.ALBEDO
var temp_plugin_node :Spatial
var temp_collision :CollisionShape
var temp_body :StaticBody

var tex_albedo_brush :ImageTexture
var tex_albedo_color :ImageTexture
var tex_roughness_brush :ImageTexture
var tex_roughness_color :ImageTexture
var tex_metalness_brush :ImageTexture
var tex_metalness_color :ImageTexture
var tex_emission_brush :ImageTexture
var tex_emission_color :ImageTexture

var pbr_shader :Shader = preload("res://addons/meshpainter/materials/pbr_shader.shader")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func show_panel(root :Node, mesh_instance :MeshInstance):
	show()
	self.root = root
	self.mesh_instance = mesh_instance
	if mesh_instance.mesh:
		generate_collision()
		setup_material()
		$VBoxContainer/TabContainer/A.show()
		_on_TabContainer_tab_selected(0)

func setup_material():
	var existing_material :Material = mesh_instance.mesh.surface_get_material(0)
	if existing_material:
		if existing_material is ShaderMaterial:
			if existing_material.shader == pbr_shader:
				tex_albedo_brush = existing_material.get_shader_param("tex_albedo_brush")
				tex_albedo_color = existing_material.get_shader_param("tex_albedo_color")
				tex_roughness_brush = existing_material.get_shader_param("tex_roughness_brush")
				tex_roughness_color = existing_material.get_shader_param("tex_roughness_color")
				tex_metalness_brush = existing_material.get_shader_param("tex_metalness_brush")
				tex_metalness_color = existing_material.get_shader_param("tex_metalness_color")
				tex_emission_brush = existing_material.get_shader_param("tex_emission_brush")
				tex_emission_color = existing_material.get_shader_param("tex_emission_color")
				return
	
	var mat = ShaderMaterial.new()
	mat.shader = pbr_shader
	
	var temp_image = Image.new()
	temp_image.create(512,512,false,Image.FORMAT_RGBAH)
	
	# Build albedo brush texture
	tex_albedo_brush = ImageTexture.new()
	temp_image.fill(Color(0,0,0,0))
	tex_albedo_brush.create_from_image(temp_image)
	tex_albedo_brush.resource_name = "Albedo brush texture"
	# Build albedo color texture
	tex_albedo_color = ImageTexture.new()
	temp_image.fill(Color(1,1,1,1))
	tex_albedo_color.create_from_image(temp_image)
	tex_albedo_color.resource_name = "Albedo color texture"
	
	# Build roughness brush texture
	tex_roughness_brush = ImageTexture.new()
	temp_image.fill(Color(0,0,0,0))
	tex_roughness_brush.create_from_image(temp_image)
	tex_roughness_brush.resource_name = "Roughness brush texture"
	# Build roughness color texture
	tex_roughness_color = ImageTexture.new()
	temp_image.fill(Color(1,1,1,1))
	tex_roughness_color.create_from_image(temp_image)
	tex_roughness_color.resource_name = "Roughness color texture"
	
	# Build metalness brush texture
	tex_metalness_brush = ImageTexture.new()
	temp_image.fill(Color(0,0,0,0))
	tex_metalness_brush.create_from_image(temp_image)
	tex_metalness_brush.resource_name = "Metalness brush texture"
	# Build metalness color texture
	tex_metalness_color = ImageTexture.new()
	temp_image.fill(Color(1,1,1,1))
	tex_metalness_color.create_from_image(temp_image)
	tex_metalness_color.resource_name = "Metalness color texture"
	
	# Build emission brush texture
	tex_emission_brush = ImageTexture.new()
	temp_image.fill(Color(0,0,0,0))
	tex_emission_brush.create_from_image(temp_image)
	tex_emission_brush.resource_name = "Emission brush texture"
	# Build albedo color texture
	tex_emission_color = ImageTexture.new()
	temp_image.fill(Color(1,1,1,1))
	tex_emission_color.create_from_image(temp_image)
	tex_emission_color.resource_name = "Emission color texture"
	
	mat.set_shader_param("tex_albedo_brush", tex_albedo_brush)
	mat.set_shader_param("tex_albedo_color", tex_albedo_color)
	mat.set_shader_param("tex_roughness_brush", tex_roughness_brush)
	mat.set_shader_param("tex_roughness_color", tex_roughness_color)
	mat.set_shader_param("tex_metalness_brush", tex_metalness_brush)
	mat.set_shader_param("tex_metalness_color", tex_metalness_color)
	mat.set_shader_param("tex_emission_brush", tex_emission_brush)
	mat.set_shader_param("tex_emission_color", tex_emission_color)
	
	mat.set_shader_param("uv1_scale", Vector3(1,1,1))
	
	mesh_instance.mesh.surface_set_material(0, mat)

func generate_collision():
	temp_collision = CollisionShape.new()
	temp_collision.set_shape(mesh_instance.mesh.create_trimesh_shape())
	temp_collision.hide()
	temp_body = StaticBody.new()
	temp_body.add_child(temp_collision)
	temp_body.collision_layer = 32
	temp_plugin_node = Spatial.new()
	temp_plugin_node.name = "MeshPainter"
	temp_plugin_node.add_child(temp_body)
	
	mesh_instance.add_child(temp_plugin_node)
	temp_collision.owner = root
	temp_body.owner = root
	temp_plugin_node.owner = root

func hide_panel():
	if mesh_instance:
		if temp_plugin_node:
			mesh_instance.remove_child(temp_plugin_node)
		mesh_instance = null
	
	if plugin_cursor:
		plugin_cursor.hide_cursor()
	hide()

func set_mesh_instance(mesh_instance :MeshInstance):
	if mesh_instance:
		if mesh_instance.mesh:
			temp_collision = CollisionShape.new()
			temp_collision.set_shape(mesh_instance.mesh.create_trimesh_shape())
			temp_body = StaticBody.new()
			temp_body.add_child(temp_collision)
			mesh_instance.add_child(temp_body)
			self.mesh_instance = mesh_instance

func _on_TabContainer_tab_selected(tab: int) -> void:
	var tab_name = "A"
	tab_mode = tab
	match tab_mode:
		TabMode.ALBEDO:
			tab_name = "A"
			plugin_cursor.show_cursor(root, mesh_instance, temp_plugin_node, tex_albedo_brush, tex_albedo_color)
		TabMode.ROUGHNESS:
			tab_name = "R"
			plugin_cursor.show_cursor(root, mesh_instance, temp_plugin_node, tex_roughness_brush, tex_roughness_color)
		TabMode.METALNESS:
			tab_name = "M"
			plugin_cursor.show_cursor(root, mesh_instance, temp_plugin_node, tex_metalness_brush, tex_metalness_color)
		TabMode.EMISSION:
			tab_name = "E"
			plugin_cursor.show_cursor(root, mesh_instance, temp_plugin_node, tex_emission_brush, tex_emission_color)

func _on_Albedo_values_changed(brush_color, brush_opacity, brush_size) -> void:
	plugin_cursor.set_brush_color(brush_color)
	plugin_cursor.set_brush_opacity(brush_opacity)
	plugin_cursor.set_brush_size(brush_size)

func _on_Roughness_values_changed(brush_color, brush_opacity, brush_size) -> void:
	plugin_cursor.set_brush_color(brush_color)
	plugin_cursor.set_brush_opacity(brush_opacity)
	plugin_cursor.set_brush_size(brush_size)
