# packages/generate — v2 Generate package

Rule-based generation targeting v2 score types.

## Dependencies

- `packages/pitch`
- `packages/scale`
- `packages/chord`
- `packages/harmony`
- `packages/rhythm`
- `packages/time`
- `packages/score`

## Scope

- melody generation from key + rhythm pattern
- chord progression generation from scale degrees
- phrase dispatcher for melody/chords
- output is `@score.SimpleTrack` / `@score.SimpleScore`

This v2 package does not depend on root `Track` or `Score`.

## Run Tests

```bash
moon test packages/generate
```
