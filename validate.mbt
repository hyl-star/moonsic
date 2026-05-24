// ============================================================
// 曲谱校验与问题报告模块 — Score Validation and Issue Report
// ============================================================
// 对已构建的 Score / ScoreLayout / Measure / Voice / Staff
// 进行非阻塞式校验，输出结构化问题报告 (ValidationReport)。
// 不阻止用户构建对象 — 校验发现的问题以 ValidationIssue 进入 report。
//
// TODO: 当 EnhancedScoreLayout / MeasureRole / TieKind / RepeatKind
// 实现后，接入 enhanced score 校验（pickup/final measure、
// tie start/stop、repeat jump target 检查）。
// 当前 v1.x 只支持基础容量、空结构、channel/program/PPQ 校验。

// ============================================================
// 核心类型定义
// ============================================================

///|
/// 校验严重级别
pub(all) enum ValidationSeverity {
  Info
  Warning
  Error
  Fatal
}

///|
/// 校验代码，标识问题类型
pub(all) enum ValidationCode {
  MeasureOverflow
  MeasureUnderfilled
  PickupMeasureTooLong
  FinalMeasureTooLong
  EmptyVoice
  EmptyStaff
  EmptyPart
  InvalidChannel
  InvalidProgram
  InvalidPPQ
  TieStartWithoutStop
  TieStopWithoutStart
  RepeatWithoutStart
  RepeatJumpTargetMissing
  UnreachableSection
  VoiceAlignmentMismatch
  UnsupportedNotation
  ScoreValidationUnsupported
}

///|
/// 校验目标类型
pub(all) enum ValidationTargetKind {
  ScoreTarget
  PartTarget
  StaffTarget
  VoiceTarget
  MeasureTarget
  EventTarget
  RepeatTarget
  SectionTarget
}

///|
/// 校验位置信息
pub(all) struct ValidationLocation {
  target_kind : ValidationTargetKind
  part_index : Int
  staff_index : Int
  voice_index : Int
  measure_index : Int
  event_index : Int
  path : String
}

///|
/// 校验问题
pub(all) struct ValidationIssue {
  severity : ValidationSeverity
  code : ValidationCode
  location : ValidationLocation
  message : String
  suggestion : String
}

///|
/// 校验报告
pub(all) struct ValidationReport {
  issues : Array[ValidationIssue]
  checked_targets : Int
  error_count : Int
  warning_count : Int
  fatal_count : Int
}

///|
/// 校验选项
pub(all) struct ValidationOptions {
  strict_measure_capacity : Bool
  empty_voice_is_error : Bool
  empty_staff_is_error : Bool
  check_repeats : Bool
  check_ties : Bool
  check_voice_alignment : Bool
  export_mode : Bool
}

// ============================================================
// Options 构造函数
// ============================================================

///|
/// 默认校验选项 — 普通编辑模式，warning 不会升级
pub fn default_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: false,
    empty_voice_is_error: false,
    empty_staff_is_error: false,
    check_repeats: false,
    check_ties: false,
    check_voice_alignment: false,
    export_mode: false,
  }
}

///|
/// 严格校验选项 — 测试 / 发布前使用
pub fn strict_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: true,
    empty_voice_is_error: true,
    empty_staff_is_error: true,
    check_repeats: false,
    check_ties: false,
    check_voice_alignment: true,
    export_mode: false,
  }
}

///|
/// 导出前校验选项 — 比 strict 多开启 export_mode
pub fn export_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: true,
    empty_voice_is_error: true,
    empty_staff_is_error: true,
    check_repeats: false,
    check_ties: false,
    check_voice_alignment: true,
    export_mode: true,
  }
}

// ============================================================
// 规则表（内部）— ValidationCode → 严重级别 / 建议
// ============================================================

