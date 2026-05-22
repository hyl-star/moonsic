# moonsic

用 MoonBit 写旋律，导出 MIDI，在浏览器播放。

```moonbit
// 定义一条 C 大调旋律
let p = @moonsic.pitch
let melody = @moonsic.track([
  @moonsic.Note(@moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter)),
  @moonsic.Note(@moonsic.note(p(@moonsic.D, @moonsic.Natural, 4), @moonsic.Quarter)),
  @moonsic.Note(@moonsic.note(p(@moonsic.E, @moonsic.Natural, 4), @moonsic.Quarter)),
  @moonsic.Note(@moonsic.note(p(@moonsic.G, @moonsic.Natural, 4), @moonsic.Quarter)),
  @moonsic.Note(@moonsic.note(p(@moonsic.C, @moonsic.Natural, 5), @moonsic.Half)),
  @moonsic.Rest(@moonsic.rest(@moonsic.Half)),
])

let score = @moonsic.score_with_tempo([melody], @moonsic.tempo(120), @moonsic.four_four())

// 导出 MIDI 字节流
let bytes = score.to_midi_bytes()
// bytes 可以直接写入 .mid 文件，或在浏览器中播放
```

## 浏览器播放

```bash
# 用任意 HTTP 服务器打开 web/ 目录
python -m http.server 8000 -d web
# 打开 http://localhost:8000，点击 Play
```

## 命令行

```bash
moon run cmd/main    # 运行示例，导出 demo.mid
moon test            # 33 tests
moon fmt             # 格式化
moon info            # 更新接口文件
```

## 项目结构

```
core.mbt     — 核心音乐模型（PitchClass, Accidental, Pitch, Duration, Tempo, TimeSignature,
               Note, Rest, MusicEvent, Track, Score，验证函数）
runtime.mbt  — 事件运行时（NoteEvent，Track/Score 展开为时间线）
midi.mbt     — 频率转换 + MIDI 导出（Format 1，CAIMEOX/midi）
web/         — 浏览器播放 demo（Play/Stop，WebAudio OscillatorNode）
cmd/main/    — CLI 入口
```

## API 速览

| 类型 | 构造器 | 核心方法 |
|------|--------|----------|
| `PitchClass` | `C, D, E, F, G, A, B` | `base_semitone()`, `to_string()` |
| `Accidental` | `Natural, Sharp, Flat` | `semitone_offset()`, `to_string()` |
| `Pitch` | `pitch(class, acc, octave)`, `natural(class, octave)` | `to_midi()`, `transpose(n)`, `frequency()` |
| `Duration` | `Whole, Half, Quarter, Eighth, Sixteenth` | `beats()`, `ticks(ppq)`, `seconds(bpm)` |
| `Tempo` | `tempo(bpm)`, `default_tempo()` | `quarter_seconds()` |
| `TimeSignature` | `time_signature(n,d)`, `four_four()` | `measure_beats()` |
| `Note` | `note(pitch, dur)`, `note_with_velocity(p, d, v)` | `transpose(n)` |
| `Rest` | `rest(duration)` | |
| `MusicEvent` | `Note(note)`, `Rest(rest)` | `duration()`, `transpose(n)` |
| `Track` | `track(events)`, `track_with_channel(e, ch)` | `append(e)`, `transpose(n)`, `repeat(n)`, `to_note_events()` |
| `Score` | `score(tracks)`, `score_with_tempo(t, t, ts)` | `transpose(n)`, `to_note_events()`, `to_midi_bytes()` |
| `NoteEvent` | *(由 to_note_events 生成)* | `end()`, `start_seconds(bpm)`, `duration_ticks(ppq)` |
