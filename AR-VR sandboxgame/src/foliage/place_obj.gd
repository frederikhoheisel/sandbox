extends Node

var acorn = preload("res://src/game/pickable_acorn.tscn")

## spawns a acorn at the position of the right hand of the VR player
func _on_right_hand_xr_controller_3d_2_button_pressed(button_name: String) -> void:
	if button_name == "ax_button" or button_name == "by_button":
		var acorn_scene = acorn.instantiate()
		get_tree().root.get_child(0).add_child(acorn_scene)
		acorn_scene.global_position = $"../RightHand".global_position

## spawns a acorn at the position of the left hand of the VR player
func _on_left_hand_xr_controller_3d_button_pressed(button_name: String) -> void:
	if button_name == "ax_button" or button_name == "by_button":
		var acorn_scene = acorn.instantiate()
		get_tree().root.get_child(0).add_child(acorn_scene)
		acorn_scene.global_position = $"../../LeftHandXRController3D/LeftHand".global_position
