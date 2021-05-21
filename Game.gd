extends Node2D

# Load the network player to be added.
const network_player: PackedScene = preload("res://NetworkPlayer.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for member in Globals.LOBBY_MEMBERS:
		if member['steam_id'] == Globals.STEAM_ID:
			continue
		add_child(network_player.instance())
