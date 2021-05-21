extends KinematicBody2D

# ---
# Constants
# ---

const MAX_SPEED: int = 500
const MAX_FALL: int = 750
const ACCELERATION: int = 40
const GRAVITY: int = 20
const JUMP: int = 500
const IDLE_MIN: int = 20

# ---
# Movement variables
# ---

var motion: Vector2 = Vector2.ZERO
var animstate: String = "Idle"

# ---
# Node hooks
# ---

onready var camera := $PlayerCamera
onready var hitbox := $PhysicsHitbox
onready var texture := $Visual/Texture
onready var animation := $Visual/AnimationPlayer

# ---
# Godot functions
# ---


func _ready() -> void:
	camera.current = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		texture.flip_h = true

	if event.is_action_pressed("move_right"):
		texture.flip_h = false

	if event.is_action_pressed("jump") and is_on_floor():
		motion.y = -JUMP

func _physics_process(_delta: float) -> void:
	_movement()
	# _send_player_data_packet()


# ---
# Self-made funtions
# ---


func _send_player_data_packet() -> void:
	# Player data is the following:
	# 0 = steam_id, 1 = pos, 2 = animstate
	# TODO: Implement animstates.
	Globals.send_P2P_Packet("all", {"player": Globals.STEAM_ID, "position": global_position})


func _movement() -> void:
	if not is_on_floor():
		# Apply gravity to the vertical axis of the motion.
		motion.y += GRAVITY

	# LIMIT the amount of fall speed.
	if motion.y >= MAX_FALL:
		motion.y = MAX_FALL

	# Clamp the horizontal movement of the player.
	motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)

	# Get the horizontal direction with the input strength
	var horizontal_direction: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

	# Check if any button is pressed.
	if horizontal_direction != 0:
		# Get the horizontal motion from direction and acceleration.
		motion.x += ACCELERATION * horizontal_direction
	else:
		# Apply deceration if no input is pressed.
		motion.x = lerp(motion.x, 0, 0.2)

	if is_on_ceiling():
		motion.y += GRAVITY * 2

	# Set the player in motion with the set motion vector.
	var _move: Vector2 = move_and_slide(motion, Vector2.UP)

	# Lastly, let's call our animations to the movement.
	_handle_animations()


func _handle_animations() -> void:
	# Set the idle animation, if no motion is being used.
	if (motion.x >= -IDLE_MIN && motion.x <= IDLE_MIN) and is_on_floor():
		animation.play("IdleBlue")
		animstate = "Idle"
		return

	if is_on_floor():
		animation.play("RunBlue")
		animstate = "Run"
		return
