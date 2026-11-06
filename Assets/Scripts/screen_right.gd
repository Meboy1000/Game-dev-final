extends MeshInstance3D

@export var camera: Camera3D
var basepos 
var baserot
var looking = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	basepos = position
	baserot = rotation


func _input(InputEvent) -> void:
	if Input.is_action_just_pressed("togglemap"):
		if looking:
			print("not looking at the map")
			self.position = basepos
			self.rotation = baserot
			looking = false
		else:
			print("looking at the map")
			var targpos = camera.position
			targpos.z -= 3
			global_position = targpos
			rotation.y = 0
			looking = true
