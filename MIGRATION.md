# Moonsic v1 -> v2 迁移指南

## 概述

moonsic v2 采用多包架构，将原来的单根包拆分为 25 个独立功能子包。根包 `username/moonsic` 不再导出任何 API，所有原有符号已迁移到 `packages/` 下的对应子包。

## 核心变更

| 变更类型 | v1 | v2 |
|---------|----|----|
| 包结构 | 单一根包 `username/moonsic` | 25 个子包在 `packages/` 下 |
| 引用方式 | 直接用符号名 | 用 `@package.Symbol` 引用 |
| 构造器 | 非检查构造 (`pitch(C, Sharp, 4)`) | 检查构造 (`pitch_checked(...)` / 同名但返回 `Result`) |
| Pitch 快捷构造 | `c(4)`, `cs(4)`, `db(4)` | `@pitch.c(4)`, `@pitch.cs(4)`, `@pitch.db(4)` |
| Duration 类型 | `Duration` 枚举 (`Whole/Half/Quarter/...`) | `@time.RhythmDuration` 结构 (`DurWhole/DurHalf/...`) |
| Score 模型 | `Score` struct + `Track` struct | `@score.SimpleScore` + `@score.SimpleTrack` (简化) |
| MIDI 导出 | `score.to_midi_bytes()` (非检查) | `@midi.simple_score_to_midi_bytes_checked()` (返回 `Result`) |
| MusicXML 导出 | `score_to_musicxml_string_checked()` | `@musicxml.simple_score_to_musicxml_string_checked()` |
| WAV 导出 | `score.to_wav_bytes()` | `@wav.playback_timeline_to_wav_bytes_checked()` |
| JSON 序列化 | `json_parse` / `json_stringify` | `@json.json_parse` / `@json.json_stringify` |
| 乐理 | `degree()` (非检查) | `@scale.key_degree_checked()` (返回 `Result`) |
| 旋律生成 | `generate_melody()` (非检查) | `@generate.generate_melody_checked()` (返回 `Result`) |
| 和弦进行 | `progression()` / `roman_progression()` | `@generate.generate_chord_progression_checked()` |
| 文本记谱 | `melody_str()` / `score_str()` | 已移除 (需手动构造 `SimpleEvent`) |
| 错误处理 | 混用异常和返回值 | 统一 `Result[T, E]` 模式 |

## API 映射表

### 音高 (Pitch)

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `Pitch` | `@pitch.Pitch` | replaced | 类型结构未变 |
| `PitchClass` | `@pitch.PitchClass` | replaced | 枚举值未变 |
| `Accidental` | `@pitch.Accidental` | replaced | 枚举值未变 |
| `pitch(class, acc, oct)` | `@pitch.pitch(class, acc, oct)` | replaced | 直接构造，不检查 |
| `pitch_checked(...)` | `@pitch.pitch_checked(...)` | replaced | 检查 octave |
| `c(4)` ... `b(4)` | `@pitch.c(4)` ... `@pitch.b(4)` | replaced | 自然音快捷构造 |
| `cs(4)` ... `gs(4)` | `@pitch.cs(4)` ... `@pitch.gs(4)` | replaced | 升号快捷构造 |
| `db(4)` ... `bb(4)` | `@pitch.db(4)` ... `@pitch.bb(4)` | replaced | 降号快捷构造 |
| `pitch_to_midi(p)` | `p.to_midi()` | replaced | Pitch 方法 |
| `midi_to_pitch_checked(n)` | `@pitch.midi_to_pitch_checked(n)` | replaced | 逆转换 |
| `pitch_to_frequency_checked(p)` | `@pitch.pitch_to_frequency_checked(p)` | replaced | 频率转换 |
| `pitch_equal(a, b)` | `@pitch.pitch_equal(a, b)` | replaced | 等音比较 |
| `enharmonic_equal(a, b)` | `@pitch.enharmonic_equal(a, b)` | replaced | 异名同音 |
| `transpose_pitch(p, semitones)` | `@pitch.transpose_pitch_checked(p, semitones)` | replaced | 移调 |

