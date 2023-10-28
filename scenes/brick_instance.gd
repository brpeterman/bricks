extends Node3D
class_name BrickInstance

signal can_connect_brick(stud_brick: BrickInstance, anti_stud_brick: BrickInstance, stud: Stud, anti_stud: AntiStud)
signal brick_selected(brick: BrickInstance)

var brick_definition: Brick
var studs: Array[Stud]
var anti_studs: Array[AntiStud]
var intersecting = false
var potential_connections = {}

var stud_scene = preload("res://scenes/stud.tscn")
var anti_stud_scene = preload("res://scenes/anti_stud.tscn")

func init(brick_def: Brick) -> BrickInstance: #TODO: Accept a material to apply to meshes
	brick_definition = brick_def
	return self

func try_connect_all():
	# Find first antistud with a potential connection
	var first_stud = null
	var first_anti_stud = null
	for anti_stud in anti_studs:
		first_stud = potential_connections.get(anti_stud)
		if first_stud != null:
			first_anti_stud = anti_stud
			break
	if first_stud == null: return
	
	# Align the brick so that connection is flush
	var offset = first_stud.global_position - first_anti_stud.global_position
	position += offset
	
	# Connect 'em all up
	complete_potential_connections()
	
	# Parent to the first stud's brick
	var parent_brick = first_stud.get_parent() as BrickInstance
	reparent(parent_brick)
	
func unparent():
	for anti_stud in anti_studs:
		anti_stud.unlink()
	
	var current_scene = get_tree().current_scene
	if get_parent() != current_scene:
		reparent(current_scene)

func rotate_brick(amount: float):
	rotation.y += amount

func complete_potential_connections():
	for anti_stud in potential_connections:
		var stud = potential_connections.get(anti_stud)
		if stud != null:
			stud.link(anti_stud)
			anti_stud.link(stud)
	potential_connections = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Create mesh instances, collision, and studs
	var brick_mesh = MeshInstance3D.new()
	brick_mesh.mesh = brick_definition.mesh
	add_child(brick_mesh)
	
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = brick_definition.collision_mesh.create_trimesh_shape()
	var collision_object = Area3D.new()
	collision_object.add_child(collision_shape)
	add_child(collision_object)
	
	collision_object.connect("input_event", _on_input_event)
	
	for stud_def in brick_definition.studs:
		var stud = stud_scene.instantiate()
		stud.transform = stud_def
		studs.append(stud)
		add_child(stud)
	for anti_stud_def in brick_definition.anti_studs:
		var anti_stud = anti_stud_scene.instantiate()
		anti_stud.transform = anti_stud_def
		anti_studs.append(anti_stud)
		add_child(anti_stud)
	
	for anti_stud in anti_studs:
		anti_stud.connect("can_connect", _on_can_connect)
		anti_stud.connect("can_not_connect", _on_can_not_connect)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_can_connect(stud: Stud, anti_stud: AntiStud):
	if intersecting: return
	
	potential_connections[anti_stud] = stud
	#can_connect_brick.emit(self, anti_stud.get_parent_node_3d() as BrickInstance, stud, anti_stud)
	
func _on_can_not_connect(anti_stud: AntiStud):
	potential_connections[anti_stud] = null

func _on_input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		print("Selected a brick")
		brick_selected.emit(self)
