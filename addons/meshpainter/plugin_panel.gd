tool
extends Control

class_name PluginPanel

enum SelectionMode {BRUSH, BUCKET, ERASER}

var plugin_cursor :PluginCursor

var root :Node
var mesh_instance :MeshInstance

var selected_mode = SelectionMode.BRUSH
var temp_plugin_node :Spatial
var temp_collision :CollisionShape
var temp_body :StaticBody

var current_material :ShaderMaterial
var texture_brush_info :ImageTexture
var texture_albedo_info :ImageTexture
var texture_mrae_info :ImageTexture

var pbr_shader :Shader = preload("res://addons/meshpainter/materials/pbr_shader.shader")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_BrushButton_pressed()

func show_panel(root :Node, mesh_instance :MeshInstance):
	show()
	self.root = root
	self.mesh_instance = mesh_instance
	if mesh_instance.mesh:
		generate_collision()
		setup_material()
		plugin_cursor.show_cursor(root, mesh_instance, temp_plugin_node, current_material, texture_brush_info, texture_albedo_info)
		_on_ColorPickerButton_color_changed(Color.cornflower)
		_on_OpacitySlider_value_changed(1.0)
		_on_SizeSlider_value_changed(0.1)

func setup_material():
	mesh_instance.mesh.surface_set_material(0, null)
	
	var mat = ShaderMaterial.new()
	mat.shader = pbr_shader
	
	var temp_image = Image.new()
	temp_image.create(512,512,false,Image.FORMAT_RGBAH)
	
	# Build brush info texture
	texture_brush_info = ImageTexture.new()
	temp_image.fill(Color(0,0,0,0))
	texture_brush_info.create_from_image(temp_image)
	texture_brush_info.resource_name = "Brush info texture"
	
	# Build albedo info texture
	texture_albedo_info = ImageTexture.new()
	temp_image.fill(Color(1,1,1,1))
	texture_albedo_info.create_from_image(temp_image)
	texture_albedo_info.resource_name = "Albedo info texture"
	
	# Build mrae info texture
	texture_mrae_info = ImageTexture.new()
	temp_image.fill(Color(0,1,0,0))
	texture_mrae_info.create_from_image(temp_image)
	texture_mrae_info.resource_name = "MRAE info texture"
	
	mat.set_shader_param("texture_brush_info", texture_brush_info)
	mat.set_shader_param("texture_albedo_info", texture_albedo_info)
	mat.set_shader_param("texture_mrae_info", texture_mrae_info)
	
	mat.set_shader_param("uv1_scale", Vector3(1,1,1))
	
	mesh_instance.mesh.surface_set_material(0, mat)

func generate_collision():
	temp_collision = CollisionShape.new()
	temp_collision.set_shape(mesh_instance.mesh.create_trimesh_shape())
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


func _on_BrushButton_pressed() -> void:
	selected_mode = SelectionMode.BRUSH
	$VBoxContainer/HBoxContainer/BrushButton.set_pressed_no_signal(true)
	$VBoxContainer/HBoxContainer/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/EraserButton.set_pressed_no_signal(false)


func _on_BucketButton_pressed() -> void:
	selected_mode = SelectionMode.BUCKET
	$VBoxContainer/HBoxContainer/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/BucketButton.set_pressed_no_signal(true)
	$VBoxContainer/HBoxContainer/EraserButton.set_pressed_no_signal(false)


func _on_EraserButton_pressed() -> void:
	selected_mode = SelectionMode.ERASER
	$VBoxContainer/HBoxContainer/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/EraserButton.set_pressed_no_signal(true)

func _on_ColorPickerButton_color_changed(color: Color) -> void:
	plugin_cursor.set_brush_color(color)

func _on_OpacitySlider_value_changed(alpha: float) -> void:
	plugin_cursor.set_brush_opacity(alpha)

func _on_SizeSlider_value_changed(size: float) -> void:
	plugin_cursor.set_brush_size(size)
