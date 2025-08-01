extends Node3D

var check_time: float = 1.0
var cur_time: float = 0.0

const MODEL_DEFAULT: PackedScene = preload("res://src/foliage/tree_model_default.tscn")
const MODEL_PINE: PackedScene = preload("res://src/foliage/tree_model_pine.tscn")
const MODEL_DETAILED: PackedScene = preload("res://src/foliage/tree_model_detailed.tscn")
const MODEL_OAK: PackedScene = preload("res://src/foliage/tree_model_oak.tscn")
const MODEL_PLATEAU: PackedScene = preload("res://src/foliage/tree_model_plateau.tscn")
const MODEL_SMALL: PackedScene = preload("res://src/foliage/tree_model_small.tscn")
const MODEL_THIN: PackedScene = preload("res://src/foliage/tree_model_thin.tscn")

var tree_models: Array = [MODEL_DEFAULT, MODEL_PINE, MODEL_DETAILED, MODEL_OAK, MODEL_PLATEAU, MODEL_SMALL, MODEL_THIN]

func _ready() -> void:
	self.rotation.y = randf() * 2 * PI
	
	select_rand_model()
	
	var rand_size := randf_range(4.0, 10.0)
	var tween := get_tree().create_tween()
	tween.tween_property($Model, "scale", Vector3(rand_size, rand_size, rand_size), 2.0)

func select_rand_model() -> void:
	var rand_scene = tree_models[randi() % tree_models.size()].instantiate()
	$Model.add_child(rand_scene)

func snap_to_ground() -> void:
	$RayCast3D.force_raycast_update()
	var depth = $RayCast3D.get_collision_point().y
	self.global_position.y = depth
	#print("tree pos after: " + str(self.global_position))

func _process(delta: float) -> void:
	cur_time += delta
	if cur_time > check_time:
		self.global_position.y += 10.0
		snap_to_ground()
		cur_time = 0.0
