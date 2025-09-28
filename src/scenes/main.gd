extends Node3D

@export var packages: int = 0
@export var quota: int = 5
@export var overdue_packages: int = 0
@export var arrow: Node3D
@export var orientation_offset_deg: float = -90.0  # try 90 or -90

@export var cube_size: Vector3 = Vector3(0.5, 0.5, 0.5)
@export var bottom_color: Color = Color(0, 1, 0, 1)  # solid green
@export var top_color: Color = Color(0, 1, 0, 0)     # transparent
@export var height: float = 2.0                      # matches cube_size.y / 2

var origin_transform: Transform3D

var fatigue: float = 0.0
var fatigue_rate: float = 1 # 0.01 every 0.1s = 0.1 per second

var waypoints: Array = []
var current_waypoint: Area3D
var current_indicator: MeshInstance3D

var day = 1

var fictional_seconds: int = 9 * 3600  # start at 6:00
var hours: int = 0
var minutes: int = 0

func make_indicator(area):
	var cube = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = cube_size
	cube.mesh = mesh
	area.add_child(cube)

	# Simple glowing shader
	var shader = Shader.new()
	shader.code = """
	    shader_type spatial;
        render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

        uniform vec4 base_color : source_color = vec4(0.0, 1.0, 0.0, 0.8);
        uniform float glow_strength : hint_range(0.0, 2.0) = 1.0;
        uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;

        void fragment() {
            // Create a pulsing effect
            float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5;
            
            // Rim lighting effect
            float rim = 1.0 - dot(NORMAL, VIEW);
            rim = pow(rim, 2.0);
            
            // Combine base color with glow
            vec3 final_color = base_color.rgb + (rim * glow_strength * pulse);
            
            ALBEDO = final_color;
            ALPHA = base_color.a;
            EMISSION = base_color.rgb * rim * glow_strength * pulse;
        }
	"""

	var material = ShaderMaterial.new()
	material.shader = shader

	# Set shader parameters
	material.set_shader_parameter("base_color", bottom_color)
	material.set_shader_parameter("glow_strength", 1.5)
	material.set_shader_parameter("pulse_speed", 2.0)

	cube.material_override = material

	return cube
	
func reset_vehicle():
	var vehicle = $Truck/VehicleBody3D
	var position = Vector3(0, 0, 0)
	var rotation_degrees = Vector3(0, 0, 0)
	# Convert degrees to radians
	var rotation_radians = rotation_degrees * deg_to_rad(1)

	# Create a Basis from Euler angles (XYZ)
	var new_basis = Basis()
	new_basis = new_basis.rotated(Vector3.RIGHT, rotation_radians.x)
	new_basis = new_basis.rotated(Vector3.UP, rotation_radians.y)
	new_basis = new_basis.rotated(Vector3.FORWARD, rotation_radians.z)

	# Set the global transform
	vehicle.transform = origin_transform

	# Stop all movement
	vehicle.linear_velocity = Vector3.ZERO
	vehicle.angular_velocity = Vector3.ZERO

func new_day():
	overdue_packages += quota - packages
	day += 1
	quota = 5 + 2 * day - 1 + overdue_packages
	packages = 0
	$GUI/EndShift.visible = false
	$GUI/Day/DayLabel.text = "Day "+str(day)
	$GUI/Day/OverdueParcels.text = str(overdue_packages)+" overdue packages"
	await get_tree().create_timer(0.1).timeout # setup camera first
	$GUI/Day.visible = true
	$GUI/Day/AnimationPlayer.play("fade_in")
	await get_tree().create_timer(1).timeout
	set_random_waypoint()
	reset_vehicle()
	$GUI/Quota.text = "Quota: 0/"+str(quota)
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = true
	await get_tree().create_timer(3).timeout
	$GUI/Day/AnimationPlayer.play("fade_out")
	await get_tree().create_timer(1).timeout
	$GUI/Day.visible = false
	get_tree().paused = false

func _ready() -> void:
	origin_transform = $Truck/VehicleBody3D.transform
	
	for child in $Map/CollectionPoints.get_children():
		waypoints.append(child)
		
	arrow = $Truck/VehicleBody3D/NavigationArrow
	set_random_waypoint()
	await get_tree().create_timer(0.1).timeout # setup camera first
	$GUI/Day.visible = true
	$GUI/Day/AnimationPlayer.play("fade_in")
	await get_tree().create_timer(1).timeout
	$Reincarnated.play()
	get_tree().paused = true
	$GUI/Tutorial.visible = true
	await get_tree().create_timer(3).timeout
	$GUI/Day/AnimationPlayer.play("fade_out")
	await get_tree().create_timer(1).timeout
	$GUI/Day.visible = false
	$GUI/EndShift.pressed.connect(new_day)
	$Map.point_hit.connect(point_hit)

func set_random_waypoint():
	arrow.visible = true
	$GUI/Dialogue.visible = false
	var random_waypoint = waypoints.pick_random()
	print("random ", random_waypoint)
	if current_waypoint == random_waypoint:
		set_random_waypoint()
	else:
		current_waypoint = random_waypoint
		current_indicator = make_indicator(current_waypoint)
		print("selected ", random_waypoint)
		
func end_day(timeout = false):
	$GUI/EndShift.visible = true
	$GUI/Dialogue.visible = true
	
	if timeout:
		$GUI/Dialogue.text = "I'm getting tired... I don't want to go overtime"
	else:
		arrow.visible = false
		$GUI/Dialogue.text = "Packages delivered! I should end my shift now"

func point_hit(point):
	print(point)
	if point == current_waypoint.name:
		packages += 1
		$GUI/Quota.text = "Quota: "+str(packages)+"/"+str(quota)
		current_indicator.queue_free()
		if packages >= quota:
			end_day()
		else:
			set_random_waypoint()

func _process(delta: float) -> void:
	# --- Fatigue accumulation ---
	fatigue += fatigue_rate * delta
	$GUI/Fatigue.value = round(fatigue * 50)

	# --- Arrow rotation ---
	if current_waypoint and arrow:
		var dir = current_waypoint.global_transform.origin - arrow.global_transform.origin
		dir.y = 0
		if dir.length_squared() < 0.0001:
			return
		var angle = atan2(dir.x, dir.z)                      # global yaw to target
		var desired_global = angle + deg_to_rad(orientation_offset_deg)
		# If arrow is a child of the truck, you may want local yaw:
		var parent_yaw = 0.0
		var parent = arrow.get_parent()
		if parent and parent is Node3D:
			parent_yaw = parent.global_transform.basis.get_euler().y
		var desired_local = desired_global - parent_yaw
		arrow.rotation.y = desired_local                       # set local yaw directly
		
	fictional_seconds += delta * 240  # 0.5 sec = 1 min => 120x speed (1 sec = 2 min)

	hours = int(fictional_seconds / 3600) % 24
	minutes = int((fictional_seconds % 3600) / 60)

	$GUI/Time.text = "%02d:%02d" % [hours, minutes]
