///|
pub(all) struct BrowserEventDocument {
  events : Array[GameTimelineEntry]
  ppq : Int
  tempo_bpm : Int
  loop_enabled : Bool
  loop_start_ticks : Int
  loop_end_ticks : Int
}

///|
pub(all) struct GameTimelineOptions {
  ppq : Int
  enable_loop : Bool
  include_markers : Bool
}

///|
pub(all) struct GameBrowserExportOptions {
  ppq : Int
  enable_loop : Bool
  include_markers : Bool
}

///|
pub(all) struct GameTimelineExport {
  cue_id : String
  timeline : GameTimelineSource
  loop_enabled : Bool
  loop_start_ticks : Int
  loop_end_ticks : Int
}

///|
pub(all) struct GameAssetExport {
  asset_id : String
  asset_type : String
  uri : String
}

///|
pub(all) struct GameMusicExportDocument {
  schema_version : String
  project_id : String
  project_name : String
  timelines : Array[GameTimelineExport]
  assets : Array[GameAssetExport]
  validation : GameValidationReport
}

///|
pub fn default_game_timeline_options() -> GameTimelineOptions {
  { ppq: 480, enable_loop: false, include_markers: false }
}

///|
pub fn default_game_browser_export_options() -> GameBrowserExportOptions {
  { ppq: 480, enable_loop: false, include_markers: false }
}

///|
pub fn game_cue_to_timeline_checked(
  cue : GameCue,
  options : GameTimelineOptions,
) -> Result[GameTimelineSource, GameMusicError] {
  if options.ppq <= 0 {
    return Err(TimelineConversionFailed("ppq must be > 0"))
  }
  if cue.segments.length() == 0 {
    return Err(TimelineConversionFailed("cue has no segments"))
  }
  let entries : Array[GameTimelineEntry] = []
  let mut max_ticks = 0
  for segment in cue.segments {
    match segment.source {
      TimelineSource(timeline) => {
        let offset = musical_time_to_ticks(
          segment.start,
          options.ppq,
          @time.time_signature(4, 4),
        )
        for entry in timeline.entries {
          let scaled_tick = offset +
            scale_tick(entry.tick, timeline.ppq, options.ppq)
          let scaled_duration = scale_tick(
            entry.duration_ticks,
            timeline.ppq,
            options.ppq,
          )
          entries.push({
            tick: scaled_tick,
            channel: entry.channel,
            note: entry.note,
            velocity: entry.velocity,
            is_note_on: entry.is_note_on,
            duration_ticks: scaled_duration,
          })
          if scaled_tick + scaled_duration > max_ticks {
            max_ticks = scaled_tick + scaled_duration
          }
        }
        let scaled_total = offset +
          scale_tick(timeline.total_ticks, timeline.ppq, options.ppq)
        if scaled_total > max_ticks {
          max_ticks = scaled_total
        }
      }
      AudioAssetSource(_) | EmptySource => ()
    }
  }
  Ok({ entries, ppq: options.ppq, total_ticks: max_ticks })
}

///|
pub fn game_project_to_timelines_checked(
  project : GameMusicProject,
  options : GameTimelineOptions,
) -> Result[Array[GameTimelineExport], GameMusicError] {
  let exports : Array[GameTimelineExport] = []
  for cue in project.cues {
    let timeline = match game_cue_to_timeline_checked(cue, options) {
      Ok(result) => result
      Err(e) => return Err(e)
    }
    let (loop_enabled, loop_start_ticks, loop_end_ticks) = match
      cue.default_loop {
      Some(loop_region) =>
        (
          options.enable_loop,
          musical_time_to_ticks(
            loop_region.start,
            options.ppq,
            project.time_signature,
          ),
          musical_time_to_ticks(
            loop_region.end,
            options.ppq,
            project.time_signature,
          ),
        )
      None => (false, 0, timeline.total_ticks)
    }
    exports.push({
      cue_id: cue.id,
      timeline,
      loop_enabled,
      loop_start_ticks,
      loop_end_ticks,
    })
  }
  Ok(exports)
}

///|
pub fn game_project_to_browser_events_checked(
  project : GameMusicProject,
  cue_id : String,
  options : GameBrowserExportOptions,
) -> Result[BrowserEventDocument, GameMusicError] {
  let mut found : GameCue? = None
  for cue in project.cues {
    if cue.id == cue_id {
      found = Some(cue)
      break
    }
  }
  match found {
    None => Err(MissingCue("cue not found: " + cue_id))
    Some(cue) => {
      let timeline = match
        game_cue_to_timeline_checked(cue, {
          ppq: options.ppq,
          enable_loop: options.enable_loop,
          include_markers: options.include_markers,
        }) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      Ok({
        events: timeline.entries,
        ppq: timeline.ppq,
        tempo_bpm: project.tempo_bpm,
        loop_enabled: options.enable_loop,
        loop_start_ticks: 0,
        loop_end_ticks: timeline.total_ticks,
      })
    }
  }
}

///|
pub fn game_music_export_document_checked(
  project : GameMusicProject,
  options : GameTimelineOptions,
) -> Result[GameMusicExportDocument, GameMusicError] {
  let timelines = match game_project_to_timelines_checked(project, options) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  Ok({
    schema_version: "moonsic.game.v2",
    project_id: project.id,
    project_name: project.name,
    timelines,
    assets: [],
    validation: validate_game_project_report(project),
  })
}

///|
fn scale_tick(value : Int, from_ppq : Int, to_ppq : Int) -> Int {
  if from_ppq <= 0 || from_ppq == to_ppq {
    value
  } else {
    (value.to_double() * to_ppq.to_double() / from_ppq.to_double()).to_int()
  }
}

///|
fn musical_time_to_ticks(
  value : MusicalTime,
  ppq : Int,
  signature : @time.TimeSignature,
) -> Int {
  let bar_ticks = (signature.measure_beats() * ppq.to_double()).to_int()
  value.bar * bar_ticks + (value.beat * ppq.to_double()).to_int() + value.tick
}
