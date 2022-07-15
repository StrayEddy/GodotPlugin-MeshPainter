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
var layer_nb = 0
var layer_value = Color.black

func setup():
	_on_BrushButton_pressed()

# When brush button pressed, show brush panel
func _on_BrushButton_pressed() -> void:
	mode = Modes.BRUSH
	$VBoxContainer/Modes/BrushButton.set_pressed_no_signal(true)
	$VBoxContainer/Modes/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/EraserButton.set_pressed_no_signal(false)
	
	$VBoxContainer/ValueContainer.show()
	$VBoxContainer/SizeContainer.show()
	
	update_brush()

# When bucket button pressed, show bucket panel
func _on_BucketButton_pressed() -> void:
	mode = Modes.BUCKET
	
	$VBoxContainer/Modes/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/BucketButton.set_pressed_no_signal(true)
	$VBoxContainer/Modes/EraserButton.set_pressed_no_signal(false)
	
	$VBoxContainer/ValueContainer.show()
	$VBoxContainer/SizeContainer.hide()
	
	update_brush()

# When eraser button pressed, show eraser panel
func _on_EraserButton_pressed() -> void:
	mode = Modes.ERASER
	
	$VBoxContainer/Modes/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/Modes/EraserButton.set_pressed_no_signal(true)
	
	$VBoxContainer/ValueContainer.hide()
	$VBoxContainer/SizeContainer.show()
	
	update_brush()

func _on_ValueSlider_value_changed(value: float) -> void:
	update_brush()

func _on_SizeSlider_value_changed(value: float) -> void:
	update_brush()


func get_mode():
	return mode

func get_value():
	return $VBoxContainer/ValueContainer/ValueSlider.value

func get_size():
	return $VBoxContainer/SizeContainer/SizeSlider.value

func update_brush():
	var mode = get_mode()
	var value = get_value()
	var size = get_size()
	
	match mode:
		Modes.BRUSH:
			brush_color = Color(value, value, value, 1.0)
			brush_opacity = 1.0
			brush_size = size/100
		Modes.BUCKET:
			brush_color = Color(value, value, value, 1.0)
			brush_opacity = 1.0
			brush_size = 1.0
		Modes.ERASER:
			brush_color = Color(1.0, 1.0, 1.0, 1.0)
			brush_opacity = 1.0
			brush_size = size/100
	
	emit_signal("values_changed", brush_color, brush_opacity, brush_size)


