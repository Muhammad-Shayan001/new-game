# AFTERLIFE.EXE — AUDIO DIRECTION & SOUND DESIGN MASTER GUIDE
**Document Version:** 2.0.0 (Production Master)  
**Lead Audio Director & Composer:** Antigravity Sound Lab  
**Mix Format:** 3D Spatial Binaural (Headphones) & Stereo (Device Speakers)  

---

## 1. SONIC IDENTITY: THE SOUND OF MEMORY DECAY

The audio landscape of **AFTERLIFE.EXE** bridges melancholic emotional intimacy with chilling technological terror. It rejects generic orchestral jumpscares in favor of analog tape flutter, sub-bass pressure, resonant binaural whispers, and moody retro-futurist synthesizers.

### 1.1 The Three Acoustic Layers
1. **The Physical Realm (Real Echo City):**
   - Naturalistic, tactile foley: rubber boot soles splashing on rain-soaked asphalt, distant hum of city power grids, wind whistling through fire escape railings, the metallic clang of opening heavy fire exit doors.
2. **The Mind Realm (Memory Vision & Internal Monologue):**
   - Sub-bass heartbeat pulse ($40\text{Hz}-60\text{Hz}$ sine wave), binaural clock ticks, reverse-reverb vocal echoes, cassette player motor hum.
3. **The Glitch Realm (The Under-Code & Reality Shift):**
   - Corrupted datastreams, granular synthesis artifacts, dial-up handshake fragments pitch-shifted down three octaves, sudden spatial phase cancellations that make the player feel their ears popped.

---

## 2. GODOT 4 AUDIO BUS ARCHITECTURE

```
+-----------------------------------------------------------------------------------+
|                                MASTER BUS (0 dB)                                  |
+-----------------------------------------------------------------------------------+
       |                    |                    |                     |
       v                    v                    v                     v
 [ MUSIC BUS ]       [ SFX BUS ]         [ VOICE BUS ]         [ AMBIENCE BUS ]
 (-3 dB)             (0 dB)              (+2 dB Normalizer)    (-6 dB)
       |                    |                    |                     |
   Sidechain             3D Spatial          High-Pass             Binaural
   Compressor            Reverb Sends        Speech Clarity        Convolution
 (Ducks -4dB during    (Small Concrete,      Filter (120Hz cut)    Reverb (Rain/Metro)
  Dialogue)             Large Void)
```

### 2.1 Dynamic Stem System
Exploration music is split into four synchronized stems running in parallel:
- **`Stem_Base`**: Sub-bass drones and ambient electric guitar chords.
- **`Stem_Rhythm`**: Minimalist lo-fi glitch beats and muted snare taps (fades in during investigation).
- **`Stem_Tension`**: Distorted analog synthesizer arpeggios (fades in during supernatural danger).
- **`Stem_Memory`**: Melancholic upright piano with felt-mute dampening (fades in near memory fragments).

---

## 3. ORIGINAL SOUNDTRACK (OST) THEMATIC COMPOSITION

| Track Title | Context & Placement | Tempo & Key | Instruments & Production |
| :--- | :--- | :--- | :--- |
| **"Terminal Awakening"** | Main Menu & Opening Title | 72 BPM / D Minor | Prophet-5 analog synth pads, bowed cello, vinyl crackle, tape saturation |
| **"Neon & Tarmac"** | Echo City Main Street Rain | 84 BPM / F# Minor | Downtempo trip-hop drums, Fender Rhodes piano, filtered rainfall foley |
| **"The Archivist's Archive"**| Meeting the Archivist | Free Time / A Minor | Glass armonica, deep pipe organ hum, reversed tape loops |
| **"Fractured Protocol"** | Reality Shift & Puzzles | 118 BPM / C Minor | Industrial percussion, modular synth filter sweeps, bitcrushed bass |
| **"The Last Memory"** | Climax & Ending Credits | 68 BPM / E Minor | Intimate acoustic piano, soaring shoegaze ambient guitars, haunting female vocalises |

---

## 4. FOLEY & SOUND ASSET SPECIFICATIONS

- **Footsteps Matrix:** 6 ground surface types (Wet Asphalt, Puddle Splash, Concrete, Metal Grate, Interior Wood, Glass Shards) with 5 velocity variations each to prevent repetitive auditory fatigue.
- **Audio Codec for Mobile:**
  - Music & Ambience: Compressed OGG Vorbis ($128\text{ kbps}$, looped seamless with metadata beat cues).
  - Short SFX & Foley: Uncompressed 16-bit WAV ($44.1\text{kHz}$) loaded in RAM for instantaneous zero-latency playback.
