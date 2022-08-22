# Cursor that will paint on textures, based on mesh surface position and brush info (color, opacity, size)

@tool
extends Node3D

class_name PluginCursor

var root :Node
var mesh_instance :MeshInstance3D
var temp_plugin_node :Node3D

var brush_color :Color
var brush_size :float
# Painting tells if mouse is painting right now or not
var painting = false

# Buffers will contain the brush and color information
var brush_buffer :Array
var color_buffer :Array
# Textures will contain the texture version of buffers to pass it to PBR shader
var tex_brush :ImageTexture
var tex_color :ImageTexture

# history undo-redo management
var history_manager :HistoryManager

# Show cursor and setup textures to paint
func show_cursor(root :Node, mesh_instance :MeshInstance3D, temp_plugin_node :Node3D, tex_brush :ImageTexture, tex_color :ImageTexture):
	show()
	
	self.root = root
	self.mesh_instance = mesh_instance
	self.temp_plugin_node = temp_plugin_node
	self.tex_brush = tex_brush
	self.tex_color = tex_color
	
	history_manager = HistoryManager.new()
	
	# Retrieve buffers from current textures, buffers are easier to manipulate
	textures_to_buffers()
	history_manager.add_history(brush_buffer, color_buffer)
	
	# Add cursor to tree under the temporary plugin node
	var cursor_absent = true
	for child in temp_plugin_node.get_children():
		if child == self:
			cursor_absent = false
			break
	
	if cursor_absent:
		temp_plugin_node.add_child(self)
		self.owner = root

# Hide cursor and remove it from the tree
func hide_cursor():
	painting = false
	if temp_plugin_node:
		# Add cursor to tree under the temporary plugin node
		var cursor_present = false
		for child in temp_plugin_node.get_children():
			if child == self:
				cursor_present = true
				break
		if cursor_present:
			temp_plugin_node.remove_child(self)
	hide()

# Set brush rgb
func set_brush_color(color :Color):
	brush_color.r = color.r
	brush_color.g = color.g
	brush_color.b = color.b

# Set brush alpha
func set_brush_opacity(alpha: float):
	brush_color.a = alpha

# Set brush size
# Brush size param is very small, scale cursor mesh to fit new real size
func set_brush_size(size :float):
	brush_size = size
	if size == 1.0:
		size *= 100
	$Cursor.scale = Vector3(1.0, 1.0, 1.0) * size

# Take current textures and create the associated buffers (brush and color info)
func textures_to_buffers():
	brush_buffer = []
	color_buffer = []
	
	var brush_image = tex_brush.get_image()
	var color_image = tex_color.get_image()
	
	# Build buffers one row at a time
	var is_done = false
	for x in range(0, brush_image.get_width()):
		var brush_info = brush_image.get_pixel(x, 0)
		if brush_info.a == 0.0:
			# Brush color alpha means we reached the end of brush info
			is_done = true
			break
		else:
			brush_buffer.append(brush_info)
			color_buffer.append(color_image.get_pixel(x, 0))

# Use buffers to update current textures
func buffers_to_textures():
	var brush_image = tex_brush.get_image()
	var color_image = tex_color.get_image()
	
	# Clear textures first
	brush_image.fill(Color(0,0,0,0))
	color_image.fill(Color(1,1,1,1))
	
	var width = brush_image.get_width()
	var height = brush_image.get_height()
	
	for x in range(0, brush_buffer.size()):
		brush_image.set_pixel(x, 0, brush_buffer[x])
		color_image.set_pixel(x, 0, color_buffer[x])
	
	tex_brush.set_image(brush_image)
	tex_color.set_image(color_image)

# Where we paint with mouse
func input(camera :Camera3D, event: InputEvent) -> bool:
	var captured_event = false
	
	if event is InputEventMouseMotion:
		# Cast a ray to find position on mesh where we point
		var ray_origin = camera.project_ray_origin(event.position)
		var ray_dir = camera.project_ray_normal(event.position)
		var ray_distance = camera.far
		
		var space_state =  camera.get_world_3d().direct_space_state
		var ray_params :PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
		ray_params.from = ray_origin
		ray_params.to =  ray_origin + ray_dir * ray_distance
		var hit = space_state.intersect_ray(ray_params)
		if hit:
			# Mouse is over mesh, we get surface position and place the cursor there
			display_brush_at(hit.position, hit.normal)
			if painting:
				# Prepare brush and color info
				var local_pos = mesh_instance.to_local(hit.position)
				var brush_info = Color(local_pos.x, local_pos.y, local_pos.z, brush_size)
				var color_info = brush_color
				
				# In case we use bucket fill with max opacity, all past edits don't matter
				# Clear the buffers, to prevent them from getting too big over time
				if brush_size == 1.0 and brush_color.a == 1.0:
					brush_buffer = []
					color_buffer = []
				
				# Append brush and color info to the buffers
				brush_buffer.append(brush_info)
				color_buffer.append(color_info)
				
				# Update textures with new buffer info
				buffers_to_textures()
				
				# Let editor know we want to capture mouse events
				captured_event = true
		else:
			# Don't show the cursor
			display_brush_at()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and visible:
			# We start painting
			painting = event.pressed
			captured_event = true
			if not painting:
				history_manager.add_history(brush_buffer, color_buffer)
	
	# Return tells editor if we caputre mouse events or not
	return captured_event

# Show the cursor where we are pointing on mesh
func display_brush_at(pos = null, normal = null) -> void:
	if pos and self.owner:
		$Cursor.visible = true
		$Cursor.global_transform.origin = pos
		$CursorMiddle.visible = true
		$CursorMiddle.global_transform.origin = pos
	else:
		$Cursor.visible = false
		$CursorMiddle.visible = false

func undo():
	history_manager.undo()
	brush_buffer = history_manager.get_brush_buffer()
	color_buffer = history_manager.get_color_buffer()
	buffers_to_textures()

func redo():
	history_manager.redo()
	brush_buffer = history_manager.get_brush_buffer()
	color_buffer = history_manager.get_color_buffer()
	buffers_to_textures()
