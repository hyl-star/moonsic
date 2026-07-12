# Moonsic Package Split Status

Current state: v2 package extraction is functionally complete. The root package
is now empty and all v1 legacy API has been removed. All functionality lives in
the 25 v2 packages under `packages/`.

## v2 Packages (25 total)

- `packages/pitch`: pitch classes, accidentals, MIDI/frequency conversion, parsing
- `packages/interval`: interval quality, interval calculation, inversion, parsing
- `packages/time`: rational time, signatures, durations, tempo maps, FFI helpers
- `packages/scale`: scales and keys
- `packages/chord`: chord qualities, parsing, pitch expansion
- `packages/harmony`: roman numerals, progressions, voice leading
- `packages/rhythm`: rhythm cells, patterns, phrase fitting
- `packages/motif`: degree motifs, motif transforms, motif-to-track conversion
- `packages/score`: v2 `SimpleScore` and professional `ScoreLayout` IR
- `packages/validation`: score layout validation and reports
- `packages/json`: dependency-free JSON value, parser, stringify, decode helpers
- `packages/parse`: unified parse-to-JSON facade
- `packages/midi`: v2 MIDI events, validation, score conversion, bytes export, GM instruments
- `packages/musicxml`: v2 MusicXML model, conversion, string writer
- `packages/timeline`: note-event timeline and browser event export
- `packages/wav`: simple sine-wave WAV rendering from timeline events
- `packages/game`: game music IR, validation, JSON export, timeline/browser bridge
- `packages/generate`: melody, chord progression, bass, accompaniment, game loop generation
- `packages/adapter`: external generation request/response/patch protocol and JSON/FFI helpers
- `packages/drums`: GM drum helpers and basic beat generation
- `packages/transform`: pure `SimpleTrack` transforms
- `packages/structure`: song sections and arrangement helpers
- `packages/ffi`: v2 string-in/string-out facade for parse, generation, MIDI, and MusicXML
- `packages/demo`: end-to-end pipeline: request -> generate -> export
- `packages/web`: web/browser playback event output from timeline/score

## Remaining Cleanup

- Root package has been emptied; v1 legacy API fully removed.
- `cmd/main` CLI entry has been deleted; v2 CLI entry not yet rebuilt.
- `examples/output` currently only contains `.gitkeep`; real file-write commands pending (see `todo/v2-fix-07-examples-output-files.md`).
- `validation/benchmark.mbt` still needs to be added.

## Verification

- `moon fmt`: clean
- `moon info`: clean (1 warning pending fix)
- `moon test`: 487 passed, 0 failed
