extends Control

@export var font: Font
# Keep track of drawing states
enum State { WAITING, DRAWING }
var current_state = State.WAITING

var center_point: Vector2 = Vector2.ZERO
var preview_radius: float = 0.0

# Store permanently placed circles as a list of dictionaries: [{"center": Vector2, "radius": float}]
var placed_circles: Array = []
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_C:
			clear_map()
			
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match current_state:
			State.WAITING:
				# First click: Get local mouse coordinates relative to this specific UI node
				center_point = get_local_mouse_position()
				current_state = State.DRAWING
			
			State.DRAWING:
				# Second click: Lock in the circle dimensions
				var final_radius = center_point.distance_to(get_local_mouse_position())
				
				# Ignore tiny accidental double-clicks
				if final_radius > 1.0:
					placed_circles.append({"center": center_point, "radius": final_radius, "edge": get_local_mouse_position()})
				
				current_state = State.WAITING
				queue_redraw() # Final layout refresh

	# Optional: Right-click cancels the current drawing
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if current_state == State.DRAWING:
			current_state = State.WAITING
			queue_redraw()

	# Track mouse movement to update the preview radius dynamically
	elif event is InputEventMouseMotion:
		if current_state == State.DRAWING:
			preview_radius = center_point.distance_to(get_local_mouse_position())
			queue_redraw() # Forces the UI to clear and redraw on the next frame


func _draw() -> void:
	# 1. Draw all previously placed permanent circles
	for circle in placed_circles:
		draw_circle_outline(circle.center, circle.radius, Color.MEDIUM_SPRING_GREEN, 2.0)
		draw_line(circle.center, circle.edge, Color.MEDIUM_SPRING_GREEN, 2)
		draw_string(font, ((circle.center + circle.edge)/2), str(circle.radius).pad_decimals(2))
	# 2. Draw the live preview if the player is currently expanding a circle
	if current_state == State.DRAWING:
		var current_mouse = get_local_mouse_position()
		
		# Draw a small UI center crosshair/dot
		draw_circle(center_point, 3.0, Color.WHITE)
		# Draw the live expanding outline
		draw_circle_outline(center_point, preview_radius, Color(1, 1, 1, 0.6), 1.5)
		# Draw a thin connector line
		draw_line(center_point, current_mouse, Color(1, 1, 1, 0.3), 1.0)
		# Draw radius display
		draw_string(font, ((center_point + current_mouse) / 2), str(preview_radius).pad_decimals(2))

# Helper function because Godot's built-in draw_circle() fills the entire shape
func draw_circle_outline(center: Vector2, radius: float, color: Color, width: float) -> void:
	if radius <= 0:
		return
	# draw_arc arguments: center, radius, start_angle, end_angle, point_count, color, width, antialiasing
	draw_arc(center, radius, 0, TAU, 64, color, width, true)

func clear_map() -> void:
	print("clearing map")
	
	placed_circles = []
	current_state = State.WAITING
	queue_redraw()
