tool
extends PanelContainer

signal values_changed(brush_color, brush_opacity, brush_size)

var brush_color :Color
var brush_size :float
var brush_opacity :float

func _ready() -> void:
	pass # Replace with function body.

func show():
	.show()
	_on_BrushButton_pressed()

func _on_BrushButton_pressed() -> void:
	$VBoxContainer/HBoxContainer/BrushButton.set_pressed_no_signal(true)
	$VBoxContainer/HBoxContainer/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/EraserButton.set_pressed_no_signal(false)
	show_brush_panel()

func _on_BucketButton_pressed() -> void:
	$VBoxContainer/HBoxContainer/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/BucketButton.set_pressed_no_signal(true)
	$VBoxContainer/HBoxContainer/EraserButton.set_pressed_no_signal(false)
	show_bucket_panel()

func _on_EraserButton_pressed() -> void:
	$VBoxContainer/HBoxContainer/BrushButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/BucketButton.set_pressed_no_signal(false)
	$VBoxContainer/HBoxContainer/EraserButton.set_pressed_no_signal(true)
	show_eraser_panel()


func show_brush_panel():
	$VBoxContainer/BrushPanel.show()
	$VBoxContainer/BucketPanel.hide()
	$VBoxContainer/EraserPanel.hide()
	$VBoxContainer/BrushPanel/ColorPickerButton.color = Color.cornflower
	$VBoxContainer/BrushPanel/VBoxContainer2/OpacitySlider.value = 1.0
	$VBoxContainer/BrushPanel/VBoxContainer3/SizeSlider.value = 0.1
	_on_Brush_ColorPickerButton_color_changed(Color.cornflower)
	_on_Brush_OpacitySlider_value_changed(1.0)
	_on_Brush_SizeSlider_value_changed(0.1)

func show_bucket_panel():
	$VBoxContainer/BrushPanel.hide()
	$VBoxContainer/BucketPanel.show()
	$VBoxContainer/EraserPanel.hide()
	
	$VBoxContainer/BucketPanel/ColorPickerButton.color = Color.cornflower
	$VBoxContainer/BucketPanel/VBoxContainer2/OpacitySlider.value = 1.0
	_on_Bucket_ColorPickerButton_color_changed(Color.cornflower)
	_on_Bucket_OpacitySlider_value_changed(1.0)

func show_eraser_panel():
	$VBoxContainer/BrushPanel.hide()
	$VBoxContainer/BucketPanel.hide()
	$VBoxContainer/EraserPanel.show()
	
	$VBoxContainer/EraserPanel/VBoxContainer3/SizeSlider.value = 0.1
	_on_Eraser_SizeSlider_value_changed(0.1)


# Brush UI events
func _on_Brush_ColorPickerButton_color_changed(color: Color) -> void:
	brush_color = color
	on_Brush_values_changed()
func _on_Brush_OpacitySlider_value_changed(alpha: float) -> void:
	brush_opacity = alpha
	on_Brush_values_changed()
func _on_Brush_SizeSlider_value_changed(size: float) -> void:
	brush_size = size/100
	on_Brush_values_changed()

# Bucket UI events
func _on_Bucket_ColorPickerButton_color_changed(color: Color) -> void:
	brush_color = color
	brush_size = 1.0
	on_Brush_values_changed()
func _on_Bucket_OpacitySlider_value_changed(alpha: float) -> void:
	brush_opacity = alpha
	on_Brush_values_changed()

# Eraser UI events
func _on_Eraser_SizeSlider_value_changed(size: float) -> void:
	brush_color = Color.white
	brush_size = size/100
	brush_opacity = 1.0
	on_Brush_values_changed()

func on_Brush_values_changed():
	emit_signal("values_changed", brush_color, brush_opacity, brush_size)
