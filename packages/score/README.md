# packages/score — v2 Score IR 独立模拟包

v2 的核心曲谱 IR 包，提供 SimpleScore（快速作曲）和 ScoreLayout（专业曲谱）两层模型。

## 依赖

- `packages/pitch` — Pitch 类型
- `packages/time` — RhythmDuration, TimeSignature, Rational

## 与根包的区别

| 特性 | 根包 (v1.x) | packages/score (v2) |
|------|-------------|---------------------|
| 时值类型 | `Duration` (score internal) | `@time.RhythmDuration` |
| 音高类型 | `Pitch` (同包) | `@pitch.Pitch` |
| 错误类型 | 分散 | `ScoreError` 独立 |
| 不含 | — | MIDI/MusicXML/WAV/Validation |

## 包含模块

- `score_error.mbt` — ScoreError + to_string
- `score_types.mbt` — ID 类型 + 枚举（MeasureRole, Clef, Barline, SectionKind, RepeatKind, etc.）
- `score_event.mbt` — ScoreEvent, NoteEvent, RestEvent, ChordEvent + Notation/Lyric 构造器
- `score_simple.mbt` — SimpleNote/Rest/Chord/Event/Track/Score + 构造器
- `score_layout.mbt` — Measure/Voice/Staff/Part/ScoreLayout + Section/Repeat/Ending 构造器

## 推荐 API

| 函数 | 说明 |
|------|------|
| `tempo_checked(120)` | 创建 Tempo |
| `ppq_checked(480)` | 创建 PPQ |
| `velocity_checked(100)` | 创建 Velocity |
| `note_event_checked(id, pitch, dur, ...)` | 创建 NoteEvent |
| `rest_event_checked(id, dur, ...)` | 创建 RestEvent |
| `chord_event_checked(id, pitches, dur, ...)` | 创建 ChordEvent |
| `simple_note_checked(pitch, dur)` | SimpleNote → SimpleEvent |
| `simple_track_checked(events, channel)` | SimpleTrack |
| `simple_score_checked(tracks, tempo, sig)` | SimpleScore |
| `measure_checked(index, role, ...)` | 创建 Measure |
| `part_checked(id, name, abbrev, staves)` | 创建 Part |
| `score_layout_checked(id, title, ...)` | 创建 ScoreLayout |
| `section_checked(name, kind, start, end)` | 创建 Section |
| `repeat_mark_checked(kind, measure, ...)` | 创建 RepeatMark |

## 运行测试

```bash
moon test packages/score
```

## 设计原则

- 仅依赖 pitch + time，不含 scale/chord/harmony/rhythm
- 不含 MIDI/MusicXML/WAV/Validation
- 所有构造器 checked-only，返回 Result
- ScoreError 不含跨包错误依赖
