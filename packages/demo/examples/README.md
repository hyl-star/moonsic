# Examples / Output Writer

Demo 资产写入示例。配合 `examples_writer.mbt` 使用。

## 文件

| 文件 | 说明 |
|---|---|
| `examples_writer.mbt` | 资产文件写入 API |
| `demo_test.mbt` | 包含 writer 的测试用例 |

## 使用方式

```moonbit
// 1. 生成资产包
let bundle = composition_asset_pipeline_checked(
  default_composition_request()
).unwrap()

// 2. 验证并写入
write_composition_assets_checked(bundle, "examples/output/").unwrap()

// 3. 获取文件列表（供外部 CLI/JS host 执行实际磁盘写入）
let entries = collect_assets_from_bundle(bundle)
for entry in entries {
  println(entry.filename + " (" + entry.content_type + ")")
}
```

## 输出文件清单

| 文件 | 类型 | 内容 |
|---|---|---|
| `bundle.json` | JSON | 资产包摘要 |
| `score.json` | JSON | Score 序列化 |
| `composition.mid` | binary | MIDI 文件 |
| `composition.musicxml` | XML | MusicXML partwise |
| `composition.wav` | binary | WAV PCM 16-bit |
| `web-events.json` | JSON | 浏览器播放事件 |
| `game.json` | JSON | Game Music IR |

## 注意

MoonBit 当前不提供原生文件 I/O。`write_*` 函数验证内容有效性并返回 `Result`，实际磁盘写入需由上层运行时（CLI/JavaScript host）通过 `collect_assets_from_bundle` 获取文件列表后执行。
