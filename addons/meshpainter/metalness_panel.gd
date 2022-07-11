# Panel with parameters to paint metalness brush and color textures
# Brush color is used for metalness intensity
# Brush size is used for size

tool
extends PanelContainer

# Signal sent when parameters are changed
signal values_changed(brush_color, brush_opacity, brush_size)

var brush_color :Color
var brush_size :float
var brush_opacity :float

# When showing panel, use brush mode
func show():
	.show()
	_on_BrushButton_pressed()

# When brush button pressed, show brush panel
func _on_BrushButton_pressed() -> void:
	$VBoxContainer/HBoxContainer/BrushButton.set_pressed_no_signal(true)
	$VBoxContainer/HBoxContainer/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/EraserButton.set_pressed_no_signal(false)
	show_brush_panel()

# When bucket button pressed, show bucket panel
func _on_BucketButton_pressed() -> void:
	$VBoxContainer/HBoxContainer/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/BucketButton.set_pressed_no_signal(true)
	$VBoxContainer/HBoxContainer/EraserButton.set_pressed_no_signal(false)
	show_bucket_panel()

# When eraser button pressed, show eraser panel
func _on_EraserButton_pressed() -> void:
	$VBoxContainer/HBoxContainer/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/EraserButton.set_pressed_no_signal(true)
	show_eraser_panel()


# Brush panel shows and sets default brush values (max metalness, small size)
func show_brush_panel():
	$VBoxContainer/BrushPanel.show()
	$VBoxContainer/BucketPanel.hide()
	$VBoxContainer/EraserPanel.hide()
	$VBoxContainer/BrushPanel/VBoxContainer2/ValueSlider.value = 1.0
	$VBoxContainer/BrushPanel/VBoxContainer3/SizeSlider.value = 0.1
	_on_Brush_ValueSlider_value_changed(1.0)
	_on_Brush_SizeSlider_value_changed(0.1)

# Bucket panel shows and sets default bucket values (small size)
func show_bucket_panel():
	$VBoxContainer/BrushPanel.hide()
	$VBoxContainer/BucketPanel.show()
	$VBoxContainer/EraserPanel.hide()
	
	$VBoxContainer/BucketPanel/VBoxContainer2/ValueSlider.value = 1.0
	_on_Bucket_ValueSlider_value_changed(1.0)

# Eraser panel shows and sets default eraser values (small size)
func show_eraser_panel():
	$VBoxContainer/BrushPanel.hide()
	$VBoxContainer/BucketPanel.hide()
	$VBoxContainer/EraserPanel.show()
	
	$VBoxContainer/EraserPanel/VBoxContainer3/SizeSlider.value = 0.1
	_on_Eraser_SizeSlider_value_changed(0.1)


# Brush UI events
func _on_Brush_ValueSlider_value_changed(value: float) -> void:
	brush_color = Color(value, value, value, 1.0)
	brush_opacity = 1.0
	on_Brush_values_changed()
func _on_Brush_SizeSlider_value_changed(size: float) -> void:
	brush_size = size/100
	on_Brush_values_changed()

# Bucket UI events
func _on_Bucket_ValueSlider_value_changed(value: float) -> void:
	brush_color = Color(value, value, value, 1.0)
	# Size at max for bucket fill (becomes 100 meters in shader)
	brush_size = 1.0
	brush_opacity = 1.0
	on_Brush_values_changed()

# Eraser UI events
func _on_Eraser_SizeSlider_value_changed(size: float) -> void:
	# Use black on top as a way to "erase"
	brush_color = Color(0.0, 0.0, 0.0, 1.0)
	brush_size = size/100
	brush_opacity = 1.0
	on_Brush_values_changed()

# Signaling new parameters
func on_Brush_values_changed():
	emit_signal("values_changed", brush_color, brush_opacity, brush_size)
