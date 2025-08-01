extends Node3D

## Scene for a dig spot where the AR player has to dig and the VR player has to place acorns.
## Handles the marker on the surface and tree creaton.

# raycast for the setting the dig spot exactly to ground level
@onready var ground_ray_cast_3d: RayCast3D = $GroundRayCast3D
# raycast for testing if the desired depth is reached
@onready var ray_cast_3d: RayCast3D = $RayCast3D
# the cross decal which appears on the ground
@onready var decal: Decal = $Decal
# area for detecting acorns
@onready var acorn_detection_area_3d: Area3D = $AcornDetectionArea3D

# desired depth the AR player has to dig
@export var dig_depth: float = 2.0

# gets emitted when a tree is created to create a new dig spot
signal tree_planted

# tree that grows when an acorn is planted 
var tree: PackedScene = preload("res://src/foliage/tree.tscn")

var dug: bool = false
var acorn_inside: bool = false

# reference to the acorn inside (else null)
var acorn: RigidBody3D

func _ready() -> void:
	acorn_detection_area_3d.position.y = -dig_depth - 0.25
	decal.modulate = Color.WHITE
	ray_cast_3d.target_position.y = -dig_depth * 2.0

## function to check if the desired depth is reached
func _is_dug() -> bool:
	ray_cast_3d.force_raycast_update()
	var depth = self.global_position.y - ray_cast_3d.get_collision_point().y
	if depth > dig_depth:
		decal.modulate = Color.BLUE
		return true
	return false


func _physics_process(_delta: float) -> void:
	if not dug:
		dug = _is_dug()
	if acorn_inside:
		if not _is_dug():
			decal.visible = false
			spawn_tree()
			acorn_inside = false

## creates a tree and emits tree_planted
func spawn_tree() -> void:
	var tree_scene = tree.instantiate()
	add_child(tree_scene)
	tree_scene.position.y += 50.0
	tree_scene.snap_to_ground()
	tree_planted.emit()
	acorn.queue_free()

## snaps whole scene to the ground level
func snap_to_ground() -> void:
	ground_ray_cast_3d.force_raycast_update()
	var depth = ground_ray_cast_3d.get_collision_point().y
	self.global_position.y = depth


func _on_acorn_detection_area_3d_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		acorn = body
		decal.visible = false
		body.freeze = true
		acorn_inside = true
		acorn_detection_area_3d.monitoring = false
