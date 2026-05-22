# moonsic

A small MoonBit music library for describing melodies, flattening them into
runtime note events, exporting MIDI bytes, and playing a minimal browser demo.

## Minimal MoonBit Example

```moonbit nocheck
///|
let p = @moonsic.pitch

///|
let melody = @moonsic.track([
  @moonsic.Note(
    @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
  ),
  @moonsic.Note(
    @moonsic.note(p(@moonsic.D, @moonsic.Natural, 4), @moonsic.Quarter),
  ),
  @moonsic.Note(
    @moonsic.note(p(@moonsic.E, @moonsic.Natural, 4), @moonsic.Quarter),
  ),
  @moonsic.Note(
    @moonsic.note(p(@moonsic.G, @moonsic.Natural, 4), @moonsic.Quarter),
  ),
  @moonsic.Note(
    @moonsic.note(p(@moonsic.C, @moonsic.Natural, 5), @moonsic.Half),
  ),
  @moonsic.Rest(@moonsic.rest(@moonsic.Half)),
])

///|
let score = @moonsic.score_with_tempo(
  [melody],
  @moonsic.tempo(120),
  @moonsic.four_four(),
)

///|
let bytes = score.to_midi_bytes()
```

The returned `Bytes` can be written to a `.mid` file by a native command or
passed to another host layer.

## Browser Playback

```bash
python -m http.server 8000 -d web
```

Open `http://localhost:8000` and click `Play`. The browser demo uses WebAudio
`OscillatorNode` playback with a hardcoded `NoteEvent`-shaped melody.

## Commands

```bash
moon run cmd/main
moon test
moon check
moon info
moon fmt
```

## Project Shape

```text
core.mbt     Core music model: pitch, duration, notes, tracks, score
runtime.mbt  NoteEvent timeline conversion
midi.mbt     Frequency conversion and MIDI export through CAIMEOX/midi
web/         Minimal browser playback demo
cmd/main/    CLI example entry point
```

## API Snapshot

| Area | API |
| --- | --- |
| Pitch | `pitch`, `natural`, `Pitch::to_midi`, `Pitch::frequency`, `Pitch::transpose` |
| Duration | `Duration::beats`, `Duration::ticks`, `Duration::seconds` |
| Notes | `note`, `note_with_velocity`, `rest`, `MusicEvent` |
| Tracks | `track`, `track_with_channel`, `Track::append`, `Track::repeat`, `Track::transpose` |
| Score | `score`, `score_with_tempo`, `Score::to_note_events`, `Score::to_midi_bytes` |
| Runtime | `NoteEvent::end`, `NoteEvent::start_seconds`, `NoteEvent::duration_ticks` |
