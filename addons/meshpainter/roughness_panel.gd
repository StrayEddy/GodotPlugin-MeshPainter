# Panel with parameters to paint albedo brush and color textures
# Brush color and opacity are used for albedo
# Brush size is used for size

tool
extends PanelContainer

# Signal sent when parameters are changed
signal values_changed(brush_color, brush_opacity, brush_size)

enum Modes {BRUSH, BUCKET, ERASER}

var mode = Modes.BRUSH
var brush_color :Color
var brush_size :float
var brush_opacity :float
var tex_layers :TextureArray
var tex_layers_idx = 0

func setup(tex_layers :TextureArray):
	self.tex_layers = tex_layers
	_on_BrushButton_pressed()
	$VBoxContainer/ColorContainer/LayerButton.set_value(tex_layers.get_layer_data(0))
	$VBoxContainer/ColorContainer/LayerButton2.set_value(tex_layers.get_layer_data(1))
	$VBoxContainer/ColorContainer/LayerButton3.set_value(tex_layers.get_layer_data(2))
	$VBoxContainer/ColorContainer/LayerButton4.set_value(tex_layers.get_layer_data(3))

# When brush button pressed, show brush panel
func _on_BrushButton_pressed() -> void:
	$VBoxContainer/Modes/BrushButton.set_pressed_no_signal(true)
	$VBoxContainer/Modes/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/EraserButton.set_pressed_no_signal(false)
	brush_mode()

# When bucket button pressed, show bucket panel
func _on_BucketButton_pressed() -> void:
	$VBoxContainer/Modes/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/BucketButton.set_pressed_no_signal(true)
	$VBoxContainer/Modes/EraserButton.set_pressed_no_signal(false)
	bucket_mode()

# When eraser button pressed, show eraser panel
func _on_EraserButton_pressed() -> void:
	$VBoxContainer/Modes/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/EraserButton.set_pressed_no_signal(true)
	eraser_mode()

# Brush panel shows and sets default brush values (corflower color, max opacity, small size)
func brush_mode():
	mode = Modes.BRUSH
	$VBoxContainer/ColorContainer.show()
	$VBoxContainer/OpacityContainer.show()
	$VBoxContainer/SizeContainer.show()
	$VBoxContainer/ColorContainer/ColorOrTexturePicker.set_color(Color.cornflower)
	$VBoxContainer/OpacityContainer/OpacitySlider.value = 1.0
	$VBoxContainer/SizeContainer/SizeSlider.value = 0.1
	_on_ColorOrTexturePicker_color_changed(Color.cornflower)
	_on_OpacitySlider_value_changed(1.0)
	_on_SizeSlider_value_changed(0.1)

# Bucket panel shows and sets default bucket values (corflower color, max opacity)
func bucket_mode():
	mode = Modes.BUCKET
	$VBoxContainer/ColorContainer.show()
	$VBoxContainer/OpacityContainer.show()
	$VBoxContainer/SizeContainer.hide()
	$VBoxContainer/ColorContainer/ColorOrTexturePicker.set_color(Color.cornflower)
	$VBoxContainer/OpacityContainer/OpacitySlider.value = 1.0
	_on_ColorOrTexturePicker_color_changed(Color.cornflower)
	_on_OpacitySlider_value_changed(1.0)

# Eraser panel shows and sets default eraser values (small size)
func eraser_mode():
	mode = Modes.ERASER
	$VBoxContainer/ColorContainer.hide()
	$VBoxContainer/OpacityContainer.hide()
	$VBoxContainer/SizeContainer.show()
	$VBoxContainer/SizeContainer/SizeSlider.value = 0.1
	_on_SizeSlider_value_changed(0.1)



func _on_LayerButton_layer_selected() -> void:
	tex_layers_idx = 0

func _on_LayerButton2_layer_selected() -> void:
	tex_layers_idx = 1

func _on_LayerButton3_layer_selected() -> void:
	tex_layers_idx = 2

func _on_LayerButton4_layer_selected() -> void:
	tex_layers_idx = 3


func _on_LayerButton_value_changed(value) -> void:
	on_layer_buttons_value_changed(value, 0)

func _on_LayerButton2_value_changed(value) -> void:
	on_layer_buttons_value_changed(value, 1)

func _on_LayerButton3_value_changed(value) -> void:
	on_layer_buttons_value_changed(value, 2)

func _on_LayerButton4_value_changed(value) -> void:
	on_layer_buttons_value_changed(value, 3)

func on_layer_buttons_value_changed(value, layer_idx):
	if value is Color:
		var image = Image.new()
		image.fill(Color(0,0,0,0))
		match mode:
			Modes.BRUSH, Modes.BUCKET:
				brush_color = value
			Modes.ERASER:
				brush_color = Color.white
		on_values_changed()
	elif value is Texture:
		tex_layers.set_layer_data(value.get_data(), layer_idx)
		match mode:
			Modes.BRUSH, Modes.BUCKET:
				brush_color = Color(layer_idx, 1.0, 0, 0)
				brush_opacity = 0.0
			Modes.ERASER:
				brush_color = Color.white
		on_values_changed()

func _on_OpacitySlider_value_changed(value: float) -> void:
	match mode:
		Modes.BRUSH, Modes.BUCKET:
			brush_opacity = value
		Modes.ERASER:
			brush_opacity = 1.0
	on_values_changed()

func _on_SizeSlider_value_changed(value: float) -> void:
	match mode:
		Modes.BRUSH, Modes.ERASER:
			brush_size = value/100
		Modes.ERASER:
			brush_size = 1.0
	on_values_changed()

# Signaling new parameters
func on_values_changed():
	emit_signal("values_changed", brush_color, brush_opacity, brush_size)
