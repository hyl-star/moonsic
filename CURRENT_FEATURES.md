<details open>
<summary><b>中文</b> | <a href="#english">English ↓</a></summary>

# CURRENT_FEATURES — 当前功能清单

本文档记录当前 `moonsic` 代码库已实现、部分实现和仅停留在设计阶段的功能，作为未来 v2 拆包的实践地图。

当前验证状态：

```text
moon test
Total tests: 850, passed: 850, failed: 0
```

## 1. 项目定位

当前 `moonsic` 已不仅是乐理核心模块。它目前是一个单包 MoonBit 音乐语义库，包含：

- 强类型音乐数据模型
- 乐理辅助
- 节奏/时间转换
- 曲谱/布局结构
- MIDI 导出
- MusicXML 导出
- JSON 序列化
- WAV 预览渲染
- 浏览器事件 demo 输出
- 基于规则的生成
- 外部生成器协议
- 游戏音乐 IR
- 校验与报告

形态：

```text
v1.x 单包 → 宽泛的功能原型 → 尚未达到 v2 多包架构
```

## 2. 已实现功能

以下功能有具体源文件，并通过当前测试套件覆盖。

### 2.1 核心音乐模型

文件：`core.mbt` `helpers.mbt` `patterns.mbt` `structure.mbt`

- `PitchClass` `Accidental` `Pitch` `Duration` `Tempo` `TimeSignature` `Note` `Rest` `Chord` `MusicEvent` `Track` `Score`
- 音高构造器：`c/d/e/f/g/a/b` `cs/ds/fs/gs` `db/eb/gb/ab/bb`
- 时值构造器：`whole/half/quarter/eighth/sixteenth/dotted`
- 事件构造器：`n/nv/r/ch/major/minor/dim/aug/dom7/maj7/min7`
- 轨道/乐谱构造：`melody` `score1` `score_with`
- 操作：transpose/stretch/repeat/concat/reverse/map velocity/volume/pan/mute

⚠️ 部分 convenience API 仍可 abort 或静默 fallback。

### 2.2 音高与 MIDI 辅助

文件：`core.mbt` `helpers.mbt` `midi.mbt` `pitch_class_rules.mbt`

- pitch↔MIDI 转换（含 checked）
- 移调
- 文本解析（支持负八度）
- 音高等同性/等音比较/排序
- MIDI↔频率转换

### 2.3 乐理

文件：`theory.mbt` `theory_error.mbt` `interval.mbt` `scale_struct.mbt` `key.mbt` `harmony.mbt`

- 12 个音程常量
- `IntervalQuality` `Interval` 结构 + 计算 + 解析
- 12 种音阶：Major/Minor/Dorian/Phrygian/Lydian/Mixolydian/Locrian/HarmonicMinor/MelodicMinor
- 拼写感知的音阶结构
- 调号构造 + 调号感知音级查询
- 11 种和弦品质 + 解析 + 和弦音
- 罗马数字和弦进行 + 文本进行
- 基础声部引导

⚠️ `degree` 已标 deprecated，首选 `degree_checked`。

### 2.4 节奏与时间

文件：`time.mbt` `rhythm.mbt` `parse_number_util.mbt`

- `Rational` 有理数 + 算术
- `RhythmDuration` `TupletRatio` `RhythmicValue`
- dots(0-3) 附点 / tuplet 连音
- 时值→fraction→ticks / ticks→beats / ticks→seconds / BPM→microseconds
- 小节长度 ticks / 拍号解析 / 时值解析 / Tempo 解析
- BarPosition↔Tick 互转
- TimeMap（多 tempo/拍号变化）
- RhythmPattern / Motif / PhrasePattern / 重复 / 变换 / 小节适配
- FFI JSON 包装

⚠️ 部分 typed FFI 已标 deprecated。

### 2.5 曲谱布局与增强曲谱结构

文件：`score_layout.mbt` `score_enhanced.mbt` `structure.mbt` `runtime.mbt`

- `Measure` `Voice` `Staff` `Part` `ScoreLayout`
- 构造/校验/转换（layout↔score, track↔voice/staff）
- `Section` `Repeat` `Ending` `Coda/Segno` `Notation` `Lyric` `Tie`
- 增强曲谱布局 + 往返转换

