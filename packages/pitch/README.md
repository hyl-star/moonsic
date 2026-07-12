# packages/pitch — v2 Pitch 独立模拟包

MoonBit v2 多包架构的第一块试验砖。从根包 `pitch_*.mbt` 复制并独立化为自有错误类型 `PitchError` 的完整 pitch 包。

## 与根包的区别

| 特性 | 根包 (v1.x) | packages/pitch (v2) |
|------|-------------|---------------------|
| 错误类型 | `TheoryError` | `PitchError` |
| 依赖 | 全包 | 仅 `@math` |
| 测试 | 混入主测试文件 | 独立 `pitch_test.mbt` |
| parse_pitch 边界 | 仅检查下界 | 检查 MIDI 0-127 全范围 |

## 包含模块

- `pitch_core.mbt` — PitchClass, Accidental, Pitch + 基本运算 + checked API
- `pitch_midi.mbt` — MIDI/频率互转
- `pitch_parse.mbt` — 文本解析 (parse_pitch, parse_pitch_class)
- `pitch_helpers.mbt` — 快捷构造器 (c, d, e, ..., cs, db, ...)
- `pitch_class_rules.mbt` — 字母表顺序映射 (class_index, class_from_index)
- `pitch_error.mbt` — 独立错误类型 PitchError

## 推荐 API

v2 目标为 checked-only。优先使用以下 API：

| 推荐 (checked) | 旧版 (unchecked, deprecated) |
|---------------|---------------------------|
| `pitch_to_midi(p)` | — |
| `midi_to_pitch_checked(n)` | `midi_to_pitch(n)` |
| `transpose_checked(semitones)` | `Pitch::transpose(semitones)` |
| `transpose_pitch(p, n)` | — |
| `pitch_to_frequency_checked(p)` | `Pitch::frequency()` |
| `frequency_to_nearest_midi_checked(hz)` | — |
| `parse_pitch(s)` | — |
| `parse_pitch_class(s)` | — (注意：会丢弃变音记号) |

## 运行测试

从仓库根目录执行（推荐）：

```bash
moon test packages/pitch
```

注意：`cd packages/pitch && moon test` 可能因上层 `.mooncakes` 锁权限失败，请使用根目录命令。

## 设计原则

- 零依赖：仅导入 `moonbitlang/core/math`
- 不引用根包任何类型
- 不依赖 TheoryError/TimeError/MidiError
- API 签名保持与根包同名函数一致（除错误类型外）
- 未标注 deprecated 的 unchecked 函数将在 v2 正式版中移除或迁移到 compat 层
