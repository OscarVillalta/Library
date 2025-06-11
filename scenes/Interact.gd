extends Camera3D

@onready var head = $".."
@onready var camera = $"."
@onready var hand = $hand
@onready var interaction = $interaction
@onready var joint = $Generic6DOFJoint3D
@onready var staticbody = $StaticBody3D

const SENSITIVITY = 0.004

#Variables for pickup
var picked_object
@export var pull_power = 200
var rotation_power = 0.1
var locked = false

func move_head(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(60))

func pick_object():
	
	var collider = interaction.get_collider()
	if collider != null and collider is RigidBody3D:
		picked_object = collider
		picked_object.look_at(camera.global_transform.origin)
		joint.set_node_b(picked_object.get_path())

func remove_object():
	picked_object = null
	joint.set_node_b(joint.get_path())
	
func rotate_object(event):
	
	if picked_object != null:
		if event is InputEventMouseMotion:
			staticbody.rotate_x(deg_to_rad(event.relative.y * rotation_power))
			staticbody.rotate_y(deg_to_rad(event.relative.x * rotation_power))
		print(staticbody.transform.basis)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if picked_object != null:
		var a = picked_object.global_transform.origin
		var b = hand.global_transform.origin
		
		picked_object.set_linear_velocity(Vector3.ZERO)
		
		picked_object.apply_central_force((b-a)*pull_power)

func _input(event: InputEvent) -> void:
	
	if !locked:
		move_head(event)
	else:
		rotate_object(event)
		
		if Input.is_action_just_pressed("wheel_up"):
			hand.transform.origin.z = clamp(hand.transform.origin.z - 0.1, -3, -1.0)
		
		if Input.is_action_just_pressed("wheel_down"):
			hand.transform.origin.z = clamp(hand.transform.origin.z + 0.1, -3, -0.5)
	
	if Input.is_action_just_pressed("left_click"):
		if picked_object == null:
			pick_object()
		else:
			remove_object()
			
	if Input.is_action_just_pressed("right_click"):
		if picked_object != null:
			locked = true
	
	if Input.is_action_just_released("right_click"):
		locked = false
	
	
