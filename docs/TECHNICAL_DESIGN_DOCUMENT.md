# Technical Design Document
- Godot 4.x, Mobile renderer, GDScript, one shared project architecture.
- Autoloads: `GameState` (flags, clues, memories, chapter), `SaveManager` (versioned JSON, .bak backup).
- Player: `CharacterBody3D` controller, touch joystick or WASD.
- Rules: no mandatory online features; modular scenes; no paid dependencies; stability over effects.
## Planned modules
Interaction, Dialogue, Journal, Ability system, Puzzle framework, Cutscene runner, Quality settings, Networking (ENet, optional).
