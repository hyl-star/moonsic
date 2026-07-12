# packages/harmony — v2 Harmony 独立模拟包

v2 多包架构的第五块砖，负责罗马数字和声进行和声部引导。从根包 `roman_progression/voice_leading/theory_legacy` 提取纯理论逻辑。

## 依赖

- `packages/pitch` — Pitch 类型
- `packages/scale` — Key / ScaleKind / key_degree_checked
- `packages/chord` — ChordQuality / chord_pitches / chord_invert

## 与根包的区别

| 特性 | 根包 (v1.x) | packages/harmony (v2) |
|------|-------------|---------------------|
| 错误类型 | `TheoryError` | `HarmonyError` |
| 输出类型 | `Track` (依赖 score) | `Array[Array[Pitch]]` (纯理论) |
| 依赖 | 全包 | pitch + scale + chord |
| 不含生成 | melody/bass/accompaniment | 只有和声进行 |

## 包含模块

- `harmony_error.mbt` — HarmonyError
- `roman_numeral.mbt` — RomanNumeral + parse_roman_text + roman_chord_quality
- `harmony_progression.mbt` — roman_progression_checked / roman_progression_text_checked
- `voice_leading.mbt` — sort_pitches / chord_distance_pitches / voice_lead_pitches

## 推荐 API

| 函数 | 说明 |
|------|------|
| `parse_roman_text("I V vi IV")` | 文本 → Array[RomanNumeral] |
| `roman_chord_quality(kind, rn)` | 调式中罗马数字的和弦品质 |
| `roman_progression_checked(key, rns, oct)` | 进行 → Array[Array[Pitch]] |
| `roman_progression_text_checked(key, "I V", oct)` | 文本进行 → Array[Array[Pitch]] |
| `voice_lead_pitches(chords)` | 声部引导，最小化声部移动 |
| `chord_distance_pitches(a, b)` | 两个和弦的声部距离 |
| `sort_pitches(pitches)` | 按 MIDI 升序排序 |

## 运行测试

```bash
moon test packages/harmony
```

## 边界

harmony 包只做"和声分析/进行"，不生成旋律/贝斯/伴奏。生成器在后续 `packages/generate` 中。
