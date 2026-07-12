# Moonsic v2 Release Checklist

## 发布前必须通过

| # | 检查项 | 方法 | 期望 | 状态 |
|---|--------|------|------|------|
| 1 | 全部测试通过 | `moon test` | 0 failed | PASS |
| 2 | 代码格式化 | `moon fmt` | 无 diff | PASS |
| 3 | 接口生成 | `moon info` | `.mbti` 无意外变更 | PASS |
| 4 | 包结构完整 | 检查 `packages/*/` | 每个包都有 `moon.pkg` | PASS |
| 5 | 每包有 README | 检查 `packages/*/README.md` | 全覆盖 | PASS |
| 6 | 每包有测试 | 检查 `packages/*/*_test.mbt` | 全覆盖 | PASS |
| 7 | 每包有 benchmark | 检查 `packages/*/benchmark.mbt` | 全覆盖（validation 待补）| PARTIAL |
| 8 | Demo 可运行 | `moon test packages/demo` | 测试通过 | PASS |
| 9 | Golden 测试 | `moon test` | assert_eq 验证确定性输出 | PASS |
| 10 | 迁移指南 | `MIGRATION.md` 存在 | 覆盖核心 API 映射 | PASS |
| 11 | API 冻结 | `.mbti` 文件与文档匹配 | 公开 API 不再变更 | PASS |

## v2 包清单 (25 packages)

| 包名 | 职责 | README | test | benchmark | .mbti | 状态 |
|------|------|--------|------|-----------|-------|------|
| pitch | 音高 + 快捷构造 + MIDI/频率转换 + 解析 | YES | YES | YES | YES | STABLE |
| interval | 音程计算 + 转位 + 解析 | YES | YES | YES | YES | STABLE |
| time | 节奏时间 + Duration + TimeSignature + TimeMap | YES | YES | YES | YES | STABLE |
| scale | 音阶 + 调性 + Key | YES | YES | YES | YES | STABLE |
| chord | 和弦品质 + 解析 + 展开 | YES | YES | YES | YES | STABLE |
| harmony | 罗马数字 + 声部引导 | YES | YES | YES | YES | STABLE |
| rhythm | 节奏模板 + 模式 + Phrase | YES | YES | YES | YES | STABLE |
| motif | 音级动机 + 变换 | YES | YES | YES | YES | STABLE |
| score | SimpleScore + ScoreLayout + 构造器 | YES | YES | YES | YES | STABLE |
| validation | 校验报告 + profile | YES | YES | NO | YES | MISSING BENCH |
| json | 零依赖 JSON 解析/序列化 | YES | YES | YES | YES | STABLE |
| parse | 统一解析 facade | YES | YES | YES | YES | STABLE |
| midi | MIDI 事件 + 排序 + 字节导出 + GM 乐器 | YES | YES | YES | YES | STABLE |
| musicxml | MusicXML 模型 + 转换 + 字符串写入 | YES | YES | YES | YES | STABLE |
| timeline | NoteEvent 时间线 + 浏览器事件导出 | YES | YES | YES | YES | STABLE |
| wav | WAV 渲染 | YES | YES | YES | YES | STABLE |
| game | 游戏音乐 IR + 校验 + JSON 导出 | YES | YES | YES | YES | STABLE |
| generate | 旋律/和弦/bass/伴奏/loop 生成 | YES | YES | YES | YES | STABLE |
| adapter | 外部生成器请求/响应/补丁协议 | YES | YES | YES | YES | STABLE |
| drums | GM 鼓组 + 基础节拍 | YES | YES | YES | YES | STABLE |
| transform | SimpleTrack 纯变换 | YES | YES | YES | YES | STABLE |
| structure | 歌曲段落 + arrange | YES | YES | YES | YES | STABLE |
| ffi | string-in/string-out facade | YES | YES | YES | YES | STABLE |
| demo | 端到端流水线：请求->生成->导出 | YES | YES | YES | YES | STABLE |
| web | Web/Browser 播放事件输出 | YES | YES | YES | YES | STABLE |

## 已知待处理事项

1. **validation/benchmark.mbt** — 待补齐基准测试
2. **examples/output** — 当前只有 `.gitkeep`，真实落盘命令尚未完成
3. **cmd/main** — 已删除，v2 CLI 入口尚未重建
4. **root legacy** — 根包目前已清空，v1 API 已移除

## 发布命令序列

```bash
# 1. 清理 + 格式化
moon fmt

# 2. 更新接口文件
moon info

# 3. 检查 .mbti diff（如有意外变更，人工确认）
git diff -- '*generated.mbti'

# 4. 运行全部测试
moon test

# 5. 如有 golden test 更新
moon test --update

# 6. 最终检查
moon check
```

## Golden Tests 覆盖

| 包 | 测试 | 验证内容 |
|-----|------|----------|
| midi | `golden_c_major_scale_bytes` | MIDI bytes 确定性 + SMF header |
| musicxml | `golden_c_major_scale_xml` | MusicXML 字符串确定性 + 结构 |
| demo | `golden_default_pipeline_bundle` | 完整 pipeline bundle summary 确定性 |

## 发布阻断条件

| 条件 | 动作 |
|------|------|
| 测试失败 | 禁止发布，修复后重测 |
| `.mbti` 意外变更 | 人工审查，确认后提交 |
| Golden test 不一致 | 确认变更合理后 `moon test --update` |
| Demo 测试失败 | 检查 `packages/demo` 依赖 |
| 包结构缺失 | 补齐 moon.pkg / README / 测试 |

## 质量目标

- 测试数: >= 487 (当前基线: 487 passed, 0 failed)
- 包覆盖: 25/25
- 错误处理: 所有构造器返回 `Result`
- 音乐常量验证: MIDI note 0-127, velocity 0-127, channel 0-15
- 确定性: golden tests 覆盖核心导出路径
