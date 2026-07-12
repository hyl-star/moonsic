# packages/web — Web / Browser 播放事件输出模块

将 timeline / score 转换为浏览器可消费的 JSON 事件流。

## Dependencies

- `packages/timeline`
- `packages/score`
- `packages/json`

## Scope

- `WebPlaybackConfig` / `WebPlaybackEvent` / `WebEventDocument` 数据结构
- timeline / note events 到 web events 的转换
- 时间单位转换（秒/拍/tick）
- `include_note_off` 模式生成 note_on + note_off 成对事件
- JSON 序列化输出

本模块不实现 WebAudio 引擎或浏览器 UI。

## API

| 函数 | 说明 |
|---|---|
| `default_web_playback_config()` | 默认播放配置 |
| `timeline_to_web_events_checked(timeline, config)` | PlaybackTimeline → WebEventDocument（已验证） |
| `note_events_to_web_events(events, config)` | NoteEvent 数组 → WebEventDocument |
| `web_event_document_to_json(doc)` | 文档 → JSON 字符串 |
| `simple_score_to_web_json_checked(score, config)` | SimpleScore → JSON 字符串 |

## Run Tests

```bash
moon test packages/web
```
