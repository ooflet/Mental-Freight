extends Camera3D

@onready var target: Node3D = %VehicleBody3D
@export var offset := Vector3(0, 2, -2)  # controls distance and angle
@export var look_at_offset := Vector3(0, 0, 0)  # where the camera looks

func _process(_delta):
	if target:
		# Place camera relative to target
		global_position = target.global_position + offset
		# Look at the target (with slight offset if desired)
		look_at(target.global_position + look_at_offset, Vector3.UP)
