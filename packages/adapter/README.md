# moonsic adapter

External generation adapter protocol for v2 packages.

The package provides:

- checked request, provider, and patch types
- JSON encode/decode for generation request/response and `SimpleScore`
- deterministic mock provider for tests and demos
- patch validation/application for `SimpleScore` track operations
- string-in/string-out FFI helpers

Dependencies are limited to `json`, `pitch`, `scale`, `score`, and `time`.
