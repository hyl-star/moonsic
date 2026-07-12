# packages/scale — v2 Scale/Key 独立模拟包

v2 多包架构的第三块砖。从根包 `scale_kind/scale_core/scale_parse/key_core` 复制并独立化为自有错误类型 `ScaleError` 的 scale/key 包。

## 依赖

- `packages/pitch` — PitchClass, Accidental, Pitch 类型及构造器

## 与根包的区别

| 特性 | 根包 (v1.x) | packages/scale (v2) |
|------|-------------|---------------------|
| 错误类型 | `TheoryError` | `ScaleError` |
| Pitch 类型 | 同包定义 | 从 `@pitch` 导入 |
| 依赖 | 全包 | 仅 `packages/pitch` |
| 不含 Chord | ChordQuality/RomanNumeral | 等待 packages/chord |

## 包含模块

- `scale_error.mbt` — ScaleError 独立错误类型
- `scale_kind.mbt` — ScaleKind 枚举 (12 种音阶) + intervals
- `scale_core.mbt` — Scale 结构体 + build_scale / build_scale_spelled
- `scale_parse.mbt` — parse_scale 文本解析
- `key_core.mbt` — Key 结构体 + key_degree_checked + key_spelling 调号表

## 推荐 API

| 推荐 (checked) | 旧版 (unchecked / legacy) |
|---------------|--------------------------|
| `key_degree_checked(deg, octave)` | `Key::degree(deg, octave)` (abort) |
| `build_scale(root, kind)` | — |
| `build_scale_spelled(root, acc, kind)` | — |
| `parse_scale(s)` | — |

## 运行测试

```bash
moon test packages/scale
```

## 设计原则

- 依赖 packages/pitch，不依赖根包
- 不含 ChordQuality、Chord、RomanNumeral、voice_lead
- 所有核心 API 返回 Result
- ScaleKind 可被 packages/chord 复用
