# packages/json — v2 JSON utility package

Small dependency-free JSON AST, parser, stringifier, and typed accessors.

## Scope

- `JsonValue` and `JsonField`
- compact `json_stringify`
- recursive-descent `json_parse`
- basic typed decode helpers

This package does not encode domain objects such as Score, MIDI, MusicXML, or game IR. Domain packages should build on this package.

## Run Tests

```bash
moon test packages/json
```
