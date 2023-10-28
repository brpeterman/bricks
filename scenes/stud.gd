extends Node3D
class_name Stud

var linked_to: AntiStud = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_detection_area_area_entered(area: Area3D):
	if is_linked(): return
	if not area.get_parent() is AntiStud: return
	
	print("Can connect stud and anti-stud")
	var anti_stud = area.get_parent() as AntiStud
	if anti_stud.is_linked(): return
	
	anti_stud.can_connect_to(self)

func _on_detection_area_area_exited(area):
	if is_linked(): return
	if not area.get_parent() is AntiStud: return
	
	print("Anti-stud left area")
	var anti_stud = area.get_parent() as AntiStud
	if anti_stud.is_linked(): return
	
	anti_stud.can_not_connect_any()

func link(anti_stud: AntiStud):
	linked_to = anti_stud

func unlink():
	linked_to = null

func is_linked() -> bool:
	return linked_to != null
