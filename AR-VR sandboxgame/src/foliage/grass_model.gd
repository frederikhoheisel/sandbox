extends Node3D

@export var wait_time: float = 1.0

const MODEL_GRASS: PackedScene = preload("res://src/foliage/grass.tscn")
const MODEL_GRASS_LARGE: PackedScene = preload("res://src/foliage/grass_large.tscn")
const MODEL_GRASS_LEAFS: PackedScene = preload("res://src/foliage/grass_leafs.tscn")
const MODEL_GRASS_LEAFS_LARGE: PackedScene = preload("res://src/foliage/grass_leafs_large.tscn")
const MODEL_FLOWER_RED: PackedScene = preload("res://src/foliage/flower_red.tscn")
const MODEL_FLOWER_YELLOW: PackedScene = preload("res://src/foliage/flower_yellow.tscn")
const MODEL_FLOWER_PURPLE: PackedScene = preload("res://src/foliage/flower_purple.tscn")
const MODEL_MUSHROOM: PackedScene = preload("res://src/foliage/mushroom.tscn")
const MODEL_CROPS: PackedScene = preload("res://src/foliage/crops.tscn")

var grass_models: Array = [
		MODEL_GRASS, MODEL_GRASS, MODEL_GRASS, MODEL_GRASS, MODEL_GRASS, 
		MODEL_GRASS_LARGE, MODEL_GRASS_LEAFS, MODEL_GRASS_LEAFS_LARGE, 
		MODEL_FLOWER_RED, MODEL_FLOWER_YELLOW, MODEL_FLOWER_PURPLE,
		MODEL_MUSHROOM, MODEL_CROPS
		]

var selected_model: Node3D

func _ready() -> void:
	self.rotation.y = randf() * TAU
	select_rand_model()
	var rand_size := randf_range(1.0, 5.0)
	var tween := get_tree().create_tween()
	tween.tween_method(func(_val): pass, 0, 1, wait_time)
	tween.tween_property(selected_model, "scale", Vector3(rand_size, rand_size, rand_size), 2.0).set_trans(Tween.TRANS_SPRING)


func select_rand_model() -> void:
	selected_model = grass_models[randi() % grass_models.size()].instantiate()
	selected_model.scale = Vector3(0.01, 0.01, 0.01)
	add_child(selected_model)
