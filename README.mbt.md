<details open>
<summary><b>中文</b> | <a href="#english">English ↓</a></summary>

# moonsic

MoonBit 音乐语义库 — 用强类型描述音乐，导出 MIDI/WAV/浏览器事件。

> **v2 多包架构已发布。** v1 根包 API 已弃用，请参考 [MIGRATION.md](./MIGRATION.md) 迁移。

## v2 多包架构 (25 packages)

```
packages/
  pitch/      音高 + 快捷构造 + MIDI/频率 + 解析
  interval/   音程计算 + 转位 + 解析
  time/       节奏时间 + RhythmDuration + TimeSignature
  scale/      音阶 + 调性 + Key
  chord/      和弦品质 + 解析 + 展开
  harmony/    罗马数字 + 声部引导
  rhythm/     节奏模板 + 模式 + Phrase
  motif/      音级动机 + 变换
  score/      SimpleScore + ScoreLayout + 构造器
  validation/ 校验报告 + profile
  json/       零依赖 JSON 解析/序列化
  parse/      统一解析 facade
  midi/       MIDI 事件 + 排序 + 字节导出 + GM 乐器
  musicxml/   MusicXML 模型 + 转换 + 字符串写入
  timeline/   NoteEvent 时间线 + 浏览器事件导出
  wav/        WAV 渲染
  game/       游戏音乐 IR
  generate/   旋律/和弦/bass/伴奏生成
  adapter/    外部生成器协议
  drums/      GM 鼓组 + 基本节拍
  transform/  SimpleTrack 纯变换
  structure/  歌曲段落 + arrange
  ffi/        string-in/string-out facade
  demo/       端到端作曲流水线
```

## 快速开始 (v2)

```moonbit nocheck
///| 导入所需包（moon.pkg 中配置）

///| import: pitch, time, score, midi

///|
let p = @pitch.c(4) // C4

///|
let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)

///|
let vel = @score.velocity_checked(100).unwrap()

///|
let n = @score.simple_note_checked(p, dur, Some(vel)).unwrap()

///|
let track = @score.simple_track_checked([n], None, None).unwrap()

///|
let tempo = @score.tempo_checked(120).unwrap()

///|
let sig = @time.time_signature(4, 4)

///|
let score = @score.simple_score_checked([track], tempo, sig).unwrap()

///|
let midi = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
```

## v1 快速开始（已弃用）

<details>
<summary>点击展开 v1 API 示例</summary>

```moonbit nocheck
///|
let chords = progression(c(3), Major, [I, V, VI, IV], half())

///|
let lead = melody_str("C4q D4q E4q G4q")

///|
let song = score_with([chords, lead], 120, four_four())

///|
let midi = song.to_midi_bytes() // MIDI 字节流

///|
let wav = song.to_wav_bytes() // WAV 音频
```

</details>

## 核心概念

- **Pitch** — 音高 = 音名 + 变音记号 + 八度，`@pitch.c(4)` = C4 (MIDI 60)
- **RhythmDuration** — 时值：`@time.rhythm_duration(unit, dots, tuplet)`
- **SimpleEvent** — 轨道事件：`Note` | `Rest` | `Chord` (在 `@score` 包)
- **SimpleTrack** — 有序事件序列，带 channel/program/volume/pan/mute
- **SimpleScore** — 速度 + 拍号 + 多轨道
- **NoteEvent** — 运行时事件：start/duration/midi/velocity/channel (在 `@timeline` 包)

数据流 (v2)：

```text
@score.SimpleScore → @midi / @musicxml / @timeline → @wav / Browser / Bytes
```

## API 速览

### 音高
| 函数 | 结果 | MIDI |
|------|------|------|
| `c(4)` `d(4)` `e(4)` `f(4)` `g(4)` `a(4)` `b(4)` | 自然音 | 60~71 |
| `cs(4)` `ds(4)` `fs(4)` `gs(4)` | 升号 | 61~68 |
| `db(4)` `eb(4)` `gb(4)` `ab(4)` `bb(4)` | 降号 | 61~70 |
| `pitch(C, Sharp, 4)` | 完整构造 | — |

### 时值
| 函数 | 拍数 |
|------|------|
| `whole()` | 4.0 |
| `half()` | 2.0 |
| `quarter()` | 1.0 |
| `eighth()` | 0.5 |
| `sixteenth()` | 0.25 |
| `dotted(quarter())` | 1.5 |

### 事件
| 函数 | 说明 |
|------|------|
| `n(c(4), quarter())` | 音符（力度100） |
| `nv(c(4), quarter(), 64)` | 指定力度 |
| `r(half())` | 休止 |
| `major(c(3), half())` | 大三和弦 |
| `minor(a(3), half())` | 小三和弦 |
| `dim` `aug` `dom7` `maj7` `min7` | 其他和弦 |
| `ch([c(4),e(4),g(4)], q())` | 自定义和弦 |

