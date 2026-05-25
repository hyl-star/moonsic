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
let midi = song.to_midi_bytes_with_ppq_checked(480)

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
| `degree_checked(root, kind, n)` | Nth scale degree with structured errors |
| `degree(root, kind, n)` | Legacy throwing scale-degree helper |
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

### Generation

| Function | Description |
|----------|-------------|
| `generate_melody_checked(key, rhythm)` | Generate melody with structured errors |
| `generate_chord_progression_checked(context, bars)` | Generate chord progression |
| `generate_accompaniment_checked(context, pattern)` | Generate accompaniment pattern |

### Rhythm and Motif

| Function | Description |
|----------|-------------|
| `rhythm_pattern_checked(cells)` | Build rhythm pattern with validation |
| `motif_checked(degrees, rhythm)` | Build melodic motif |
| `repeat_motif_checked(motif, count)` | Repeat motif into phrase pattern |
| `join_patterns_checked(patterns)` | Concatenate multiple phrase patterns |
| `fit_pattern_to_bars_checked(pattern, time_sig)` | Fit pattern to bar boundaries |

### Enhanced Score Structure

| Function | Description |
|----------|-------------|
| `make_section_checked(kind, label, start, end)` | Create section marker |
| `enhanced_measure_checked(beats)` | Build enhanced measure |
| `score_to_enhanced_layout_checked(score, ppq)` | Convert score to enhanced layout |
| `enhanced_layout_to_score_checked(layout)` | Convert enhanced layout back to score |

### Validation

| Function | Description |
|----------|-------------|
| `validate_score_layout_report(layout)` | Validate score layout, return report |
| `validation_report_has_errors(report)` | Check if report contains errors |
| `validation_report_to_json(report)` | Serialize report to JSON |

### MusicXML Export

| Function | Description |
|----------|-------------|
| `score_to_musicxml_checked(score, options)` | Export score to MusicXML with validation |
| `musicxml_to_string_checked(doc, doctype)` | Serialize MusicXML document to string |
| `score_to_musicxml_string_checked(score)` | Convenience: score to MusicXML string in one call |

### External Generator Adapter

| Function | Description |
|----------|-------------|
| `generation_request_checked(task, constraints)` | Build validated generation request |
| `deterministic_mock_generate(request)` | Deterministic mock generator |
| `generation_request_to_json(request)` | Serialize request to JSON |

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
let bytes = song.to_midi_bytes_with_ppq_checked(480)