///|
fn default_severity(code : ValidationCode) -> ValidationSeverity {
  match code {
    MeasureOverflow => Error
    MeasureUnderfilled => Warning
    PickupMeasureTooLong => Error
    FinalMeasureTooLong => Error
    EmptyVoice => Warning
    EmptyStaff => Warning
    EmptyPart => Warning
    InvalidChannel => Error
    InvalidProgram => Error
    InvalidPPQ => Fatal
    TieStartWithoutStop => Error
    TieStopWithoutStart => Error
    RepeatWithoutStart => Error
    RepeatJumpTargetMissing => Error
    UnreachableSection => Warning
    VoiceAlignmentMismatch => Warning
    UnsupportedNotation => Warning
    ScoreValidationUnsupported => Warning
  }
}

///|
fn default_suggestion(code : ValidationCode) -> String {
  match code {
    MeasureOverflow =>
      "缩短该小节事件、拆分跨小节 tie，或改为 CadenzaMeasure"
    MeasureUnderfilled =>
      "补 rest、标记为 PickupMeasure/FinalMeasure，或调整拍号"
    PickupMeasureTooLong => "缩短 pickup 小节或改为 NormalMeasure"
    FinalMeasureTooLong => "缩短 final 小节或改为 NormalMeasure"
    EmptyVoice => "删除空 voice 或添加 rest/note"
    EmptyStaff => "删除空 staff 或添加 voice"
    EmptyPart => "删除空 part 或添加 staff"
    InvalidChannel => "使用 0..15 的 MIDI channel"
    InvalidProgram => "使用 0..127 的 program"
    InvalidPPQ => "使用大于 0 的 PPQ"
    TieStartWithoutStop => "添加对应 TieStop"
    TieStopWithoutStart => "添加对应 TieStart"
    RepeatWithoutStart => "添加 RepeatStart 或移除 RepeatEnd"
    RepeatJumpTargetMissing => "添加目标 Segno/Coda/Fine 标记"
    UnreachableSection => "检查 section 顺序和 repeat 跳转"
    VoiceAlignmentMismatch => "补齐 measure 或调整 voice 对齐"
    UnsupportedNotation => "降级 notation 或扩展导出器"
    ScoreValidationUnsupported => "使用更完整的 enhanced score 结构"
  }
}

///|
fn code_to_string(code : ValidationCode) -> String {
  match code {
    MeasureOverflow => "MeasureOverflow"
    MeasureUnderfilled => "MeasureUnderfilled"
    PickupMeasureTooLong => "PickupMeasureTooLong"
    FinalMeasureTooLong => "FinalMeasureTooLong"
    EmptyVoice => "EmptyVoice"
    EmptyStaff => "EmptyStaff"
    EmptyPart => "EmptyPart"
    InvalidChannel => "InvalidChannel"
    InvalidProgram => "InvalidProgram"
    InvalidPPQ => "InvalidPPQ"
    TieStartWithoutStop => "TieStartWithoutStop"
    TieStopWithoutStart => "TieStopWithoutStart"
    RepeatWithoutStart => "RepeatWithoutStart"
    RepeatJumpTargetMissing => "RepeatJumpTargetMissing"
    UnreachableSection => "UnreachableSection"
    VoiceAlignmentMismatch => "VoiceAlignmentMismatch"
    UnsupportedNotation => "UnsupportedNotation"
    ScoreValidationUnsupported => "ScoreValidationUnsupported"
  }
}

///|
fn severity_to_string(severity : ValidationSeverity) -> String {
  match severity {
    Info => "Info"
    Warning => "Warning"
    Error => "Error"
    Fatal => "Fatal"
  }
}

///|
fn target_kind_to_string(kind : ValidationTargetKind) -> String {
  match kind {
    ScoreTarget => "Score"
    PartTarget => "Part"
    StaffTarget => "Staff"
    VoiceTarget => "Voice"
    MeasureTarget => "Measure"
    EventTarget => "Event"
    RepeatTarget => "Repeat"
    SectionTarget => "Section"
  }
}

// ============================================================
// Report 构造与合并（内部）
// ============================================================

///|
fn new_empty_report() -> ValidationReport {
  {
    issues: [],
    checked_targets: 0,
    error_count: 0,
    warning_count: 0,
    fatal_count: 0,
  }
}

///|
fn bump_checked(report : ValidationReport, delta : Int) -> ValidationReport {
  {
    issues: report.issues,
    checked_targets: report.checked_targets + delta,
    error_count: report.error_count,
    warning_count: report.warning_count,
    fatal_count: report.fatal_count,
  }
}

