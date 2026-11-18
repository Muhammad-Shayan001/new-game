# Networking Design

**Status: skeleton only.** `Net` (scripts/network/network_manager.gd) provides host / join / leave over ENet (max 4 players) and `is_authority()`. There is no state replication yet.

## Principles
- The campaign is fully offline; `Net.is_authority()` is `true` offline, so gameplay code that checks it behaves identically in single player.
- Host-authoritative: the host owns `GameState`, missions and puzzles; clients send intents (interact, move input) and receive state.
- Co-op content is separate ("Echo Trials" rooms) and never gates the campaign.

## Planned work (not started)
1. Player spawner + `MultiplayerSynchronizer` for transform/animation state.
2. Replicate `GameState` flags and mission states from host to clients (event-based via `EventBus`).
3. Interaction requests as RPCs validated by the host (`Interactable.interact`).
4. Lobby UI, join by IP/LAN, disconnect handling, drop-in/out.
5. Tests: two-process headless test hosting and joining on loopback.

Tested today: hosting on a port, double-host refused, leaving, authority semantics (`test_core`).