///|
let bytes = song.to_midi_bytes_with_ppq_checked(960)
```

Exports multi-track MIDI with tempo meta event, time signature, instrument program change, and NoteOn/NoteOff ordering. Produces Standard MIDI File (SMF) format 1. Can be saved to `.mid` and opened in DAWs or notation software. The legacy `to_midi_bytes` and `to_midi_bytes_with_ppq` helpers are kept for compatibility and may abort on invalid input; new code should prefer checked APIs.

## Export WAV

```moonbit nocheck
///|
let wav = song.to_wav_bytes() // 44100Hz 16-bit mono PCM
```

v1 includes simple built-in sine-wave synthesis with ADSR envelope, normalize, and master gain. Future `moondsp` backend integration is on the roadmap.

## Browser Playback

```bash
moon run cmd/main | Out-File -Encoding utf8 web/demo-events.js  # Generate data (PowerShell requires utf8)
py -m http.server 8000 -d web              # Start server
# Open http://localhost:8000, click Play
```

The demo loads moonsic-generated event data or falls back to a hardcoded melody. Supports loop playback, ADSR synthesis, and drum synthesis.

## API Stability

**Stable API** (intended to remain backward-compatible through v1.x):
- Pitch and duration constructors (`c(4)`, `quarter()`, etc.)
- Event constructors (`n()`, `nv()`, `r()`, `ch()`, `major()`, `minor()`, etc.)
- Track/Score builders (`melody()`, `score1()`, `score_with()`, `track()`)
- Music operations (`transpose`, `stretch`, `repeat`, `concat`, `reverse`, `map_velocity`)
- Render/export (`to_midi_bytes_with_ppq_checked`, `to_wav_bytes`, `note_events_to_browser_js`)
- Core types (`Pitch`, `Duration`, `Note`, `Chord`, `Rest`, `MusicEvent`, `Track`, `Score`, `NoteEvent`)

**Experimental API** (evolving, may change in minor versions):
- `melody_str` / `score_str` text parser
- `roman_progression` / `accompany` / `voice_lead`
- Bass and arpeggio generators (`bass_from_progression`, `arpeggiate_dir`)
- Style enums (`BassStyle`, `ArpStyle`, `AccompanimentStyle`)

## Checked vs Convenience API

moonsic provides two styles of API for critical functions:

| Style | Behavior | Example |
|-------|----------|---------|
| **Checked API** | Returns `Result[T, String]`, never aborts on invalid input | `tempo_checked(120)` -> `Ok(Tempo)` |
| **Convenience API** | May `abort()` on invalid input (legacy behavior, kept for compatibility) | `tempo(120)` |

**New code should prefer checked APIs.** Convenience APIs are retained solely for backward compatibility but may abort when given invalid inputs such as negative tempo, out-of-range MIDI notes, or invalid PPQ values.

### Legacy API to Recommended API

| Legacy API | Recommended Checked API |
|------------|------------------------|
| `tempo` | `tempo_checked` |
| `midi_to_pitch` | `midi_to_pitch_checked` |
| `to_midi_bytes` | `to_midi_bytes_with_ppq_checked` |
| `to_midi_bytes_with_ppq` | `to_midi_bytes_with_ppq_checked` |
| `degree` | `degree_checked` |
| Typed FFI time helpers (`ffi_duration_ticks`, etc.) | JSON-string FFI wrappers (`ffi_duration_ticks_json`, etc.) |

### API Stability Levels

Every public API is classified into one of these levels:

| Level | Commitment |
|-------|-----------|
| **Stable** | v1.x will not break signature or semantics |
| **CheckedPreferred** | Legacy API kept for compatibility; checked variant recommended for new code |
| **Experimental** | Signature may adjust in v1.x minor versions |
| **Legacy** | Retained for backward compatibility; docs point to replacement API |
| **Internal** | No external compatibility promise; may change without notice |

## Feature Status

| Module | Status | Notes |
|--------|--------|-------|
| Core model (Pitch, Duration, Note, Track, Score) | **Stable** | Backward-compatible through v1.x |
| Text notation parser (`melody_str`, `score_str`) | **Experimental** | DSL syntax may evolve |
| MIDI export (`to_midi_bytes_with_ppq_checked`) | **Stable** | Standard MIDI File format 1 |
| WAV export (`to_wav_bytes`) | **Stable** | 44100 Hz 16-bit mono PCM |
| Browser event export | **Stable** | WebAudio scheduler integration |
| Theory (scales, chords, progression) | **Stable** | Core theory; roman parser experimental |
| Accompaniment / Bass / Arpeggio | **Experimental** | Style enums and defaults may adjust |
| Harmony (roman numerals, voice leading) | **Experimental** | Parser coverage expanding |
| MusicXML export | **Planned** | Design doc in `todo/`; not yet implemented |
| External generator protocol | **Planned** | Design doc in `todo/`; not yet implemented |
| AI / ML integration | **Planned** | Roadmap item; no runtime code yet |

## Module Coverage

| Module | Docs | Examples | Tests | Benchmark |
|--------|------|----------|-------|-----------|
| Theory (scales, chords, key, roman, voice lead) | README | demo | required | suggested |
| Time (BPM, tempo, ticks, bar length) | README | demo | required | suggested |
| Score / Structure (section, arrange, layer, pad) | README | demo | required | suggested |
| MIDI / Web / WAV export | README | demo | required | required |
| Serialize / JSON / FFI | README | suggested | required | required |
| Generation (accompany, bass, arpeggio, drums) | README | demo | required | required |
| MusicXML export | planned | planned | planned | suggested |
| External generator protocol | planned | planned | planned | not required |

## Release Quality Checklist

Every release must pass these gates:

| Gate | Command | Required |
|------|---------|----------|
| Interface update | `moon info` | yes |
| Code formatting | `moon fmt` | yes |
| All tests pass | `moon test` | yes |
| README accuracy review | manual / `grep` | yes |
| `.mbti` diff review | manual diff after `moon info` | yes |
| Benchmark smoke | benchmark command | recommended |

After `moon info`, always review `pkg.generated.mbti` diffs to confirm API changes are intentional and compatible.

## Version Policy

| Phase | Breaking Changes Allowed |
|-------|-------------------------|
| v1.x patch | Not allowed |
| v1.x minor | Experimental API only |
| v2 alpha | Package split and migration permitted |
| v2 stable | New stability commitments established |

moonsic is currently in **v1.x** (single-package library). No physical package split is planned during v1.x.

## Data Model Notes

- `Duration` in `core.mbt` is the legacy convenience duration used by note/chord helpers. Use the richer `RhythmDuration` APIs in `time.mbt` when tuplets, dots, PPQ conversion, or strict validation matter.
- `Scale.tones` is kept as a compatibility view of pitch-class letters. Use `Scale.spelled_tones` for spelling-aware output such as F# major, Bb minor, and JSON/user-facing notation.
- Strict FFI entry points should prefer the JSON-string wrappers such as `ffi_duration_ticks_json`, `ffi_ticks_to_seconds_json`, and `ffi_bar_length_json`; typed FFI helpers are retained for compatibility.

## Project Structure

```
core.mbt                         Core music model: Pitch, Duration, Note, Chord, Rest, MusicEvent, Track, Score
runtime.mbt                      Event runtime: NoteEvent, track/song flattening, browser JS export
midi.mbt                         MIDI compatibility layer: frequency helpers and checked export wrappers
helpers.mbt                      Composition shortcuts: pitch/duration/event builders, text parser
theory.mbt                       Music theory: intervals, scales, chord qualities, chord progression
patterns.mbt                     Track transforms: concat, reverse, stretch, map_velocity, octave
instruments.mbt                  GM instrument presets
arpeggio.mbt                     Arpeggio generator
bass.mbt                         Bass line generator
drums.mbt                        Drum constants and basic beat
harmony.mbt                      Roman numeral parser and voice leading
key.mbt                          Key-aware pitch spelling
structure.mbt                    Section, arrange, layer, pad_to
wav.mbt                          WAV/PCM export
accompany.mbt                    Multi-track accompaniment templates
pitch_class_rules.mbt            Shared pitch-class letter ordering rules
parse_number_util.mbt            Shared ASCII number parser for time/JSON paths
ffi_json.mbt                     Shared JSON response helpers for FFI wrappers
generate.mbt                     Rule-based music generation: melody, chords, bass, accompaniment
rhythm.mbt                       Rhythm template, motif, pattern transform, repeat, join
score_enhanced.mbt               Professional score structure: Section, Repeat, Ending, Notation, Lyric
validate.mbt                     Non-blocking score validation with structured issue reports
musicxml.mbt                     MusicXML export: score-to-MusicXML conversion, validation
adapter.mbt                      External generator protocol: request/response, mock provider
moonsic_*_test.mbt               Split blackbox tests by module area
web/                             Browser playback engine (scheduler + ADSR + loop)
cmd/main/                        CLI entry point (generates browser demo data)
```

## Development Commands

```bash
moon test              # Run tests (602 tests)
moon check             # Type check
moon info              # Update pkg.generated.mbti
moon fmt               # Format code
moon run cmd/main      # Generate browser demo data
```

After `moon info`, review `pkg.generated.mbti` diffs to confirm API changes are intentional.

## Roadmap

- **Post-v1** - Split theory/time/score/export packages for cleaner dependency boundaries
- **Post-v1** - DSL compiler and stronger text-to-Score diagnostics
- **Post-v1** - `moondsp` WAV backend and adaptive real-time scheduling
- **v2** - Package architecture: `moonsic-core` (Pitch/Duration), `moonsic-theory`, `moonsic-time`, `moonsic-score`, `moonsic-midi`, `moonsic-wav`, `moonsic-musicxml`, `moonsic-gen` (generators), `moonsic-web`. See `todo/newv1plus7.md` for detailed v2 package plan.
- **v2** - Deprecation period for legacy convenience APIs before removal in v2 stable

Prior version summaries are maintained in `todo/` design documents.
