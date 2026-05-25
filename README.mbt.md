<details open>
<summary><b>中文</b> | <a href="#english">English ↓</a></summary>

# moonsic

MoonBit 音乐语义库 — 用强类型描述音乐，导出 MIDI/WAV/浏览器事件。

## 快速开始

```moonbit
let chords = progression(c(3), Major, [I, V, VI, IV], half())
let lead = melody_str("C4q D4q E4q G4q")
let song = score_with([chords, lead], 120, four_four())
let midi = song.to_midi_bytes()  // MIDI 字节流
let wav = song.to_wav_bytes()    // WAV 音频
```

## 核心概念

- **Pitch** — 音高 = 音名 + 变音记号 + 八度，`c(4)` = C4 (MIDI 60)
- **Duration** — 时值：`whole()` `half()` `quarter()` `eighth()` `sixteenth()` `dotted()`
- **MusicEvent** — 轨道事件：`Note` | `Rest` | `Chord`
- **Track** — 有序事件序列，带通道/乐器/音量/声像/静音
- **Score** — 速度 + 拍号 + 多轨道
- **NoteEvent** — 运行时事件：start/duration/midi/velocity/channel

数据流：

```text
API / 文本记谱 → Score → NoteEvent → MIDI / WAV / 浏览器事件 → 声音
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
```moonbit
let t = melody_str("C4q D4q [E4 G4]h Rq D4q:64 x2")
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

## 项目结构

```
core.mbt        核心音乐模型
runtime.mbt     事件运行时 + 浏览器导出
midi.mbt        MIDI 导出
wav.mbt         WAV 渲染
helpers.mbt     快捷 API + 文本解析器
theory.mbt      乐理：音程/音阶/和弦
patterns.mbt    轨道变换
instruments.mbt GM 乐器
arpeggio.mbt    琶音生成
bass.mbt        低音生成
drums.mbt       鼓组
harmony.mbt     罗马数字 + 声部引导
key.mbt         调号拼写
structure.mbt   Section/arrange
time.mbt        节奏时间：Rational/Tuplet/TimeMap
interval.mbt    音程计算
scale_struct.mbt Scale 结构
theory_error.mbt TheoryError
serialize.mbt   JSON 编解码
score_layout.mbt 曲谱布局
score_midi.mbt  MIDI 语义适配
score_enhanced.mbt 专业曲谱结构
validate.mbt    校验报告
musicxml.mbt    MusicXML 导出
playback.mbt    播放时间线
generate.mbt    音乐生成
rhythm.mbt      节奏/动机
adapter.mbt     外部生成器协议
game_music.mbt  游戏音频 IR
benchmark.mbt   性能基准
web/            浏览器编辑器 + 播放器
```

## 命令

```bash
moon test          # 849 tests
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

## Quick Start

```moonbit
let chords = progression(c(3), Major, [I, V, VI, IV], half())
let lead = melody_str("C4q D4q E4q G4q")
let song = score_with([chords, lead], 120, four_four())
let midi = song.to_midi_bytes()
let wav = song.to_wav_bytes()
```

## Core Concepts

- **Pitch** — class + accidental + octave, `c(4)` = C4 (MIDI 60)
- **Duration** — `whole()` `half()` `quarter()` `eighth()` `sixteenth()` `dotted()`
- **MusicEvent** — `Note` | `Rest` | `Chord`
- **Track** — ordered events with channel/instrument/volume/pan/mute
- **Score** — tempo + time signature + tracks
- **NoteEvent** — runtime event: start/duration/midi/velocity/channel

Pipeline: `API / text notation → Score → NoteEvent → MIDI / WAV / browser events → sound`

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

```moonbit
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

## Project Structure

```
core.mbt · runtime.mbt · midi.mbt · wav.mbt · helpers.mbt · theory.mbt
patterns.mbt · instruments.mbt · arpeggio.mbt · bass.mbt · drums.mbt
harmony.mbt · key.mbt · structure.mbt · time.mbt · interval.mbt
scale_struct.mbt · theory_error.mbt · serialize.mbt · score_layout.mbt
score_midi.mbt · score_enhanced.mbt · validate.mbt · musicxml.mbt
playback.mbt · generate.mbt · rhythm.mbt · adapter.mbt · game_music.mbt
benchmark.mbt · web/
```

## Commands

```bash
moon test          # 849 tests
moon run cmd/main  # CLI demo
moon fmt
moon info
```

</div>
