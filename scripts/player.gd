extends CharacterBody3D


@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var hand = $Head/Camera3D/hand
@onready var interaction = $Head/Camera3D/interaction
@onready var joint = $Head/Camera3D/Generic6DOFJoint3D
@onready var staticbody = $Head/Camera3D/StaticBody3D

var speed
const WALK_SPEED = 4.0
const SPRINT_SPEED = 6.0
const CROUCH_SPEED = 3
const JUMP_VELOCITY = 4.8
const FRICTION = 10

var gravity = 9.8

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

#fov variables
const BASE_FOV = 80.0
const FOV_CHANGE = 1.5

#Variables for pickup
var picked_object
@export var pull_power = 8
var rotation_power = 0.05
var locked = false

func pick_object():
	var collider = interaction.get_collider()
	if collider != null and collider is RigidBody3D:
		picked_object = collider
		joint.set_node_b(picked_object.get_path())

func remove_object():
	picked_object = null
	joint.set_node_b(joint.get_path())


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle Sprint and crouch.
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	elif Input.is_action_pressed("crouch"):
		speed = CROUCH_SPEED
		self.set_scale(lerp(get_scale(), Vector3(1,0.5,1), 0.1))
	else:
		self.set_scale(lerp(get_scale(), Vector3(1,1,1), 0.1))
		speed = WALK_SPEED
	
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis *  Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * FRICTION)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * FRICTION)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# Head bob
	t_bob += delta * (sqrt(pow(velocity.x, 2) + pow(velocity.z, 2))) * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp((sqrt(pow(velocity.x, 2) + pow(velocity.z, 2))), 5, SPRINT_SPEED*2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	
	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
