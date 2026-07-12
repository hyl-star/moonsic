# packages/chord — v2 Chord 独立模拟包

v2 多包架构的第四块砖。从根包 `chord_quality/chord_parse` 复制并独立化为自有错误类型 `ChordError` 的 chord 包。

## 依赖

- `packages/pitch` — PitchClass, Accidental, Pitch 类型及构造器

## 与根包的区别

| 特性 | 根包 (v1.x) | packages/chord (v2) |
|------|-------------|---------------------|
| 错误类型 | `TheoryError` | `ChordError` |
| 和弦表示 | `MusicEvent` / `Chord` (依赖 score) | `Array[Pitch]` (纯音高数组) |
| 依赖 | 全包 | 仅 `packages/pitch` |
| 不含 Roman | RomanNumeral/progression | 等待 packages/harmony |

## 包含模块

- `chord_error.mbt` — ChordError 独立错误类型
- `chord_quality.mbt` — ChordQuality (11 种) + intervals + letter_steps + chord_pitches + chord_invert
- `chord_parse.mbt` — parse_chord / parse_chord_quality_checked

## 推荐 API

| 推荐 (checked) | 说明 |
|---------------|------|
| `chord_pitches(root, quality)` | 生成正确拼写的和弦音高数组 |
| `chord_invert(pitches, times)` | 和弦转位，返回 Result |
| `parse_chord("Cmaj7")` | 文本解析 → Array[Pitch] |
| `parse_chord_quality_checked("maj7")` | 解析品质后缀 |
| `chord_pitch_classes(root, quality)` | 音级列表（去重） |

## 运行测试

```bash
moon test packages/chord
```

## 设计原则

- 仅依赖 packages/pitch
- 不含 Duration/MusicEvent/Chord 等 score 类型
- 不含 RomanNumeral/progression/voice_lead
- 优先 checked Result API
