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
const FLOOR_DETECT_DISTANCE: int = 10

# ---
# Movement variables
# ---

var motion: Vector2 = Vector2.ZERO
var animstate: String = "Idle"
var airstate: bool = false
var in_jump: bool = false

# ---
# Node hooks
# ---

onready var camera := $PlayerCamera
onready var hitbox := $PhysicsHitbox
onready var texture := $Visual/Texture
onready var animation := $Visual/AnimationPlayer
onready var platform_detector := $PlatformDetector

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



func _physics_process(_delta: float) -> void:
	_movement()
	_send_player_data_packet()


# ---
# Self-made funtions
# ---


func _send_player_data_packet() -> void:
	# Player data is the following:
	# 0 = steam_id, 1 = pos, 2 = animstate
	# TODO: Implement animstates.
	Globals.send_P2P_Packet(
		"all", {"player": Globals.STEAM_ID, "position": global_position, "anim": animstate}
	)


func _jump() -> void:
	# When released, the jump damping logic should be played.
	if Input.is_action_just_released("jump") and in_jump:
		# Add the jump force const to the jump amount.
		motion.y *= 0.6
	
	# TODO: Double jump!!!
	# Execute jump logic, when "jump" is pressed and is on the ground.
	if Input.is_action_pressed("jump") and is_on_floor():

		motion.y -= JUMP # Apply jump force to the vertical axis to "jump".
		in_jump = true # Set the jump state to true, so no double jump yet.

	elif is_on_floor(): # When hitting the ground after a jump...
		in_jump = false # Reset the jump state.

# This is to fix the movement issues, like getting stuck to ceilings.
func _move_and_snap() -> void:

	var snap_vector: Vector2 = Vector2.ZERO # Declare the fixed movement vector.

	if motion.y == 0.0: 										# If there is no vertical movement...
		snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE 	# ...stick to the ground.

	var is_on_platform: bool = platform_detector.is_colliding() # Check if touching the ground.

	# Apply the fixed movement to the current movement vector.
	motion = move_and_slide_with_snap(
		motion, snap_vector, Vector2.UP, not is_on_platform, 4, 0.8, false
	)


func _movement() -> void:
	# Gravity logic
	if not is_on_floor(): # When the player is "in the air"...
		motion.y += GRAVITY # Apply gravity to them.
	
	_jump() # All the jump logic in one function.

	if motion.y >= MAX_FALL: # If the maximum falling speed is reached...
		motion.y = MAX_FALL # Limit it to the max falling speed.

	# Clamp the x movement of the player, basically limiting.
	motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)

	# Get the horizontal direction, by getting the difference of the two
	# X axis inputs. More important for controllers, but hey...
	var horizontal_direction: float = (
		Input.get_action_strength("move_right")
		- Input.get_action_strength("move_left")
	)

	if horizontal_direction != 0: # Check if any x axis inputs are pressed...
		# Apply acceleration to the horizontal direction value,
		# add this multiplied value to the x axis of the motion vec,
		# acceleration is just adding a value gradually to reach max speed,
		# when it's reached it won't go faster, limited later on in the code.
		motion.x += ACCELERATION * horizontal_direction

	else: # If there are no buttons pressed...
		motion.x = lerp(motion.x, 0, 0.2) # *Smoothly* set the player to null speed.

	_handle_animations() # Depending on what state the player is, do animation.

	_move_and_snap() # Call the movement fix, check on the function.


func _handle_animations() -> void:
	var is_standing: bool = motion.x >= -IDLE_MIN && motion.x <= IDLE_MIN
	
	if is_on_floor():
		airstate = false
	
	# Set the idle animation, if no motion is being used.
	# Call the idle, if the speed is low enough, since it's a lerping value.
	# ... and well... if the player is on the ground?
	# Also set the colour by the player's lobby colour.
	if is_standing and is_on_floor():
		animation.play("Idle" + Globals.character_colour)
		animstate = "Idle" + Globals.character_colour
		return # We'll talk about this later...

	# If the player is in movement, and is on the ground play the running anim.
	# Also set the colour like earlier.
	if is_on_floor():
		animation.play("Run" + Globals.character_colour)
		animstate = "Run" + Globals.character_colour
		return
	elif not is_standing and not airstate:
		animation.play("RunJump" + Globals.character_colour)
		animstate = "RunJump" + Globals.character_colour
	elif not airstate:
		animation.play("Jump" + Globals.character_colour)
		animstate = "Jump" + Globals.character_colour

	airstate = true


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "RunJump" + Globals.character_colour:
		animation.play("Jump" + Globals.character_colour)