///|
fn add_issue_to_report(
  report : ValidationReport,
  issue : ValidationIssue,
) -> ValidationReport {
  let issues : Array[ValidationIssue] = []
  for iss in report.issues {
    issues.push(iss)
  }
  issues.push(issue)
  let mut ec = report.error_count
  let mut wc = report.warning_count
  let mut fc = report.fatal_count
  match issue.severity {
    Error => ec = ec + 1
    Fatal => {
      ec = ec + 1
      fc = fc + 1
    }
    Warning => wc = wc + 1
    _ => ()
  }
  {
    issues,
    checked_targets: report.checked_targets,
    error_count: ec,
    warning_count: wc,
    fatal_count: fc,
  }
}

///|
fn merge_reports(
  a : ValidationReport,
  b : ValidationReport,
) -> ValidationReport {
  let issues : Array[ValidationIssue] = []
  for iss in a.issues {
    issues.push(iss)
  }
  for iss in b.issues {
    issues.push(iss)
  }
  {
    issues,
    checked_targets: a.checked_targets + b.checked_targets,
    error_count: a.error_count + b.error_count,
    warning_count: a.warning_count + b.warning_count,
    fatal_count: a.fatal_count + b.fatal_count,
  }
}

///|
fn make_location(
  kind : ValidationTargetKind,
  part_idx : Int,
  staff_idx : Int,
  voice_idx : Int,
  measure_idx : Int,
  event_idx : Int,
  path : String,
) -> ValidationLocation {
  {
    target_kind: kind,
    part_index: part_idx,
    staff_index: staff_idx,
    voice_index: voice_idx,
    measure_index: measure_idx,
    event_index: event_idx,
    path,
  }
}

///|
fn make_issue(
  code : ValidationCode,
  location : ValidationLocation,
  message : String,
) -> ValidationIssue {
  let severity = default_severity(code)
  let suggestion = default_suggestion(code)
  { severity, code, location, message, suggestion }
}

// ============================================================
// 校验逻辑 — Measure
// ============================================================

///|
/// 计算 measure 中所有事件的总拍数
fn measure_events_beats(events : Array[MusicEvent]) -> Double {
  let mut total = 0.0
  for e in events {
    total = total + e.duration().beats()
  }
  total
}

///|
/// 校验单个 Measure。
/// 若 measure 自带 signature 则用它；否则使用传入的 sig。
/// 检查容量溢出 (MeasureOverflow) 和填充不足 (MeasureUnderfilled)。
pub fn validate_measure_report(
  measure : Measure,
  sig : TimeSignature,
  _ppq : Int,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = new_empty_report()
  report = bump_checked(report, 1)
  let effective_sig = match measure.signature {
    Some(s) => s
    None => sig
  }
  let capacity = effective_sig.measure_beats()
  let used = measure_events_beats(measure.events)
  // 使用 0.000001 容差比较浮点
  if used > capacity + 0.000001 {
    let loc = make_location(
      MeasureTarget,
      -1,
      -1,
      -1,
      measure.index,
      -1,
      "measure[" + measure.index.to_string() + "]",
    )
    report = add_issue_to_report(
      report,
      make_issue(
        MeasureOverflow,
        loc,
        "小节 #\{measure.index} 溢出：拍数 \{used} > 容量 \{capacity}",
      ),
    )
  } else if used < capacity - 0.000001 && options.strict_measure_capacity {
    let loc = make_location(
      MeasureTarget,
      -1,
      -1,
      -1,
      measure.index,
      -1,
      "measure[" + measure.index.to_string() + "]",
    )
    report = add_issue_to_report(
      report,
      make_issue(
        MeasureUnderfilled,
        loc,
        "小节 #\{measure.index} 未填满：拍数 \{used} < 容量 \{capacity}",
      ),
    )
  }
  report
}

// ============================================================
// 校验逻辑 — Voice
// ============================================================

