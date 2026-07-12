# packages/rhythm — v2 Rhythm Pattern 独立模拟包

v2 多包架构的节奏模式包。从根包 `rhythm_pattern/rhythm_phrase` 提取纯 pattern/cell/repeat/join/fit 逻辑。

## 依赖

- `packages/time` — RhythmDuration, TimeSignature, Rational, bar/tick 换算

## 与根包的区别

| 特性 | 根包 (v1.x) | packages/rhythm (v2) |
|------|-------------|---------------------|
| 时值类型 | `Duration` (score) | `@time.RhythmDuration` |
| 错误类型 | `MotifError` | `RhythmError` |
| 不含 Motif | Motif/MotifEvent/MotifTransform | 纯 rhythm，无 pitch 依赖 |
| 依赖 | 全包 | 仅 `packages/time` |

## 包含模块

- `rhythm_error.mbt` — RhythmError
- `rhythm_cell.mbt` — AccentStrength, RhythmCell, RhythmPattern, RhythmTemplateKind, 内置模板
- `rhythm_pattern.mbt` — PatternJoinMode, PatternFillMode, PhrasePattern,  repeat/join/fit

## 推荐 API

| 函数 | 说明 |
|------|------|
| `rhythm_template(kind)` | 内置节奏模板 |
| `rhythm_pattern_checked(cells)` | 构建 pattern，校验空模板 |
| `repeat_pattern_checked(p, n)` | 重复 n 次 → PhrasePattern |
| `join_patterns_checked(ps, mode)` | 拼接多个 pattern |
| `fit_pattern_to_bars_checked(p, sig, bars, fill)` | 小节适配 |

## time 与 rhythm 的区别

| packages/time | packages/rhythm |
|---------------|-----------------|
| 单位/坐标：RhythmDuration, Rational, PPQ, TickPosition | 模式/乐句：RhythmCell, RhythmPattern, PhrasePattern |
| tick/beat/bar/second 换算 | repeat/join/fit_to_bars 操作 |
| DurUnit, TupletRatio | PatternJoinMode, PatternFillMode |

## 运行测试

```bash
moon test packages/rhythm
```
