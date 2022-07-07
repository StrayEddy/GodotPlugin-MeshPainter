tool
extends Spatial

class_name PluginCursor

var root :Node
var mesh_instance :MeshInstance
var temp_plugin_node :Spatial
var material :ShaderMaterial
var texture :ImageTexture

var clicking = false
var plugin_painter = PluginPainter.new()

func show_cursor(root :Node, mesh_instance :MeshInstance, temp_plugin_node :Spatial, material :ShaderMaterial, texture :ImageTexture):
	show()
	self.root = root
	self.mesh_instance = mesh_instance
	self.temp_plugin_node = temp_plugin_node
	self.material = material
	self.texture = texture
	
	
	temp_plugin_node.add_child(self)
	self.owner = root
	plugin_painter.setup(mesh_instance.mesh)

func hide_cursor():
	clicking = false
	temp_plugin_node.remove_child(self)
	hide()

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
				plugin_painter.paint_uv(texture, hit.position, hit.normal, Color.black)
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