///|
/// 校验 Voice：空声部检查、递归校验子 measure。
pub fn validate_voice_report(
  voice : Voice,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = new_empty_report()
  report = bump_checked(report, 1)
  // 空声部检查
  if voice.measures.length() == 0 {
    let code = EmptyVoice
    let sever = if options.empty_voice_is_error {
      Error
    } else {
      default_severity(code)
    }
    let loc = make_location(
      VoiceTarget,
      -1,
      -1,
      -1,
      -1,
      -1,
      "voice[\{voice.name}]",
    )
    report = add_issue_to_report(report, {
      severity: sever,
      code,
      location: loc,
      message: "空声部：voice[\{voice.name}] 无 measure",
      suggestion: default_suggestion(code),
    })
  }
  // 递归校验每个 measure（使用 4/4 + 480 作为默认，measure 自带 sig 优先）
  let default_sig = four_four()
  for i = 0; i < voice.measures.length(); i = i + 1 {
    let m = voice.measures[i]
    let sub = validate_measure_report(m, default_sig, 480, options)
    report = merge_reports(report, sub)
  }
  report
}

// ============================================================
// 校验逻辑 — Staff
// ============================================================

///|
fn is_valid_channel_c(c : Int) -> Bool {
  c >= 0 && c <= 15
}

///|
fn is_valid_program_c(p : Int) -> Bool {
  p >= 0 && p <= 127
}

///|
/// 校验 Staff：channel/program 合法性、空 staff、多声部对齐、递归校验 voice。
pub fn validate_staff_report(
  staff : Staff,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = new_empty_report()
  report = bump_checked(report, 1)
  // Channel 检查
  match staff.channel {
    Some(c) =>
      if !is_valid_channel_c(c) {
        let loc = make_location(
          StaffTarget,
          -1,
          -1,
          -1,
          -1,
          -1,
          "staff[\{staff.name}]",
        )
        report = add_issue_to_report(
          report,
          make_issue(
            InvalidChannel,
            loc,
            "非法 MIDI channel：\{c}，staff[\{staff.name}]",
          ),
        )
      }
    None => ()
  }
  // Program 检查
  match staff.program {
    Some(p) =>
      if !is_valid_program_c(p) {
        let loc = make_location(
          StaffTarget,
          -1,
          -1,
          -1,
          -1,
          -1,
          "staff[\{staff.name}]",
        )
        report = add_issue_to_report(
          report,
          make_issue(
            InvalidProgram,
            loc,
            "非法 MIDI program：\{p}，staff[\{staff.name}]",
          ),
        )
      }
    None => ()
  }
  // 空 staff 检查
  if staff.voices.length() == 0 {
    let code = EmptyStaff
    let sever = if options.empty_staff_is_error {
      Error
    } else {
      default_severity(code)
    }
    let loc = make_location(
      StaffTarget,
      -1,
      -1,
      -1,
      -1,
      -1,
      "staff[\{staff.name}]",
    )
    report = add_issue_to_report(report, {
      severity: sever,
      code,
      location: loc,
      message: "空 staff：staff[\{staff.name}] 无 voice",
      suggestion: default_suggestion(code),
    })
  }
  // 多声部对齐检查
  if options.check_voice_alignment && staff.voices.length() > 1 {
    let first_count = staff.voices[0].measures.length()
    let mut aligned = true
    for i = 1; i < staff.voices.length(); i = i + 1 {
      if staff.voices[i].measures.length() != first_count {
        aligned = false
      }
    }
    if !aligned {
      let loc = make_location(
        StaffTarget,
        -1,
        -1,
        -1,
        -1,
        -1,
        "staff[\{staff.name}]",
      )
      report = add_issue_to_report(
        report,
        make_issue(
          VoiceAlignmentMismatch,
          loc,
          "声部对齐不一致：staff[\{staff.name}] 各 voice 的 measure 数量不相等",
        ),
      )
    }
  }
  // 递归校验每个 voice
  for i = 0; i < staff.voices.length(); i = i + 1 {
    let sub = validate_voice_report(staff.voices[i], options)
    report = merge_reports(report, sub)
  }
  report
}

// ============================================================
// 校验逻辑 — ScoreLayout
// ============================================================

