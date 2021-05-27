extends KinematicBody2D

# Constants
const MAX_SPEED: int = 500
const MAX_FALL: int = 750
const ACCELERATION: int = 40
const GRAVITY: int = 20
const JUMP: int = 500
const IDLE_MIN: int = 20
const FLOOR_DETECT_DISTANCE: int = 10

# Globals
var motion: Vector2 = Vector2.ZERO
var animstate: String = "Idle"
var airstate: bool = false
var in_jump: bool = false

# Hooks
onready var camera := $PlayerCamera
onready var hitbox := $PhysicsHitbox
onready var texture := $Visual/Texture
onready var animation := $Visual/AnimationPlayer
onready var platform_detector := $PlatformDetector


func _input(event: InputEvent) -> void:
	# Flip left
	if event.is_action_pressed("move_left"):
		texture.flip_h = true

	# Flip right
	if event.is_action_pressed("move_right"):
		texture.flip_h = false


# Run on every tick (60 ticks/sec)
func _physics_process(_delta: float) -> void:
	_movement()
	_send_player_data_packet()


# Send all the player data in a single packet
func _send_player_data_packet() -> void:
	Globals.send_P2P_Packet(
		"all",
		{
			"player": Globals.STEAM_ID,
			"position": global_position,
			"anim": animstate,
			"flip": texture.flip_h
		}
	)


func _jump() -> void:
	# Main jump logic
	if Input.is_action_pressed("jump") and is_on_floor():
		motion.y -= JUMP
		in_jump = true
	elif is_on_floor():
		in_jump = false

	# Jump interruption logic
	if Input.is_action_just_released("jump") and in_jump:
		# Don't set this to 0
		motion.y *= 0.6


# Movement fix idk
func _move_and_snap() -> void:
	var snap_vector: Vector2 = Vector2.ZERO

	if motion.y == 0.0:
		snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE

	var is_on_platform: bool = platform_detector.is_colliding()

	motion = move_and_slide_with_snap(
		motion, snap_vector, Vector2.UP, not is_on_platform, 4, 0.8, false
	)


func _movement() -> void:
	if not is_on_floor():
		motion.y += GRAVITY

	# Don't... I know.
	_jump()

	if motion.y >= MAX_FALL:
		motion.y = MAX_FALL

	motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)

	var horizontal_direction: float = (
		Input.get_action_strength("move_right")
		- Input.get_action_strength("move_left")
	)

	# Main horizontal movement logic
	if horizontal_direction != 0:
		motion.x += ACCELERATION * horizontal_direction
	else:
		motion.x = lerp(motion.x, 0, 0.2)

	# Yes, I know that this is not the best method
	_handle_animations(horizontal_direction)

	# Movement fix call idk pasted it
	_move_and_snap()


func _handle_animations(horizontal_movement: float) -> void:
	# True if there is no input movement.
	var no_horizontal_input: bool = not horizontal_movement

	# On-ground animations
	if is_on_floor():
		# Reset the air-state
		airstate = false

		var idle: String = "Idle" + Globals.character_colour
		var run: String = "Run" + Globals.character_colour
		animstate = idle if no_horizontal_input else run

		# Playing the animation separately to avoid repetation.
		animation.play(animstate)

	# In-air animations
	elif not airstate and not platform_detector.is_colliding():
		# Set air-state to true, to avoid repeated animations.
		airstate = true

		var jump: String = "Jump" + Globals.character_colour
		var run_jump: String = "RunJump" + Globals.character_colour
		animstate = jump if no_horizontal_input else run_jump

		# Playing the animation separately to avoid repetation.
		animation.play(animstate)


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	# Play Jump anim after RunJump for falling effect.
	if anim_name == "RunJump" + Globals.character_colour:
		animation.play("Jump" + Globals.character_colour)
