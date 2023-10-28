extends Node3D

const PUSH_PULL_INCREMENT = 0.25
const MAX_SELECT_DISTANCE = 100.0

const BRICK_INSTANCE_SCENE = preload("res://scenes/brick_instance.tscn")
const BRICK_TYPES: Array[BrickDefinition] = [
	preload("res://resources/bricks/brick_1x1.tres"),
	preload("res://resources/bricks/brick_2x1.tres"),
	preload("res://resources/bricks/plate_2x1.tres"),
	preload("res://resources/bricks/plate_4x1.tres"),
	preload("res://resources/bricks/plate_4x2.tres")
]
const COLORS = [
	preload("res://resources/materials/blue.tres"),
	preload("res://resources/materials/red.tres"),
	preload("res://resources/materials/green.tres"),
	preload("res://resources/materials/yellow.tres"),
]
var Constants = load("res://util/constants.gd")

var selected_brick: BrickInstance = null
var selected_tree: BrickInstance = null

# Called when the node enters the scene tree for the first time.
func _ready():
	var brick1 = BRICK_INSTANCE_SCENE.instantiate().init(BRICK_TYPES.pick_random()).paint(COLORS.pick_random())
	var brick2 = BRICK_INSTANCE_SCENE.instantiate().init(BRICK_TYPES.pick_random()).paint(COLORS.pick_random())
	var brick3 = BRICK_INSTANCE_SCENE.instantiate().init(BRICK_TYPES.pick_random()).paint(COLORS.pick_random())
	var brick4 = BRICK_INSTANCE_SCENE.instantiate().init(BRICK_TYPES.pick_random()).paint(COLORS.pick_random())
	for brick in [brick1, brick2, brick3, brick4]:
		add_child(brick)
		brick.connect("can_connect_brick", _on_can_connect_brick)
	brick2.global_position = Vector3(3.0, 0.0, 0.0)
	brick3.global_position = Vector3(-3.0, 0.0, 0.0)
	brick4.global_position = Vector3(-1.0, 0.0, 2.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	if selected_tree != null:
		var mouse_position = get_viewport().get_mouse_position()
		
		var distance_change = 0.0
		if Input.is_action_just_pressed("push"):
			distance_change = PUSH_PULL_INCREMENT
		elif Input.is_action_just_pressed("pull"):
			distance_change = -PUSH_PULL_INCREMENT
			
		move_selected_tree(mouse_position, distance_change)
	pass

func _input(event):
	if event.is_action_pressed("rotate"):
		rotate_selected()
	if event.is_action_pressed("detach"):
		detach_selected()
	if event.is_action_pressed("select"):
		handle_select()

func _on_can_connect_brick(stud_brick: BrickInstance, anti_stud_brick: BrickInstance, stud: Stud, anti_stud: AntiStud):
	#anti_stud_brick.connect_to_stud(stud_brick, stud, anti_stud)
	#try_release_selected_brick()
	pass

func try_release_selected():
	try_connect_selected()
	selected_brick = null
	selected_tree = null

func try_connect_selected():
	if selected_brick == null: return
	
	selected_brick.try_connect_all()

func move_selected_tree(mouse_position: Vector2, distance_change: float):
	# Get current distance from camera
	var distance = clampf(abs(selected_brick.global_position - $Camera3D.global_position).length() + distance_change, 2.0, 20.0)
	
	# Translate viewport position to vector from camera
	var direction = $Camera3D.project_ray_normal(mouse_position)
	
	# Move the object
	var selected_offset = selected_tree.global_position - selected_brick.global_position
	selected_tree.global_position = $Camera3D.global_position + selected_offset + direction * distance
	
func rotate_selected():
	if selected_tree != null:
		selected_tree.rotate_brick(PI / 2.0)

func detach_selected():
	if selected_brick != null:
		selected_brick.unparent()
		selected_tree = selected_brick

func handle_select():
	if selected_brick != null:
		try_release_selected()
		return
	
	# Otherwise find the brick under the cursor and pick it up
	var mouse_position = get_viewport().get_mouse_position()
	var direction = $Camera3D.project_ray_normal(mouse_position)
	var cast_point = $Camera3D.global_position + direction * MAX_SELECT_DISTANCE
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create($Camera3D.global_position, cast_point)
	query.collision_mask = Constants.COLLISION_LAYER_BRICKS
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	if result.is_empty(): return
	
	var collider = result['collider'] as Node3D
	if not collider.get_parent() is BrickInstance: return
	
	var brick = collider.get_parent() as BrickInstance
	selected_brick = brick
	selected_tree = brick.get_root()
	
