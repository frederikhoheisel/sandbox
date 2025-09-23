extends Node

## Handles the game logic of spawning dig spots on the sandbox surface.

@export var max_number_trees: int = 64

@onready var objective_container: Node3D = $ObjectiveContainer
@onready var depth_test_ray_cast_3d: RayCast3D = $DepthTestRayCast3D
@onready var sandbox_mesh: MeshInstance3D = %MeshInstance3D

var dig_spot: PackedScene = preload("res://src/game/dig_spot.tscn")
var tree: PackedScene = preload("res://src/foliage/tree.tscn")

var tree_positions: Array[Vector3] = []
var tree_spawn_times: Array[int] = []
var tree_count: int = 0


func _ready() -> void:
	sandbox_mesh.mesh.material.set("shader_parameter/start_time", Time.get_ticks_msec() as float)
	tree_positions.resize(max_number_trees)
	tree_positions.fill(Vector3(0.0, 0.0, 0.0))
	
	tree_spawn_times.resize(max_number_trees)
	tree_spawn_times.fill(0)


func _process(_delta: float) -> void:
	#if Input.is_action_just_pressed("place_tree"):
		#spawn_tree()
	pass


## recursive function
func _get_diggable_pos(depth: int = 0) -> Vector3:
	#printt("tree positions:", tree_positions)
	#printt("---------------------------------------")
	#print(depth)
	# magic numbers yay! 
	var try_pos = Vector3(randf_range(-38.3, 36.05), 40.0, randf_range(-25.2, 20.75)) * 2.0
	#var try_pos = Vector3(0.0, 10.0, 0.0)
	if depth >= 256:
		return try_pos
	depth_test_ray_cast_3d.position = try_pos
	depth_test_ray_cast_3d.force_raycast_update()
	var test_depth: float = depth_test_ray_cast_3d.get_collision_point().y
	for pos: Vector3 in tree_positions:
		var distance: float = try_pos.distance_to(pos)
		#printt("distance: ", distance)
		if distance < 10.0:
			##print("distance to close")
			return _get_diggable_pos(depth + 1)
	if test_depth > -10.0:
		return try_pos
	return _get_diggable_pos(depth + 1)


func place_objective() -> void:
	var dig_spot_scene = dig_spot.instantiate()
	objective_container.add_child(dig_spot_scene)
	var pos: Vector3 = _get_diggable_pos()
	dig_spot_scene.position = pos
	tree_positions[tree_count] = pos
	dig_spot_scene.snap_to_ground()
	dig_spot_scene.tree_planted.connect(change_ground)
	dig_spot_scene.tree_planted.connect(place_objective)


func spawn_tree() -> void:
	#for child in get_children():
		#if child is GrowingTree:
			#child.queue_free()
	var tree_scene: GrowingTree = tree.instantiate()
	add_child(tree_scene)
	tree_scene.global_position = _get_diggable_pos()
	tree_scene.position.y += 50.0
	#tree_scene.snap_to_ground()
	
	tree_positions[tree_count] = tree_scene.global_position
	tree_spawn_times[tree_count] = Time.get_ticks_msec() + 100
	tree_count += 1
	#print(tree_positions)
	#print("---------------------------------------------------------------------")
	sandbox_mesh.mesh.material.set("shader_parameter/tree_positions", tree_positions)
	sandbox_mesh.mesh.material.set("shader_parameter/tree_spawn_times", tree_spawn_times)
	sandbox_mesh.mesh.material.set("shader_parameter/tree_count", tree_count)
	#print(sandbox_mesh.mesh.material.get("shader_parameter/tree_positions"))


func change_ground() -> void:
	tree_spawn_times[tree_count] = Time.get_ticks_msec() + 100
	tree_count += 1
	sandbox_mesh.mesh.material.set("shader_parameter/tree_positions", tree_positions)
	sandbox_mesh.mesh.material.set("shader_parameter/tree_spawn_times", tree_spawn_times)
	sandbox_mesh.mesh.material.set("shader_parameter/tree_count", tree_count)
