extends Node2D

# ---
# Enums
# ---

enum lobby_status { Private, Friends, Public, Invisible }
enum search_distance { Close, Default, Far, Worldwide }

# ---
# Object definitions
# ---

onready var steam_username: Label = $SteamName
onready var set_lobby_name: TextEdit = $Create/LobbySetter
onready var get_lobby_name: Label = $Chat/LobbyName
onready var lobby_output: RichTextLabel = $Chat/RichTextLabel
onready var lobby_popup: PopupPanel = $LobbyListPopup
onready var lobby_list: VBoxContainer = $LobbyListPopup/Panel/Scroll/VBox
onready var player_count: Label = $Players/Label
onready var player_list: RichTextLabel = $Players/RichTextLabel
onready var chat_input: TextEdit = $Message/TextEdit

# ---
# Preloads
# ---

const lobby_selection: PackedScene = preload("res://LobbyJoinSelection.tscn")

# ---
# Godot functions
# ---


func _ready() -> void:
	# Setting the steam name text to be the player's steam name.
	steam_username.text = Globals.STEAM_USERNAME

	# Steam setup
	var _tmp: int = Steam.connect("lobby_created", self, "_on_Lobby_Created")
	_tmp = Steam.connect("lobby_match_list", self, "_on_Lobby_Match_List")
	_tmp = Steam.connect("lobby_joined", self, "_on_Lobby_Joined")
	_tmp = Steam.connect("lobby_chat_update", self, "_on_Lobby_Chat_Update")
	_tmp = Steam.connect("lobby_message", self, "_on_Lobby_Message")
	_tmp = Steam.connect("lobby_data_update", self, "_on_Lobby_Data_Update")
	_tmp = Steam.connect("lobby_invite", self, "_on_Lobby_Invite")
	_tmp = Steam.connect("join_requested", self, "_on_Lobby_Join_Requested")

	# Check for command line arguments
	_check_Command_Line()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lobby_send_message"):
		_send_Chat_Message()


# ---
# Self-made functions
# ---


# Creates a lobby if available.
func _create_Lobby() -> void:
	# Make sure a lobby is not already set
	if Globals.LOBBY_ID == 0:
		# Creates a lobby with the Steam API.
		# Params: 1. Lobby Accessability; 2. Max Players
		Steam.createLobby(lobby_status.Public, 4)


# Joins the lobby with the specified ID.
func _join_Lobby(lobbyID: int) -> void:
	# Let's hide the lobby list.
	lobby_popup.hide()

	# Say which lobby was joined by name.
	var lobby_name = Steam.getLobbyData(lobbyID, "name")
	_display_message("Joining lobby " + str(lobby_name) + "...")

	# Clear any previous lobby members lists, if you were in a previous lobby
	Globals.LOBBY_MEMBERS.clear()

	# Make the lobby join request to Steam
	Steam.joinLobby(lobbyID)


func _get_Lobby_Members() -> void:
	# Clear your previous lobby list
	Globals.LOBBY_MEMBERS.clear()

	# Get the number of members from this lobby from Steam
	var MEMBERS: int = Steam.getNumLobbyMembers(Globals.LOBBY_ID)

	# Get the data of these players from Steam
	for MEMBER in range(0, MEMBERS):
		# Get the member's Steam ID
		var MEMBER_STEAM_ID: int = Steam.getLobbyMemberByIndex(Globals.LOBBY_ID, MEMBER)

		# Get the member's Steam name
		var MEMBER_STEAM_NAME: String = Steam.getFriendPersonaName(MEMBER_STEAM_ID)

		# Add them to the list
		_add_Player_List(MEMBER_STEAM_ID, MEMBER_STEAM_NAME)


func _add_Player_List(steam_id: int, steam_name: String):
	# Add them to the list
	Globals.LOBBY_MEMBERS.append({"steam_id": steam_id, "steam_name": steam_name})

	# Clear the current player-list
	player_list.clear()

	var tmp: int = 0

	# Add players to the player-list
	for MEMBER in Globals.LOBBY_MEMBERS:
		player_list.add_text(str(MEMBER['steam_name']) + "\n")

		tmp += 1
		player_count.text = "Players (" + str(tmp) + ")"


func _send_Chat_Message() -> void:
	# Get the entered chat message
	var MESSAGE: String = chat_input.text

	# Pass the message to Steam
	var SENT: bool = Steam.sendLobbyChatMsg(Globals.LOBBY_ID, MESSAGE)

	# Was it sent successfully?
	if not SENT:
		_display_message("ERROR: Chat message failed to send.")

	# Clear the chat input
	chat_input.text = ""


func _leave_Lobby() -> void:
	# If in a lobby, leave it
	if Globals.LOBBY_ID != 0:
		# Leaving feedback
		_display_message("Leaving lobby...")

		# Send leave request to Steam
		Steam.leaveLobby(Globals.LOBBY_ID)

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		Globals.LOBBY_ID = 0

		# Resetting player status
		get_lobby_name.text = "Lobby Name"
		player_count.text = "Players (0)"
		player_list.clear()

		# Close session with all users
		for MEMBERS in Globals.LOBBY_MEMBERS:
			var _tmp: int = Steam.closeP2PSessionWithUser(MEMBERS['steam_id'])

		# Clear the local lobby list
		Globals.LOBBY_MEMBERS.clear()


func _start_game() -> void:
	if Globals.LOBBY_MEMBERS == []:
		return

	Globals.send_P2P_Packet("all", {"message": "startgame", "from": Globals.STEAM_ID})
	var _load_game = get_tree().change_scene("res://Game.tscn")


# Displays a message to the chat, replaces print.
func _display_message(message: String) -> void:
	lobby_output.add_text("\n" + str(message))


