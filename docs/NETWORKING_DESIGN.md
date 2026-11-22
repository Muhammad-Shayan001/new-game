# AFTERLIFE.EXE — MULTIPLAYER & CO-OP NETWORKING ARCHITECTURE
**Document Version:** 2.0.0 (Production Master)  
**Lead Multiplayer & Network Engineer:** Antigravity Connected Systems Lab  
**Architecture:** Host-Authoritative Client/Server (Listen-Server) via Godot 4 `ENetMultiplayerPeer` & WebRTC Relay Fallback  

---

## 1. DESIGN OBJECTIVE: OPTIONAL CO-OP MEMORY EXPEDITIONS

Multiplayer in **AFTERLIFE.EXE** is completely optional and strictly cooperative (1–4 Players).
It is designed around an asymmetrical information mechanic called **"Divergent Perception"**:
- **Player 1 (The Host / Alex):** Possesses `Memory Vision` and can see hidden clues, footprints, and door codes.
- **Player 2 (Client 1 / Maya):** Possesses `Reality Shift` and can physically manipulate spatial geometry and unlock alternate dimensional pathways.
- **Players 3 & 4 (Clients 2 & 3 / Recon Specialists):** Possess `Time Echo` and radio jamming tools to suppress hostile Watcher entities.

Neither player can solve cooperative puzzles alone; players must communicate through voice chat, in-game pings, or radio frequency transcripts.

---

## 2. SYNCHRONIZATION & AUTHORITY MODEL

```
+-----------------------------------------------------------------------------------+
|                           HOST (LISTEN-SERVER / AUTHORITATIVE)                    |
|   - Owns Game State, Story Flags, Puzzle Solved States, AI Entities              |
|   - Runs Physics Validation & Damage Calculations                                 |
+-----------------------------------------------------------------------------------+
       ^                                                      ^
       | RPC [Input State & Character Position]                | RPC [Sync Game State]
       v                                                      v
+-------------------------------+              +-------------------------------+
| CLIENT 1 (PEER / GUEST)       |              | CLIENT 2 (PEER / GUEST)       |
|  - Client-Side Prediction     |              |  - Client-Side Prediction     |
|  - Interpolated Ghost Avatars |              |  - Interpolated Ghost Avatars |
+-------------------------------+              +-------------------------------+
```

### 2.1 State Replication Rules
1. **Player Transform Sync:** Replicated at 20Hz (every 50ms) using delta compression and Hermite cubic spline interpolation on client avatars to hide mobile latency up to $150\text{ms}$.
2. **Puzzle & Door State Sync:** Reliable RPC (`@rpc("call_local", "reliable")`) guaranteeing zero desynchronization of unlocked gates or solved memory sequences.
3. **Entity Synchronization:** The Host executes entity behavior trees (Watchers/Mimics). Clients receive target position vectors and play local audio/animation cues.

---

## 3. FREE / LOW-COST NETWORKING INFRASTRUCTURE

- **LAN Auto-Discovery:** Uses UDP broadcast on port `7777` for local Wi-Fi co-op play without any external servers or internet connection.
- **Internet Private Rooms:** 6-character room codes (`"ECHO-79"`) resolved through a lightweight, free WebRTC signaling service running on Cloudflare Workers / free tier VPS.
- **Offline Campaign Isolation:** If no network connection is detected, the networking subsystem remains completely disabled, guaranteeing 100% offline campaign functionality with zero battery drain.
