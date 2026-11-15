extends Node
## Optional co-op (1-4 players, host-authoritative, Godot ENet). The offline campaign
## never depends on this node: with state OFFLINE every is_authority() call is true,
## so gameplay code can be written once for both modes.
## Rule: only the authority mutates shared state; clients send requests (RPCs).

enum State { OFFLINE, HOSTING, CONNECTING, CONNECTED }

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

var state: State = State.OFFLINE

func _ready() -> void:
	multiplayer.peer_connected.connect(func(id): EventBus.network_peer_joined.emit(id))
	multiplayer.peer_disconnected.connect(func(id): EventBus.network_peer_left.emit(id))
	multiplayer.connected_to_server.connect(func(): _set_state(State.CONNECTED))
	multiplayer.connection_failed.connect(_on_connection_lost)
	multiplayer.server_disconnected.connect(_on_connection_lost)

func is_online() -> bool:
	return state != State.OFFLINE

func is_authority() -> bool:
	return state == State.OFFLINE or multiplayer.is_server()

func host(port: int = DEFAULT_PORT) -> Error:
	if is_online():
		return ERR_ALREADY_IN_USE
	if port < 1024 or port > 65535:
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		GameLog.error("Network", "host failed: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	_set_state(State.HOSTING)
	return OK

func join(address: String, port: int = DEFAULT_PORT) -> Error:
	if is_online():
		return ERR_ALREADY_IN_USE
	if address.strip_edges() == "" or port < 1024 or port > 65535:
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address.strip_edges(), port)
	if err != OK:
		GameLog.error("Network", "join failed: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	_set_state(State.CONNECTING)
	return OK

func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	_set_state(State.OFFLINE)

func _on_connection_lost() -> void:
	GameLog.warn("Network", "connection lost; returning to offline play")
	leave()

func _set_state(value: State) -> void:
	if state != value:
		state = value
		EventBus.network_state_changed.emit(int(value))
