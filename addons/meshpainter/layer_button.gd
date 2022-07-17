tool
extends TextureButton

signal value_changed(value, is_color)
signal selected(value, is_color)

export var can_pick_color = true

var value = Color.white

func select():
	var event = InputEventMouseButton.new()
	event.button_mask = BUTTON_LEFT
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
	var gradient_tex = GradientTexture.new()
	gradient_tex.gradient = Gradient.new()
	gradient_tex.gradient.colors = [color]
	self.texture_normal = gradient_tex
	emit_signal("value_changed", value, true)

func set_texture(texture :ImageTexture):
	var image = texture.get_data()
	if image.get_format() != Image.FORMAT_RGBAH:
		image.convert(Image.FORMAT_RGBAH)
	if image.get_size() != Vector2(512, 512):
		image.resize(512, 512)
	var tex :ImageTexture = ImageTexture.new()
	tex.create_from_image(image)
	self.value = tex
	self.texture_normal = tex
	emit_signal("value_changed", value, false)

func _on_ColorButton_pressed() -> void:
	if can_pick_color:
		$PopupDialog.hide()
		$ColorDialog.popup()
		$ColorDialog.set_global_position(get_global_mouse_position())
	else:
		$PopupDialog.hide()
		$ColorDialog/ColorPicker.color = Color.white
		_on_ColorDialog_confirmed()

func _on_TextureButton_pressed() -> void:
	$PopupDialog.hide()
	$TextureDialog.popup()
	$TextureDialog.set_global_position(get_global_mouse_position())

func _on_ColorDialog_confirmed() -> void:
	var color = $ColorDialog/ColorPicker.color
	set_value(color)
	
	$Frame.show()
	emit_signal("selected", value, value is Color)

func _on_TextureDialog_file_selected(path: String) -> void:
	var image :Image = Image.new()
	image.load(path)
	var tex = ImageTexture.new()
	tex.create_from_image(image)
	self.value = tex
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
			$PopupDialog.set_global_position(get_global_mouse_position())
			$PopupDialog.set_as_minsize()
