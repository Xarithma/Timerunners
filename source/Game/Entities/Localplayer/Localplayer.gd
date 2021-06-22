extends KinematicBody2D

const MAX_SPEED: int = 500
const MAX_FALL: int = 750
const ACCELERATION: int = 40
const GRAVITY: int = 20
const JUMP: int = 300
const IDLE_MIN: int = 20
const FLOOR_DETECT_DISTANCE: int = 10

# -> Movement
var movement: Vector2 = Vector2.ZERO
var animation_name: String = "Idle"
var stop_anim_loop: bool = false

var IN_JUMP: bool = false
var IN_CLIMB: bool = false
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
	_move_player()
	_send_player_data_packet()


func _send_player_data_packet() -> void:
	Globals.send_P2P_Packet(
		"all",
		{
			"message": "player_data",
			"player": Globals.STEAM_ID,
			"position": global_position,
			"anim": animation_name,
			"flip": texture.flip_h
		}
	)


func _handle_horizontal_movement(horizontal_direction: float) -> void:
	movement.x = clamp(movement.x, -MAX_SPEED, MAX_SPEED)

	if horizontal_direction != 0:
		movement.x += ACCELERATION * horizontal_direction
	else:
		movement.x = lerp(movement.x, 0, 0.2)

	if IN_CLIMB:
		movement.x *= 0.8


func _handle_falling() -> void:
	if is_on_floor():
		return

	if IN_CLIMB:
		return

	movement.y += GRAVITY

	if movement.y >= MAX_FALL:
		movement.y = MAX_FALL


func _apply_climb_cooldown() -> void:
	yield(get_tree().create_timer(0.1), "timeout")
	can_climb = true


func _jump_from_climb() -> void:
	if not Input.is_action_just_pressed("jump"):
		return

	# if not can_climb:
	# 	return

	movement.y -= JUMP * 0.9
	can_climb = false
	IN_CLIMB = false

	_apply_climb_cooldown()


func _handle_jumping() -> void:
	if Input.is_action_pressed("jump") and is_on_floor():
		movement.y -= JUMP
		IN_JUMP = true
	elif is_on_floor():
		IN_JUMP = false

	if Input.is_action_just_released("jump") and IN_JUMP:
		movement.y *= 0.6

	_jump_from_climb()


func _set_on_ground_animation(horizontal_direction: float) -> void:
	var idle_anim_name: String = "Idle" + Globals.player_color
	var run_anim_name: String = "Run" + Globals.player_color
	animation_name = idle_anim_name if not horizontal_direction else run_anim_name


func _set_in_air_animation(horizontal_direction: float) -> void:
	var jump_anim_name: String = "Jump" + Globals.player_color
	var run_jump_anim_name: String = "RunJump" + Globals.player_color
	animation_name = jump_anim_name if not horizontal_direction else run_jump_anim_name


func _handle_animations(horizontal_direction: float) -> void:
	if is_on_floor():
		_set_on_ground_animation(horizontal_direction)
		stop_anim_loop = false
		animation.play(animation_name)
	elif not stop_anim_loop:
		_set_in_air_animation(horizontal_direction)
		stop_anim_loop = true
		animation.play(animation_name)


func _fix_movement() -> void:
	# ! Not done by me, don't know why it works, it just does
	var snap_vector: Vector2 = Vector2.ZERO

	if movement.y == 0.0:
		snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE

	var is_on_platform: bool = platform_detector.is_colliding()

	movement = move_and_slide_with_snap(
		movement, snap_vector, Vector2.UP, not is_on_platform, 4, 0.8, false
	)


func _move_player() -> void:
	var horizontal_direction: float = (
		Input.get_action_strength("move_right")
		- Input.get_action_strength("move_left")
	)

	_handle_horizontal_movement(horizontal_direction)
	_handle_falling()
	_handle_jumping()
	_fix_movement()

	_handle_animations(horizontal_direction)


func _start_climbing() -> void:
	if not can_climb:
		return

	movement.y = 0
	IN_CLIMB = true


func _stop_climbing() -> void:
	IN_CLIMB = false
	can_climb = true


# * -> Connects


func _anim_finished(last_animation: String) -> void:
	if last_animation == "RunJump" + Globals.player_color:
		animation.play("Jump" + Globals.player_color)


func _on_collide(body: Node) -> void:
	if body.name == "Climb":
		_start_climbing()


func _on_uncollide(body: Node) -> void:
	if body.name == "Climb":
		_stop_climbing()