///|
/// 校验完整 ScoreLayout：PPQ、空 part、递归校验 part → staff → voice → measure。
pub fn validate_score_layout_report(
  layout : ScoreLayout,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = new_empty_report()
  report = bump_checked(report, 1)
  // PPQ 检查
  if layout.ppq <= 0 {
    let loc = make_location(ScoreTarget, -1, -1, -1, -1, -1, "score_layout")
    report = add_issue_to_report(
      report,
      make_issue(InvalidPPQ, loc, "非法 PPQ：\{layout.ppq}，必须 > 0"),
    )
  }
  // 空整体检查
  if layout.parts.length() == 0 {
    report = add_issue_to_report(
      report,
      make_issue(
        EmptyPart,
        make_location(ScoreTarget, -1, -1, -1, -1, -1, "score_layout"),
        "空 ScoreLayout：无 part",
      ),
    )
  }
  // 遍历 part → staff → voice → measure
  for pi = 0; pi < layout.parts.length(); pi = pi + 1 {
    let part = layout.parts[pi]
    if part.staves.length() == 0 {
      let loc = make_location(
        PartTarget,
        pi,
        -1,
        -1,
        -1,
        -1,
        "part[" + pi.to_string() + "]",
      )
      report = add_issue_to_report(
        report,
        make_issue(
          EmptyPart,
          loc,
          "空 part：part[" + pi.to_string() + "][\{part.name}] 无 staff",
        ),
      )
    }
    for si = 0; si < part.staves.length(); si = si + 1 {
      let staff = part.staves[si]
      let staff_path = "part[" +
        pi.to_string() +
        "]/staff[" +
        si.to_string() +
        "]"
      report = bump_checked(report, 1)
      // Channel 检查
      match staff.channel {
        Some(c) =>
          if !is_valid_channel_c(c) {
            let loc = make_location(StaffTarget, pi, si, -1, -1, -1, staff_path)
            report = add_issue_to_report(
              report,
              make_issue(
                InvalidChannel,
                loc,
                "非法 MIDI channel：\{c}，\{staff_path}",
              ),
            )
          }
        None => ()
      }
      // Program 检查
      match staff.program {
        Some(p) =>
          if !is_valid_program_c(p) {
            let loc = make_location(StaffTarget, pi, si, -1, -1, -1, staff_path)
            report = add_issue_to_report(
              report,
              make_issue(
                InvalidProgram,
                loc,
                "非法 MIDI program：\{p}，\{staff_path}",
              ),
            )
          }
        None => ()
      }
      // 空 staff 检查
      if staff.voices.length() == 0 {
        let code = EmptyStaff
        let sever = if options.empty_staff_is_error {
          Error
        } else {
          default_severity(code)
        }
        let loc = make_location(StaffTarget, pi, si, -1, -1, -1, staff_path)
        report = add_issue_to_report(report, {
          severity: sever,
          code,
          location: loc,
          message: "空 staff：\{staff_path}[\{staff.name}] 无 voice",
          suggestion: default_suggestion(code),
        })
      }
      // 多声部对齐
      if options.check_voice_alignment && staff.voices.length() > 1 {
        let first_count = staff.voices[0].measures.length()
        let mut aligned = true
        for vi = 1; vi < staff.voices.length(); vi = vi + 1 {
          if staff.voices[vi].measures.length() != first_count {
            aligned = false
          }
        }
        if !aligned {
          let loc = make_location(StaffTarget, pi, si, -1, -1, -1, staff_path)
          report = add_issue_to_report(
            report,
            make_issue(
              VoiceAlignmentMismatch,
              loc,
              "声部对齐不一致：\{staff_path} 各 voice 的 measure 数量不相等",
            ),
          )
        }
      }
      // 递归校验每个 voice
      for vi = 0; vi < staff.voices.length(); vi = vi + 1 {
        let voice = staff.voices[vi]
        let voice_path = staff_path + "/voice[" + vi.to_string() + "]"
        report = bump_checked(report, 1)
        // 空 voice 检查
        if voice.measures.length() == 0 {
          let code = EmptyVoice
          let sever = if options.empty_voice_is_error {
            Error
          } else {
            default_severity(code)
          }
          let loc = make_location(VoiceTarget, pi, si, vi, -1, -1, voice_path)
          report = add_issue_to_report(report, {
            severity: sever,
            code,
            location: loc,
            message: "空声部：\{voice_path}[\{voice.name}] 无 measure",
            suggestion: default_suggestion(code),
          })
        }
        // 递归校验每个 measure
        for mi = 0; mi < voice.measures.length(); mi = mi + 1 {
          let m = voice.measures[mi]
          let m_path = voice_path + "/measure[" + mi.to_string() + "]"
          report = bump_checked(report, 1)
          let effective_sig = match m.signature {
            Some(s) => s
            None => layout.initial_signature
          }
          let capacity = effective_sig.measure_beats()
          let used = measure_events_beats(m.events)
          if used > capacity + 0.000001 {
            let loc = make_location(
              MeasureTarget,
              pi,
              si,
              vi,
              m.index,
              -1,
              m_path,
            )
            report = add_issue_to_report(
              report,
              make_issue(
                MeasureOverflow,
                loc,
                "小节 \{m_path} 溢出：拍数 \{used} > 容量 \{capacity}",
              ),
            )
          } else if used < capacity - 0.000001 &&
            options.strict_measure_capacity {
            let loc = make_location(
              MeasureTarget,
              pi,
              si,
              vi,
              m.index,
              -1,
              m_path,
            )
            report = add_issue_to_report(
              report,
              make_issue(
                MeasureUnderfilled,
                loc,
                "小节 \{m_path} 未填满：拍数 \{used} < 容量 \{capacity}",
              ),
            )
          }
        }
      }
    }
  }
  report
}

