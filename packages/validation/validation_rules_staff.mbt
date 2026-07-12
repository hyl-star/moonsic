// ============================================================
// Staff 校验
// ============================================================

///|
pub fn validate_staff(
  s : @score.Staff,
  default_sig : @time.TimeSignature,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = empty_validation_report()
  let path = "staff[\{s.name}]"
  if s.name == "" {
    report = report_add_issue(
      report,
      make_issue(EmptyStaff, path, "staff 名称为空"),
    )
  }
  if s.voices.length() == 0 && options.empty_staff_is_error {
    report = report_add_issue(
      report,
      make_issue(EmptyStaff, path, "staff 无 voice"),
    )
  }
  for v in s.voices {
    let sub = validate_voice(v, default_sig, options)
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
