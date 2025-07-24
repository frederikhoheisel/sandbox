extends Node

@onready var objective_container: Node3D = $ObjectiveContainer
@onready var depth_test_ray_cast_3d: RayCast3D = $DepthTestRayCast3D

var objective: PackedScene = preload("res://src/game/objective_area.tscn")
var dig_spot: PackedScene = preload("res://src/game/dig_spot.tscn")

var sandbox_pos: Array = [
		-40.3,	#left
		38.05,	#right
		-27.2,	#top
		22.75]	#bottom

func _ready() -> void:
	pass


func  _get_diggable_pos() -> Vector3:
	while true:
		var try_pos = Vector3(randf_range(-35.0, 33.0), 10.0, randf_range(-22.0, 18.0))
		#var try_pos = Vector3(0.0, 10.0, 0.0)
		depth_test_ray_cast_3d.position = try_pos
		depth_test_ray_cast_3d.force_raycast_update()
		var test_depth = depth_test_ray_cast_3d.get_collision_point().y
		if test_depth > -8.0:
			return try_pos
	return Vector3.ZERO


func place_objective() -> void:
	var dig_spot_scene = dig_spot.instantiate()
	objective_container.add_child(dig_spot_scene)
	var pos: Vector3 = _get_diggable_pos()
	dig_spot_scene.position = pos
	dig_spot_scene.snap_to_ground()
	dig_spot_scene.tree_planted.connect(place_objective)
	#var objective_scene: Node3D = objective.instantiate()
	#objective_container.add_child(objective_scene)
	#objective_scene.build.connect(place_objective)
	#objective_scene.position = Vector3(randf_range(-35.0, 33.0), 10.0, randf_range(-22.0, 18.0))
	#objective_scene.snap_to_ground()
	#%ProjectorWindow.track_obj = objective_scene
