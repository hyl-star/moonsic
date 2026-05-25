// ============================================================
// 曲谱校验与问题报告模块 — Score Validation and Issue Report
// ============================================================
// 对已构建的 Score / ScoreLayout / Measure / Voice / Staff
// 进行非阻塞式校验，输出结构化问题报告 (ValidationReport)。
// 不阻止用户构建对象 — 校验发现的问题以 ValidationIssue 进入 report。
//
// v2 扩展: Profile 档案系统、export readiness、golden text、
// ValidationContext 全层级路径、source 规则追踪。
//
// TODO: 当 EnhancedScoreLayout / MeasureRole / TieKind / RepeatKind
// 实现后，接入 enhanced score 校验（pickup/final measure、
// tie start/stop、repeat jump target 检查）。

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
  // ---- 基础参数 ----
  InvalidPPQ
  ValidateInvalidTimeSignature
  ValidateInvalidTempo
  ValidateInvalidScorePath

  // ---- 空结构 ----
  EmptyScore
  EmptyPart
  EmptyStaff
  EmptyVoice
  EmptyMeasure

  // ---- 小节容量 ----
  ValidateMeasureOverflow
  MeasureUnderfilled
  PickupMeasureTooLong
  FinalMeasureTooLong
  FreeTimeMeasureUnsupported
  CadenzaMeasureUnsupported

  // ---- 声部对齐 ----
  VoiceAlignmentMismatch
  MeasureIndexMismatch
  DuplicateMeasureIndex

  // ---- MIDI 边界 ----
  ValidateInvalidChannel
  ValidateInvalidProgram
  InvalidMidiVelocity
  InvalidMidiNote

  // ---- Tie 链条 ----
  TieStartWithoutStop
  TieStopWithoutStart
  TieContinueWithoutStart
  TiePitchMismatch
  TieDurationSuspicious

  // ---- Repeat / Jump ----
  RepeatWithoutStart
  RepeatStartWithoutEnd
  RepeatJumpTargetMissing
  EndingWithoutRepeat
  EndingRangeInvalid
  CodaTargetMissing
  SegnoTargetMissing
  UnreachableSection

  // ---- 导出兼容性 ----
  UnsupportedNotation
  UnsupportedLyric
  UnsupportedClef
  UnsupportedForMidi
  UnsupportedForMusicXml
  UnsupportedForGame

  // ---- 通用 ----
  ScoreValidationUnsupported
}

///|
/// 校验目标类型
pub(all) enum ValidationTargetKind {
  ValidateScoreTarget
  PartTarget
  StaffTarget
  VoiceTarget
  MeasureTarget
  EventTarget
  SectionTarget
  RepeatTarget
  EndingTarget
  CodaTarget
  SegnoTarget
  ExportTarget
}

///|
/// 校验规则 ID（用于追踪问题来源规则）
pub(all) struct ValidationRuleId {
  value : String
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
  source : ValidationRuleId
}

///|
/// 校验报告
pub(all) struct ValidationReport {
  issues : Array[ValidationIssue]
  checked_targets : Int
  info_count : Int
  warning_count : Int
  error_count : Int
  fatal_count : Int
}

///|
/// 校验选项
pub(all) struct ValidationOptions {
  strict_measure_capacity : Bool
  empty_voice_is_error : Bool
  empty_staff_is_error : Bool
  empty_part_is_error : Bool
  check_repeats : Bool
  check_ties : Bool
  check_voice_alignment : Bool
  export_mode : Bool
  check_midi_readiness : Bool
  check_musicxml_readiness : Bool
  check_game_readiness : Bool
  unsupported_notation_is_error : Bool
  warning_as_error : Bool
}

///|
/// 校验上下文（用于传递层级路径信息）
pub(all) struct ValidationContext {
  part_index : Int
  staff_index : Int
  voice_index : Int
  path_prefix : String
}

///|
/// 校验档案（预设选项模板）
pub(all) enum ValidationProfile {
  EditingProfile
  StrictProfile
  MidiExportProfile
  MusicXmlExportProfile
  GameExportProfile
  GoldenTestProfile
}

///|
/// 校验错误（用于 JSON decode / profile 构造等）
pub(all) enum ValidationError {
  InvalidValidationProfile(String)
  InvalidValidationOptions(String)
  InvalidValidationReport(String)
  InvalidValidationJson(String)
  JsonDecodeError(String)
  JsonEncodeError(String)
  MissingJsonField(String)
  ScoreLayoutError(String)
}

///|
/// 字符串化
pub fn ValidationError::to_string(self : ValidationError) -> String {
  match self {
    InvalidValidationProfile(msg) => "InvalidValidationProfile: \{msg}"
    InvalidValidationOptions(msg) => "InvalidValidationOptions: \{msg}"
    InvalidValidationReport(msg) => "InvalidValidationReport: \{msg}"
    InvalidValidationJson(msg) => "InvalidValidationJson: \{msg}"
    JsonDecodeError(msg) => "JsonDecodeError: \{msg}"
    JsonEncodeError(msg) => "JsonEncodeError: \{msg}"
    MissingJsonField(msg) => "MissingJsonField: \{msg}"
    ScoreLayoutError(msg) => "ScoreLayoutError: \{msg}"
  }
}

