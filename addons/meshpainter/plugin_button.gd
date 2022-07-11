# Button to activate the painting and show the paint panel

tool
extends TextureButton

class_name PluginButton

var plugin_panel :PluginPanel

var root :Node
var mesh_instance :MeshInstance
var handle = false

# Show button in UI, untoggled
func show_button(root: Node, mesh_instance :MeshInstance):
	set_pressed_no_signal(false)
	show()
	self.root = root
	self.mesh_instance = mesh_instance
	# Prepare root and mesh_instance for when the button will be toggled

# Hide button in UI, untoggled
func hide_button():
	plugin_panel.hide_panel()
	set_pressed_no_signal(false)
	hide()

# When button toggled, show painting panel
func _on_PluginButton_toggled(button_pressed: bool) -> void:
	if button_pressed:
		plugin_panel.show_panel(root, mesh_instance)
	else:
		plugin_panel.hide_panel()