### 2.6 运行时时间线与浏览器事件

文件：`runtime.mbt` `playback.mbt` `web/` `cmd/main/`

- `NoteEvent` + track/score 展平 + 排序
- start/duration 秒/tick 转换
- 浏览器 JS 事件导出
- Web demo 播放页
- CLI demo 数据生成

### 2.7 MIDI 导出

文件：`midi.mbt` `score_midi.mbt`

- `MidiEvent`（NoteOn/Off/ProgramChange/ControlChange/TempoChange/TimeSignature/TrackName/EndOfTrack）
- `MidiScore` 校验 + Score→MidiScore→bytes
- checked 导出 API

⚠️ MIDI import 不完整。部分 legacy wrapper 已标 deprecated。

### 2.8 MusicXML 导出

文件：`musicxml.mbt`

- MusicXML score model（part-list/measure/attributes/clef/key/time/note/rest/direction/notation/backup）
- Score/ScoreLayout→MusicXML→XML string
- checked one-shot export + 导出就绪校验 + FFI JSON

⚠️ MusicXML import 不完整。

### 2.9 JSON 序列化

文件：`serialize.mbt` `ffi_json.mbt`

- `JsonValue` / `JsonField` + `json_stringify` / `json_escape`
- 递归下降 JSON 解析器
- Score/Track/NoteEvent/Pitch/Duration/Chord→JSON 双向

### 2.10 WAV 预览渲染

文件：`wav.mbt`

- `Score::to_wav_bytes` 44100Hz 16-bit mono PCM
- sine oscillator + attack/release envelope + normalize + master gain + RIFF header

⚠️ 无 `AudioRenderConfig`/`PcmBuffer`/`AudioError`。未接入 moondsp。

### 2.11 基于规则的生成

文件：`generate.mbt` `rhythm.mbt` `bass.mbt` `arpeggio.mbt` `accompany.mbt` `drums.mbt` `harmony.mbt`

- `GenerateMode` `MelodyContour` `AccompanimentPattern` `VoiceLeadingStrategy`
- 旋律/短语/和弦进行/bass/伴奏/游戏循环生成
- 确定性生成 + FFI JSON

⚠️ Convenience API 静默 fallback 已标 deprecated。

### 2.12 外部生成器适配器

文件：`adapter.mbt`

- `GenerationRequest/Response` `GenerationPatch` `ScoreFragment` `GenerationCandidate`
- Provider 能力声明 + 确定性 mock + JSON 往返 + FFI

### 2.13 游戏音乐 IR

文件：`game_music.mbt`

- `GameCue` `LoopRegion` `Stinger` `TransitionRule` `MusicState` `MusicParameter`
- `GameMusicProject` + 校验 + 时间线导出 + JSON 导出
- 44 种 enum/struct + 29 个 pub API

⚠️ 无运行时调度器，无引擎适配器。

### 2.14 校验与报告

文件：`validate.mbt`

- `ValidationSeverity/Code/Issue/Report` + `ValidationProfile`(6 档)
- Measure/Voice/Staff/Part/ScoreLayout/Score 全层级校验
- 导出就绪检查（MIDI/MusicXML/Game）
- Report JSON/GoldenText 输出 + FFI

### 2.15 乐器与鼓组

文件：`instruments.mbt` `drums.mbt`

- 8 个 GM 乐器常量 + `instrument()` 轨道设置
- 鼓常量 + `kick/snare/hat` + `basic_beat`

## 3. 部分实现

| 功能 | 已有 | 缺失 |
|------|------|------|
| MIDI Import | 事件模型 + 导出 | bytes→事件 import、事件→Score pipeline |
| MusicXML Import | 导出 + 模型 | 解析器、AST→ScoreLayout、roundtrip |
| 专业曲谱 | 布局 + 增强结构 | 作为所有 exporter 的主 IR、完整 repeat 语义 |
| WAV/Audio | 简单渲染 | moondsp 集成、stereo、synth patch、streaming |
| Browser/Web | demo 存在 | 稳定 schema 包、FFI 契约、production scheduler |
| Game Runtime | IR 存在 | 运行时调度器、引擎适配器、realtime transition |
| v2 Compat/Quality | 设计文档 + 部分 deprecated | 实际 compat/quality 包 |

