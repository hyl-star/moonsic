// ============================================================
// Validation 核心类型
// ============================================================

///|
pub(all) enum ValidationSeverity {
  Info
  Warning
  Error
  Fatal
}

///|
pub(all) enum ValidationCode {
  EmptyScore
  EmptyPart
  EmptyStaff
  EmptyVoice
  MeasureOverflow
  MeasureUnderfilled
  VoiceAlignmentMismatch
  MeasureIndexOutOfOrder
  InvalidPPQ
  InvalidTempo
  InvalidChannel
  InvalidProgram
  InvalidSectionRange
  InvalidRepeatCount
  InvalidEndingNumber
  InvalidVelocity
  EmptyChordPitches
}

///|
pub(all) struct ValidationIssue {
  severity : ValidationSeverity
  code : ValidationCode
  path : String
  message : String
}

///|
pub(all) struct ValidationReport {
  issues : Array[ValidationIssue]
  info_count : Int
  warning_count : Int
  error_count : Int
  fatal_count : Int
}

///|
pub fn empty_validation_report() -> ValidationReport {
  {
    issues: [],
    info_count: 0,
    warning_count: 0,
    error_count: 0,
    fatal_count: 0,
  }
}

///|
pub fn report_add_issue(
  report : ValidationReport,
  issue : ValidationIssue,
) -> ValidationReport {
  let iss : Array[ValidationIssue] = []
  for i in report.issues {
    iss.push(i)
  }
  iss.push(issue)
  let ic = report.info_count + (if issue.severity is Info { 1 } else { 0 })
  let wc = report.warning_count +
    (if issue.severity is Warning { 1 } else { 0 })
  let ec = report.error_count +
    (if issue.severity is Error || issue.severity is Fatal { 1 } else { 0 })
  let fc = report.fatal_count + (if issue.severity is Fatal { 1 } else { 0 })
  {
    issues: iss,
    info_count: ic,
    warning_count: wc,
    error_count: ec,
    fatal_count: fc,
  }
}

///|
pub fn report_has_errors(report : ValidationReport) -> Bool {
  report.error_count > 0
}

///|
pub fn report_issue_count(report : ValidationReport) -> Int {
  report.issues.length()
}
