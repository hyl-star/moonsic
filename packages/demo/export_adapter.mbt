// ============================================================
// Export Adapter — 统一封装现有导出能力
// ============================================================

///|
/// 导出资产结果集合
pub(all) struct ExportAssetResult {
  midi_bytes : Bytes?
  musicxml : String?
  timeline : @timeline.PlaybackTimeline?
  wav_bytes : Bytes?
  web_events_json : String?
  warnings : Array[DemoWarning]
}

///|
/// 导出 MIDI bytes
pub fn export_midi_asset_checked(
  score : @score.SimpleScore,
  ppq : Int,
) -> Result[Bytes, DemoError] {
  if ppq <= 0 {
    return Err(InvalidRequest("PPQ must be > 0"))
  }
  match @midi.simple_score_to_midi_bytes_checked(score, ppq) {
    Ok(bytes) => Ok(bytes)
    Err(e) => Err(SerializationFailed("MIDI export: " + e.to_string()))
  }
}

///|
/// 导出 MusicXML 字符串
pub fn export_musicxml_asset_checked(
  score : @score.SimpleScore,
) -> Result[String, DemoError] {
  let options = @musicxml.default_musicxml_export_options()
  match @musicxml.simple_score_to_musicxml_string_checked(score, options) {
    Ok(xml) => Ok(xml)
    Err(e) => Err(SerializationFailed("MusicXML export: " + e.to_string()))
  }
}

///|
/// Score -> PlaybackTimeline
pub fn export_timeline_asset_checked(
  score : @score.SimpleScore,
) -> Result[@timeline.PlaybackTimeline, DemoError] {
  match @timeline.timeline_from_simple_score_checked(score) {
    Ok(tl) => Ok(tl)
    Err(e) => Err(SerializationFailed("timeline: " + e.to_string()))
  }
}

///|
/// PlaybackTimeline -> WAV bytes
pub fn export_wav_asset_checked(
  timeline : @timeline.PlaybackTimeline,
) -> Result[Bytes, DemoError] {
  let config = @wav.default_wav_render_config()
  match @wav.playback_timeline_to_wav_bytes_checked(timeline, config) {
    Ok(bytes) => Ok(bytes)
    Err(e) => Err(SerializationFailed("WAV export: " + e.to_string()))
  }
}

///|
/// PlaybackTimeline -> Web events JSON
pub fn export_web_events_asset_checked(
  timeline : @timeline.PlaybackTimeline,
) -> Result[String, DemoError] {
  if timeline.events.length() == 0 {
    return Err(SerializationFailed("web events: no events in timeline"))
  }
  let config = @web.default_web_playback_config()
  let doc = match @web.timeline_to_web_events_checked(timeline, config) {
    Ok(d) => d
    Err(e) => return Err(SerializationFailed("web events: " + e.to_string()))
  }
  Ok(@web.web_event_document_to_json(doc))
}

///|
/// Score + Timeline -> Game Music Project JSON
pub fn export_game_ir_asset_checked(
  score : @score.SimpleScore,
  timeline : @timeline.PlaybackTimeline,
) -> Result[String, DemoError] {
  let game_timeline = @game.game_timeline_from_note_events(timeline.events, 480)
  let segment = match
    @game.game_segment_from_timeline_checked(
      "main_segment", "Main Demo Segment", game_timeline,
    ) {
    Ok(s) => s
    Err(e) => return Err(SerializationFailed("game segment: " + e.to_string()))
  }
  let loop_region = match
    @game.loop_region_checked(
      "main_loop",
      @game.musical_time_zero(),
      @game.musical_time(
        score.time_signature.numerator * score.time_signature.denominator / 4,
        0.0,
        0,
      ),
      @game.NextBar,
    ) {
    Ok(r) => Some(r)
    Err(_) => (None : @game.LoopRegion?)
  }
  let cue = match
    @game.game_cue_checked("demo_cue", "Demo Cue", @game.LoopCue, [segment]) {
    Ok(c) => c
    Err(e) => return Err(SerializationFailed("game cue: " + e.to_string()))
  }
  let cue_with_loop = { ..cue, default_loop: loop_region }
  let project = match
    @game.game_project_checked("demo_project", "Moonsic Demo", [cue_with_loop]) {
    Ok(p) => p
    Err(e) => return Err(SerializationFailed("game project: " + e.to_string()))
  }
  let options = @game.default_game_export_options()
  match @game.game_project_to_json_checked(project, options) {
    Ok(json) => Ok(json)
    Err(e) => Err(SerializationFailed("game IR: " + e.to_string()))
  }
}

///|
/// 对所有资产类型执行导出，收集 warnings
pub fn export_all_score_assets(score : @score.SimpleScore) -> ExportAssetResult {
  let ppq = 480
  let warnings : Array[DemoWarning] = []

  // MIDI
  let midi_bytes = match export_midi_asset_checked(score, ppq) {
    Ok(bytes) => Some(bytes)
    Err(e) => {
      warnings.push(demo_warning("export", "midi_failed", e.to_string()))
      None
    }
  }

  // MusicXML
  let musicxml = match export_musicxml_asset_checked(score) {
    Ok(xml) => Some(xml)
    Err(e) => {
      warnings.push(demo_warning("export", "musicxml_failed", e.to_string()))
      None
    }
  }

  // Timeline
  let timeline = match export_timeline_asset_checked(score) {
    Ok(tl) => Some(tl)
    Err(e) => {
      warnings.push(demo_warning("export", "timeline_failed", e.to_string()))
      None
    }
  }

  // WAV & Web events (需要 timeline)
  let wav_bytes = match timeline {
    Some(tl) =>
      match export_wav_asset_checked(tl) {
        Ok(bytes) => Some(bytes)
        Err(e) => {
          warnings.push(demo_warning("export", "wav_failed", e.to_string()))
          None
        }
      }
    None => {
      warnings.push(
        demo_warning(
          "export", "wav_skipped", "WAV skipped: timeline unavailable",
        ),
      )
      None
    }
  }

  let web_events_json = match timeline {
    Some(tl) =>
      match export_web_events_asset_checked(tl) {
        Ok(json) => Some(json)
        Err(e) => {
          warnings.push(demo_warning("export", "web_failed", e.to_string()))
          None
        }
      }
    None => {
      warnings.push(
        demo_warning(
          "export", "web_skipped", "Web events skipped: timeline unavailable",
        ),
      )
      None
    }
  }

  { midi_bytes, musicxml, timeline, wav_bytes, web_events_json, warnings }
}

///|
/// 导出 game IR（可选，失败不影响其他资产）
pub fn export_game_asset(
  score : @score.SimpleScore,
  timeline : @timeline.PlaybackTimeline,
) -> Result[String, DemoError] {
  export_game_ir_asset_checked(score, timeline)
}
