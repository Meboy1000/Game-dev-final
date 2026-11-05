extends Camera3D

@export var raycaster: RayCast3D
@export var map: MeshInstance3D
@export var subViewport: SubViewport

var startRotation: Vector3
var hovering := false
var simMousePos := Vector2.ZERO

func _ready() -> void:
	startRotation = rotation
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

func _process(_delta: float) -> void:
	var mousePos := get_viewport().get_mouse_position()

	var screenSize := get_viewport().get_visible_rect().size
	var x := mousePos.x / screenSize.x * 2.0 - 1.0
	var y := mousePos.y / screenSize.y * 2.0 - 1.0
	rotation.y = startRotation.y - deg_to_rad(x * 15.0)
	rotation.x = startRotation.x - deg_to_rad(y * 15.0)

	raycaster.look_at(project_position(mousePos, 10))
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
	motion.relative = newPos - simMousePos if hovering else Vector2.ZERO
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
