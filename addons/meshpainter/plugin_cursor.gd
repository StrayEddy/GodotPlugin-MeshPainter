tool
extends Spatial

class_name PluginCursor

var root :Node
var mesh_instance :MeshInstance
var temp_plugin_node :Spatial

var brush_color :Color
var brush_size :float
var clicking = false

var brush_buffer :Array
var color_buffer :Array
var tex_brush :ImageTexture
var tex_color :ImageTexture

func show_cursor(root :Node, mesh_instance :MeshInstance, temp_plugin_node :Spatial, tex_brush :ImageTexture, tex_color :ImageTexture):
	show()
	
	self.root = root
	self.mesh_instance = mesh_instance
	self.temp_plugin_node = temp_plugin_node
	self.tex_brush = tex_brush
	self.tex_color = tex_color
	
	textures_to_buffers()
	
	temp_plugin_node.add_child(self)
	self.owner = root

func hide_cursor():
	clicking = false
	if temp_plugin_node:
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
	color_buffer = []
	
	var brush_image = tex_brush.get_data()
	var color_image = tex_color.get_data()
	
	brush_image.lock()
	color_image.lock()
	
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
				color_buffer.append(color_image.get_pixel(x, y))
	
	brush_image.unlock()
	color_image.unlock()

func buffers_to_textures():
	var brush_image = tex_brush.get_data()
	var color_image = tex_color.get_data()
	brush_image.fill(Color(0,0,0,0))
	color_image.fill(Color(1,1,1,1))
	brush_image.lock()
	color_image.lock()
	
	var width = brush_image.get_width()
	var height = brush_image.get_height()
	
	for i in range(0, brush_buffer.size()):
		var x = i % width
		var y = i / width
		brush_image.set_pixel(x, y, brush_buffer[i])
		color_image.set_pixel(x, y, color_buffer[i])
	
	brush_image.unlock()
	color_image.unlock()
	tex_brush.set_data(brush_image)
	tex_color.set_data(color_image)

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
				var color_info = brush_color
				
				if brush_size == 1.0 and brush_color.a == 1.0:
					brush_buffer = []
					color_buffer = []
				
				brush_buffer.append(brush_info)
				color_buffer.append(color_info)
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
