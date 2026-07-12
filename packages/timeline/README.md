# packages/timeline — v2 Timeline package

Runtime note timeline for v2 score types.

## Dependencies

- `packages/pitch`
- `packages/time`
- `packages/score`

## Scope

- flat `NoteEvent`
- `SimpleScore -> Array[NoteEvent]`
- `ScoreLayout -> Array[NoteEvent]`
- beat timeline to seconds `PlaybackTimeline`
- browser demo JS event serialization

## Run Tests

```bash
moon test packages/timeline
```