// ============================================================
// 校验逻辑 — Score（基础乐谱）
// ============================================================

///|
/// 从基础 Score 做基础校验：PPQ、track channel/program。
/// 注意：Score 无 measure 结构，不校验小节容量。
/// 返回 report 包含 ScoreValidationUnsupported 提示。
pub fn validate_score_report(
  score : Score,
  ppq : Int,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = new_empty_report()
  report = bump_checked(report, 1)
  // PPQ 检查
  if ppq <= 0 {
    let loc = make_location(ScoreTarget, -1, -1, -1, -1, -1, "score")
    report = add_issue_to_report(
      report,
      make_issue(InvalidPPQ, loc, "非法 PPQ：\{ppq}，必须 > 0"),
    )
  }
  // 对每个 track 检查 channel/program
  for ti = 0; ti < score.tracks.length(); ti = ti + 1 {
    let track = score.tracks[ti]
    if !is_valid_channel_c(track.channel) {
      let loc = make_location(
        StaffTarget,
        -1,
        ti,
        -1,
        -1,
        -1,
        "track[" + ti.to_string() + "]",
      )
      report = add_issue_to_report(
        report,
        make_issue(
          InvalidChannel,
          loc,
          "非法 MIDI channel：\{track.channel}，track[" +
          ti.to_string() +
          "]",
        ),
      )
    }
    if !is_valid_program_c(track.program) {
      let loc = make_location(
        StaffTarget,
        -1,
        ti,
        -1,
        -1,
        -1,
        "track[" + ti.to_string() + "]",
      )
      report = add_issue_to_report(
        report,
        make_issue(
          InvalidProgram,
          loc,
          "非法 MIDI program：\{track.program}，track[" +
          ti.to_string() +
          "]",
        ),
      )
    }
  }
  // 标记：Score 不支持完整 measure 级校验
  if !options.export_mode {
    report = add_issue_to_report(
      report,
      make_issue(
        ScoreValidationUnsupported,
        make_location(ScoreTarget, -1, -1, -1, -1, -1, "score"),
        "Score 不支持完整 measure 级校验，请使用 ScoreLayout 获得更详细的校验",
      ),
    )
  }
  report
}

// ============================================================
// Report 查询
// ============================================================

///|
/// report 是否包含 Error 或 Fatal 级别问题
pub fn validation_report_has_errors(report : ValidationReport) -> Bool {
  report.error_count > 0
}

