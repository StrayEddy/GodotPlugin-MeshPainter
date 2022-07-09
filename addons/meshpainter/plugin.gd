tool
extends EditorPlugin

var plugin_panel :PluginPanel
var plugin_button :PluginButton
var plugin_cursor :PluginCursor
var editable = false

func selection_changed() -> void:
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	if selection.size() == 1 and selection[0] is MeshInstance:
		var root = get_tree().get_edited_scene_root()
		var mesh_instance = selection[0]
		editable = true
		plugin_button.show_button(root, mesh_instance)
		plugin_panel.hide_panel()
		plugin_cursor.hide_cursor()
	else:
		editable = false
		plugin_button.hide_button()

func handles(obj) -> bool:
	return editable

func forward_spatial_gui_input(camera, event) -> bool:
	return plugin_cursor.input(camera, event)

func _enter_tree():
	plugin_cursor = preload("res://addons/meshpainter/plugin_cursor.tscn").instance()
	plugin_cursor.hide()
	
	plugin_panel = preload("res://addons/meshpainter/plugin_panel.tscn").instance()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, plugin_panel)
	plugin_panel.hide()
	plugin_panel.plugin_cursor = plugin_cursor
	
	plugin_button = preload("res://addons/meshpainter/plugin_button.tscn").instance()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, plugin_button)
	plugin_button.hide()
	plugin_button.plugin_panel = plugin_panel
	
	get_editor_interface().get_selection().connect("selection_changed", self, "selection_changed")
	

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, plugin_button)
	if plugin_button:
		plugin_button.free()
		
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, plugin_panel)
	if plugin_panel:
		plugin_panel.free()
