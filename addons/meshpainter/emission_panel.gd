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
var tex_layer_0 :ImageTexture
var tex_layer_1 :ImageTexture
var tex_layer_2 :ImageTexture
var tex_layer_3 :ImageTexture
var layer_nb = 0
var layer_value = Color.black

func setup(tex_layer_0 :ImageTexture, tex_layer_1 :ImageTexture, tex_layer_2 :ImageTexture, tex_layer_3 :ImageTexture):
	self.tex_layer_0 = tex_layer_0
	self.tex_layer_1 = tex_layer_1
	self.tex_layer_2 = tex_layer_2
	self.tex_layer_3 = tex_layer_3
	_on_BrushButton_pressed()
	$VBoxContainer/ColorContainer/LayerButton4.set_value(tex_layer_3)
	$VBoxContainer/ColorContainer/LayerButton3.set_value(tex_layer_2)
	$VBoxContainer/ColorContainer/LayerButton2.set_value(tex_layer_1)
	$VBoxContainer/ColorContainer/LayerButton.set_value(tex_layer_0)
	$VBoxContainer/ColorContainer/LayerButton.select()

# When brush button pressed, show brush panel
func _on_BrushButton_pressed() -> void:
	mode = Modes.BRUSH
	$VBoxContainer/Modes/BrushButton.set_pressed_no_signal(true)
	$VBoxContainer/Modes/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/EraserButton.set_pressed_no_signal(false)
	
	$VBoxContainer/ColorContainer.show()
	$VBoxContainer/IntensityContainer.show()
	$VBoxContainer/SizeContainer.show()
	
	update_brush()

# When bucket button pressed, show bucket panel
func _on_BucketButton_pressed() -> void:
	mode = Modes.BUCKET
	
	$VBoxContainer/Modes/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/BucketButton.set_pressed_no_signal(true)
	$VBoxContainer/Modes/EraserButton.set_pressed_no_signal(false)
	
	$VBoxContainer/ColorContainer.show()
	$VBoxContainer/IntensityContainer.show()
	$VBoxContainer/SizeContainer.hide()
	
	update_brush()

# When eraser button pressed, show eraser panel
func _on_EraserButton_pressed() -> void:
	mode = Modes.ERASER
	
	$VBoxContainer/Modes/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/EraserButton.set_pressed_no_signal(true)
	
	$VBoxContainer/ColorContainer.hide()
	$VBoxContainer/IntensityContainer.hide()
	$VBoxContainer/SizeContainer.show()
	
	update_brush()


func _on_LayerButton_selected(value, is_color) -> void:
	on_layer_change(value, is_color, 0)
	$VBoxContainer/ColorContainer/LayerButton2.deselect()
	$VBoxContainer/ColorContainer/LayerButton3.deselect()
	$VBoxContainer/ColorContainer/LayerButton4.deselect()
func _on_LayerButton2_selected(value, is_color) -> void:
	on_layer_change(value, is_color, 1)
	$VBoxContainer/ColorContainer/LayerButton.deselect()
	$VBoxContainer/ColorContainer/LayerButton3.deselect()
	$VBoxContainer/ColorContainer/LayerButton4.deselect()
func _on_LayerButton3_selected(value, is_color) -> void:
	on_layer_change(value, is_color, 2)
	$VBoxContainer/ColorContainer/LayerButton.deselect()
	$VBoxContainer/ColorContainer/LayerButton2.deselect()
	$VBoxContainer/ColorContainer/LayerButton4.deselect()
func _on_LayerButton4_selected(value, is_color) -> void:
	on_layer_change(value, is_color, 3)
	$VBoxContainer/ColorContainer/LayerButton.deselect()
	$VBoxContainer/ColorContainer/LayerButton2.deselect()
	$VBoxContainer/ColorContainer/LayerButton3.deselect()

func _on_LayerButton_value_changed(value, is_color) -> void:
	on_layer_change(value, is_color, 0)
func _on_LayerButton2_value_changed(value, is_color) -> void:
	on_layer_change(value, is_color, 1)
func _on_LayerButton3_value_changed(value, is_color) -> void:
	on_layer_change(value, is_color, 2)
func _on_LayerButton4_value_changed(value, is_color) -> void:
	on_layer_change(value, is_color, 3)


func on_layer_change(value, is_color, layer_idx):
	layer_nb = layer_idx
	layer_value = value
	if not is_color:
		match layer_idx:
			0:
				tex_layer_0.set_data(value.get_data())
			1:
				tex_layer_1.set_data(value.get_data())
			2:
				tex_layer_2.set_data(value.get_data())
			3:
				tex_layer_3.set_data(value.get_data())
	update_brush()

func _on_IntensitySlider_value_changed(value: float) -> void:
	update_brush()

func _on_SizeSlider_value_changed(value: float) -> void:
	update_brush()



func get_mode():
	return mode

func get_layer_nb():
	return layer_nb

func get_layer_value():
	return layer_value

func get_intensity():
	return $VBoxContainer/IntensityContainer/IntensitySlider.value

func get_size():
	return $VBoxContainer/SizeContainer/SizeSlider.value

func update_brush():
	var mode = get_mode()
	var layer_nb = get_layer_nb()
	var layer_value = get_layer_value()
	var intensity = get_intensity()
	var size = get_size()
	
	match mode:
		Modes.BRUSH:
			if layer_value is Color:
				brush_color = layer_value
				brush_opacity = intensity
				brush_size = size
			else:
				brush_color = Color(layer_nb, intensity, 0, 0)
				brush_opacity = 0.0
				brush_size = size
		Modes.BUCKET:
			if layer_value is Color:
				brush_color = layer_value
				brush_opacity = intensity
				brush_size = 1.0
			else:
				brush_color = Color(layer_nb, intensity, 0, 0)
				brush_opacity = 0.0
				brush_size = 1.0
		Modes.ERASER:
			brush_color = Color.white
			brush_opacity = 0.0
			brush_size = size
	
	emit_signal("values_changed", brush_color, brush_opacity, brush_size)
