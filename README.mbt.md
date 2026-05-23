# moonsic

moonsic is a MoonBit music IR and export library with MIDI, WAV, and browser event output.

## Quick Start

```moonbit nocheck
///|
let chords = progression(c(3), Major, [I, V, VI, IV], half())

///|
let lead = melody_str("C4q D4q E4q G4q")

///|
let song = score_with([chords, lead], 120, four_four())

///|
let midi = song.to_midi_bytes()

///|
let wav = song.to_wav_bytes()
```

## Core Concepts

- **Pitch** — pitch class + accidental + octave, e.g. `c(4)` = C4 (MIDI 60).
- **Duration** — `whole()`, `half()`, `quarter()`, `eighth()`, `sixteenth()`, `dotted()`.
- **MusicEvent** — track element: `Note`, `Rest`, or `Chord`.
- **Track** — ordered sequence of events with channel, instrument, volume, pan, mute.
- **Score** — tempo + time signature + multiple tracks.
- **NoteEvent** — runtime event with absolute start time, duration, MIDI note, velocity, channel.

Pipeline:

```text
API / text notation -> Score -> NoteEvent -> MIDI / WAV / browser events
```

## Compose With MoonBit API

### Pitch shortcuts

| Function | Result | MIDI |
|----------|--------|------|
| `c(4)` | C4 | 60 |
| `d(4)` | D4 | 62 |
| `e(4)` | E4 | 64 |
| `f(4)` | F4 | 65 |
| `g(4)` | G4 | 67 |
| `a(4)` | A4 | 69 |
| `b(4)` | B4 | 71 |
| `cs(4)` | C#4 | 61 |
| `ds(4)` | D#4 | 63 |
| `fs(4)` | F#4 | 66 |
| `gs(4)` | G#4 | 68 |
| `db(4)` | Db4 | 61 |
| `eb(4)` | Eb4 | 63 |
| `gb(4)` | Gb4 | 66 |
| `ab(4)` | Ab4 | 68 |
| `bb(4)` | Bb4 | 70 |

### Duration

| Function | Beats |
|----------|-------|
| `whole()` | 4.0 |
| `half()` | 2.0 |
| `quarter()` | 1.0 |
| `eighth()` | 0.5 |
| `sixteenth()` | 0.25 |
| `dotted(quarter())` | 1.5 |

### Events

| Function | Description |
|----------|-------------|
| `n(c(4), quarter())` | Note with default velocity 100 |
| `nv(c(4), quarter(), 64)` | Note with explicit velocity |
| `r(half())` | Rest |
| `major(c(3), half())` | Major triad C E G |
| `minor(a(3), half())` | Minor triad A C E |
| `dim(b(3), half())` | Diminished triad B D F |
| `aug(c(4), half())` | Augmented triad C E G# |
| `dom7(g(3), half())` | Dominant 7th G B D F |
| `maj7(c(4), half())` | Major 7th C E G B |
| `min7(a(3), half())` | Minor 7th A C E G |
| `ch([c(4),e(4),g(4)], quarter())` | Custom chord |

### Track and Score

| Function | Description |
|----------|-------------|
| `melody([...])` | Create track from events |
| `melody_with_channel([...], ch)` | Track with channel |
| `track_with_channel([...], ch)` | Explicit channel track |
| `score1(track)` | Single-track score (120 BPM, 4/4) |
| `score_with([tracks], bpm, time_sig)` | Multi-track score |
| `empty_track()` | Empty track |

### Music Operations

| Function | Description |
|----------|-------------|
| `track.transpose(n)` | Transpose track by n semitones |
| `track.stretch(factor)` | Stretch durations |
| `track.repeat(count)` | Repeat track N times |
| `track.concat(other)` | Concatenate two tracks |
| `track.reverse()` | Reverse event order |
| `track.map_velocity(f)` | Map velocity function over all events |
| `track.up_octave()` | Raise one octave |
| `track.down_octave()` | Lower one octave |
| `track.duration_beats()` | Total beats |
| `track.with_volume(v)` | Set track volume (0.0..) |
| `track.with_pan(p)` | Set track pan (-1.0..1.0) |

### Theory

| Function | Description |
|----------|-------------|
| `scale(root, kind, octaves)` | Build scale pitches |
| `degree(root, kind, n)` | Nth scale degree |
| `key(tonic, kind)` | Key with spelling table |
| `progression(root, kind, [I, IV, V], dur)` | Chord progression |
| `roman_progression(key, "I V vi IV", dur)` | Text-based progression |
| `voice_lead(chords)` | Apply voice leading |
| `bass_from_progression(chords, style, octave)` | Generate bass line |
| `arpeggiate(chords, step_dur)` | Arpeggiate chords |
| `arpeggiate_dir(chords, step_dur, style)` | Arpeggiate with style |

### Instrument and Drums

