# Networking Design
Optional co-op, 1-4 players, Godot high-level multiplayer (ENet). Host-authoritative. Offline campaign must never depend on it.

## Built (v0.1.0)
`NetworkManager`: host, join, leave, state signals (`network_state_changed`, `network_peer_joined/left`), argument validation, automatic return to offline when the connection drops, and `is_authority()` which is always true offline. Tested headless (host, refuse double host/join, invalid ports).

## Rules
- Only the authority (host) changes shared state; clients send requests.
- Campaign systems contain no RPCs. Co-op content is a separate set of "Echo Trials" rooms.
- Gameplay code asks `NetworkManager.is_authority()` and works the same offline.

## Not built
State replication, player spawning for peers, shared Reality Shift states, split-role puzzles, join UI.