### 轨道与乐谱
| 函数 | 说明 |
|------|------|
| `melody([...])` | 创建轨道 |
| `score1(track)` | 单轨乐谱 |
| `score_with([tracks], bpm, ts)` | 多轨乐谱 |
| `track.transpose(n)` | 移调 |
| `track.stretch(f)` `track.concat` `track.reverse` | 变换 |

### 乐理
| 函数 | 说明 |
|------|------|
| `scale(root, kind, octaves)` | 音阶 |
| `degree(root, kind, n)` | 第N级 |
| `progression(root, kind, [I,IV,V], dur)` | 和弦进行 |
| `roman_progression(key, "I V vi IV", dur)` | 文本进行 |
| `voice_lead(chords)` | 声部引导 |
| `bass_from_progression(chords, style, oct)` | 低音 |
| `arpeggiate(chords, step_dur)` | 琶音 |

### 文本记谱
```moonbit nocheck
///|
let t = melody_str("C4q D4q [E4 G4]h Rq D4q:64 x2")

///|
let s = score_str("tempo 140\ntime 3/4\nC4q D4q E4q")
```
格式：`音名[变音][八度]时值[:力度]`。和弦：`[音1 音2...]时值`。重复：`xN`。

### 导出

| 函数 | 输出 |
|------|------|
| `song.to_midi_bytes()` | MIDI 字节流 (SMF Format 1) |
| `song.to_wav_bytes()` | WAV 字节流 (44100Hz 16-bit mono) |
| `score_to_json(song)` | JSON 字符串 |
| `score_to_musicxml_string_checked(s, opts)` | MusicXML 字符串 |

### 曲谱结构（进阶）
| 模块 | 内容 |
|------|------|
| `score_layout.mbt` | Measure/Voice/Staff/Part/ScoreLayout |
| `score_enhanced.mbt` | Section/Repeat/Ending/Notation/Lyric/Tie |
| `validate.mbt` | ValidationProfile + 导出就绪校验 |

### 生成
| 模块 | 内容 |
|------|------|
| `generate.mbt` | 旋律/和弦/bass/伴奏/游戏循环生成 |
| `rhythm.mbt` | 节奏模板/动机/模式变换 |

### 协议
| 模块 | 内容 |
|------|------|
| `adapter.mbt` | 外部生成器协议 (GenerationRequest/Response) |
| `game_music.mbt` | 游戏音频 IR (Cue/Loop/Stinger/Transition) |

## 项目结构 (v2)

```
moon.pkg               根包（空）
moon.mod.json          模块元数据
packages/              24 个子包
  pitch/              音高 + 快捷构造 + MIDI/频率 + 解析
  interval/           音程计算 + 转位 + 解析
  time/               节奏时间 + RhythmDuration + TimeSignature
  scale/              音阶 + 调性 + Key
  chord/              和弦品质 + 解析 + 展开
  harmony/            罗马数字 + 声部引导
  rhythm/             节奏模板 + 模式 + Phrase
  motif/              音级动机 + 变换
  score/              SimpleScore + ScoreLayout + 构造器
  validation/         校验报告 + profile
  json/               零依赖 JSON 解析/序列化
  parse/              统一解析 facade
  midi/               MIDI 事件 + 排序 + 字节导出 + GM 乐器
  musicxml/           MusicXML 模型 + 转换 + 字符串写入
  timeline/           NoteEvent 时间线 + 浏览器事件导出
  wav/                WAV 渲染
  game/               游戏音乐 IR + 校验 + JSON 导出
  generate/           旋律/和弦/bass/伴奏/loop 生成
  adapter/            外部生成器请求/响应/补丁
  drums/              GM 鼓组 + 基本节拍
  transform/          SimpleTrack 纯变换
  structure/          歌曲段落 + arrange
  ffi/                string-in/string-out facade
  demo/               端到端作曲流水线
cmd/main/             CLI 入口
web/                  浏览器编辑器 + 播放器
```

## 命令

```bash
moon test          # 386+ tests
moon run cmd/main  # CLI demo
moon fmt           # 格式化
moon info          # 更新接口
```

## API 稳定性

**Stable**：Pitch/Duration 构造器、事件构造器、Track/Score 构造、Music 操作（transpose/stretch/repeat/concat）、Render/export（to_midi_bytes/to_wav_bytes）、核心类型

**Experimental**：`melody_str`/`score_str`、`roman_progression`/`accompany`/`voice_lead`、Bass/Arpeggio 生成器、Style 枚举、newv1plus 模块

</details>

---

<div id="english">

# moonsic

MoonBit music IR and export library with MIDI, WAV, and browser event output.

> **v2 multi-package architecture released.** See [MIGRATION.md](./MIGRATION.md) for v1 to v2 migration.

## v2 Multi-Package Architecture (25 packages)

