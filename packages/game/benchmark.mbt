///|
pub fn bench_game_json_export(count : Int) -> String {
  let source = GameTimelineSource::{ entries: [], ppq: 480, total_ticks: 0 }
  let segment = GameSegment::{
    id: "seg",
    label: "Segment",
    source: TimelineSource(source),
    start: musical_time_zero(),
    duration_beats: 1.0,
    loop_region: None,
    intensity_level: 5,
    tags: [],
  }
  let cue = GameCue::{
    id: "cue",
    name: "Cue",
    kind: LoopCue,
    segments: [segment],
    default_loop: None,
    tags: [],
  }
  let project = game_project_checked("p", "Project", [cue]).unwrap()
  let options = default_game_export_options()
  let mut size = 0
  for i = 0; i < count; i = i + 1 {
    match game_project_to_json_checked(project, options) {
      Ok(json) => size = size + json.length()
      Err(_) => ()
    }
  }
  "game_json_export count=\{count} bytes=\{size}"
}
