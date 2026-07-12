// ============================================================
// ScoreLayout + Section/Repeat 校验
// ============================================================

///|
pub fn validate_score_layout(
  layout : @score.ScoreLayout,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = empty_validation_report()

  if layout.ppq.value <= 0 {
    report = report_add_issue(
      report,
      make_issue(InvalidPPQ, "score", "PPQ 必须 > 0"),
    )
  }
  if layout.parts.length() == 0 {
    report = report_add_issue(
      report,
      make_issue(EmptyScore, "score", "乐谱无 part"),
    )
  }

  let sig = layout.initial_signature
  for p in layout.parts {
    let sub = validate_part(p, sig, options)
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

  // Section 校验
  for s in layout.sections {
    if s.end_measure.value < s.start_measure.value {
      report = report_add_issue(
        report,
        make_issue(InvalidSectionRange, "section[\{s.name}]", "end < start"),
      )
    }
  }

  // RepeatMark 校验
  for r in layout.repeats {
    if r.repeat_count < 1 {
      report = report_add_issue(
        report,
        make_issue(InvalidRepeatCount, "repeat", "repeat_count < 1"),
      )
    }
  }

  // EndingBracket 校验
  for eb in layout.endings {
    if eb.number < 1 {
      report = report_add_issue(
        report,
        make_issue(InvalidEndingNumber, "ending", "number < 1"),
      )
    }
  }

  report
}
