# packages/wav — v2 WAV package

Simple 16-bit mono WAV renderer for timeline note events.

## Dependencies

- `moonbitlang/core/math`
- `packages/pitch`
- `packages/timeline`

## Scope

- `Array[NoteEvent] -> WAV Bytes`
- `PlaybackTimeline -> WAV Bytes`
- configurable sample rate, master gain, and tail seconds

This is still a simple sine-wave preview renderer, not a full audio synthesis backend.

## Run Tests

```bash
moon test packages/wav
```
