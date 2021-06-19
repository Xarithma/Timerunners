extends KinematicBody2D

const MAX_SPEED: int = 500
const MAX_FALL: int = 750
const ACCELERATION: int = 40
const GRAVITY: int = 20
const JUMP: int = 500
const IDLE_MIN: int = 20
const FLOOR_DETECT_DISTANCE: int = 10

# -> Movement
var motion: Vector2 = Vector2.ZERO
var animstate: String = "Idle"
var airstate: bool = false
var in_jump: bool = false
var in_climb: bool = false
var can_climb: bool = false

# -> Hooks
onready var camera := $PlayerCamera
onready var physics_hitbox := $PhysicsHitbox
onready var logic_area := $LogicHitArea
onready var texture := $Visual/Texture
onready var animation := $Visual/AnimationPlayer
onready var platform_detector := $PlatformDetector

# -> Connects
onready var animation_connect = animation.connect("animation_finished", self, "_anim_finished")
onready var logic_body_entered = logic_area.connect("body_entered", self, "_on_collide")
onready var logic_body_exited = logic_area.connect("body_exited", self, "_on_uncollide")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		texture.flip_h = true

	if event.is_action_pressed("move_right"):
		texture.flip_h = false


func _physics_process(_delta: float) -> void:
	_movement()
	_send_player_data_packet()


func _send_player_data_packet() -> void:
	Globals.send_P2P_Packet(
		"all",
		{
			"message": "player_data",
			"player": Globals.STEAM_ID,
			"position": global_position,
			"anim": animstate,
			"flip": texture.flip_h
		}
	)


func _movement() -> void:
	# * -> Horizontal movement
	var horizontal_direction: float = (
		Input.get_action_strength("move_right")
		- Input.get_action_strength("move_left")
	)

	motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)

	if horizontal_direction != 0:
		motion.x += ACCELERATION * horizontal_direction
	else:
		motion.x = lerp(motion.x, 0, 0.2)

	# * -> Vertical motion
	if not is_on_floor() and not in_climb:
		motion.y += GRAVITY

		if motion.y >= MAX_FALL:
			motion.y = MAX_FALL

	# * -> Jump
	if Input.is_action_pressed("jump") and is_on_floor():
		motion.y -= JUMP
		in_jump = true
	elif is_on_floor():
		in_jump = false

	if Input.is_action_just_released("jump") and in_jump:
		motion.y *= 0.6

	# * -> Climb
	if Input.is_action_just_pressed("jump") and in_climb:
		can_climb = false
		in_climb = false
		motion.y -= JUMP

	if not can_climb:
		yield(get_tree().create_timer(0.1), "timeout")
		can_climb = true

	# * -> Animations
	var no_horizontal_input: bool = not horizontal_direction

	if is_on_floor():
		airstate = false

		var idle: String = "Idle" + Globals.player_color
		var run: String = "Run" + Globals.player_color
		animstate = idle if no_horizontal_input else run

		animation.play(animstate)

	elif not airstate and not platform_detector.is_colliding():
		airstate = true

		var jump: String = "Jump" + Globals.player_color
		var run_jump: String = "RunJump" + Globals.player_color
		animstate = jump if no_horizontal_input else run_jump

		animation.play(animstate)

	# * -> Movement fix
	# ! Not done by me, don't know why it works, it just does
	var snap_vector: Vector2 = Vector2.ZERO

	if motion.y == 0.0:
		snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE

	var is_on_platform: bool = platform_detector.is_colliding()

	motion = move_and_slide_with_snap(
		motion, snap_vector, Vector2.UP, not is_on_platform, 4, 0.8, false
	)


# VVV Connects VVV


func _anim_finished(anim_name: String) -> void:
	if anim_name == "RunJump" + Globals.player_color:
		animation.play("Jump" + Globals.player_color)


func _on_collide(body: Node) -> void:
	if body.name == "Climb" and can_climb:
		motion.y = 0
		in_climb = true


func _on_uncollide(body: Node) -> void:
	if body.name == "Climb":
		in_climb = false
		can_climb = true