// ============================================================
// Options 构造函数
// ============================================================

///|
/// 默认校验选项 — 普通编辑模式，warning 不会升级
pub fn default_validation_options() -> ValidationOptions {
  editing_validation_options()
}

///|
/// 编辑模式校验选项 — 所有宽松检查
pub fn editing_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: false,
    empty_voice_is_error: false,
    empty_staff_is_error: false,
    empty_part_is_error: false,
    check_repeats: false,
    check_ties: false,
    check_voice_alignment: false,
    export_mode: false,
    check_midi_readiness: false,
    check_musicxml_readiness: false,
    check_game_readiness: false,
    unsupported_notation_is_error: false,
    warning_as_error: false,
  }
}

///|
/// 严格校验选项 — 测试 / 发布前使用
pub fn strict_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: true,
    empty_voice_is_error: true,
    empty_staff_is_error: true,
    empty_part_is_error: true,
    check_repeats: true,
    check_ties: true,
    check_voice_alignment: true,
    export_mode: false,
    check_midi_readiness: false,
    check_musicxml_readiness: false,
    check_game_readiness: false,
    unsupported_notation_is_error: true,
    warning_as_error: false,
  }
}

///|
/// 导出前校验选项 — 比 strict 多开启 export_mode
pub fn export_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: true,
    empty_voice_is_error: true,
    empty_staff_is_error: true,
    empty_part_is_error: true,
    check_repeats: false,
    check_ties: false,
    check_voice_alignment: true,
    export_mode: true,
    check_midi_readiness: false,
    check_musicxml_readiness: false,
    check_game_readiness: false,
    unsupported_notation_is_error: false,
    warning_as_error: false,
  }
}

///|
/// MIDI 导出前校验选项
pub fn midi_export_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: true,
    empty_voice_is_error: true,
    empty_staff_is_error: true,
    empty_part_is_error: true,
    check_repeats: false,
    check_ties: false,
    check_voice_alignment: true,
    export_mode: true,
    check_midi_readiness: true,
    check_musicxml_readiness: false,
    check_game_readiness: false,
    unsupported_notation_is_error: false,
    warning_as_error: false,
  }
}

///|
/// MusicXML 导出前校验选项
pub fn musicxml_export_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: true,
    empty_voice_is_error: true,
    empty_staff_is_error: true,
    empty_part_is_error: true,
    check_repeats: true,
    check_ties: true,
    check_voice_alignment: true,
    export_mode: true,
    check_midi_readiness: false,
    check_musicxml_readiness: true,
    check_game_readiness: false,
    unsupported_notation_is_error: true,
    warning_as_error: false,
  }
}

///|
/// Game IR 导出前校验选项
pub fn game_export_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: true,
    empty_voice_is_error: true,
    empty_staff_is_error: true,
    empty_part_is_error: true,
    check_repeats: true,
    check_ties: false,
    check_voice_alignment: false,
    export_mode: true,
    check_midi_readiness: false,
    check_musicxml_readiness: false,
    check_game_readiness: true,
    unsupported_notation_is_error: false,
    warning_as_error: false,
  }
}

///|
/// Golden test 校验选项 — 最严格，warning 升级为 error
pub fn golden_test_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: true,
    empty_voice_is_error: true,
    empty_staff_is_error: true,
    empty_part_is_error: true,
    check_repeats: true,
    check_ties: true,
    check_voice_alignment: true,
    export_mode: true,
    check_midi_readiness: true,
    check_musicxml_readiness: true,
    check_game_readiness: true,
    unsupported_notation_is_error: true,
    warning_as_error: true,
  }
}

///|
/// 根据档案返回对应校验选项
pub fn validation_options_for_profile(
  profile : ValidationProfile,
) -> ValidationOptions {
  match profile {
    EditingProfile => editing_validation_options()
    StrictProfile => strict_validation_options()
    MidiExportProfile => midi_export_validation_options()
    MusicXmlExportProfile => musicxml_export_validation_options()
    GameExportProfile => game_export_validation_options()
    GoldenTestProfile => golden_test_validation_options()
  }
}

// ============================================================
// 规则表（内部）— ValidationCode → 严重级别 / 建议
// ============================================================