///|
/// report 是否包含 Warning 级别问题
pub fn validation_report_has_warnings(report : ValidationReport) -> Bool {
  report.warning_count > 0
}

///|
/// report 中 Error + Fatal 总数
pub fn validation_report_error_count(report : ValidationReport) -> Int {
  report.error_count
}

///|
/// report 中 Warning 总数
pub fn validation_report_warning_count(report : ValidationReport) -> Int {
  report.warning_count
}

// ============================================================
// Report 导出 — JSON
// ============================================================

///|
/// 将 issue 序列化为 JSON 字符串
fn issue_to_json(issue : ValidationIssue) -> String {
  "{\"severity\":\"" +
  severity_to_string(issue.severity) +
  "\",\"code\":\"" +
  code_to_string(issue.code) +
  "\",\"location\":{" +
  "\"target_kind\":\"" +
  target_kind_to_string(issue.location.target_kind) +
  "\",\"part_index\":" +
  issue.location.part_index.to_string() +
  ",\"staff_index\":" +
  issue.location.staff_index.to_string() +
  ",\"voice_index\":" +
  issue.location.voice_index.to_string() +
  ",\"measure_index\":" +
  issue.location.measure_index.to_string() +
  ",\"event_index\":" +
  issue.location.event_index.to_string() +
  ",\"path\":" +
  json_escape(issue.location.path) +
  "},\"message\":" +
  json_escape(issue.message) +
  ",\"suggestion\":" +
  json_escape(issue.suggestion) +
  "}"
}

///|
/// 将 ValidationReport 序列化为 JSON 字符串。
pub fn validation_report_to_json(report : ValidationReport) -> String {
  let mut s = "{\"error_count\":" +
    report.error_count.to_string() +
    ",\"warning_count\":" +
    report.warning_count.to_string() +
    ",\"fatal_count\":" +
    report.fatal_count.to_string() +
    ",\"checked_targets\":" +
    report.checked_targets.to_string() +
    ",\"issues\":["
  let n = report.issues.length()
  for i = 0; i < n; i = i + 1 {
    s = s + issue_to_json(report.issues[i])
    if i < n - 1 {
      s = s + ","
    }
  }
  s + "]}"
}

///|
/// 将 ValidationReport 转换为可读摘要。
pub fn validation_report_to_summary(report : ValidationReport) -> String {
  if report.issues.length() == 0 {
    return "校验通过，0 个问题。"
  }
  let mut s = "校验报告：错误 " +
    report.error_count.to_string() +
    " 个，警告 " +
    report.warning_count.to_string() +
    " 个，致命 " +
    report.fatal_count.to_string() +
    " 个，共检查 " +
    report.checked_targets.to_string() +
    " 个目标。\n"
  for iss in report.issues {
    s = s +
      "[" +
      severity_to_string(iss.severity) +
      "] " +
      code_to_string(iss.code) +
      ": " +
      iss.message +
      " (建议: " +
      iss.suggestion +
      ")\n"
  }
  s
}

// ============================================================
// FFI — JSON → ScoreLayout 解析 & 校验
// ============================================================

///|
/// 从 JsonValue 还原 Measure（内部，用于 FFI）
fn measure_from_jv(v : JsonValue) -> Result[Measure, String] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let index = match jv_lookup(fields, "index") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let sig = match jv_lookup(fields, "signature") {
    Ok(jv) =>
      match time_sig_from_jv(jv) {
        Ok(ts) => Some(ts)
        Err(_) => None
      }
    Err(_) => None
  }
  let events_jv = match jv_lookup(fields, "events") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let event_arr = match jv_as_array(events_jv) {
    Ok(arr) => arr
    Err(e) => return Err(e)
  }
  let events : Array[MusicEvent] = []
  for evjv in event_arr {
    match music_event_from_jv(evjv) {
      Ok(ev) => events.push(ev)
      Err(e) => return Err(e)
    }
  }
  Ok({ index, signature: sig, events })
}