| Function | Description |
|----------|-------------|
| `instrument(track, program)` | Set MIDI instrument |
| `acoustic_grand_piano()` | Program 0 |
| `violin()` | Program 40 |
| `drum_note(note, dur, vel)` | Drum event |
| `kick(dur)` | Kick drum (36) |
| `snare(dur)` | Snare drum (38) |
| `hat(dur)` | Closed hat (42) |
| `basic_beat(bars)` | 3-track drum pattern |

## Text Notation

```moonbit nocheck
///|
let t = melody_str("C4q D4q [E4 G4]h Rq D4q:64 x2")

///|
let s = score_str("tempo 140\ntime 3/4\nC4q D4q E4q")
```

Format: `[Note][Accidental][Octave][Duration][:Velocity]`.  
Chord format: `[Pitch1 Pitch2 ...]Duration`.  
Repeat suffix: `xN`. Line comments: `# comment`.

## Export MIDI

```moonbit nocheck
///|
let bytes = song.to_midi_bytes() // default PPQ 480

///|
let bytes = song.to_midi_bytes_with_ppq(960)
```

Exports multi-track MIDI with tempo meta event, time signature, instrument program change, and NoteOn/NoteOff ordering. Produces Standard MIDI File (SMF) format 1. Can be saved to `.mid` and opened in DAWs or notation software.

## Export WAV

```moonbit nocheck
///|
let wav = song.to_wav_bytes() // 44100Hz 16-bit mono PCM
```

v10 uses simple built-in sine-wave synthesis with ADSR envelope, normalize, and master gain. Future `moondsp` backend integration is on the roadmap.

## Browser Playback

```bash
moon run cmd/main | Out-File -Encoding utf8 web/demo-events.js  # Generate data (PowerShell requires utf8)
py -m http.server 8000 -d web              # Start server
# Open http://localhost:8000, click Play
```

The demo loads moonsic-generated event data or falls back to a hardcoded melody. Supports loop playback, ADSR synthesis, and drum synthesis.

## API Stability

**Stable API** (intended to remain backward-compatible through v10.x):
- Pitch and duration constructors (`c(4)`, `quarter()`, etc.)
- Event constructors (`n()`, `nv()`, `r()`, `ch()`, `major()`, `minor()`, etc.)
- Track/Score builders (`melody()`, `score1()`, `score_with()`, `track()`)
- Music operations (`transpose`, `stretch`, `repeat`, `concat`, `reverse`, `map_velocity`)
- Render/export (`to_midi_bytes`, `to_wav_bytes`, `note_events_to_browser_js`)
- Core types (`Pitch`, `Duration`, `Note`, `Chord`, `Rest`, `MusicEvent`, `Track`, `Score`, `NoteEvent`)

**Experimental API** (evolving, may change in minor versions):
- `melody_str` / `score_str` text parser
- `roman_progression` / `accompany` / `voice_lead`
- Bass and arpeggio generators (`bass_from_progression`, `arpeggiate_dir`)
- Style enums (`BassStyle`, `ArpStyle`, `AccompanimentStyle`)

## Project Structure

```
core.mbt        — Core music model (~750 lines): Pitch, Duration, Note, Chord, Rest, MusicEvent, Track, Score
runtime.mbt     — Event runtime (~140 lines): NoteEvent, track/song flattening, browser JS export
midi.mbt        — MIDI export (~230 lines): frequency conversion, validation, SMF generation
helpers.mbt     — Composition shortcuts (~190 lines): pitch/duration/event builders, text parser
theory.mbt      — Music theory (~230 lines): intervals, scales, chord qualities, chord progression
patterns.mbt    — Track transforms (~155 lines): concat, reverse, stretch, map_velocity, octave
instruments.mbt — GM instrument presets (~50 lines)
arpeggio.mbt    — Arpeggio generator (~70 lines)
bass.mbt        — Bass line generator (~70 lines)
drums.mbt       — Drum constants and basic beat (~80 lines)
harmony.mbt     — Roman numeral parser + voice leading (~180 lines)
key.mbt         — Key-aware pitch spelling (~90 lines)
structure.mbt   — Section, arrange, layer, pad_to (~150 lines)
wav.mbt         — WAV/PCM export (~150 lines)
accompany.mbt   — Multi-track accompaniment templates (~90 lines)
web/            — Browser playback engine (scheduler + ADSR + loop)
cmd/main/       — CLI entry point (generates browser demo data)
```

## Development Commands

```bash
moon test              # Run tests (127 tests)
moon check             # Type check
moon info              # Update pkg.generated.mbti
moon fmt               # Format code
moon run cmd/main      # Generate browser demo data
```

After `moon info`, review `pkg.generated.mbti` diffs to confirm API changes are intentional.

## Roadmap

- **v11** — DSL compiler, text-to-Score pipeline
- **v12** — `moondsp` WAV backend (replacing built-in synthesis)
- **v13** — Adaptive audio, real-time scheduling

Prior version summaries are maintained in `todo/` design documents.
