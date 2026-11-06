extends Control

var camera_pos := Vector2.ZERO   # World coordinate at the screen center
var zoom := 1.0                  # Pixels per world unit multiplier
var dragging := false

const MIN_ZOOM := 0.1
const MAX_ZOOM := 20.0
const TARGET_GRID_PIXELS := 70.0

var font := ThemeDB.fallback_font
const LABEL_FONT_SIZE := 14

# Keep track of drawing states
enum State { WAITING, DRAWING }
var current_state = State.WAITING

var center_point: Vector2 = Vector2.ZERO
var preview_radius: float = 0.0

# Store permanently placed circles as a list of dictionaries: [{"center": Vector2, "radius": float}]
var placed_circles: Array = []

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			placed_circles.clear()
			current_state = State.WAITING
			queue_redraw()
			
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Middle mouse: pan
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			return

		# Mouse wheel: zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_mouse(1.15, event.position)
			return

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_mouse(1.0 / 1.15, event.position)
			return

		# Left mouse: place circle center, then radius edge
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_world: Vector2 = screen_to_world(event.position)

			if current_state == State.WAITING:
				center_point = mouse_world
				current_state = State.DRAWING

			else:
				var final_radius: float = center_point.distance_to(mouse_world)

				if final_radius > 0.01:
					placed_circles.append({
						"center": center_point,
						"radius": final_radius,
						"edge": mouse_world
					})

				current_state = State.WAITING

			queue_redraw()
			return

		# Right mouse cancels a circle currently being drawn
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if current_state == State.DRAWING:
				current_state = State.WAITING
				queue_redraw()
			return

	elif event is InputEventMouseMotion:
		if dragging:
			camera_pos -= event.relative / zoom

		# Needed for both panning and the live circle preview.
		queue_redraw()

func _zoom_at_mouse(factor: float, mouse_pos: Vector2):
	var world_before := screen_to_world(mouse_pos)

	zoom = clamp(zoom * factor, MIN_ZOOM, MAX_ZOOM)

	var world_after := screen_to_world(mouse_pos)
	camera_pos += world_before - world_after
	queue_redraw()

func screen_to_world(screen_pos: Vector2) -> Vector2:
	return camera_pos + (screen_pos - size * 0.5) / zoom

func world_to_screen(world_pos: Vector2) -> Vector2:
	return size * 0.5 + (world_pos - camera_pos) * zoom

func _draw():
	# Black background
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)

	var grid_step := get_grid_step()
	var visible_top_left := screen_to_world(Vector2.ZERO)
	var visible_bottom_right := screen_to_world(size)

	var min_x : float = floor(visible_top_left.x / grid_step) * grid_step
	var max_x : float = ceil(visible_bottom_right.x / grid_step) * grid_step
	var min_y : float = floor(visible_top_left.y / grid_step) * grid_step
	var max_y : float = ceil(visible_bottom_right.y / grid_step) * grid_step

	# Minor grid lines
	for x in range(int(min_x / grid_step), int(max_x / grid_step) + 1):
		var world_x := x * grid_step
		var screen_x := world_to_screen(Vector2(world_x, 0)).x
		var color := Color(0.22, 0.22, 0.22)

		if x == 0:
			color = Color(0.8, 0.25, 0.25) # Y axis

		draw_line(Vector2(screen_x, 0), Vector2(screen_x, size.y), color, 1.0)

	for y in range(int(min_y / grid_step), int(max_y / grid_step) + 1):
		var world_y := y * grid_step
		var screen_y := world_to_screen(Vector2(0, world_y)).y
		var color := Color(0.22, 0.22, 0.22)

		if y == 0:
			color = Color(0.25, 0.8, 0.25) # X axis

		draw_line(Vector2(0, screen_y), Vector2(size.x, screen_y), color, 1.0)
		
		# Axis number labels
	var x_axis_screen_y := world_to_screen(Vector2(0, 0)).y
	var y_axis_screen_x := world_to_screen(Vector2(0, 0)).x

	# Keep labels visible even when the corresponding axis is off-screen.
	var x_label_y : float = clamp(x_axis_screen_y + 6.0, 6.0, size.y - 22.0)
	var y_label_x : float = clamp(y_axis_screen_x + 6.0, 6.0, size.x - 70.0)

	# X-axis values
	for x in range(int(min_x / grid_step), int(max_x / grid_step) + 1):
		if x == 0:
			continue

		var world_x := x * grid_step
		var screen_x := world_to_screen(Vector2(world_x, 0)).x
		var label := str(world_x)

		draw_string(
			font,
			Vector2(screen_x + 4, x_label_y + LABEL_FONT_SIZE),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			LABEL_FONT_SIZE,
			Color(0.8, 0.8, 0.8)
		)

	# Y-axis values
	for y in range(int(min_y / grid_step), int(max_y / grid_step) + 1):
		if y == 0:
			continue

		var world_y := y * grid_step
		var screen_y := world_to_screen(Vector2(0, world_y)).y
		var label := str(world_y)

		draw_string(
			font,
			Vector2(y_label_x, screen_y - 4),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			LABEL_FONT_SIZE,
			Color(0.8, 0.8, 0.8)
		)
		# Draw placed circles
	for circle: Dictionary in placed_circles:
		var world_center: Vector2 = circle["center"]
		var world_edge: Vector2 = circle["edge"]
		var world_radius: float = circle["radius"]

		var screen_center: Vector2 = world_to_screen(world_center)
		var screen_edge: Vector2 = world_to_screen(world_edge)
		var screen_radius: float = world_radius * zoom

		draw_circle_outline(
			screen_center,
			screen_radius,
			Color(0.0, 0.98, 0.6),
			2.0
		)

		draw_line(
			screen_center,
			screen_edge,
			Color(0.0, 0.98, 0.6),
			2.0
		)

		var radius_label: String = "%.2f" % world_radius
		draw_string(
			font,
			(screen_center + screen_edge) * 0.5,
			radius_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			Color.WHITE
		)

	# Live circle preview
	if current_state == State.DRAWING:
		var mouse_world: Vector2 = screen_to_world(get_local_mouse_position())
		var radius_world: float = center_point.distance_to(mouse_world)

		var screen_center: Vector2 = world_to_screen(center_point)
		var screen_mouse: Vector2 = world_to_screen(mouse_world)
		var screen_radius: float = radius_world * zoom

		draw_circle(screen_center, 3.0, Color.WHITE)
		draw_circle_outline(
			screen_center,
			screen_radius,
			Color(1.0, 1.0, 1.0, 0.65),
			1.5
		)
		draw_line(
			screen_center,
			screen_mouse,
			Color(1.0, 1.0, 1.0, 0.35),
			1.0
		)

		draw_string(
			font,
			(screen_center + screen_mouse) * 0.5,
			"%.2f" % radius_world,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			Color.WHITE
		)

func get_grid_step() -> float:
	# Pick clean world-unit intervals while keeping cells near 70 screen pixels.
	var desired_world_step := TARGET_GRID_PIXELS / zoom
	var exponent : float = floor(log(desired_world_step) / log(10.0))
	var base := pow(10.0, exponent)
	var normalized := desired_world_step / base

	if normalized <= 1.0:
		return 1.0 * base
	elif normalized <= 2.0:
		return 2.0 * base
	elif normalized <= 5.0:
		return 5.0 * base
	else:
		return 10.0 * base

func draw_circle_outline(
	center: Vector2,
	radius: float,
	color: Color,
	width: float
) -> void:
	if radius <= 0.0:
		return

	draw_arc(center, radius, 0.0, TAU, 64, color, width, true)
