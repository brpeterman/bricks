extends Node3D
class_name BrickInstance

signal can_connect_brick(stud_brick: BrickInstance, anti_stud_brick: BrickInstance, stud: Stud, anti_stud: AntiStud)
signal brick_selected(brick: BrickInstance)

var Constants = load("res://util/constants.gd")

var brick_definition: BrickDefinition
var material: BaseMaterial3D
var studs: Array[Stud]
var anti_studs: Array[AntiStud]
var intersecting = false
var potential_connections = {}
var rotating = false

var stud_scene = preload("res://scenes/stud.tscn")
var anti_stud_scene = preload("res://scenes/anti_stud.tscn")

func init(brick_def: BrickDefinition) -> BrickInstance: #TODO: Accept a material to apply to meshes
	brick_definition = brick_def
	return self

func paint(new_material: BaseMaterial3D):
	material = new_material
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
	get_root().position += offset
	
	# Parent to the first stud's brick
	var parent_brick = first_stud.get_parent() as BrickInstance
	if get_root() != parent_brick.get_root():
		get_root().reparent(parent_brick)
	
	# Connect 'em all up
	complete_potential_connections()
	
func unparent():
	for anti_stud in anti_studs:
		anti_stud.unlink()
	
	var current_scene = get_tree().current_scene
	if get_parent() != current_scene:
		reparent(current_scene)

func rotate_brick(amount: float):
	if rotating: return
	
	rotating = true
	var tween = create_tween()
	var new_rotation = rotation + Vector3(0, amount, 0)
	tween.tween_property(self, "rotation", new_rotation, 0.2)
	tween.tween_callback(func(): rotating = false)

func complete_potential_connections():
	for anti_stud in potential_connections:
		var stud = potential_connections.get(anti_stud)
		if stud != null:
			stud.link(anti_stud)
			anti_stud.link(stud)
			var stud_brick = stud.get_parent() as BrickInstance
			if stud_brick.get_root() != get_root():
				var offset = anti_stud.global_position - stud.global_position
				stud_brick.get_root().global_position += offset
				stud_brick.get_root().reparent(self)
	potential_connections = {}

func get_root() -> BrickInstance:
	var parent = self
	while parent.get_parent() is BrickInstance:
		parent = parent.get_parent()
	return parent

# Called when the node enters the scene tree for the first time.
func _ready():
	# Create mesh instances, collision, and studs
	var brick_mesh = MeshInstance3D.new()
	brick_mesh.mesh = brick_definition.mesh
	if material != null:
		brick_mesh.material_override = material
	add_child(brick_mesh)
	
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = brick_definition.collision_mesh.create_trimesh_shape()
	var collision_object = Area3D.new()
	collision_object.add_child(collision_shape)
	collision_object.collision_layer = Constants.COLLISION_LAYER_BRICKS
	collision_object.collision_mask = Constants.COLLISION_LAYER_WORLD | Constants.COLLISION_LAYER_BRICKS
	add_child(collision_object)
	
	for stud_def in brick_definition.studs:
		var stud = stud_scene.instantiate() as Stud
		if material != null:
			stud.paint(material)
		stud.transform = stud_def
		studs.append(stud)
		add_child(stud)
	for anti_stud_def in brick_definition.anti_studs:
		var anti_stud = anti_stud_scene.instantiate() as AntiStud
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
	
func _on_can_not_connect(anti_stud: AntiStud):
	potential_connections[anti_stud] = null
