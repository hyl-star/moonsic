// ============================================================
// Part 校验
// ============================================================

///|
pub fn validate_part(
  p : @score.Part,
  default_sig : @time.TimeSignature,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = empty_validation_report()
  let path = "part[\{p.name}]"
  if p.name == "" {
    report = report_add_issue(
      report,
      make_issue(EmptyPart, path, "part 名称为空"),
    )
  }
  if p.staves.length() == 0 && options.empty_part_is_error {
    report = report_add_issue(
      report,
      make_issue(EmptyPart, path, "part 无 staff"),
    )
  }
  for s in p.staves {
    let sub = validate_staff(s, default_sig, options)
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
