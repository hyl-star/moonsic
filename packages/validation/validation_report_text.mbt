// ============================================================
// Report → 文本输出
// ============================================================

///|
pub fn validation_report_to_text(report : ValidationReport) -> String {
  if report.issues.length() == 0 {
    return "通过，0 个问题"
  }
  let mut s = "校验报告：错误 \{report.error_count} 警告 \{report.warning_count} 信息 \{report.info_count}\n"
  for iss in report.issues {
    s = s +
      "[\{severity_label(iss.severity)}] \{code_label(iss.code)} | \{iss.path} | \{iss.message}\n"
  }
  s
}

///|
pub fn validation_report_to_summary(report : ValidationReport) -> String {
  if report.issue_count() == 0 {
    return "OK"
  }
  "ERR=\{report.error_count} WARN=\{report.warning_count}"
}

///|
pub fn ValidationReport::issue_count(self : ValidationReport) -> Int {
  self.issues.length()
}
