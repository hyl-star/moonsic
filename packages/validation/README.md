# packages/validation — v2 Validation 独立模拟包

消费 packages/score 的 ScoreLayout，输出结构化 ValidationReport。只报告问题，不修改输入。

## 依赖

- `packages/score` — ScoreLayout / Part / Staff / Voice / Measure / ScoreEvent
- `packages/time` — TimeSignature (measure capacity 计算)

## 包含模块

- `validation_error.mbt` — ValidationError
- `validation_types.mbt` — ValidationSeverity/Code/Issue/Report
- `validation_options.mbt` — ValidationProfile/Options (4 档预设)
- `validation_rules_common.mbt` — 默认严重级别 / 共享辅助
- `validation_rules_measure.mbt` — Measure 校验
- `validation_rules_voice.mbt` — Voice 校验
- `validation_rules_staff.mbt` — Staff 校验
- `validation_rules_part.mbt` — Part 校验
- `validation_rules_score.mbt` — ScoreLayout + Section/Repeat 校验
- `validation_report_text.mbt` — report → 可读文本
- `validation_report_json.mbt` — report → JSON 字符串

## 推荐 API

| 函数 | 说明 |
|------|------|
| `validate_measure(measure, sig, options)` | 单小节校验 |
| `validate_voice(voice, sig, options)` | 单声部校验 |
| `validate_staff(staff, sig, options)` | 单五线谱校验 |
| `validate_part(part, sig, options)` | 单声部组校验 |
| `validate_score_layout(layout, options)` | 完整乐谱校验 |
| `validation_report_to_text(report)` | → 可读摘要 |
| `validation_report_to_json(report)` | → JSON 字符串 |

## 运行测试

```bash
moon test packages/validation
```

## 设计原则

- 只报告问题，不修改输入
- 所有 API 返回 ValidationReport（非 Result）
- 不 abort
- 不做 MIDI/MusicXML 专属规则（MVP）