```
packages/
  pitch/      pitch classes, shortcuts, MIDI/frequency, parsing
  interval/   interval quality, calculation, inversion, parsing
  time/       rational time, RhytDuration, TimeSignature
  scale/      scales, keys
  chord/      chord qualities, parsing, pitch expansion
  harmony/    roman numerals, voice leading
  rhythm/     rhythm cells, patterns, phrase fitting
  motif/      degree motifs, transforms, track conversion
  score/      SimpleScore, ScoreLayout, constructors
  validation/ validation reports, profiles
  json/       zero-dependency JSON parse/stringify
  parse/      unified parse-to-JSON facade
  midi/       MIDI events, sorting, bytes export, GM instruments
  musicxml/   MusicXML model, conversion, string writer
  timeline/   NoteEvent timeline, browser event export
  wav/        WAV rendering
  game/       game music IR, validation, JSON export
  generate/   melody, chords, bass, accompaniment generation
  adapter/    external generator request/response/patch
  drums/      GM drum helpers, basic beat generation
  transform/  pure SimpleTrack transforms
  structure/  song sections, arrangement
  ffi/        string-in/string-out facade
  demo/       end-to-end composition pipeline
```

## Quick Start (v2)

```moonbit nocheck
///| Import required packages in moon.pkg

///| import: pitch, time, score, midi

///|
let p = @pitch.c(4)

///|
let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)

///|
let vel = @score.velocity_checked(100).unwrap()

///|
let n = @score.simple_note_checked(p, dur, Some(vel)).unwrap()

///|
let track = @score.simple_track_checked([n], None, None).unwrap()

///|
let tempo = @score.tempo_checked(120).unwrap()

///|
let sig = @time.time_signature(4, 4)

///|
let score = @score.simple_score_checked([track], tempo, sig).unwrap()

///|
let midi = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
```

## v1 Quick Start (deprecated)

<details>
<summary>Click to expand v1 API examples</summary>

```moonbit nocheck
///|
let chords = progression(c(3), Major, [I, V, VI, IV], half())

///|
let lead = melody_str("C4q D4q E4q G4q")

///|
let song = score_with([chords, lead], 120, four_four())

///|
let midi = song.to_midi_bytes()

///|
let wav = song.to_wav_bytes()
```

</details>

## Core Concepts

- **Pitch** — class + accidental + octave, `@pitch.c(4)` = C4 (MIDI 60)
- **RhythmDuration** — `@time.rhythm_duration(unit, dots, tuplet)`
- **SimpleEvent** — `Note` | `Rest` | `Chord` (in `@score` package)
- **SimpleTrack** — ordered events with channel/program/volume/pan/mute
- **SimpleScore** — tempo + time signature + tracks
- **NoteEvent** — runtime event: start/duration/midi/velocity/channel (in `@timeline` package)

Pipeline (v2): `@score.SimpleScore → @midi / @musicxml / @timeline → @wav / Browser / Bytes`

## Pitch Shortcuts

| Function | Result | MIDI |
|----------|--------|------|
| `c(4)`..`b(4)` | natural | 60-71 |
| `cs(4)`..`gs(4)` | sharp | 61-68 |
| `db(4)`..`bb(4)` | flat | 61-70 |

## Events

| Function | Description |
|----------|-------------|
| `n(p, d)` | Note with default velocity |
| `nv(p, d, v)` | Note with velocity |
| `r(d)` | Rest |
| `major(r, d)` / `minor(r, d)` | Triads |
| `dim` `aug` `dom7` `maj7` `min7` | Other chords |

## Track & Score

| Function | Description |
|----------|-------------|
| `melody([...])` | Create track |
| `score1(t)` | Single-track score |
| `score_with([tracks], bpm, ts)` | Multi-track score |
| `track.transpose/stretch/concat/reverse` | Transforms |

## Theory

| Function | Description |
|----------|-------------|
| `scale(root, kind, n)` | Build scale |
| `degree(root, kind, n)` | Nth degree |
| `progression(root, kind, rns, dur)` | Chord progression |
| `roman_progression(key, text, dur)` | Text-based progression |
| `voice_lead(chords)` | Voice leading |
| `bass_from_progression` / `arpeggiate` | Generators |

## Text Notation

```moonbit nocheck
///|
let t = melody_str("C4q D4q [E4 G4]h Rq D4q:64 x2")
```
Format: `Note[Accidental]OctaveDuration[:Velocity]`. Chord: `[P1 P2...]Dur`. Repeat: `xN`.

## Export

| Function | Output |
|----------|--------|
| `song.to_midi_bytes()` | MIDI bytes (SMF Format 1) |
| `song.to_wav_bytes()` | WAV bytes (44100Hz 16-bit mono) |
| `score_to_json(song)` | JSON string |
| `score_to_musicxml_string_checked(s, opts)` | MusicXML string |

## Project Structure (v2)

```
moon.pkg               root package (empty)
moon.mod.json          module metadata
packages/              24 sub-packages (see v2 section above)
cmd/main/              CLI entrypoint
web/                   browser editor + player
```

## Commands

```bash
moon test          # 386+ tests
moon run cmd/main  # CLI demo
moon fmt
moon info
```

</div>
