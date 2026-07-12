///|
pub fn game_project_to_json_checked(
  project : GameMusicProject,
  options : GameExportOptions,
) -> Result[String, GameMusicError] {
  let report = validate_game_project_report(project)
  if options.strict && game_validation_report_has_errors(report) {
    return Err(ValidationFailed("strict mode blocks export"))
  }
  Ok(@json.json_stringify(game_project_to_json_value(project, options, report)))
}

///|
fn game_project_to_json_value(
  project : GameMusicProject,
  options : GameExportOptions,
  report : GameValidationReport,
) -> @json.JsonValue {
  let fields : Array[@json.JsonField] = [
    @json.json_field(
      "schema_version",
      @json.json_string(options.schema_version),
    ),
    @json.json_field(
      "project",
      @json.json_object([
        @json.json_field("id", @json.json_string(project.id)),
        @json.json_field("name", @json.json_string(project.name)),
        @json.json_field("tempo_bpm", @json.json_int(project.tempo_bpm)),
        @json.json_field("cue_count", @json.json_int(project.cues.length())),
        @json.json_field("state_count", @json.json_int(project.states.length())),
        @json.json_field(
          "parameter_count",
          @json.json_int(project.parameters.length()),
        ),
        @json.json_field(
          "transition_count",
          @json.json_int(project.transitions.length()),
        ),
      ]),
    ),
  ]
  if options.include_validation_report {
    fields.push(
      @json.json_field("validation", validation_report_json_value(report)),
    )
  }
  @json.json_object(fields)
}

///|
fn validation_report_json_value(
  report : GameValidationReport,
) -> @json.JsonValue {
  @json.json_object([
    @json.json_field("error_count", @json.json_int(report.summary.error_count)),
    @json.json_field(
      "warning_count",
      @json.json_int(report.summary.warning_count),
    ),
    @json.json_field("info_count", @json.json_int(report.summary.info_count)),
    @json.json_field(
      "total_issues",
      @json.json_int(report.summary.total_issues),
    ),
  ])
}

///|
pub fn game_validation_report_to_json(report : GameValidationReport) -> String {
  @json.json_stringify(validation_report_json_value(report))
}
