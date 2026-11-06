extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Attach this script to your Area3D or StaticBody3D node (Godot 4)
func _on_input_event(_camera: Node, event: InputEvent, click_position: Vector3, _click_normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var next_scene = load("res://Assets/Scenes/map_ui.tscn")
		get_tree().change_scene_to_packed(next_scene)
		print("Clicked object at world position: ", click_position)
