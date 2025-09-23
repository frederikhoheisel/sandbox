class_name GrowingTree
extends Node3D

@export var grass_count: int = 64
@export var circle_radius: float = 12.0

const MODEL_DEFAULT: PackedScene = preload("res://src/foliage/tree_model_default.tscn")
const MODEL_PINE: PackedScene = preload("res://src/foliage/tree_model_pine.tscn")
const MODEL_DETAILED: PackedScene = preload("res://src/foliage/tree_model_detailed.tscn")
const MODEL_OAK: PackedScene = preload("res://src/foliage/tree_model_oak.tscn")
const MODEL_PLATEAU: PackedScene = preload("res://src/foliage/tree_model_plateau.tscn")
const MODEL_SMALL: PackedScene = preload("res://src/foliage/tree_model_small.tscn")
const MODEL_THIN: PackedScene = preload("res://src/foliage/tree_model_thin.tscn")

var tree_models: Array = [MODEL_DEFAULT, MODEL_PINE, MODEL_DETAILED, MODEL_OAK, MODEL_PLATEAU, MODEL_SMALL, MODEL_THIN]

var grass_model: PackedScene = preload("res://src/foliage/grass_model.tscn")

@onready var tree_model_container: Node3D = $TreeModelContainer
@onready var grass_model_container: Node3D = $GrassModelContainer


func _ready() -> void:
	self.rotation.y = randf() * TAU
	
	select_rand_tree_model()
	
	var rand_size := randf_range(4.0, 10.0)
	var tween := get_tree().create_tween()
	tween.tween_property(tree_model_container, "scale", Vector3(rand_size, rand_size, rand_size), 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	place_grass_in_circle()


func select_rand_tree_model() -> void:
	var rand_scene = tree_models[randi() % tree_models.size()].instantiate()
	tree_model_container.add_child(rand_scene)


func place_grass_in_circle():
	for i in range(grass_count):
		var angle = randf() * TAU
		var distance = sqrt(randf()) * circle_radius  # Square root for uniform distribution
		
		var x = cos(angle) * distance
		var z = sin(angle) * distance
		
		
		# Instantiate grass
		var grass_instance = grass_model.instantiate()
		grass_instance.wait_time = distance / 2.0 + 0.3
		grass_model_container.add_child(grass_instance)
		grass_instance.position = Vector3(x, 0.0, z)
