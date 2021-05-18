extends KinematicBody2D

# ---
# Constants
# ---

const GRAVITY: int = 5
const MAX_SPEED: int = 150
const ACCELERATION: int = 50
const JUMP_HEIGHT: int = -200

# ---
# Movement variables
# ---

var velocity: Vector2 = Vector2.ZERO

# ---
# Node hooks
# ---

onready var camera := $PlayerCamera
onready var hitbox := $PhysicsHitbox
onready var texture := $Texture

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


# ---
# Self-made funtions
# ---


func _send_player_data_packet() -> void:
	pass


func _movement(delta: float) -> void:
	velocity.y += GRAVITY
