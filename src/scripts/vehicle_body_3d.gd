extends VehicleBody3D 

@export var MAX_STEER = 0.3
@export var ENGINE_POWER = 15 
@export var ACCELERATION_RATE = 20.0  # How quickly engine force builds up
@export var DECELERATION_RATE = 20.0  # How quickly it slows down when not accelerating

var current_engine_force = 0.0

func _physics_process(delta): 
	# Smooth steering (keeping your original approach)
	steering = move_toward(steering, Input.get_axis("right", "left") * MAX_STEER, delta * 10) 
	
	# Get target engine force from input
	var target_engine_force = Input.get_axis("down", "up") * ENGINE_POWER
	
	# Smoothly interpolate engine force for acceleration
	if abs(target_engine_force) > abs(current_engine_force):
		# Accelerating - use acceleration rate
		current_engine_force = move_toward(current_engine_force, target_engine_force, ACCELERATION_RATE * delta)
	else:
		# Decelerating or coasting - use deceleration rate
		current_engine_force = move_toward(current_engine_force, target_engine_force, DECELERATION_RATE * delta)
	
	# Apply the smoothed engine force
	engine_force = current_engine_force
