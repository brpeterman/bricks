extends Node3D
class_name Stud

var linked_to: AntiStud = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func link(anti_stud: AntiStud):
	linked_to = anti_stud

func unlink():
	linked_to = null

func is_linked() -> bool:
	return linked_to != null
