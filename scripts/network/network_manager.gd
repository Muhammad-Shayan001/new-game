extends Node
## Optional online co-op (1-4 players). The offline campaign never depends on this class:
## when no peer exists, is_authority() is true and everything behaves as single-player.
## Design: host-authoritative, Godot high-level multiplayer over ENet. See docs/NETWORKING_DESIGN.md.

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

var state: String = "offline"        # offline | hosting | joining | connected
var players: Array[int] = []

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func(): _set_state("connected"))
	multiplayer.connection_failed.connect(func(): leave())
	multiplayer.server_disconnected.connect(func(): leave())

func is_online() -> bool:
	return state != "offline"

## True for single player and for the host; gameplay that mutates shared state checks this.
func is_authority() -> bool:
	return not is_online() or multiplayer.is_server()

func host(port: int = DEFAULT_PORT, max_players: int = MAX_PLAYERS) -> bool:
	if is_online():
		return false
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, clampi(max_players, 1, MAX_PLAYERS) - 1)
	if err != OK:
		Log.error("Net", "Cannot host on %d: %s" % [port, error_string(err)])
		return false
	multiplayer.multiplayer_peer = peer
	players = [1]
	_set_state("hosting")
	return true

func join(address: String, port: int = DEFAULT_PORT) -> bool:
	if is_online():
		return false
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		Log.error("Net", "Cannot join %s:%d: %s" % [address, port, error_string(err)])
		return false
	multiplayer.multiplayer_peer = peer
	_set_state("joining")
	return true

func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players = []
	_set_state("offline")

func _on_peer_connected(id: int) -> void:
	if id not in players:
		players.append(id)

func _on_peer_disconnected(id: int) -> void:
	players.erase(id)

func _set_state(s: String) -> void:
	if state != s:
		state = s
		EventBus.network_state_changed.emit(s)