### 时值 (Time/Duration)

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `Duration` | (已移除) | removed | v1 `Whole/Half/Quarter` 枚举已弃用 |
| `RhythmDuration` | `@time.RhythmDuration` | replaced | 新类型：`{unit: DurUnit, dots: Int, tuplet: TupletRatio?}` |
| `DurUnit` | `@time.DurUnit` | replaced | `DurWhole/DurHalf/DurQuarter/...` |
| `whole()` | `@time.rhythm_duration(@time.DurWhole, 0, None)` | replaced | 需手动构造 |
| `half()` | `@time.rhythm_duration(@time.DurHalf, 0, None)` | replaced | |
| `quarter()` | `@time.rhythm_duration(@time.DurQuarter, 0, None)` | replaced | |
| `eighth()` | `@time.rhythm_duration(@time.DurEighth, 0, None)` | replaced | |
| `sixteenth()` | `@time.rhythm_duration(@time.DurSixteenth, 0, None)` | replaced | |
| `dotted(d)` | `@time.rhythm_duration(d.unit, d.dots + 1, d.tuplet)` | replaced | 手动加 dots |
| `time_signature(n, d)` | `@time.time_signature(n, d)` | replaced | 直接构造 |
| `four_four()` | `@time.four_four()` | replaced | |
| `tempo(bpm)` | `@score.tempo_checked(bpm)` | changed | 移到 score 包，返回 `Result` |
| `Rational` | `@time.Rational` | replaced | |
| `TimeSignature` | `@time.TimeSignature` | replaced | |
| `TimeMap` | `@time.TimeMap` | replaced | 增加了检查 |

### 得分模型 (Score)

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `Score` | `@score.SimpleScore` | renamed | 简化版：tempo + signature + tracks |
| `Track` | `@score.SimpleTrack` | renamed | channel/program 改用 `MidiChannel?`/`MidiProgram?` |
| `MusicEvent` | `@score.SimpleEvent` | renamed | `Note(Rest/Chord)` 枚举 |
| `Note` | `@score.SimpleNote` | renamed | |
| `Rest` | `@score.SimpleRest` | renamed | |
| `Chord` | `@score.SimpleChord` | renamed | |
| `n(p, d)` | `@score.simple_note_checked(p, d, None)` | replaced | 返回 `Result` |
| `nv(p, d, v)` | `@score.simple_note_checked(p, d, Some(vel))` | replaced | velocity 需 `Velocity` 类型 |
| `r(d)` | `@score.simple_rest_checked(d)` | replaced | |
| `ch(ps, d)` | `@score.simple_chord_checked(ps, d, None)` | replaced | |
| `melody(evts)` | `@score.simple_track_checked(evts, None, None)` | replaced | |
| `score_with(ts, bpm, sig)` | `@score.simple_score_checked(ts, tempo, sig)` | replaced | 参数顺序变化 |
| `Tempo` | `@score.Tempo` | replaced | |
| `Velocity` | `@score.Velocity` | replaced | 检查 0-127 |
| `MidiChannel` | `@score.MidiChannel` | replaced | 检查 0-15 |
| `MidiProgram` | `@score.MidiProgram` | replaced | 检查 0-127 |

### MIDI 导出

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `MidiEvent` | `@midi.MidiEvent` | replaced | 结构相同 |
| `MidiEventKind` | `@midi.MidiEventKind` | replaced | |
| `MidiScore` | `@midi.MidiScore` | replaced | |
| `MidiTrack` | `@midi.MidiTrack` | replaced | |
| `MidiError` | `@midi.MidiError` | replaced | |
| `note_on(t, ch, n, v)` | `@midi.note_on(t, ch, n, v)` | replaced | 返回 `Result` |
| `note_off(t, ch, n, v)` | `@midi.note_off(t, ch, n, v)` | replaced | 返回 `Result` |
| `program_change(t, ch, p)` | `@midi.program_change(t, ch, p)` | replaced | |
| `tempo_change(t, bpm)` | `@midi.tempo_change(t, bpm)` | replaced | |
| `midi_time_signature(t, n, d)` | `@midi.midi_time_signature(t, n, d)` | replaced | |
| `score_to_midi_score(s, ppq)` | `@midi.simple_score_to_midi_score(s, ppq)` | replaced | |
| `score_to_midi_bytes(s, ppq)` | `@midi.simple_score_to_midi_bytes_checked(s, ppq)` | replaced | 返回 `Result` |
| `midi_score_to_bytes(ms)` | `@midi.midi_score_to_bytes(ms)` | replaced | |
| `sort_midi_events(es)` | `@midi.sort_midi_events(es)` | replaced | |

