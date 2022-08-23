@tool
extends TextureButton

signal value_changed(value, is_color)
signal selected(value, is_color)

@export var can_pick_color = true
@export var type = "albedo"
@export var layer_nb = 0
var folder = ""

const tex_size = 512
var value = Color.WHITE

func select():
	var event = InputEventMouseButton.new()
	event.button_mask = MOUSE_BUTTON_LEFT
	_on_LayerButton_gui_input(event)

func deselect():
	$Frame.hide()

func set_value(value):
	if value is Color:
		set_color(value)
	elif value is ImageTexture:
		set_texture(value)

func set_color(color :Color):
	self.value = color
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = Gradient.new()
	gradient_tex.gradient.colors = [color]
	self.texture_normal = gradient_tex
	emit_signal("value_changed", value, true)

func set_texture(texture :ImageTexture):
	var image :Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	if image.get_format() != Image.FORMAT_RGBA4444:
		image.convert(Image.FORMAT_RGBA4444)
	if image.get_size() != Vector2i(tex_size, tex_size):
		image.resize(tex_size, tex_size)
	var tex :ImageTexture = ImageTexture.create_from_image(image)
	tex.create_from_image(image)
	
	self.value = texture
	self.texture_normal = texture
	emit_signal("value_changed", value, false)

func _on_ColorButton_pressed() -> void:
	if can_pick_color:
		$PopupDialog.hide()
		$ColorDialog.popup()
		$ColorDialog.position = Vector2i(get_global_mouse_position())
	else:
		$PopupDialog.hide()
		$ColorDialog/ColorPicker.color = Color.WHITE
		_on_ColorDialog_confirmed()

func _on_TextureButton_pressed() -> void:
	$PopupDialog.hide()
	$TextureDialog.popup()
	$TextureDialog.position = Vector2i(get_global_mouse_position())

func _on_ColorDialog_confirmed() -> void:
	var color = $ColorDialog/ColorPicker.color
	set_value(color)
	
	$Frame.show()
	emit_signal("selected", value, value is Color)

func _on_TextureDialog_file_selected(path: String) -> void:
	var tex = load(path)
	self.value = tex
	set_value(tex)
	
	# Save new layer texture
	var save_path = folder + type + "_layer_" + str(layer_nb) + ".mpaint"
	ImageManager.texture_to_mpaint(tex, save_path)
	
	$Frame.show()
	emit_signal("selected", value, value is Color)

func _on_LayerButton_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_mask == MOUSE_BUTTON_LEFT:
			$Frame.show()
			emit_signal("selected", value, value is Color)
		if event.button_mask == MOUSE_BUTTON_RIGHT:
			$PopupDialog.popup()
			$PopupDialog.position = Vector2i(get_global_mouse_position())
