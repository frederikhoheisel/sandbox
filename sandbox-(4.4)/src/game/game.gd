extends Node

@onready var objective_container: Node3D = $ObjectiveContainer

var objective: PackedScene = preload("res://src/game/objective_area.tscn")

var sandbox_pos: Array = [
		-40.3,	#left
		38.05,	#right
		-27.2,	#top
		22.75]	#bottom

func _ready() -> void:
	pass

func place_objective() -> void:
	var objective_scene: Node3D = objective.instantiate()
	objective_container.add_child(objective_scene)
	objective_scene.build.connect(place_objective)
	objective_scene.position = Vector3(randf_range(-35.0, 33.0), 10.0, randf_range(-22.0, 18.0))
	objective_scene.snap_to_ground()
	#%ProjectorWindow.track_obj = objective_scene