### MusicXML 导出

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `MusicXmlScore` | `@musicxml.MusicXmlScore` | replaced | 结构简化 |
| `MusicXmlPart` | `@musicxml.MusicXmlPart` | replaced | |
| `MusicXmlMeasure` | `@musicxml.MusicXmlMeasure` | replaced | |
| `MusicXmlNote` | `@musicxml.MusicXmlNote` | replaced | |
| `MusicXmlError` | `@musicxml.MusicXmlError` | replaced | |
| `MusicXmlExportOptions` | `@musicxml.MusicXmlExportOptions` | replaced | 字段减少 |
| `default_musicxml_export_options()` | `@musicxml.default_musicxml_export_options()` | replaced | |
| `score_to_musicxml_checked(s, opts)` | `@musicxml.simple_score_to_musicxml_checked(s, opts)` | replaced | |
| `musicxml_to_string_checked(doc, opts)` | `@musicxml.musicxml_score_to_string(doc, opts)` | replaced | |

### JSON / 序列化

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `JsonValue` | `@json.JsonValue` | replaced | JNull/JBool/JNumber/JString/JArray/JObject |
| `JsonField` | `@json.JsonField` | replaced | |
| `json_parse(s)` | `@json.json_parse(s)` | replaced | |
| `json_stringify(v)` | `@json.json_stringify(v)` | replaced | |

### FFI (外部接口)

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `ffi_parse_pitch_to_midi(s)` | `@ffi.ffi_parse_pitch_to_midi(s)` | replaced | string-in/string-out |
| `ffi_build_scale(s)` | `@ffi.ffi_build_scale(s)` | replaced | |
| `ffi_score_to_musicxml_json(s)` | `@ffi.ffi_score_to_musicxml_json(s)` | replaced | |
| `ffi_generate_melody_json(s)` | `@ffi.ffi_generate_melody_json(s)` | replaced | |

### 乐理 (Theory)

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `Key` | `@scale.Key` | replaced | |
| `key(p, kind)` | `@scale.key(p, kind)` | replaced | |
| `ScaleKind` | `@scale.ScaleKind` | replaced | |
| `scale(root, kind, n)` | `@scale.scale(root, kind, n)` | replaced | |
| `degree(p, kind, n)` | `@scale.key_degree_checked(key, n, octave)` | changed | 需先构造 Key |
| `Interval` | `@interval.Interval` | replaced | |
| `interval_between(a, b)` | `@interval.interval_between_checked(a, b)` | replaced | |
| `parse_pitch(s)` | `@pitch.parse_pitch(s)` | replaced | |
| `parse_scale(s)` | `@scale.parse_scale(s)` | replaced | |
| `parse_chord(s)` | `@chord.parse_chord(s)` | replaced | |
| `ChordQuality` | `@chord.ChordQuality` | replaced | |
| `TheoryError` | `@pitch.PitchError` / `@chord.ChordError` / `@scale.ScaleError` | split | 各包独立错误类型 |

### 音乐生成 (Generate)

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `generate_melody(k, rp)` | `@generate.generate_melody_checked(k, rp, cfg)` | replaced | 多了一个 `GenerationConfig` 参数 |
| `generate_chord_progression(k, degs, d)` | `@generate.generate_chord_progression_checked(k, degs, d, cfg)` | replaced | |
| `GenerationConfig` | `@generate.GenerationConfig` | replaced | |
| `GenerateError` | `@generate.GenerateError` | replaced | |

### 游戏音乐 (Game)

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `GameMusicProject` | `@game.GameMusicProject` | replaced | |
| `GameCue` | `@game.GameCue` | replaced | |
| `GameSegment` | `@game.GameSegment` | replaced | |
| `GameTimelineSource` | `@game.GameTimelineSource` | replaced | |
| `game_project_checked(...)` | `@game.game_project_checked(...)` | replaced | |
| `game_cue_checked(...)` | `@game.game_cue_checked(...)` | replaced | |

### 鼓组 (Drums)

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `KICK/Snare/HiHat` 等常量 | `@drums.KICK` / `@drums.SNARE` 等 | replaced | |
| `basic_beat(bpm)` | `@drums.basic_beat(bpm)` | replaced | |
| `drum_note(n, d, v)` | `@drums.drum_note_checked(n, d, v)` | replaced | 返回 `Result` |

### 乐谱结构 (Structure)

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `Section` | `@structure.Section` | replaced | 移除了 `Intro/Verse/Chorus/...` 快捷构造的布局含义 |
| `SectionKind` | `@structure.SectionKind` | replaced | |
| `intro/chous/verse/...` | `@structure.section_checked(name, kind, tracks)` | changed | |

### 验证 (Validation)

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `ValidationReport` | `@validation.ValidationReport` | replaced | |
| `ValidationIssue` | `@validation.ValidationIssue` | replaced | |
| `ValidationCode` | `@validation.ValidationCode` | replaced | |

