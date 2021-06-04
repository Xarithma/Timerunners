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
var in_climb: bool = false
var can_climb: bool = false

# Hooks
onready var camera := $PlayerCamera
onready var physics_hitbox := $PhysicsHitbox
onready var logic_area := $LogicHitArea
onready var texture := $Visual/Texture
onready var animation := $Visual/AnimationPlayer
onready var platform_detector := $PlatformDetector

# Connects
onready var animation_connect = animation.connect("animation_finished", self, "_anim_finished")
onready var logic_body_entered = logic_area.connect("body_entered", self, "_on_collide")
onready var logic_body_exited = logic_area.connect("body_exited", self, "_on_uncollide")


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


func _climb() -> void:
	if not in_climb:
		return
	
	if Input.is_action_just_pressed("jump"):
		can_climb = false
		in_climb = false
		motion.y -= JUMP


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
	# Get the horizontal direction by input strenght
	var horizontal_direction: float = (
		Input.get_action_strength("move_right")
		- Input.get_action_strength("move_left")
	)

	# All horizontal movement logic
	_do_horizontal_motion(horizontal_direction)

	# All vertical movement logic
	_do_vertical_motion()

	# All jump logic
	_jump()

	# All climbing logic
	_climb()

	# Yes, I know, I'm increasing the time for nothing
	_handle_climb_cooldown()

	# Yes, I know that this is not the best method
	_handle_animations(horizontal_direction)

	# Movement fix call idk pasted it
	_move_and_snap()


func _do_horizontal_motion(horizontal_direction: float) -> void:
	# Limit the horizontal motion to the max speed
	motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)

	# Main horizontal movement logic
	if horizontal_direction != 0:
		motion.x += ACCELERATION * horizontal_direction
	else:
		motion.x = lerp(motion.x, 0, 0.2)


func _do_vertical_motion() -> void:
	if is_on_floor() or in_climb:
		return

	# Perfection
	motion.y += GRAVITY

	# Don't fall too hard
	if motion.y >= MAX_FALL:
		motion.y = MAX_FALL


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


func _handle_climb_cooldown() -> void:
	# Don't run if can climb
	if can_climb:
		return

	# After a short cooldown, can cooldown again
	yield(get_tree().create_timer(0.1), "timeout")
	can_climb = true


func _anim_finished(anim_name: String) -> void:
	# Play Jump anim after RunJump for falling effect.
	if anim_name == "RunJump" + Globals.character_colour:
		animation.play("Jump" + Globals.character_colour)


func _on_collide(body: Node) -> void:
	if body.name == "Climb" and can_climb:
		motion.y = 0
		in_climb = true


func _on_uncollide(body: Node) -> void:
	if body.name == "Climb":
		in_climb = false
		can_climb = true