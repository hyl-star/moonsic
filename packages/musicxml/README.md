# packages/musicxml — v2 MusicXML 导出/导入包

消费 packages/score 的 SimpleScore，输出 MusicXML XML 字符串；
也可将 MusicXML XML 字符串导入回 ScoreLayout，实现完整往返。

## 导出（export）

- `simple_score_to_musicxml_checked(score, opts)` — SimpleScore → MusicXmlScore
- `musicxml_score_to_string(doc, opts)` — MusicXmlScore → XML 字符串
- `simple_score_to_musicxml_string_checked(score, opts)` — 一步到 XML

## 导入（import）

- `parse_musicxml_xml_checked(xml)` — XML 字符串 → MusicXmlScore
- `musicxml_score_to_layout_checked(mx_score)` — MusicXmlScore → ScoreLayout
- `musicxml_string_to_layout_checked(xml)` — XML 字符串 → ScoreLayout（一步到位）
- `musicxml_string_to_import_result_checked(xml)` — 同时返回 ScoreLayout + 导入报告
- `musicxml_import_report_to_json(report)` — ImportReport → JSON 字符串

### 支持的 MusicXML 元素

| 元素 | 状态 |
|------|------|
| score-partwise | 支持 |
| part-list/score-part/part-name | 支持 |
| part/measure | 支持 |
| attributes/divisions | 支持 |
| time/beats/beat-type | 支持 |
| clef | 解析但默认 Treble |
| note/pitch/step/alter/octave | 支持 |
| note/rest | 支持 |
| note/chord | 支持（聚合为 ChordEvent） |
| note/dot | 支持 |
| note/duration/type | 支持 |
| direction | 不支持（warning） |
| backup/forward | 不支持（warning） |
| tie/lyric | 部分支持（忽略，warning） |

## 依赖

- `packages/score` — SimpleScore / SimpleTrack / SimpleEvent / ScoreLayout
- `packages/time` — RhythmDuration / TimeSignature
- `packages/pitch` — Pitch / PitchClass / Accidental

## 运行测试

```bash
moon test packages/musicxml
```