### v2 新增包 (无 v1 对应)

| v2 位置 | 职责 | 说明 |
|---------|------|------|
| `@demo` | 端到端流水线 | 请求->生成->导出，组合所有子包 |
| `@web` | Web/Browser 播放事件输出 | timeline/score 到浏览器 JSON 事件流 |

### 其他

| v1 根包符号 | v2 位置 | 状态 | 说明 |
|------------|---------|------|------|
| `NoteEvent` | `@timeline.NoteEvent` | replaced | 移到 timeline 包 |
| `PlaybackTimeline` | `@timeline.PlaybackTimeline` | replaced | |
| `melody_str(s)` / `score_str(s)` | (已移除) | removed | 文本记谱不再支持 |
| `arpaddiate(t, d)` | (已移除) | removed | 由 generate 替代 |
| `voice_lead(t)` | `@harmony.voice_lead(t)` | replaced | |
| `bass_from_progression(t, style, oct)` | (已移除) | removed | 由 generate 替代 |
| `accompany(key, style, ...)` | (已移除) | removed | 由 generate 替代 |
| GM 乐器常量 | `@midi.acoustic_grand_piano()` 等 | replaced | 移到 midi 包 |

## 迁移步骤

### 步骤 1: 更新 moon.pkg 依赖

```json
// 旧 (v1)
{
  "import": []

// 新 (v2) — 按需添加
{
  "import": [
    { "path": "username/moonsic/packages/pitch" },
    { "path": "username/moonsic/packages/time" },
    { "path": "username/moonsic/packages/score" },
    { "path": "username/moonsic/packages/midi" },
    { "path": "username/moonsic/packages/musicxml" }
  ]
}
```

### 步骤 2: 替换引用前缀

```moonbit
// 旧 (v1): 直接用符号名
let p = c(4)
let d = quarter()
let n = n(p, d)
let score = score1(melody([n]))

// 新 (v2): 用 @package. 前缀
let p = @pitch.c(4)
let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
let n = @score.simple_note_checked(p, dur, None).unwrap()
let track = @score.simple_track_checked([n], None, None).unwrap()
let tempo = @score.tempo_checked(120).unwrap()
let sig = @time.time_signature(4, 4)
let score = @score.simple_score_checked([track], tempo, sig).unwrap()
```

### 步骤 3: 切换到检查 API

v1 中大量构造器不检查输入合法性，v2 统一使用返回 `Result` 的 `_checked` 后缀函数。迁移时需要处理错误：

```moonbit
// 旧 (v1): 非检查
let score = score_with([track], 120, four_four())
let midi = score.to_midi_bytes()

// 新 (v2): 检查并处理错误
let score = match @score.simple_score_checked([track], tempo, sig) {
  Ok(s) => s
  Err(e) => abort("score error: \{e.to_string()}")
}
let midi = match @midi.simple_score_to_midi_bytes_checked(score, 480) {
  Ok(b) => b
  Err(e) => abort("MIDI error: \{e.to_string()}")
}
```

### 步骤 4: 替换 Duration 构造

v1 的 `Duration` 枚举已被 `RhythmDuration` 替代：

```moonbit
// 旧 (v1)
let d = dotted(quarter())

// 新 (v2)
let d = @time.rhythm_duration(@time.DurQuarter, 1, None)
```

## 向后兼容

根包 `username/moonsic` 的 `moon.pkg` 目前为空。所有旧文件已从根包移除。v1 API 不再可用。

使用 v2 packages 需要在 `moon.pkg` 中显式 import 对应的子包路径。`packages/demo` 和 `packages/web` 是 v2 新增包，无 v1 对应。

## 常见问题

**Q: 为什么不再用 `Duration` 枚举？**
A: `RhythmDuration` 支持连音 (tuplet) 和附点 (dots)，表达能力更强，且与 MIDI/MusicXML 标准直接对应。

**Q: 文本记谱 `melody_str()` 去哪了？**
A: 文本解析器已移除。推荐直接构造 `SimpleEvent`，或通过外部 JSON 接口输入。

**Q: 如何处理原来不返回错误的函数？**
A: v2 中大部分构造器返回 `Result`。可使用 `.unwrap()` 快速转换（数据合法时安全），或用模式匹配处理错误。

**Q: 为什么拆这么多包？**
A: 单一职责，按需引入。只写 WAV 的模块不需要引入 MusicXML 的所有类型。MoonBit 编译器会消除未使用的包。
