///|
pub(all) enum GameIssueSeverity {
  GameInfo
  GameWarning
  GameError
}

///|
pub(all) enum GameIssueCode {
  CueHasNoSegments
  DuplicateCue
  MissingDefaultCue
  InvalidLoopRange
  TransitionTargetMissing
  ParameterOutOfRange
}

///|
pub(all) struct GameValidationIssue {
  severity : GameIssueSeverity
  code : GameIssueCode
  path : String
  message : String
}

///|
pub(all) struct GameValidationSummary {
  total_issues : Int
  error_count : Int
  warning_count : Int
  info_count : Int
}

///|
pub(all) struct GameValidationReport {
  issues : Array[GameValidationIssue]
  summary : GameValidationSummary
}

///|
pub fn empty_game_validation_report() -> GameValidationReport {
  {
    issues: [],
    summary: {
      total_issues: 0,
      error_count: 0,
      warning_count: 0,
      info_count: 0,
    },
  }
}

///|
pub fn game_validation_report_has_errors(report : GameValidationReport) -> Bool {
  report.summary.error_count > 0
}

///|
pub fn validate_game_project_report(
  project : GameMusicProject,
) -> GameValidationReport {
  let issues : Array[GameValidationIssue] = []
  let cue_ids = extract_cue_ids(project.cues)
  if has_duplicate_string(cue_ids) {
    issues.push({
      severity: GameError,
      code: DuplicateCue,
      path: "project.cues",
      message: "duplicate cue id",
    })
  }
  for cue in project.cues {
    if cue.segments.length() == 0 {
      issues.push({
        severity: GameError,
        code: CueHasNoSegments,
        path: "project.cues[" + cue.id + "]",
        message: "cue has no segments",
      })
    }
  }
  for transition in project.transitions {
    if !array_contains_string(cue_ids, transition.from_cue) {
      issues.push({
        severity: GameError,
        code: TransitionTargetMissing,
        path: "project.transitions[" + transition.id + "].from_cue",
        message: "from cue does not exist",
      })
    }
    if !array_contains_string(cue_ids, transition.to_cue) {
      issues.push({
        severity: GameError,
        code: TransitionTargetMissing,
        path: "project.transitions[" + transition.id + "].to_cue",
        message: "to cue does not exist",
      })
    }
  }
  for parameter in project.parameters {
    if parameter.min_value >= parameter.max_value ||
      parameter.default_value < parameter.min_value ||
      parameter.default_value > parameter.max_value {
      issues.push({
        severity: GameError,
        code: ParameterOutOfRange,
        path: "project.parameters[" + parameter.id + "]",
        message: "parameter range/default is invalid",
      })
    }
  }
  summarize_issues(issues)
}

///|
fn summarize_issues(
  issues : Array[GameValidationIssue],
) -> GameValidationReport {
  let mut error_count = 0
  let mut warning_count = 0
  let mut info_count = 0
  for issue in issues {
    match issue.severity {
      GameError => error_count = error_count + 1
      GameWarning => warning_count = warning_count + 1
      GameInfo => info_count = info_count + 1
    }
  }
  {
    issues,
    summary: {
      total_issues: issues.length(),
      error_count,
      warning_count,
      info_count,
    },
  }
}
