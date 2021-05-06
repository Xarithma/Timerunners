extends Node

# Steam vars
var OWNED: bool = false
var ONLINE: bool = false
var STEAM_ID: int = 0
var STEAM_USERNAME: String = ""

# Lobby vars
var LOBBY_DATA
var LOBBY_ID: int = 0
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

	var _tmp: int = Steam.connect("p2p_session_request", self, "_on_P2P_Session_Request")
	_tmp = Steam.connect("p2p_session_connect_fail", self, "_on_P2P_Session_Connect_Fail")


func _process(_delta: float) -> void:
	Steam.run_callbacks()
	_read_P2P_Packet()


# ---
# Self-made Functions
# ---


func _read_P2P_Packet() -> void:
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)

	# There is a packet
	if PACKET_SIZE > 0:
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, 0)

		if PACKET.empty():
			print("WARNING: read an empty packet with non-zero size!")

		# Get the remote user's ID
		var _PACKET_ID: String = str(PACKET.steamIDRemote)
		var PACKET_CODE: String = str(PACKET.data[0])

		# Make the packet data readable
		var READABLE = bytes2var(PACKET.data.subarray(1, PACKET_SIZE - 1))

		# Print the packet to output
		print("Packet: " + str(READABLE))
		print("Packet Code: " + PACKET_CODE)

		# Append logic here to deal with packet data
		if "startgame" in READABLE:
			var _load_game = get_tree().change_scene("res://Game.tscn")


func send_P2P_Packet(target: String, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var SEND_TYPE: int = 2
	var CHANNEL: int = 0

	# Create a data array to send the data through
	var _DATA: PoolByteArray
	_DATA.append(256)
	_DATA.append_array(var2bytes(packet_data))

	# If sending a packet to everyone
	if target == "all":
		# If there is more than one user, send packets
		if LOBBY_MEMBERS.size() > 1:
			# Loop through all members that aren't you
			for MEMBER in LOBBY_MEMBERS:
				if MEMBER['steam_id'] != STEAM_ID:
					var _tmp: int = Steam.sendP2PPacket(
						MEMBER['steam_id'], _DATA, SEND_TYPE, CHANNEL
					)

	# Else sending it to someone specific
	else:
		var _tmp: int = Steam.sendP2PPacket(int(target), _DATA, SEND_TYPE, CHANNEL)


func make_P2P_Handshake() -> void:
	print("Sending P2P handshake to the lobby")
	send_P2P_Packet("all", {"message": "handshake", "from": Globals.STEAM_ID})


# ---
# Steam Callbacks
# ---


func _on_P2P_Session_Request(remoteID: int) -> void:
	# Get the requester's name
	var _REQUESTER: String = Steam.getFriendPersonaName(remoteID)

	# Accept the P2P session; can apply logic to deny this request if needed
	var _tmp: bool = Steam.acceptP2PSessionWithUser(remoteID)

	# Make the initial handshake
	make_P2P_Handshake()


func _on_P2P_Session_Connect_Fail(lobbyID: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with " + str(lobbyID) + " [no error given].")

	# Else if target user was not running the same game
	elif session_error == 1:
		print(
			(
				"WARNING: Session failure with "
				+ str(lobbyID)
				+ " [target user not running the same game]."
			)
		)

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print(
			(
				"WARNING: Session failure with "
				+ str(lobbyID)
				+ " [local user doesn't own app / game]."
			)
		)

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print(
			(
				"WARNING: Session failure with "
				+ str(lobbyID)
				+ " [target user isn't connected to Steam]."
			)
		)

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with " + str(lobbyID) + " [connection timed out].")

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with " + str(lobbyID) + " [unused].")

	# Else no known error
	else:
		print(
			(
				"WARNING: Session failure with "
				+ str(lobbyID)
				+ " [unknown error "
				+ str(session_error)
				+ "]."
			)
		)