///|
/// 根据 profile 获取 ValidationCode 的默认严重级别。
/// 部分 code 在不同 profile 下严重级别不同。
pub fn validation_code_default_severity(
  code : ValidationCode,
  profile : ValidationProfile,
) -> ValidationSeverity {
  match code {
    // ---- Fatal in all profiles ----
    InvalidPPQ | ValidateInvalidScorePath => Fatal

    // ---- Error in all profiles ----
    ValidateInvalidTimeSignature
    | ValidateInvalidTempo
    | ValidateMeasureOverflow
    | PickupMeasureTooLong
    | FinalMeasureTooLong
    | TieStartWithoutStop
    | TieStopWithoutStart
    | RepeatWithoutStart
    | RepeatStartWithoutEnd
    | RepeatJumpTargetMissing
    | EndingWithoutRepeat
    | CodaTargetMissing
    | SegnoTargetMissing => Error

    // ---- Profile-dependent ----
    EmptyScore => if profile is EditingProfile { Warning } else { Error }
    EmptyPart => if profile is EditingProfile { Warning } else { Error }
    EmptyStaff =>
      match profile {
        EditingProfile | MidiExportProfile => Warning
        _ => Error
      }
    EmptyVoice =>
      match profile {
        EditingProfile | MidiExportProfile => Warning
        _ => Error
      }
    MeasureUnderfilled =>
      match profile {
        EditingProfile => Info
        StrictProfile | MidiExportProfile => Warning
        _ => Error
      }
    VoiceAlignmentMismatch =>
      match profile {
        EditingProfile => Info
        StrictProfile | MidiExportProfile => Warning
        _ => Error
      }
    ValidateInvalidChannel =>
      match profile {
        EditingProfile | MusicXmlExportProfile => Warning
        _ => Error
      }
    ValidateInvalidProgram =>
      match profile {
        EditingProfile | MusicXmlExportProfile => Warning
        _ => Error
      }
    TieContinueWithoutStart | TiePitchMismatch | TieDurationSuspicious => Error
    EndingRangeInvalid => Error
    UnsupportedNotation =>
      match profile {
        EditingProfile | MidiExportProfile => Info
        StrictProfile | MusicXmlExportProfile => Warning
        GoldenTestProfile => Error
        _ => Error
      }
    UnsupportedForMidi =>
      match profile {
        EditingProfile
        | StrictProfile
        | GameExportProfile
        | MusicXmlExportProfile => Info
        MidiExportProfile | GoldenTestProfile => Error
      }
    UnsupportedForMusicXml =>
      match profile {
        EditingProfile
        | MidiExportProfile
        | GameExportProfile
        | GoldenTestProfile => Info
        MusicXmlExportProfile => Error
        StrictProfile => Warning
      }
    UnsupportedForGame =>
      match profile {
        EditingProfile
        | StrictProfile
        | MidiExportProfile
        | MusicXmlExportProfile => Info
        GameExportProfile | GoldenTestProfile => Error
      }
    ScoreValidationUnsupported =>
      match profile {
        EditingProfile => Info
        GoldenTestProfile => Error
        _ => Warning
      }

    // ---- Default catch-all for new codes ----
    EmptyMeasure => if profile is EditingProfile { Warning } else { Error }
    FreeTimeMeasureUnsupported | CadenzaMeasureUnsupported => Warning
    MeasureIndexMismatch | DuplicateMeasureIndex => Error
    InvalidMidiVelocity | InvalidMidiNote => Error
    UnreachableSection => Warning
    UnsupportedLyric | UnsupportedClef =>
      if profile is EditingProfile {
        Info
      } else {
        Warning
      }
  }
}

///|
/// 获取 ValidationCode 的默认修复建议（中文）
pub fn validation_code_default_suggestion(code : ValidationCode) -> String {
  match code {
    InvalidPPQ => "使用大于 0 的 PPQ"
    ValidateInvalidTimeSignature =>
      "使用合法拍号，例如 4/4、3/4、6/8"
    ValidateInvalidTempo => "使用大于 0 的 BPM"
    ValidateInvalidScorePath =>
      "使用正确的路径格式，如 part[0]/staff[0]/voice[0]"
    EmptyScore => "添加至少一个 part 或 track"
    EmptyPart => "删除空 part 或添加 staff"
    EmptyStaff => "删除空 staff 或添加 voice"
    EmptyVoice => "删除空 voice 或添加 rest/note"
    EmptyMeasure => "删除空小节或添加 rest"
    ValidateMeasureOverflow =>
      "缩短该小节事件、拆分跨小节 tie，或改为 CadenzaMeasure"
    MeasureUnderfilled =>
      "补 rest、标记为 PickupMeasure/FinalMeasure，或调整拍号"
    PickupMeasureTooLong => "缩短 pickup 小节或改为 NormalMeasure"
    FinalMeasureTooLong => "缩短 final 小节或改为 NormalMeasure"
    FreeTimeMeasureUnsupported =>
      "当前导出目标不支持 FreeTimeMeasure，请使用普通小节"
    CadenzaMeasureUnsupported =>
      "当前导出目标不支持 CadenzaMeasure，请使用普通小节"
    VoiceAlignmentMismatch => "补齐 measure 或调整 voice 对齐"
    MeasureIndexMismatch => "确保所有声部的 measure index 一致"
    DuplicateMeasureIndex => "每声部内 measure index 必须唯一"
    ValidateInvalidChannel => "使用 0..15 的 MIDI channel"
    ValidateInvalidProgram => "使用 0..127 的 MIDI program"
    InvalidMidiVelocity => "velocity 必须在 0..127 范围内"
    InvalidMidiNote => "MIDI note 必须在 0..127 范围内"
    TieStartWithoutStop => "添加对应 TieStop"
    TieStopWithoutStart => "添加对应 TieStart"
    TieContinueWithoutStart => "TieContinue 必须有前置 TieStart"
    TiePitchMismatch => "确保 tie start/stop 连接相同音高"
    TieDurationSuspicious => "tie 连接的事件总时长异常，请检查"
    RepeatWithoutStart => "添加 RepeatStart 或移除 RepeatEnd"
    RepeatStartWithoutEnd => "添加 RepeatEnd 或移除 RepeatStart"
    RepeatJumpTargetMissing => "添加目标 Segno/Coda/Fine 标记"
    EndingWithoutRepeat => "添加相关 repeat 或移除 ending"
    EndingRangeInvalid =>
      "ending 范围无效，检查 start_measure/end_measure"
    CodaTargetMissing => "添加 Coda 标记"
    SegnoTargetMissing => "添加 Segno 标记"
    UnreachableSection => "检查 section 顺序和 repeat 跳转"
    UnsupportedNotation => "降级 notation 或扩展导出器"
    UnsupportedLyric => "降级 lyric 或扩展导出器"
    UnsupportedClef => "使用标准 clef 或扩展导出器"
    UnsupportedForMidi => "MIDI 导出不支持此特性，请降级"
    UnsupportedForMusicXml => "MusicXML 导出不支持此特性，请降级"
    UnsupportedForGame => "Game IR 不支持此特性，请降级"
    ScoreValidationUnsupported => "使用更完整的 enhanced score 结构"
  }
}

