extends Node

# Steam vars
var OWNED: bool = false
var ONLINE: bool = false
var STEAM_ID: int = 0
var STEAM_USERNAME: String = ""

# Lobby vars
var DATA
var LOBBY_MEMBERS: Array = []
var LOBBY_INVITE_ARG: bool = false


func _ready() -> void:
	var INIT: Dictionary = Steam.steamInit()

	if INIT['status'] != 1:
		print("Failed to init Steam." + str(INIT['verbal']) + " Shutting down...")
		get_tree().quit()

	ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_USERNAME = Steam.getPersonaName()
	OWNED = Steam.isSubscribed()

	if not OWNED:
		print("User does not own this game.")
		get_tree().quit()


func _process(_delta: float) -> void:
	Steam.run_callbacks()