## 4. 仅设计阶段

以下存在于 `todo/` 设计文档中，尚未完全落地：

```text
todo/v2-pitch.md   todo/v2-chord.md   todo/v2-rhytm.md
todo/v2-score.md   todo/v2-Validatio.md
todo/v2-MIDIandMusicXML.md   todo/v2-Generate.md
todo/v2-WAV-Web.md   todo/v2-GameMusicIR.md
```

## 5. 测试覆盖

```text
850 passed, 0 failed
8 个测试文件：moonsic_test / composition / core_runtime / serialize / theory_parse / time / timeline_midi_layout / benchmark
```

已知问题：`moonsic_test.mbt` 仍偏大，部分测试用宽泛 `Err(_)` 断言，缺少更多 golden test。

## 6. 发布风险

1. 单包架构过大
2. Legacy convenience API 仍可 abort/fallback
3. 部分 FFI 已 deprecated 但仍 public
4. MIDI/MusicXML import 不完整
5. WAV 只是简单内置渲染器
6. Game IR 运行时未实现
7. `todo/` 被 `.gitignore` 忽略

## 7. 建议下一步

1. **暂停加新功能** — 先稳定架构
2. **提取 Pitch 边界** — pitch_core/midi/parse/helpers/error
3. **提取 Time/Rhythm 边界** — legacy Duration vs strict RhythmDuration
4. **提取 Theory 和 Score** — 按 Pitch→Time→Scale/Key/Chord→ScoreLayout→Validation 顺序
5. **README 加功能状态表** — Implemented/Partial/Planned/Deprecated 分类

## 一句话

```text
moonsic 目前是一个宽泛的 v1.x 单包音乐 IR/生成/导出原型，测试覆盖良好；下一步重点是架构提取而非增加功能。
```

</details>

---

<div id="english">

# CURRENT_FEATURES

This document records what the current `moonsic` codebase already implements, what is partially implemented, and what is currently design-only. It is intended as a practical map for future v2 package splitting.

Current verification: `moon test` → **850 passed, 0 failed**

## 1. Project Identity

Current `moonsic` is a single-package MoonBit music semantic library with: strong music data models, theory helpers, rhythm/time conversion, score/layout structures, MIDI export, MusicXML export, JSON serialization, WAV preview rendering, browser event demo output, rule-based generation, external generator protocol, game music IR, and validation/reporting.

Shape: **v1.x single package → broad feature prototype → not yet v2 multi-package architecture**

## 2. Implemented Features

### 2.1 Core Music Model
Files: `core.mbt` `helpers.mbt` `patterns.mbt` `structure.mbt`
- All core types, pitch/duration/event constructors, track/score builders, operations (transpose/stretch/repeat/concat/reverse/map velocity/volume/pan/mute)
⚠️ Some convenience APIs can still abort or fallback

### 2.2 Pitch and MIDI Helpers
Files: `core.mbt` `helpers.mbt` `midi.mbt` `pitch_class_rules.mbt`
- pitch↔MIDI (checked), transposition, text parsing (negative octave), pitch equality/enharmonic/comparison, MIDI↔frequency

### 2.3 Theory
Files: `theory.mbt` `theory_error.mbt` `interval.mbt` `scale_struct.mbt` `key.mbt` `harmony.mbt`
- 12 intervals, Interval struct + calc + parse, 12 scale kinds, spelling-aware scale, key construction + key-aware degree, 11 chord qualities + parse + tones, Roman numeral progression + text + voice leading
⚠️ `degree` deprecated, prefer `degree_checked`

### 2.4 Rhythm and Time
Files: `time.mbt` `rhythm.mbt` `parse_number_util.mbt`
- Rational arithmetic, RhythmDuration, tuplets, dots, duration↔fraction↔ticks, bar length, BPM↔microseconds, ticks↔seconds, position↔tick, TimeMap, RhythmPattern/Motif/PhrasePattern + transform + fit-to-bars, FFI JSON wrappers
⚠️ Some typed FFI deprecated

