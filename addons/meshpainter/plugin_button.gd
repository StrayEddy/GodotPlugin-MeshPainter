tool
extends TextureButton

class_name PluginButton

var plugin_panel :PluginPanel

var root :Node
var mesh_instance :MeshInstance
var handle = false

func show_button(root: Node, mesh_instance :MeshInstance):
	set_pressed_no_signal(false)
	show()
	self.root = root
	self.mesh_instance = mesh_instance

func hide_button():
	plugin_panel.hide_panel()
	set_pressed_no_signal(false)
	hide()

func _on_PluginButton_toggled(button_pressed: bool) -> void:
	if button_pressed:
		plugin_panel.show_panel(root, mesh_instance)
	else:
		plugin_panel.hide_panel()