///|
/// 将 ValidationCode 转为字符串表示
pub fn validation_code_to_string(code : ValidationCode) -> String {
  match code {
    InvalidPPQ => "InvalidPPQ"
    ValidateInvalidTimeSignature => "ValidateInvalidTimeSignature"
    ValidateInvalidTempo => "ValidateInvalidTempo"
    ValidateInvalidScorePath => "ValidateInvalidScorePath"
    EmptyScore => "EmptyScore"
    EmptyPart => "EmptyPart"
    EmptyStaff => "EmptyStaff"
    EmptyVoice => "EmptyVoice"
    EmptyMeasure => "EmptyMeasure"
    ValidateMeasureOverflow => "ValidateMeasureOverflow"
    MeasureUnderfilled => "MeasureUnderfilled"
    PickupMeasureTooLong => "PickupMeasureTooLong"
    FinalMeasureTooLong => "FinalMeasureTooLong"
    FreeTimeMeasureUnsupported => "FreeTimeMeasureUnsupported"
    CadenzaMeasureUnsupported => "CadenzaMeasureUnsupported"
    VoiceAlignmentMismatch => "VoiceAlignmentMismatch"
    MeasureIndexMismatch => "MeasureIndexMismatch"
    DuplicateMeasureIndex => "DuplicateMeasureIndex"
    ValidateInvalidChannel => "ValidateInvalidChannel"
    ValidateInvalidProgram => "ValidateInvalidProgram"
    InvalidMidiVelocity => "InvalidMidiVelocity"
    InvalidMidiNote => "InvalidMidiNote"
    TieStartWithoutStop => "TieStartWithoutStop"
    TieStopWithoutStart => "TieStopWithoutStart"
    TieContinueWithoutStart => "TieContinueWithoutStart"
    TiePitchMismatch => "TiePitchMismatch"
    TieDurationSuspicious => "TieDurationSuspicious"
    RepeatWithoutStart => "RepeatWithoutStart"
    RepeatStartWithoutEnd => "RepeatStartWithoutEnd"
    RepeatJumpTargetMissing => "RepeatJumpTargetMissing"
    EndingWithoutRepeat => "EndingWithoutRepeat"
    EndingRangeInvalid => "EndingRangeInvalid"
    CodaTargetMissing => "CodaTargetMissing"
    SegnoTargetMissing => "SegnoTargetMissing"
    UnreachableSection => "UnreachableSection"
    UnsupportedNotation => "UnsupportedNotation"
    UnsupportedLyric => "UnsupportedLyric"
    UnsupportedClef => "UnsupportedClef"
    UnsupportedForMidi => "UnsupportedForMidi"
    UnsupportedForMusicXml => "UnsupportedForMusicXml"
    UnsupportedForGame => "UnsupportedForGame"
    ScoreValidationUnsupported => "ScoreValidationUnsupported"
  }
}

///|
/// 将 ValidationSeverity 转为字符串
pub fn validation_severity_to_string(severity : ValidationSeverity) -> String {
  match severity {
    Info => "Info"
    Warning => "Warning"
    Error => "Error"
    Fatal => "Fatal"
  }
}

///|
/// 将 ValidationTargetKind 转为字符串
pub fn validation_target_kind_to_string(kind : ValidationTargetKind) -> String {
  match kind {
    ValidateScoreTarget => "Score"
    PartTarget => "Part"
    StaffTarget => "Staff"
    VoiceTarget => "Voice"
    MeasureTarget => "Measure"
    EventTarget => "Event"
    RepeatTarget => "Repeat"
    SectionTarget => "Section"
    EndingTarget => "Ending"
    CodaTarget => "Coda"
    SegnoTarget => "Segno"
    ExportTarget => "Export"
  }
}

// ============================================================
// Report 构造与合并（内部 + 公开）
// ============================================================

///|
/// 创建空校验报告
pub fn validation_report_empty() -> ValidationReport {
  {
    issues: [],
    checked_targets: 0,
    info_count: 0,
    warning_count: 0,
    error_count: 0,
    fatal_count: 0,
  }
}

