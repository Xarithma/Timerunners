extends Node2D

enum lobby_status { Private, Friends, Public, Invisible }
enum search_distance { Close, Default, Far, Worldwide }

onready var steam_name: Label = $SteamName
onready var set_lobby_name: TextEdit = $Create/LobbySetter
onready var get_lobby_name: Label = $Chat/LobbyName
onready var lobby_output: RichTextLabel = $Chat/RichTextLabel
onready var lobby_popup: PopupPanel = $LobbyListPopup
onready var lobby_list: VBoxContainer = $LobbyListPopup/Panel/Scroll/VBox
onready var player_count: Label = $Players/Label
onready var player_list: RichTextLabel = $Players/RichTextLabel
onready var chat_input: TextEdit = $Message/TextEdit
