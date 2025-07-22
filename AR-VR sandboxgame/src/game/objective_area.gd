extends Node3D

var pos_probe_count: int = 0
var neg_probe_count: int = 0
signal build

@onready var ground_ray_cast_3d: RayCast3D = $GroundRayCast3D
@onready var probe_container_inside: Node3D = $ProbeContainerInside
@onready var probe_container_outside: Node3D = $ProbeContainerOutside

func _ready() -> void:
	pos_probe_count = probe_container_inside.get_child_count()
	neg_probe_count = probe_container_outside.get_child_count()

func _physics_process(_delta: float) -> void:
	var pos_probes: int = 0
	var neg_probes: int = 0
	
	for p: Probe in probe_container_inside.get_children():
		if p.detect_sand():
			pos_probes += 1
			#print("sand " + str(pos_probes))
	
	for p: Probe in probe_container_outside.get_children():
		if not p.detect_sand():
			neg_probes += 1
	
	if pos_probes == pos_probe_count:
		print("submerged")
		if neg_probes == neg_probe_count:
			print("edges free")
			build.emit()
			self.queue_free()

func snap_to_ground() -> void:
	ground_ray_cast_3d.force_raycast_update()
	var depth = ground_ray_cast_3d.get_collision_point().y
	#print(depth)
	#print($RayCast3D.get_collider())
	self.global_position.y = depth + 1.0
