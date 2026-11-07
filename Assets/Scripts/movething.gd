extends Node3D

@export var rotation_speed: float = 3.0   # Speed of the actual rotation interpolation
@export var input_speed: float = 2.0      # How fast the target angle changes while holding the button

var target_rotation_y: float = 0.0

func _process(delta: float) -> void:
	# 1. Check if buttons are being held and change the target angle
	if Input.is_action_pressed("rotateleft"):
		target_rotation_y += input_speed * delta
	if Input.is_action_pressed("rotateright"):
		target_rotation_y -= input_speed * delta

	# 2. Smoothly interpolate current rotation to the target rotation
	rotation.y = lerp_angle(rotation.y, target_rotation_y, rotation_speed * delta)