### 2.5 Score Layout and Enhanced Structure
Files: `score_layout.mbt` `score_enhanced.mbt` `structure.mbt` `runtime.mbt`
- Measure/Voice/Staff/Part/ScoreLayout + construct/validate/convert, Section/Repeat/Ending/Coda/Segno/Notation/Lyric/Tie, enhanced layout + roundtrip

### 2.6 Runtime Timeline and Browser Events
Files: `runtime.mbt` `playback.mbt` `web/` `cmd/main/`
- NoteEvent + flattening + sort, start/duration sec/tick conversion, browser JS export, web demo, CLI demo

### 2.7 MIDI Export
Files: `midi.mbt` `score_midi.mbt`
- MidiEvent (9 kinds), MidiScore validation, Score→MidiScore→bytes, checked APIs
⚠️ MIDI import incomplete

### 2.8 MusicXML Export
Files: `musicxml.mbt`
- Full MusicXML score model, Score/ScoreLayout→XML string, checked export + readiness validation + FFI JSON
⚠️ MusicXML import incomplete

### 2.9 JSON Serialization
Files: `serialize.mbt` `ffi_json.mbt`
- JsonValue/JsonField, json_stringify/json_escape, recursive descent parser, Score/Track/NoteEvent/Pitch/Duration/Chord↔JSON bidirectional

### 2.10 WAV Preview
Files: `wav.mbt`
- Score::to_wav_bytes 44100Hz 16-bit mono, sine oscillator + envelope + normalize + master gain + RIFF header
⚠️ No AudioRenderConfig/PcmBuffer/AudioError. No moondsp integration.

### 2.11 Rule-Based Generation
Files: `generate.mbt` `rhythm.mbt` `bass.mbt` `arpeggio.mbt` `accompany.mbt` `drums.mbt` `harmony.mbt`
- GenerateMode/MelodyContour/AccompanimentPattern/VoiceLeadingStrategy, melody/phrase/chords/bass/accompaniment/game_loop generation, deterministic + FFI JSON
⚠️ Convenience APIs deprecated

### 2.12 External Generator Adapter
Files: `adapter.mbt`
- GenerationRequest/Response, Patch, ScoreFragment, Candidate, Provider capabilities, deterministic mock, JSON roundtrip + FFI

### 2.13 Game Music IR
Files: `game_music.mbt`
- GameCue/LoopRegion/Stinger/TransitionRule/MusicState/MusicParameter, GameMusicProject + validation + timeline export + JSON export, 44 types + 29 pub APIs
⚠️ No runtime scheduler or engine adapter

### 2.14 Validation and Reports
Files: `validate.mbt`
- ValidationSeverity/Code/Issue/Report, 6 ValidationProfiles (Editing/Strict/MIDI/MusicXML/Game/Golden), full hierarchy validation, export readiness checks, Report JSON/GoldenText + FFI

### 2.15 Instruments and Drums
Files: `instruments.mbt` `drums.mbt`
- 8 GM program helpers, track instrument setter, drum constants, kick/snare/hat, basic beat

## 3. Partially Implemented

MIDI Import · MusicXML Import · Professional Score Layout · WAV/Audio Backend · Browser/Web Package · Game Music Runtime · v2 Compat/Quality

## 4. Design-Only

v2 multi-package layout and dedicated packages (pitch/time/score/midi/musicxml/generate/wav/web/game/compat/quality) exist in `todo/v2-*.md` design documents.

## 5-7. Tests / Risks / Next Steps

850 tests passed. Main risks: single-package bloat, legacy abort APIs, incomplete imports, no moondsp backend. Recommended next: **stop adding features → extract Pitch boundary → then Time/Rhythm → Theory → Score → Validation → MIDI/MusicXML → Generate → WAV/Web → Game → Compat/Quality**.

**One sentence**: moonsic is currently a broad v1.x single-package music IR/generation/export prototype with strong test coverage, and the next major work is architecture extraction rather than more feature growth.

</div>
