extends MeshInstance3D

@export var camera: Camera3D
@export var inputaction: String
var basepos 
var baserot
var looking = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	basepos = position
	baserot = rotation


func _input(_event) -> void:
	if Input.is_action_just_pressed(inputaction):
		if looking:
			print("not looking at the map")
			self.position = basepos
			self.rotation = baserot
			looking = false
			Screenlocks.release_lock(self)
		else:
			if Screenlocks.request_lock(self):
				print("looking at the map")
				var targpos = camera.position
				print(targpos)
				targpos.z -= 3
				print(targpos)
				position = targpos
				rotation.y = 0
				looking = true
