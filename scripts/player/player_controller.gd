extends CharacterBody3D

## Player scene foundation for Deadlock Outbreak's first-person perspective.
## Movement, mouse look, interaction, and combat are intentionally deferred to
## their separately authorized subtasks.

@export_range(1.4, 1.8, 0.01) var eye_height: float = 1.62

@onready var eye_pivot: Node3D = $EyePivot
@onready var view_camera: Camera3D = $EyePivot/Camera3D


func _ready() -> void:
	eye_pivot.position.y = eye_height
	view_camera.current = true
