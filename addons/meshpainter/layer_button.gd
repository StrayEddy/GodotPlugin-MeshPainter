tool
extends TextureButton

signal value_changed(value, is_color)
signal selected(value, is_color)

var value = Color.black

func select():
	var event = InputEventMouseButton.new()
	event.button_mask = BUTTON_LEFT
	_on_LayerButton_gui_input(event)

func deselect():
	$Frame.hide()

func set_value(value):
	if value is Color:
		set_color(value)
	elif value is Image:
		value.lock()
		if value.get_pixel(0,0) == Color(0,0,0,0):
			set_color(Color.cornflower)
		else:
			var tex = ImageTexture.new()
			tex.create_from_image(value)
			set_texture(tex)
		value.unlock()
	elif value is Texture:
		set_texture(value)

func set_color(color :Color):
	self.value = color
	var gradient_tex = GradientTexture.new()
	gradient_tex.gradient = Gradient.new()
	gradient_tex.gradient.colors = [color]
	self.texture_normal = gradient_tex
	emit_signal("value_changed", value, true)

func set_texture(texture :Texture):
	self.value = texture
	self.texture_normal = texture
	emit_signal("value_changed", value, false)

func _on_ColorButton_pressed() -> void:
	$ColorDialog.popup()
	$PopupDialog.hide()

func _on_TextureButton_pressed() -> void:
	$TextureDialog.popup()
	$PopupDialog.hide()

func _on_ColorDialog_confirmed() -> void:
	var color = $ColorDialog/ColorPicker.color
	set_value(color)
	
	$Frame.show()
	emit_signal("selected", value, value is Color)

func _on_TextureDialog_file_selected(path: String) -> void:
	var image = Image.new()
	image.load(path)
	if image.get_format() != Image.FORMAT_RGBAH:
		image.convert(Image.FORMAT_RGBAH)
	if image.get_size() != Vector2(512, 512):
		image.resize(512, 512)
	var tex = ImageTexture.new()
	tex.create_from_image(image)
	set_value(tex)
	
	$Frame.show()
	emit_signal("selected", value, value is Color)

func _on_LayerButton_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_mask == BUTTON_LEFT:
			$Frame.show()
			emit_signal("selected", value, value is Color)
		if event.button_mask == BUTTON_RIGHT:
			$PopupDialog.popup()
