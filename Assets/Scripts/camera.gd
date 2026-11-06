extends Camera3D

@export var max_horizontal_angle: float = 30.0 # Degrees left/right
@export var max_vertical_angle: float = 30.0   # Degrees up/down
@export_range(0.0, 1.0) var look_ahead_factor: float = 0.5
@export var smooth_speed: float = 4.0

@export var raycaster: RayCast3D
@export var subViewport: SubViewport
@export var map: MeshInstance3D

var initial_rotation: Vector3
var hovering := false
var simMousePos := Vector2.ZERO

func _ready() -> void:
	# Cache starting orientation
	initial_rotation = rotation
	# Make sure mouse is visible and free to click UI/3D nodes
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

func _process(delta: float) -> void:
	# 1. Grab screen boundary dimensions
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 2. Normalize mouse coordinates from -1.0 to 1.0 (Center is 0.0)
	var norm_x = (mouse_pos.x / viewport_size.x) * 2.0 - 1.0
	var norm_y = (mouse_pos.y / viewport_size.y) * 2.0 - 1.0
	
	# 3. Calculate target angles in radians
	var target_yaw = deg_to_rad(-norm_x * max_horizontal_angle * look_ahead_factor)
	var target_pitch = deg_to_rad(-norm_y * max_vertical_angle * look_ahead_factor)
	
	# 4. Define the absolute target rotation matrix
	var target_rotation = Vector3(
		initial_rotation.x + target_pitch,
		initial_rotation.y + target_yaw,
		initial_rotation.z
	)
	
	# 5. Spherically interpolate the camera angle
	rotation.x = lerp_angle(rotation.x, target_rotation.x, smooth_speed * delta)
	rotation.y = lerp_angle(rotation.y, target_rotation.y, smooth_speed * delta)
	
	raycaster.look_at(project_position(mouse_pos, 20))
	raycaster.force_raycast_update()

	if not raycaster.is_colliding():
		hovering = false
		return
	

	var local := map.to_local(raycaster.get_collision_point())
	var meshSize := (map.mesh as QuadMesh).size
	var newPos := Vector2(
		(local.x / meshSize.x + 0.5) * subViewport.size.x,
		(0.5 - local.y / meshSize.y) * subViewport.size.y
	)
	
	var motion := InputEventMouseMotion.new()
	motion.position = newPos
	motion.global_position = newPos
	motion.relative = newPos - (simMousePos if hovering else Vector2.ZERO)
	motion.button_mask = Input.get_mouse_button_mask()
	subViewport.push_input(motion)

	simMousePos = newPos
	hovering = true
	
func _input(event: InputEvent) -> void:
	
	
	
	
	if not hovering:
		return
	
	
	if event is InputEventMouseButton:
		var e := event.duplicate() as InputEventMouseButton
		e.position = simMousePos
		e.global_position = simMousePos
		subViewport.push_input(e)
	elif event is InputEventKey:
		subViewport.push_input(event)
	elif event is InputEventMouseMotion:
		print("its moving dipshit")
		var e := event.duplicate() as InputEventMouseMotion
		e.position = simMousePos
		e.global_position = simMousePos
		subViewport.push_input(e)
	
