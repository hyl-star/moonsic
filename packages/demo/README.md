# Moonsic Demo / Composition Asset Pipeline

端到端音乐资产流水线：串接 `generate -> score -> validation -> midi/musicxml/timeline/wav/web/game`，输出 `CompositionAssetBundle`。

## Usage

```moonbit
// 默认配置完整 pipeline
let bundle = composition_asset_pipeline_checked(default_composition_request()).unwrap()

// JSON 入口
let json = composition_request_to_json(default_composition_request())
let bundle = composition_asset_pipeline_from_json_checked(json).unwrap()

// FFI 入口
let output = ffi_composition_assets_json(json)
```

## API

| Function | Description |
|---|---|
| `composition_asset_pipeline_checked` | 主入口，输入 `CompositionRequest`，输出资产包 |
| `composition_asset_pipeline_from_json_checked` | JSON/AI JSON 入口 |
| `ffi_composition_assets_json` | 字符串 FFI |
| `default_composition_request` | 稳定默认请求 |
| `composition_asset_bundle_to_json` | 资产包摘要 JSON |
| `composition_request_to_json` | 请求序列化 |
| `normalize_composition_request_checked` | 请求标准化 |

## Architecture

```
CompositionRequest (JSON / MoonBit)
  → normalize → NormalizedCompositionRequest
  → generate (melody + chords)
  → Score Assembly → SimpleScore
  → Validation → report
  → Export Adapter
    → MIDI bytes
    → MusicXML string
    → Timeline
    → WAV bytes
    → Web events JSON
    → Game IR JSON
  → CompositionAssetBundle
```

See `todo/v2-continue-demo-pipeline.md` for full design.
