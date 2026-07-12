# packages/midi — v2 MIDI 独立模拟包

消费 packages/score 的 SimpleScore，输出标准 MIDI 文件字节流，支持导入导出双向转换。

## 依赖

- `packages/score` — SimpleScore / SimpleTrack / SimpleEvent
- `packages/time` — RhythmDuration / TimeSignature / PPQ / Rational
- `CAIMEOX/midi` — SMF 二进制序列化 / 反序列化

## 包含模块

- `midi_error.mbt` — MidiError（含 MidiImportError）
- `midi_event.mbt` — MidiEventKind / MidiEvent / note_on / note_off / tempo_change 等构造器
- `midi_score.mbt` — MidiTrack / MidiScore + simple_score_to_midi_score
- `midi_bytes.mbt` — MidiScore → Bytes 导出
- `midi_import.mbt` — Bytes → MidiEvent → SimpleScore 导入

## 导入 API

- `midi_bytes_to_events(bytes)` — 解析 .mid bytes → 平铺的 MidiEvent 数组
- `midi_events_to_score(events, ppq)` — 将 MidiEvent 数组配对为 SimpleScore
- `midi_bytes_to_score(bytes)` — 快捷管线：bytes → SimpleScore

## 运行测试

```bash
moon test packages/midi
```
