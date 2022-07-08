tool
extends Spatial

class_name PluginCursor

var root :Node
var mesh_instance :MeshInstance
var temp_plugin_node :Spatial
var material :ShaderMaterial
var texture_brush_info :ImageTexture
var texture_albedo_info :ImageTexture

var brush_buffer :Array
var albedo_buffer :Array
var clicking = false

func show_cursor(root :Node, mesh_instance :MeshInstance, temp_plugin_node :Spatial, material :ShaderMaterial, texture_brush_info :ImageTexture, texture_albedo_info :ImageTexture):
	show()
	
	self.root = root
	self.mesh_instance = mesh_instance
	self.temp_plugin_node = temp_plugin_node
	self.material = material
	self.texture_brush_info = texture_brush_info
	self.texture_albedo_info = texture_albedo_info
	
	textures_to_buffers()
	
	temp_plugin_node.add_child(self)
	self.owner = root

func hide_cursor():
	clicking = false
	temp_plugin_node.remove_child(self)
	hide()

func textures_to_buffers():
	brush_buffer = []
	albedo_buffer = []
	
	var brush_image = texture_brush_info.get_data()
	var albedo_image = texture_albedo_info.get_data()
	
	brush_image.lock()
	albedo_image.lock()
	
	var is_done = false
	for x in range(0, brush_image.get_width()):
		if is_done:
			break
		for y in range(0, brush_image.get_height()):
			var brush_pixel = brush_image.get_pixel(x, y)
			if brush_pixel.a == 0.0:
				is_done = true
				break
			else:
				brush_buffer.append(brush_image)
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
				print(hit.position)
				print(local_pos)
				var brush_info = Color(local_pos.x, local_pos.y, local_pos.z, 0.1)
				var albedo_info = Color.cornflower
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
		$Cursor.transform.origin = pos
		
		if $Cursor.transform.basis.z.cross(normal) != Vector3.ZERO:
			$Cursor.transform.basis.y = normal
			$Cursor.transform.basis.x = $Cursor.transform.basis.z.cross(normal)
			$Cursor.transform.basis = $Cursor.transform.basis.orthonormalized()
		else:
			$Cursor.transform.basis.y = normal
			$Cursor.transform.basis.z = $Cursor.transform.basis.x.cross(normal)
			$Cursor.transform.basis = $Cursor.transform.basis.orthonormalized()
	else:
		$Cursor.visible = false
