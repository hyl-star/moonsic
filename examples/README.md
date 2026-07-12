# Moonsic Examples

端到端音乐资产流水线示例。

## 前置条件

- MoonBit 工具链已安装
- 项目依赖已下载：`moon update`

## 运行 demo pipeline 测试

```bash
# 验证完整流水线
moon test packages/demo -v

# 更新快照（如有）
moon test --update
```

## 生成输出文件

### 方式 1：PowerShell 脚本（推荐）

```powershell
powershell -ExecutionPolicy Bypass -File scripts/write_demo_assets.ps1
```

该脚本：
1. 运行 `moon test packages/demo -v
2. 解析 JSON 输出中的资产内容
3. 将文件写入 `examples/output/`

**环境要求**：Windows PowerShell 5.1+ 或 PowerShell Core 7+

### 方式 2：仅 MoonBit 命令（输出 JSON 到 stdout）

```bash
moon test packages/demo -v
```

输出一个 JSON 数组，每项包含 `filename`、`content_type`、`content`（文本）或 `content_hex`（二进制十六进制编码）。

可自行编写脚本将 hex 解码为二进制写入文件。

### 方式 3：测试验证（无需文件 I/O）

```bash
moon test packages/demo -v
```

所有资产在内存中生成并通过验证，无需写入磁盘。测试验证：
- MIDI 文件含 "MThd" header
- WAV 文件含 "RIFF"+"WAVE" header
- MusicXML 含 `<score-partwise>` 根元素
- 所有 JSON 资产可解析

## 示例请求

### 标准请求 (`request.json`)

```json
{
  "key": "C",
  "scale": "major",
  "tempo": 120,
  "bars": 8,
  "style": "pop",
  "chord_progression": ["I", "V", "vi", "IV"],
  "seed": 1
}
```

### AI 请求 (`ai-request.json`)

模拟 AI 音乐生成系统的输入格式。

## 输出目录结构

```
examples/output/
├── bundle.json          # 资产包摘要
├── score.json           # Score 序列化
├── composition.mid      # MIDI 文件
├── composition.musicxml # MusicXML (partwise)
├── composition.wav      # WAV PCM 16-bit
├── web-events.json      # 浏览器播放事件
└── game.json            # Game Music IR
```

## 清理输出

```bash
# 保留 .gitkeep，删除其余
find examples/output -type f ! -name '.gitkeep' -delete
```

PowerShell：
```powershell
Get-ChildItem examples/output -File | Where-Object { $_.Name -ne '.gitkeep' } | Remove-Item
```

## 自定义请求

编辑 `request.json` 或 `ai-request.json`，修改 key、scale、style、bars 等参数后重新运行测试。

目前 `moon test packages/demo -v
