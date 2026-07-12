// ============================================================
// Voice 校验
// ============================================================

///|
pub fn validate_voice(
  v : @score.Voice,
  default_sig : @time.TimeSignature,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = empty_validation_report()
  let path = "voice[\{v.name}]"
  if v.name == "" {
    report = report_add_issue(
      report,
      make_issue(EmptyVoice, path, "声部名称为空"),
    )
  }
  if v.measures.length() == 0 && options.empty_voice_is_error {
    report = report_add_issue(
      report,
      make_issue(EmptyVoice, path, "声部无小节"),
    )
  }

  // measure index 递增检查
  let mut prev_idx = -1
  for m in v.measures {
    if m.index.value <= prev_idx {
      report = report_add_issue(
        report,
        make_issue(
          MeasureIndexOutOfOrder,
          path + "/measure[\{m.index.value}]",
          "小节索引无序：\{m.index.value} <= \{prev_idx}",
        ),
      )
    }
    prev_idx = m.index.value
    let sub = validate_measure(m, default_sig, options)
    for iss in sub.issues {
      report = report_add_issue(report, iss)
    }
    report = {
      issues: report.issues,
      info_count: report.info_count + sub.info_count,
      warning_count: report.warning_count + sub.warning_count,
      error_count: report.error_count + sub.error_count,
      fatal_count: report.fatal_count + sub.fatal_count,
    }
  }
  report
}