///|
/// 从 JsonValue 还原 Voice（内部，用于 FFI）
fn voice_from_jv(v : JsonValue) -> Result[Voice, String] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let name = match jv_lookup(fields, "name") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let measures_jv = match jv_lookup(fields, "measures") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let measure_arr = match jv_as_array(measures_jv) {
    Ok(arr) => arr
    Err(e) => return Err(e)
  }
  let measures : Array[Measure] = []
  for mjv in measure_arr {
    match measure_from_jv(mjv) {
      Ok(m) => measures.push(m)
      Err(e) => return Err(e)
    }
  }
  Ok({ name, measures })
}

///|
/// 从 JsonValue 还原 Staff（内部，用于 FFI）
fn staff_from_jv(v : JsonValue) -> Result[Staff, String] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let name = match jv_lookup(fields, "name") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let channel = match jv_lookup(fields, "channel") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => Some(n)
        Err(_) => None
      }
    Err(_) => None
  }
  let program = match jv_lookup(fields, "program") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => Some(n)
        Err(_) => None
      }
    Err(_) => None
  }
  let instrument_name = match jv_lookup(fields, "instrument_name") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => Some(s)
        Err(_) => None
      }
    Err(_) => None
  }
  let voices_jv = match jv_lookup(fields, "voices") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let voice_arr = match jv_as_array(voices_jv) {
    Ok(arr) => arr
    Err(e) => return Err(e)
  }
  let voices : Array[Voice] = []
  for vjv in voice_arr {
    match voice_from_jv(vjv) {
      Ok(v) => voices.push(v)
      Err(e) => return Err(e)
    }
  }
  Ok({ name, channel, program, instrument_name, voices })
}

///|
/// 从 JsonValue 还原 Part（内部，用于 FFI）
fn part_from_jv(v : JsonValue) -> Result[Part, String] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let name = match jv_lookup(fields, "name") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let staves_jv = match jv_lookup(fields, "staves") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let staff_arr = match jv_as_array(staves_jv) {
    Ok(arr) => arr
    Err(e) => return Err(e)
  }
  let staves : Array[Staff] = []
  for sjv in staff_arr {
    match staff_from_jv(sjv) {
      Ok(s) => staves.push(s)
      Err(e) => return Err(e)
    }
  }
  Ok({ name, staves })
}

///|
/// 从 JsonValue 还原 ScoreLayout（内部，用于 FFI）
fn score_layout_from_jv(v : JsonValue) -> Result[ScoreLayout, String] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let title = match jv_lookup(fields, "title") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let ppq = match jv_lookup(fields, "ppq") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let composer = match jv_lookup(fields, "composer") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(_) => ""
      }
    Err(_) => ""
  }
  let parts_jv = match jv_lookup(fields, "parts") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let part_arr = match jv_as_array(parts_jv) {
    Ok(arr) => arr
    Err(e) => return Err(e)
  }
  let parts : Array[Part] = []
  for pjv in part_arr {
    match part_from_jv(pjv) {
      Ok(p) => parts.push(p)
      Err(e) => return Err(e)
    }
  }
  let initial_tempo_jv = match jv_lookup(fields, "initial_tempo") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let initial_tempo = match tempo_from_jv(initial_tempo_jv) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let initial_signature_jv = match jv_lookup(fields, "initial_signature") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let initial_signature = match time_sig_from_jv(initial_signature_jv) {
    Ok(ts) => ts
    Err(e) => return Err(e)
  }
  Ok({ title, ppq, composer, parts, initial_tempo, initial_signature })
}

///|
/// FFI 入口：接收 ScoreLayout JSON 字符串，返回校验报告 JSON。
/// 成功: {"ok":true,"data":{...}}
/// 失败: {"ok":false,"error":"...","message":"..."}
pub fn ffi_validate_score_layout_json(input : String) -> String {
  match json_parse(input) {
    Ok(jv) =>
      match score_layout_from_jv(jv) {
        Ok(layout) => {
          let report = validate_score_layout_report(
            layout,
            default_validation_options(),
          )
          let data_json = validation_report_to_json(report)
          ffi_ok_data(data_json)
        }
        Err(e) => ffi_error("ValidationError", e)
      }
    Err(e) => ffi_error("JsonParseError", e)
  }
}
