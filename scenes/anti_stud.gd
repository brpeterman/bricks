extends Node3D
class_name AntiStud

signal can_connect(stud: Stud, anti_stud: AntiStud)
signal can_not_connect(anti_stud: AntiStud)

var linked_to: Stud = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func link(stud: Stud):
	linked_to = stud

func unlink():
	if not is_linked(): return
	
	linked_to.unlink()
	linked_to = null

func is_linked() -> bool:
	return linked_to != null

func can_connect_to(stud: Stud):
	can_connect.emit(stud, self)

func can_not_connect_any():
	can_not_connect.emit(self)
