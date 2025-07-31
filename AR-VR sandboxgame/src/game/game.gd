extends Node

@onready var objective_container: Node3D = $ObjectiveContainer
@onready var depth_test_ray_cast_3d: RayCast3D = $DepthTestRayCast3D

var dig_spot: PackedScene = preload("res://src/game/dig_spot.tscn")
var tree: PackedScene = preload("res://src/foliage/tree.tscn")

func _process(delta: float) -> void:
	pass
	#if Input.is_action_pressed("place_tree"):
		#spawn_tree()

func  _get_diggable_pos() -> Vector3:
	while true:
		# magic numbers yay!
		var try_pos = Vector3(randf_range(-38.3, 36.05), 10.0, randf_range(-25.2, 20.75)) * 2.0
		#var try_pos = Vector3(0.0, 10.0, 0.0)
		depth_test_ray_cast_3d.position = try_pos
		depth_test_ray_cast_3d.force_raycast_update()
		var test_depth = depth_test_ray_cast_3d.get_collision_point().y
		if test_depth > -10.0:
			return try_pos
	return Vector3.ZERO


func place_objective() -> void:
	var dig_spot_scene = dig_spot.instantiate()
	objective_container.add_child(dig_spot_scene)
	var pos: Vector3 = _get_diggable_pos()
	dig_spot_scene.position = pos
	dig_spot_scene.snap_to_ground()
	dig_spot_scene.tree_planted.connect(place_objective)

func spawn_tree() -> void:
	var tree_scene = tree.instantiate()
	add_child(tree_scene)
	tree_scene.global_position = _get_diggable_pos()
	tree_scene.position.y += 50.0
	tree_scene.snap_to_ground()
