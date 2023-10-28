extends Node3D

const PUSH_PULL_INCREMENT = 0.5

const BRICK_INSTANCE_SCENE = preload("res://scenes/brick_instance.tscn")
const BRICK_DEF_1x1 = preload("res://resources/bricks/brick_1x1.tres")
const BRICK_DEF_2x1 = preload("res://resources/bricks/brick_2x1.tres")
var selected_brick: BrickInstance = null
var selected_tree: BrickInstance = null

# Called when the node enters the scene tree for the first time.
func _ready():
	var brick1 = BRICK_INSTANCE_SCENE.instantiate().init(BRICK_DEF_1x1)
	var brick2 = BRICK_INSTANCE_SCENE.instantiate().init(BRICK_DEF_2x1)
	var brick3 = BRICK_INSTANCE_SCENE.instantiate().init(BRICK_DEF_2x1)
	for brick in [brick1, brick2, brick3]:
		add_child(brick)
		brick.connect("can_connect_brick", _on_can_connect_brick)
		brick.connect("brick_selected", _on_brick_selected)
	brick2.global_position = Vector3(3.0, 0.0, 0.0)
	brick3.global_position = Vector3(-3.0, 0.0, 0.0)

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

func _on_can_connect_brick(stud_brick: BrickInstance, anti_stud_brick: BrickInstance, stud: Stud, anti_stud: AntiStud):
	#anti_stud_brick.connect_to_stud(stud_brick, stud, anti_stud)
	#try_release_selected_brick()
	pass

func _on_brick_selected(brick: BrickInstance):
	if selected_brick != null: return try_release_selected()
	
	selected_brick = brick
	selected_tree = find_root_brick(brick)

func find_root_brick(brick: BrickInstance) -> BrickInstance:
	var root = brick
	while root.get_parent() is BrickInstance:
		root = root.get_parent()
	return root

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
