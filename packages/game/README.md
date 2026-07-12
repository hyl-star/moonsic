# packages/game — v2 Game Music IR package

Dynamic/game music IR independent from the root package.

## Dependencies

- `packages/time`
- `packages/timeline`
- `packages/json`

## Scope

- game cue/segment/project data types
- timeline-backed segment source
- transition rules and loop regions
- validation report
- JSON summary export

This package does not implement a realtime scheduler or engine adapter.

## Run Tests

```bash
moon test packages/game
```
