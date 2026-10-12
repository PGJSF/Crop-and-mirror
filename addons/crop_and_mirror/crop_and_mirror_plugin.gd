@tool
extends EditorPlugin

const PANEL_SCENE: PackedScene = preload("res://addons/crop_and_mirror/crop_and_mirror_panel.tscn")
const PANEL_SCRIPT: GDScript = preload("res://addons/crop_and_mirror/crop_and_mirror_panel.gd")
const PANEL_TITLE: String = "Crop & Mirror"

var panel_instance: PANEL_SCRIPT
var panel_button: Button


func _enter_tree() -> void:
	panel_instance = PANEL_SCENE.instantiate() as PANEL_SCRIPT
	panel_instance.panel_title_changed.connect(_on_panel_title_changed)
	panel_button = add_control_to_bottom_panel(panel_instance, PANEL_TITLE)
	panel_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_on_panel_title_changed(panel_instance.get_panel_title())


func _on_panel_title_changed(title: String) -> void:
	if is_instance_valid(panel_button):
		panel_button.text = title


func _exit_tree() -> void:
	if is_instance_valid(panel_instance):
		remove_control_from_bottom_panel(panel_instance)
		panel_instance.free()
	panel_instance = null
	panel_button = null
