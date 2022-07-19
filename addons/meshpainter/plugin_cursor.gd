# Cursor that will paint on textures, based on mesh surface position and brush info (color, opacity, size)

tool
extends Spatial

class_name PluginCursor

var root :Node
var mesh_instance :MeshInstance
var temp_plugin_node :Spatial

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

# Show cursor and setup textures to paint
func show_cursor(root :Node, mesh_instance :MeshInstance, temp_plugin_node :Spatial, tex_brush :ImageTexture, tex_color :ImageTexture):
	show()
	
	self.root = root
	self.mesh_instance = mesh_instance
	self.temp_plugin_node = temp_plugin_node
	self.tex_brush = tex_brush
	self.tex_color = tex_color
	
	# Retrieve buffers from current textures, buffers are easier to manipulate
	textures_to_buffers()
	
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
	
	var brush_image = tex_brush.get_data()
	var color_image = tex_color.get_data()
	brush_image.decompress()
	color_image.decompress()
	
	brush_image.lock()
	color_image.lock()
	
	# Build buffers one row at a time
	var is_done = false
	for y in range(0, brush_image.get_height()):
		if is_done:
			break
		for x in range(0, brush_image.get_width()):
			var brush_info = brush_image.get_pixel(x, y)
			if brush_info.a == 0.0:
				# Brush color alpha means we reached the end of brush info
				is_done = true
				break
			else:
				brush_buffer.append(brush_info)
				color_buffer.append(color_image.get_pixel(x, y))
	
	brush_image.unlock()
	color_image.unlock()

# Use buffers to update current textures
func buffers_to_textures():
	var brush_image = tex_brush.get_data()
	var color_image = tex_color.get_data()
	brush_image.decompress()
	color_image.decompress()
	
	# Clear textures first
	brush_image.fill(Color(0,0,0,0))
	color_image.fill(Color(1,1,1,1))
	
	brush_image.lock()
	color_image.lock()
	
	var width = brush_image.get_width()
	var height = brush_image.get_height()
	
	# Color pixels row by row
	# Indexes example: [0,1,2,3,4], [5,6,7,8,9]...
	for i in range(0, brush_buffer.size()):
		var x = i % width
		var y = i / width
		brush_image.set_pixel(x, y, brush_buffer[i])
		color_image.set_pixel(x, y, color_buffer[i])
	
	brush_image.unlock()
	color_image.unlock()
	
	tex_brush.set_data(brush_image)
	tex_color.set_data(color_image)

# Where we paint with mouse
func input(camera :Camera, event: InputEvent) -> bool:
	var captured_event = false
	
	if event is InputEventMouseMotion:
		# Cast a ray to find position on mesh where we point
		var ray_origin = camera.project_ray_origin(event.position)
		var ray_dir = camera.project_ray_normal(event.position)
		var ray_distance = camera.far
		
		var space_state =  camera.get_world().direct_space_state
		var hit = space_state.intersect_ray(ray_origin, ray_origin + ray_dir * ray_distance, [], 32)
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
		if event.button_index == BUTTON_LEFT and visible:
			# We start painting
			painting = event.pressed
			captured_event = true
	
	# Return tells editor if we caputre mouse events or not
	return captured_event

# Show the cursor where we are pointing on mesh
func display_brush_at(pos = null, normal = null) -> void:
	if pos:
		$Cursor.visible = true
		$Cursor.global_transform.origin = pos
		$CursorMiddle.visible = true
		$CursorMiddle.global_transform.origin = pos
	else:
		$Cursor.visible = false
		$CursorMiddle.visible = false
