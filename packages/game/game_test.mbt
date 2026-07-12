///|
fn timeline_source() -> @game.GameTimelineSource {
  let event = @timeline.NoteEvent::{
    start: 0.0,
    duration: 1.0,
    midi_note: 60,
    velocity: 90,
    channel: 0,
  }
  @game.game_timeline_from_note_events([event], 480)
}

///|
fn segment() -> @game.GameSegment {
  @game.game_segment_from_timeline_checked("seg", "Segment", timeline_source()).unwrap()
}

///|
test "timeline_source_from_note_events" {
  let source = timeline_source()
  assert_eq(source.entries.length(), 1)
  assert_eq(source.total_ticks, 480)
}

///|
test "segment_from_timeline" {
  let seg = segment()
  assert_eq(seg.duration_beats, 1.0)
}

///|
test "cue_checked" {
  let cue = @game.game_cue_checked("cue", "Cue", @game.LoopCue, [segment()]).unwrap()
  assert_true(cue.kind.is_default_loop())
}

///|
test "project_checked" {
  let cue = @game.game_cue_checked("cue", "Cue", @game.LoopCue, [segment()]).unwrap()
  let project = @game.game_project_checked("p", "Project", [cue]).unwrap()
  assert_eq(project.cues.length(), 1)
}

///|
test "duplicate_cue_err" {
  let cue = @game.game_cue_checked("cue", "Cue", @game.LoopCue, [segment()]).unwrap()
  assert_true(@game.game_project_checked("p", "Project", [cue, cue]) is Err(_))
}

///|
test "empty_cue_validation" {
  let cue = @game.game_cue_checked("cue", "Cue", @game.LinearCue, []).unwrap()
  let project = @game.game_project_checked("p", "Project", [cue]).unwrap()
  let report = @game.validate_game_project_report(project)
  assert_true(@game.game_validation_report_has_errors(report))
}

///|
test "json_export" {
  let cue = @game.game_cue_checked("cue", "Cue", @game.LoopCue, [segment()]).unwrap()
  let project = @game.game_project_checked("p", "Project", [cue]).unwrap()
  let json = @game.game_project_to_json_checked(
    project,
    @game.default_game_export_options(),
  ).unwrap()
  assert_true(json.contains("\"schema_version\""))
}

///|
test "loop_region_checked" {
  let lr = @game.loop_region_checked(
    "loop",
    @game.musical_time_zero(),
    @game.musical_time(1, 0.0, 0),
    @game.NextBar,
  ).unwrap()
  assert_eq(lr.quantization.to_string(), "next-bar")
}

///|
test "game_cue_to_timeline" {
  let cue = @game.game_cue_checked("cue", "Cue", @game.LoopCue, [segment()]).unwrap()
  let timeline = @game.game_cue_to_timeline_checked(
    cue,
    @game.default_game_timeline_options(),
  ).unwrap()
  assert_eq(timeline.entries.length(), 1)
  assert_eq(timeline.total_ticks, 480)
}

///|
test "game_project_to_browser_events" {
  let cue = @game.game_cue_checked("cue", "Cue", @game.LoopCue, [segment()]).unwrap()
  let project = @game.game_project_checked("p", "Project", [cue]).unwrap()
  let doc = @game.game_project_to_browser_events_checked(
    project,
    "cue",
    @game.default_game_browser_export_options(),
  ).unwrap()
  assert_eq(doc.events.length(), 1)
  assert_eq(doc.loop_end_ticks, 480)
}
