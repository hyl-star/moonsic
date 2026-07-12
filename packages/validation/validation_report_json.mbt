// ============================================================
// Report -> JSON output
// ============================================================

///|
pub fn validation_report_to_json(report : ValidationReport) -> String {
  let mut s = "{\"error_count\":" + report.error_count.to_string()
  s = s + ",\"warning_count\":" + report.warning_count.to_string()
  s = s + ",\"info_count\":" + report.info_count.to_string()
  s = s + ",\"issues\":["
  for i = 0; i < report.issues.length(); i = i + 1 {
    if i > 0 {
      s = s + ","
    }
    let iss = report.issues[i]
    s = s + "{\"severity\":\"" + severity_label(iss.severity) + "\""
    s = s + ",\"code\":\"" + code_label(iss.code) + "\""
    s = s + ",\"path\":" + @json.json_escape(iss.path)
    s = s + ",\"message\":" + @json.json_escape(iss.message)
    s = s + "}"
  }
  s + "]}"
}
