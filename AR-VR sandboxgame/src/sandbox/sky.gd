extends Node3D

@onready var world_environment: WorldEnvironment = $WorldEnvironment
var sky_material: ShaderMaterial
var time: float = 0.0


func _ready():
	sky_material = world_environment.environment.sky.sky_material as ShaderMaterial


func _process(delta: float) -> void:
	time += delta
	sky_material.set("shader_parameter/overwritten_time", time)
