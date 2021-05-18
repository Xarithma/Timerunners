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

# ---
# Godot functions
# ---


func _ready() -> void:
	camera.current = true


func _input(event: InputEvent) -> void:
	pass


# ---
# Self-made funtions
# ---


func _send_player_data_packet() -> void:
	pass


func _movement(delta: float) -> void:
	velocity.y += GRAVITY