///|
fn bump_checked(report : ValidationReport, delta : Int) -> ValidationReport {
  {
    issues: report.issues,
    checked_targets: report.checked_targets + delta,
    info_count: report.info_count,
    warning_count: report.warning_count,
    error_count: report.error_count,
    fatal_count: report.fatal_count,
  }
}

///|
/// 向 report 追加一条 issue
pub fn validation_report_add_issue(
  report : ValidationReport,
  issue : ValidationIssue,
) -> ValidationReport {
  let issues : Array[ValidationIssue] = []
  for iss in report.issues {
    issues.push(iss)
  }
  issues.push(issue)
  let mut ic = report.info_count
  let mut wc = report.warning_count
  let mut ec = report.error_count
  let mut fc = report.fatal_count
  match issue.severity {
    Info => ic = ic + 1
    Warning => wc = wc + 1
    Error => ec = ec + 1
    Fatal => {
      ec = ec + 1
      fc = fc + 1
    }
  }
  {
    issues,
    checked_targets: report.checked_targets,
    info_count: ic,
    warning_count: wc,
    error_count: ec,
    fatal_count: fc,
  }
}

///|
/// 合并两份校验报告
pub fn validation_report_merge(
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
    info_count: a.info_count + b.info_count,
    warning_count: a.warning_count + b.warning_count,
    error_count: a.error_count + b.error_count,
    fatal_count: a.fatal_count + b.fatal_count,
  }
}

// ---- 内部别名（保持向后兼容）----

///|
fn new_empty_report() -> ValidationReport {
  validation_report_empty()
}

///|
fn add_issue_to_report(
  report : ValidationReport,
  issue : ValidationIssue,
) -> ValidationReport {
  validation_report_add_issue(report, issue)
}

