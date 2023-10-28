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

func aligned_with(stud: Stud) -> bool:
	var stud_direction = stud.global_basis.y.normalized()
	var anti_stud_direction = global_basis.y.normalized()
	var alignment = stud_direction.dot(anti_stud_direction)
	return alignment > 0.95

func _on_detection_area_area_entered(area: Area3D):
	if is_linked(): return
	if not area.get_parent() is Stud: return
	
	print("Can connect stud and anti-stud")
	var stud = area.get_parent() as Stud
	if stud.is_linked(): return
	if not aligned_with(stud): return
	
	can_connect.emit(stud, self)

func _on_detection_area_area_exited(area):
	if is_linked(): return
	if not area.get_parent() is Stud: return
	
	print("Stud left area")
	var stud = area.get_parent() as Stud
	if stud.is_linked(): return
	
	can_not_connect.emit(self)
