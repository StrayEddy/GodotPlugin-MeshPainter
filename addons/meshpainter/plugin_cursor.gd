tool
extends Spatial

class_name PluginCursor

var root :Node
var mesh_instance :MeshInstance
var temp_plugin_node :Spatial
var texture_brush_info :ImageTexture
var texture_albedo_info :ImageTexture

var brush_color :Color
var brush_size :float
var brush_buffer :Array
var albedo_buffer :Array
var clicking = false

func show_cursor(root :Node, mesh_instance :MeshInstance, temp_plugin_node :Spatial, texture_brush_info :ImageTexture, texture_albedo_info :ImageTexture):
	show()
	
	self.root = root
	self.mesh_instance = mesh_instance
	self.temp_plugin_node = temp_plugin_node
	self.texture_brush_info = texture_brush_info
	self.texture_albedo_info = texture_albedo_info
	
	textures_to_buffers()
	
	temp_plugin_node.add_child(self)
	self.owner = root

func hide_cursor():
	clicking = false
	temp_plugin_node.remove_child(self)
	hide()

func set_brush_color(color :Color):
	brush_color.r = color.r
	brush_color.g = color.g
	brush_color.b = color.b

func set_brush_opacity(alpha: float):
	brush_color.a = alpha

func set_brush_size(size :float):
	brush_size = size
	$Cursor.scale = Vector3(1.0, 1.0, 1.0) * size * 100

func textures_to_buffers():
	brush_buffer = []
	albedo_buffer = []
	
	var brush_image = texture_brush_info.get_data()
	var albedo_image = texture_albedo_info.get_data()
	
	brush_image.lock()
	albedo_image.lock()
	
	var is_done = false
	for y in range(0, brush_image.get_height()):
		if is_done:
			break
		for x in range(0, brush_image.get_width()):
			var brush_pixel = brush_image.get_pixel(x, y)
			if brush_pixel.a == 0.0:
				is_done = true
				break
			else:
				brush_buffer.append(brush_pixel)
				albedo_buffer.append(albedo_image.get_pixel(x, y))
	
	brush_image.unlock()
	albedo_image.unlock()

func buffers_to_textures():
	var brush_image = texture_brush_info.get_data()
	var albedo_image = texture_albedo_info.get_data()
	brush_image.lock()
	albedo_image.lock()
	
	var width = brush_image.get_width()
	var height = brush_image.get_height()
	
	for i in range(0, brush_buffer.size()):
		var x = i % width
		var y = i / width
		brush_image.set_pixel(x, y, brush_buffer[i])
		albedo_image.set_pixel(x, y, albedo_buffer[i])
	
	brush_image.unlock()
	albedo_image.unlock()
	texture_brush_info.set_data(brush_image)
	texture_albedo_info.set_data(albedo_image)

func input(camera :Camera, event: InputEvent) -> bool:
	var captured_event = false
	
	if event is InputEventMouseMotion:
		var ray_origin = camera.project_ray_origin(event.position)
		var ray_dir = camera.project_ray_normal(event.position)
		var ray_distance = camera.far
		
		var space_state =  camera.get_world().direct_space_state
		var hit = space_state.intersect_ray(ray_origin, ray_origin + ray_dir * ray_distance, [], 32)
		if hit:
			display_brush_at(hit.position, hit.normal)
			if clicking:
				var local_pos = mesh_instance.to_local(hit.position)
				var brush_info = Color(local_pos.x, local_pos.y, local_pos.z, brush_size)
				var albedo_info = brush_color
				brush_buffer.append(brush_info)
				albedo_buffer.append(albedo_info)
				buffers_to_textures()
				captured_event = true
		else:
			display_brush_at()
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and visible:
			clicking = event.pressed
			captured_event = true
	
	return captured_event

func display_brush_at(pos = null, normal = null) -> void:
	if pos:
		$Cursor.visible = true
		$Cursor.global_transform.origin = pos
		$CursorMiddle.visible = true
		$CursorMiddle.global_transform.origin = pos
	else:
		$Cursor.visible = false
		$CursorMiddle.visible = false