///|
fn merge_reports(
  a : ValidationReport,
  b : ValidationReport,
) -> ValidationReport {
  validation_report_merge(a, b)
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
/// 创建校验上下文（用于 Voice/Measure 层级校验传参）
pub fn validation_context(
  part_index : Int,
  staff_index : Int,
  voice_index : Int,
  path_prefix : String,
) -> ValidationContext {
  { part_index, staff_index, voice_index, path_prefix }
}

///|
fn default_context() -> ValidationContext {
  { part_index: -1, staff_index: -1, voice_index: -1, path_prefix: "" }
}

///|
/// 向后兼容的默认严重级别（v1 行为，无 profile 影响）
fn _default_severity_v1(code : ValidationCode) -> ValidationSeverity {
  match code {
    ValidateMeasureOverflow => Error
    MeasureUnderfilled => Warning
    PickupMeasureTooLong => Error
    FinalMeasureTooLong => Error
    EmptyVoice => Warning
    EmptyStaff => Warning
    EmptyPart => Warning
    EmptyScore => Warning
    EmptyMeasure => Warning
    ValidateInvalidChannel => Error
    ValidateInvalidProgram => Error
    InvalidPPQ => Fatal
    TieStartWithoutStop => Error
    TieStopWithoutStart => Error
    TieContinueWithoutStart => Error
    TiePitchMismatch => Error
    TieDurationSuspicious => Error
    RepeatWithoutStart => Error
    RepeatStartWithoutEnd => Error
    RepeatJumpTargetMissing => Error
    EndingWithoutRepeat => Error
    EndingRangeInvalid => Error
    CodaTargetMissing => Error
    SegnoTargetMissing => Error
    UnreachableSection => Warning
    VoiceAlignmentMismatch => Warning
    UnsupportedNotation => Warning
    ScoreValidationUnsupported => Warning
    ValidateInvalidTimeSignature => Error
    ValidateInvalidTempo => Error
    ValidateInvalidScorePath => Fatal
    MeasureIndexMismatch => Error
    DuplicateMeasureIndex => Error
    FreeTimeMeasureUnsupported => Warning
    CadenzaMeasureUnsupported => Warning
    InvalidMidiVelocity => Error
    InvalidMidiNote => Error
    UnsupportedLyric => Warning
    UnsupportedClef => Warning
    UnsupportedForMidi => Warning
    UnsupportedForMusicXml => Warning
    UnsupportedForGame => Warning
  }
}

///|
fn make_issue(
  code : ValidationCode,
  location : ValidationLocation,
  message : String,
) -> ValidationIssue {
  let severity = _default_severity_v1(code)
  let suggestion = validation_code_default_suggestion(code)
  {
    severity,
    code,
    location,
    message,
    suggestion,
    source: { value: "validation" },
  }
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
/// 检查容量溢出 (ValidateMeasureOverflow) 和填充不足 (MeasureUnderfilled)。
pub fn validate_measure_report(
  measure : Measure,
  sig : TimeSignature,
  _ppq : Int,
  options : ValidationOptions,
) -> ValidationReport {
  validate_measure_report_ctx(measure, sig, default_context(), options)
}

///|
/// 带上下文的 Measure 校验（含层级路径信息）
pub fn validate_measure_report_ctx(
  measure : Measure,
  sig : TimeSignature,
  context : ValidationContext,
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
  let m_path = if context.path_prefix == "" {
    "measure[" + measure.index.to_string() + "]"
  } else {
    context.path_prefix + "/measure[" + measure.index.to_string() + "]"
  }
  // 使用 0.000001 容差比较浮点
  if used > capacity + 0.000001 {
    let loc = make_location(
      MeasureTarget,
      context.part_index,
      context.staff_index,
      context.voice_index,
      measure.index,
      -1,
      m_path,
    )
    report = add_issue_to_report(
      report,
      make_issue(
        ValidateMeasureOverflow,
        loc,
        "小节 #\{measure.index} 溢出：拍数 \{used} > 容量 \{capacity}",
      ),
    )
  } else if used < capacity - 0.000001 && options.strict_measure_capacity {
    let loc = make_location(
      MeasureTarget,
      context.part_index,
      context.staff_index,
      context.voice_index,
      measure.index,
      -1,
      m_path,
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
  validate_voice_report_ctx(voice, default_context(), options)
}

///|
/// 带上下文的 Voice 校验
pub fn validate_voice_report_ctx(
  voice : Voice,
  context : ValidationContext,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = new_empty_report()
  report = bump_checked(report, 1)
  let voice_path = if context.path_prefix == "" {
    "voice[\{voice.name}]"
  } else {
    context.path_prefix + "/voice[\{voice.name}]"
  }
  // 空声部检查
  if voice.measures.length() == 0 {
    let code = EmptyVoice
    let sever = if options.empty_voice_is_error || options.warning_as_error {
      Error
    } else {
      validation_code_default_severity(code, EditingProfile)
    }
    let loc = make_location(
      VoiceTarget,
      context.part_index,
      context.staff_index,
      context.voice_index,
      -1,
      -1,
      voice_path,
    )
    report = add_issue_to_report(report, {
      severity: sever,
      code,
      location: loc,
      message: "空声部：\{voice_path} 无 measure",
      suggestion: validation_code_default_suggestion(code),
      source: { value: "validation" },
    })
  }
  // 递归校验每个 measure
  let default_sig = four_four()
  for i = 0; i < voice.measures.length(); i = i + 1 {
    let m = voice.measures[i]
    let m_ctx = {
      part_index: context.part_index,
      staff_index: context.staff_index,
      voice_index: context.voice_index,
      path_prefix: voice_path,
    }
    let sub = validate_measure_report_ctx(m, default_sig, m_ctx, options)
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
  validate_staff_report_ctx(staff, default_context(), options)
}

///|
/// 带上下文的 Staff 校验
pub fn validate_staff_report_ctx(
  staff : Staff,
  context : ValidationContext,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = new_empty_report()
  report = bump_checked(report, 1)
  let staff_path = if context.path_prefix == "" {
    "staff[\{staff.name}]"
  } else {
    context.path_prefix + "/staff[\{staff.name}]"
  }
  // Channel 检查
  match staff.channel {
    Some(c) =>
      if !is_valid_channel_c(c) {
        let loc = make_location(
          StaffTarget,
          context.part_index,
          context.staff_index,
          -1,
          -1,
          -1,
          staff_path,
        )
        report = add_issue_to_report(
          report,
          make_issue(
            ValidateInvalidChannel,
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
        let loc = make_location(
          StaffTarget,
          context.part_index,
          context.staff_index,
          -1,
          -1,
          -1,
          staff_path,
        )
        report = add_issue_to_report(
          report,
          make_issue(
            ValidateInvalidProgram,
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
    let sever = if options.empty_staff_is_error || options.warning_as_error {
      Error
    } else {
      validation_code_default_severity(code, EditingProfile)
    }
    let loc = make_location(
      StaffTarget,
      context.part_index,
      context.staff_index,
      -1,
      -1,
      -1,
      staff_path,
    )
    report = add_issue_to_report(report, {
      severity: sever,
      code,
      location: loc,
      message: "空 staff：\{staff_path} 无 voice",
      suggestion: validation_code_default_suggestion(code),
      source: { value: "validation" },
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
        context.part_index,
        context.staff_index,
        -1,
        -1,
        -1,
        staff_path,
      )
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
    let v_ctx = {
      part_index: context.part_index,
      staff_index: context.staff_index,
      voice_index: vi,
      path_prefix: staff_path + "/voice[" + vi.to_string() + "]",
    }
    let sub = validate_voice_report_ctx(staff.voices[vi], v_ctx, options)
    report = merge_reports(report, sub)
  }
  report
}

// ============================================================
// 校验逻辑 — Part
// ============================================================

///|
/// 校验 Part：空 part 检查、递归校验 staff。
pub fn validate_part_report(
  part : Part,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = new_empty_report()
  report = bump_checked(report, 1)
  let part_path = "part[\{part.name}]"
  if part.staves.length() == 0 {
    let code = EmptyPart
    let sever = if options.empty_part_is_error || options.warning_as_error {
      Error
    } else {
      validation_code_default_severity(code, EditingProfile)
    }
    let loc = make_location(PartTarget, -1, -1, -1, -1, -1, part_path)
    report = add_issue_to_report(report, {
      severity: sever,
      code,
      location: loc,
      message: "空 part：\{part_path} 无 staff",
      suggestion: validation_code_default_suggestion(code),
      source: { value: "validation" },
    })
  }
  for si = 0; si < part.staves.length(); si = si + 1 {
    let s_ctx = {
      part_index: -1,
      staff_index: si,
      voice_index: -1,
      path_prefix: part_path + "/staff[" + si.to_string() + "]",
    }
    let sub = validate_staff_report_ctx(part.staves[si], s_ctx, options)
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
    let loc = make_location(
      ValidateScoreTarget,
      -1,
      -1,
      -1,
      -1,
      -1,
      "score_layout",
    )
    report = add_issue_to_report(
      report,
      make_issue(InvalidPPQ, loc, "非法 PPQ：\{layout.ppq}，必须 > 0"),
    )
  }
  // 初始拍号检查（仅报告非法拍号）
  if !is_valid_time_signature(
      layout.initial_signature.numerator,
      layout.initial_signature.denominator,
    ) {
    let loc = make_location(
      ValidateScoreTarget,
      -1,
      -1,
      -1,
      -1,
      -1,
      "score_layout",
    )
    report = add_issue_to_report(
      report,
      make_issue(
        ValidateInvalidTimeSignature,
        loc,
        "非法初始拍号：\{layout.initial_signature.numerator}/\{layout.initial_signature.denominator}",
      ),
    )
  }
  // 初始速度检查
  if layout.initial_tempo.bpm <= 0 {
    let loc = make_location(
      ValidateScoreTarget,
      -1,
      -1,
      -1,
      -1,
      -1,
      "score_layout",
    )
    report = add_issue_to_report(
      report,
      make_issue(
        ValidateInvalidTempo,
        loc,
        "非法初始速度：\{layout.initial_tempo.bpm} BPM，必须 > 0",
      ),
    )
  }
  // 空整体检查
  if layout.parts.length() == 0 {
    report = add_issue_to_report(
      report,
      make_issue(
        EmptyScore,
        make_location(ValidateScoreTarget, -1, -1, -1, -1, -1, "score_layout"),
        "空 ScoreLayout：无 part",
      ),
    )
  }
  // 遍历 part → staff → voice → measure
  for pi = 0; pi < layout.parts.length(); pi = pi + 1 {
    let part = layout.parts[pi]
    let part_path = "part[" + pi.to_string() + "]"
    if part.staves.length() == 0 {
      let code = EmptyPart
      let sever = if options.empty_part_is_error || options.warning_as_error {
        Error
      } else {
        validation_code_default_severity(code, EditingProfile)
      }
      let loc = make_location(PartTarget, pi, -1, -1, -1, -1, part_path)
      report = add_issue_to_report(report, {
        severity: sever,
        code,
        location: loc,
        message: "空 part：\{part_path}[\{part.name}] 无 staff",
        suggestion: validation_code_default_suggestion(code),
        source: { value: "validation" },
      })
    }
    for si = 0; si < part.staves.length(); si = si + 1 {
      let staff = part.staves[si]
      let staff_path = part_path + "/staff[" + si.to_string() + "]"
      report = bump_checked(report, 1)
      // Channel 检查
      match staff.channel {
        Some(c) =>
          if !is_valid_channel_c(c) {
            let loc = make_location(StaffTarget, pi, si, -1, -1, -1, staff_path)
            report = add_issue_to_report(
              report,
              make_issue(
                ValidateInvalidChannel,
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
                ValidateInvalidProgram,
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
        let sever = if options.empty_staff_is_error || options.warning_as_error {
          Error
        } else {
          validation_code_default_severity(code, EditingProfile)
        }
        let loc = make_location(StaffTarget, pi, si, -1, -1, -1, staff_path)
        report = add_issue_to_report(report, {
          severity: sever,
          code,
          location: loc,
          message: "空 staff：\{staff_path}[\{staff.name}] 无 voice",
          suggestion: validation_code_default_suggestion(code),
          source: { value: "validation" },
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
      // MIDI readiness — velocity / note 范围检查（在 staff 层级无需检查，在 voice/event 层级检查）
      // 递归校验每个 voice
      for vi = 0; vi < staff.voices.length(); vi = vi + 1 {
        let voice = staff.voices[vi]
        let voice_path = staff_path + "/voice[" + vi.to_string() + "]"
        report = bump_checked(report, 1)
        // 空 voice 检查
        if voice.measures.length() == 0 {
          let code = EmptyVoice
          let sever = if options.empty_voice_is_error ||
            options.warning_as_error {
            Error
          } else {
            validation_code_default_severity(code, EditingProfile)
          }
          let loc = make_location(VoiceTarget, pi, si, vi, -1, -1, voice_path)
          report = add_issue_to_report(report, {
            severity: sever,
            code,
            location: loc,
            message: "空声部：\{voice_path}[\{voice.name}] 无 measure",
            suggestion: validation_code_default_suggestion(code),
            source: { value: "validation" },
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
                ValidateMeasureOverflow,
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
    let loc = make_location(ValidateScoreTarget, -1, -1, -1, -1, -1, "score")
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
          ValidateInvalidChannel,
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
          ValidateInvalidProgram,
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
        make_location(ValidateScoreTarget, -1, -1, -1, -1, -1, "score"),
        "Score 不支持完整 measure 级校验，请使用 ScoreLayout 获得更详细的校验",
      ),
    )
  }
  report
}

// ============================================================
// Export readiness — 导出前快速校验
// ============================================================

///|
/// MIDI 导出 readiness 校验 — 关注 PPQ/channel/program/velocity/note/tick
pub fn validate_midi_export_ready(layout : ScoreLayout) -> ValidationReport {
  validate_score_layout_report(layout, midi_export_validation_options())
}

///|
/// MusicXML 导出 readiness 校验 — 关注 measure capacity/voice/notation/tie/repeat
pub fn validate_musicxml_export_ready(layout : ScoreLayout) -> ValidationReport {
  validate_score_layout_report(layout, musicxml_export_validation_options())
}

///|
/// Game IR 导出 readiness 校验 — 关注 section/loop boundaries/transition
pub fn validate_game_export_ready(layout : ScoreLayout) -> ValidationReport {
  validate_score_layout_report(layout, game_export_validation_options())
}

///|
/// 判断 report 是否阻止导出（有 Error 或 Fatal 即阻止）
pub fn validation_report_is_export_blocking(report : ValidationReport) -> Bool {
  report.fatal_count > 0 || report.error_count > 0
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

///|
/// report 中 Fatal 总数
pub fn validation_report_fatal_count(report : ValidationReport) -> Int {
  report.fatal_count
}

///|
/// report 中 Info 总数
pub fn validation_report_info_count(report : ValidationReport) -> Int {
  report.info_count
}

// ============================================================
// Report 导出 — JSON
// ============================================================

///|
/// 将 issue 序列化为 JSON 字符串
fn issue_to_json(issue : ValidationIssue) -> String {
  "{\"severity\":\"" +
  validation_severity_to_string(issue.severity) +
  "\",\"code\":\"" +
  validation_code_to_string(issue.code) +
  "\",\"location\":{" +
  "\"target_kind\":\"" +
  validation_target_kind_to_string(issue.location.target_kind) +
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
  ",\"source\":" +
  json_escape(issue.source.value) +
  "}"
}

///|
/// 将 ValidationReport 序列化为 JSON 字符串。
pub fn validation_report_to_json(report : ValidationReport) -> String {
  let mut s = "{\"info_count\":" +
    report.info_count.to_string() +
    ",\"error_count\":" +
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
    " 个，信息 " +
    report.info_count.to_string() +
    " 个，共检查 " +
    report.checked_targets.to_string() +
    " 个目标。\n"
  for iss in report.issues {
    s = s +
      "[" +
      validation_severity_to_string(iss.severity) +
      "] " +
      validation_code_to_string(iss.code) +
      ": " +
      iss.message +
      " (建议: " +
      iss.suggestion +
      ")\n"
  }
  s
}

///|
/// 将 ValidationReport 转换为 golden test 用确定性文本。
/// 按 path/code/severity 稳定排序后输出。
pub fn validation_report_to_golden_text(report : ValidationReport) -> String {
  if report.issues.length() == 0 {
    return "GOLDEN: 0 issues"
  }
  // 复制 issues 并排序（path → code → severity）
  let sorted = []
  for iss in report.issues {
    sorted.push(iss)
  }
  // 冒泡排序（稳定排序）
  let n = sorted.length()
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n - 1 - i; j = j + 1 {
      let a = sorted[j]
      let b = sorted[j + 1]
      let cmp = golden_compare(a, b)
      if cmp > 0 {
        let tmp = sorted[j]
        sorted[j] = sorted[j + 1]
        sorted[j + 1] = tmp
      }
    }
  }
  let mut s = "GOLDEN: fatal=" +
    report.fatal_count.to_string() +
    " error=" +
    report.error_count.to_string() +
    " warning=" +
    report.warning_count.to_string() +
    " info=" +
    report.info_count.to_string() +
    " checked=" +
    report.checked_targets.to_string() +
    "\n"
  for iss in sorted {
    s = s +
      validation_severity_to_string(iss.severity) +
      "|" +
      validation_code_to_string(iss.code) +
      "|" +
      iss.location.path +
      "|" +
      iss.message +
      "\n"
  }
  s
}

///|
fn golden_compare(a : ValidationIssue, b : ValidationIssue) -> Int {
  let p = a.location.path.compare(b.location.path)
  if p != 0 {
    return p
  }
  let c = validation_code_to_string(a.code).compare(
    validation_code_to_string(b.code),
  )
  if c != 0 {
    return c
  }
  validation_severity_to_string(a.severity).compare(
    validation_severity_to_string(b.severity),
  )
}

///|
/// 获取 ValidationProfile 的字符串表示
pub fn validation_profile_to_string(profile : ValidationProfile) -> String {
  match profile {
    EditingProfile => "EditingProfile"
    StrictProfile => "StrictProfile"
    MidiExportProfile => "MidiExportProfile"
    MusicXmlExportProfile => "MusicXmlExportProfile"
    GameExportProfile => "GameExportProfile"
    GoldenTestProfile => "GoldenTestProfile"
  }
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
