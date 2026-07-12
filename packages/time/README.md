# packages/time — v2 Time 独立模拟包

v2 多包架构的第二块砖。从根包 `time_*.mbt` 复制并独立化为自有错误类型 `TimeError` 的零依赖 time 包。

## 与根包的区别

| 特性 | 根包 (v1.x) | packages/time (v2) |
|------|-------------|---------------------|
| 错误类型 | `TimeError` (与全包共享) | `TimeError` (独立) |
| TimeSignature | 来自 `score_core.mbt` | 包内联定义 |
| JSON 辅助 | 依赖 `ffi_json.mbt` / `serialize.mbt` | 内联最小实现 (TODO: 迁至 packages/json) |
| 依赖 | 全包 | **零依赖** (仅 moonbitlang/core prelude) |

## 包含模块

- `time_error.mbt` — TimeError 独立错误类型
- `time_types.mbt` — TimeSignature + is_valid_time_signature
- `time_rational.mbt` — Rational 有理数运算
- `time_duration.mbt` — DurUnit, TupletRatio, RhythmDuration, RhythmicValue + 换算
- `time_position.mbt` — TickPosition, BarPosition + 互转
- `time_map.mbt` — TempoChange, TimeSigChange, TimeMap + 查询
- `time_parse.mbt` — parse_time_sig / parse_dur_unit / parse_tempo
- `time_ffi.mbt` — FFI JSON 入口 (内联最小 JSON 解析)

## 推荐 API

| 推荐 (checked) | 旧版 (unchecked / legacy) |
|---------------|--------------------------|
| `rhythm_duration_to_fraction_checked(d)` | `rhythm_duration_to_fraction(d)` (abort on error) |
| `rhythm_duration_to_ticks(d, ppq)` | — (返回 Result) |
| `bar_length_ticks(sig, ppq)` | — (返回 Result) |
| `seconds_to_ticks_checked(s, bpm, ppq)` | `seconds_to_ticks(s, bpm, ppq)` |
| `ticks_to_seconds(ticks, bpm, ppq)` | — (返回 Result) |
| `parse_time_sig(s)` | — (返回 Result) |
| `parse_dur_unit(s)` | — (返回 Result) |
| `parse_tempo(s)` | — (返回 Result) |

## 运行测试

从仓库根目录执行（推荐）：

```bash
moon test packages/time
```

## 设计原则

- 零依赖：仅依赖 moonbitlang/core prelude
- TimeSignature 包内联（不依赖 score 包）
- JSON 辅助内联（不依赖 ffi_json/serialize）
- 不引用根包任何类型
- 不引入 Motif/PhrasePattern 等音乐生成逻辑
- 优先 checked Result API
