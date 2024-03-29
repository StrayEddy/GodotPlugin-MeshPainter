# Plugin to PBR paint a selected MeshInstance through the use of a custom PBR shader
# Main script that creates and destroys the plugin 

@tool
extends EditorPlugin

var plugin_importer :PluginImporter
var plugin_panel :PluginPanel
var plugin_button :PluginButton
var plugin_cursor :PluginCursor
var editable = false
var dir_path = "res://meshpainter-textures"

func selection_changed() -> void:
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	# If selected object in tree is mesh instance
	if selection.size() == 1 and selection[0] is MeshInstance3D:
		# Show plugin button and enable capture of mouse events
		var root = get_tree().get_edited_scene_root()
		var mesh_instance = selection[0]
		editable = true
		plugin_button.show_button(root, mesh_instance)
		plugin_panel.hide_panel()
		plugin_cursor.hide_cursor()
	else:
		# Hide the plugin button
		editable = false
		plugin_button.hide_button()

# Override functions to capture mouse events when painting an object
func _handles(obj) -> bool:
	return editable
func _forward_3d_gui_input(viewport_camera, event):
	return plugin_cursor.input(viewport_camera, event)

# Create whole plugin
func _enter_tree():
	plugin_importer = preload("res://addons/meshpainter/plugin_importer.gd").new()
	add_import_plugin(plugin_importer)
	
	# Add cursor instance: shows where to paint on mesh
	plugin_cursor = preload("res://addons/meshpainter/plugin_cursor.tscn").instantiate()
	plugin_cursor.hide()
	
	# Add panel instance: edits cursor parameters
	# Communications between panel and cursor
	plugin_panel = preload("res://addons/meshpainter/plugin_panel.tscn").instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, plugin_panel)
	plugin_panel.hide()
	plugin_panel.plugin_cursor = plugin_cursor
	plugin_panel.editor_filesystem = get_editor_interface().get_resource_filesystem()
	plugin_panel.dir_path = dir_path
	
	# Add button to 3D scene UI
	# Shows panel when toggled
	plugin_button = preload("res://addons/meshpainter/plugin_button.tscn").instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, plugin_button)
	plugin_button.hide()
	plugin_button.plugin_panel = plugin_panel
	
	# Spy on event when object selected in tree changes
	get_editor_interface().get_selection().selection_changed.connect(self.selection_changed)

# Destroy whole plugin
func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, plugin_button)
	if plugin_button:
		plugin_button.free()
		
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, plugin_panel)
	if plugin_panel:
		plugin_panel.free()