# ---
# Steam callbacks
# ---


func _on_Lobby_Created(connect: int, lobbyID: int) -> void:
	if connect == 1:
		# Set the lobby ID
		Globals.LOBBY_ID = lobbyID

		# Display the lobby creation in chat.
		_display_message("Created lobby: " + set_lobby_name.text)

		# Set some lobby data...
		var _set_lobby_data: bool = Steam.setLobbyData(lobbyID, "name", set_lobby_name.text)

		# Get lobby name and set the label text to it.
		var lobby_name = Steam.getLobbyData(lobbyID, "name")
		get_lobby_name.text = str(lobby_name)

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var RELAY: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: " + str(RELAY))


func _on_Lobby_Joined(lobbyID: int, _permissions: int, _locked: bool, _response: int) -> void:
	# Set this lobby ID as your lobby ID
	Globals.LOBBY_ID = lobbyID

	# Set the lobby name to the current lobby's name.
	var lobby_name = Steam.getLobbyData(lobbyID, "name")
	get_lobby_name.text = str(lobby_name)

	# Get the lobby members
	_get_Lobby_Members()

	# Get player character colour
	match Globals.LOBBY_MEMBERS.size():
		0:
			Globals.character_colour = "Blue"
		1:
			Globals.character_colour = "Red"
		2:
			Globals.character_colour = "Green"
		3:
			Globals.character_colour = "Yellow"

	# Make the initial handshake
	Globals.make_P2P_Handshake()


func _on_Lobby_Join_Requested(lobbyID: int, friendID: int) -> void:
	# Get the lobby owner's name
	var OWNER_NAME: String = Steam.getFriendPersonaName(friendID)

	# Display who's party you joining in your client-side chat.
	_display_message("Joining " + str(OWNER_NAME) + "'s lobby...")

	# Attempt to join the lobby
	_join_Lobby(lobbyID)


# When lobby metadata has changed.
func _on_Lobby_Data_Update(success, lobbyID: int, memberID: int, key):
	print(
		(
			"Success: "
			+ str(success)
			+ ", Lobby ID: "
			+ str(lobbyID)
			+ ", Member ID: "
			+ str(memberID)
			+ ", Key: "
			+ str(key)
		)
	)


func _on_Lobby_Chat_Update(_lobbyID: int, _changedID: int, makingChangeID: int, chatState: int) -> void:
	# Get the user who has made the lobby change
	var CHANGER: String = Steam.getFriendPersonaName(makingChangeID)

	# If a player has joined the lobby
	if chatState == 1:
		_display_message(str(CHANGER) + " has joined the lobby.")
	# Else if a player has left the lobby
	elif chatState == 2:
		_display_message(str(CHANGER) + " has left the lobby.")
	# Else if a player has been kicked
	elif chatState == 8:
		_display_message(str(CHANGER) + " has been kicked from the lobby.")
	# Else if a player has been banned
	elif chatState == 16:
		_display_message(str(CHANGER) + " has been banned from the lobby.")
	# Else there was some unknown change
	else:
		_display_message(str(CHANGER) + " did... something.")

	# Update the lobby now that a change has occurred
	_get_Lobby_Members()


func _on_Lobby_Match_List(lobbies: Array) -> void:
	for LOBBY in lobbies:
		# Pull lobby data from Steam
		var LOBBY_NAME: String = Steam.getLobbyData(LOBBY, "name")

		# Get the current number of members
		var LOBBY_MEMBERS: int = Steam.getNumLobbyMembers(LOBBY)

		# Create a button for the lobby
		var LOBBY_BUTTON = lobby_selection.instance()
		LOBBY_BUTTON.set_text(
			(
				"Lobby "
				+ str(LOBBY)
				+ ": "
				+ str(LOBBY_NAME)
				+ " - ["
				+ str(LOBBY_MEMBERS)
				+ "] Player(s)"
			)
		)
		LOBBY_BUTTON.set_size(Vector2(800, 50))
		LOBBY_BUTTON.set_name("lobby_" + str(LOBBY))
		var _tmp: int = LOBBY_BUTTON.connect("pressed", self, "_join_Lobby", [LOBBY])

		# Add the new lobby to the list
		lobby_list.add_child(LOBBY_BUTTON)


func _on_Lobby_Message(_result, user, message: String, _type):
	var SENDER = Steam.getFriendPersonaName(user)
	_display_message(str(SENDER) + " : " + str(message))


# ---
# Button Signal Functions
# ---


func _on_Create_pressed() -> void:
	_create_Lobby()


func _on_Join_pressed() -> void:
	# Popup the window
	lobby_popup.popup()

	# Set server search distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(search_distance.Worldwide)
	_display_message("Searching for lobbies...")

	Steam.requestLobbyList()


func _on_Start_pressed() -> void:
	_start_game()


func _on_Leave_pressed() -> void:
	_leave_Lobby()


func _on_Message_pressed() -> void:
	_send_Chat_Message()


func _on_Close_pressed() -> void:
	lobby_popup.hide()


# ---
# Command-line Arguments
# ---


# Allowing opening up the game when accepting an invite and more...
func _check_Command_Line() -> void:
	var ARGUMENTS = OS.get_cmdline_args()

	# There are arguments to process
	if ARGUMENTS.size() > 0:
		# Loop through them and get the useful ones
		for ARGUMENT in ARGUMENTS:
			print("Command line: " + str(ARGUMENT))

			# An invite argument was passed
			if Globals.LOBBY_INVITE_ARG:
				_join_Lobby(int(ARGUMENT))

			# A Steam connection argument exists
			if ARGUMENT == "+connect_lobby":
				Globals.LOBBY_INVITE_ARG = true
