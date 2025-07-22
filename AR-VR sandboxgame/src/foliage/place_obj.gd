extends Node

var tree = preload("res://src/foliage/tree_default.tscn")

func _on_right_hand_xr_controller_3d_2_button_pressed(button_name: String) -> void:
	if button_name == "trigger_click":
		var tree_scene = tree.instantiate()
		get_tree().root.get_child(0).add_child(tree_scene)
		tree_scene.global_position = $"../RightHand".global_position
		#print("tree pos before:" + str(tree_scene.global_position))
		tree_scene.snap_to_ground()
