extends Node3D

@export var packages: int = 0
@export var quota: int = 10
@export var arrow: Node3D
@export var orientation_offset_deg: float = -90.0  # try 90 or -90

var waypoints: Array = []
var current_waypoint: Area3D

func _ready() -> void:
	for child in $Map/CollectionPoints.get_children():
		waypoints.append(child)
		
	set_random_waypoint()
	$GUI/Tutorial.visible = true
	#$Prayer.play(Global.prayer_playbacktime.get_playback_time())
	await get_tree().create_timer(0.1).timeout # setup camera first
	$Reincarnated.play()
	get_tree().paused = true
	arrow = $Truck/VehicleBody3D/NavigationArrow
	$Map.point_hit.connect(point_hit)

func set_random_waypoint():
	var random_waypoint = waypoints.pick_random()
	print("random ", random_waypoint)
	if current_waypoint == random_waypoint:
		set_random_waypoint()
	else:
		current_waypoint = random_waypoint
		print("selected ", random_waypoint)

func point_hit(point):
	print(point)
	if point == current_waypoint.name:
		packages += 1
		$GUI/Quota.text = "Quota: "+str(packages)+"/"+str(quota)
		set_random_waypoint()

func _process(_delta):
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
		
		
