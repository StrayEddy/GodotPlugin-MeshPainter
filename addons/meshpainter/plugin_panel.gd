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
var current_texture :ImageTexture

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
		setup_materials_list()
		select_material(0)
		plugin_cursor.show_cursor(root, mesh_instance, temp_plugin_node, current_material, current_texture)

func setup_materials_list():
	for i in mesh_instance.mesh.get_surface_count():
		var material = mesh_instance.mesh.surface_set_material(i, null)
		add_material(i)
		$VBoxContainer/MaterialsList.clear()
		$VBoxContainer/MaterialsList.add_item("Material " + str(i))

func add_material(idx):
	var mat = ShaderMaterial.new()
	mat.shader = pbr_shader
	
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()
	dynImage.create(1024,1024,false,Image.FORMAT_RGB8)
	dynImage.fill(Color(1,1,1,1))
	imageTexture.create_from_image(dynImage)
	imageTexture.resource_name = "Basic white texture"
	
	mat.set_shader_param("texture_albedo", imageTexture)
	mat.set_shader_param("albedo", Color(1,1,1,1))
	mat.set_shader_param("roughness", 1.0)
	mat.set_shader_param("uv1_scale", Vector3(1,1,1))
	mat.set_shader_param("uv2_scale", Vector3(1,1,1))
	mesh_instance.mesh.surface_set_material(idx, mat)
	
	current_texture = imageTexture

func select_material(idx :int):
	$VBoxContainer/MaterialsList.select(idx)
	current_material = mesh_instance.mesh.surface_get_material(idx)

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

func _on_MaterialsList_item_selected(index: int) -> void:
	var mat: SpatialMaterial = mesh_instance.mesh.surface_get_material(index)
	current_texture = mat.albedo_texture
