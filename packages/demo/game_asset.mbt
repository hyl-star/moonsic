// ============================================================
// Game Asset — 包装作曲结果为游戏动态音乐资产
// ============================================================

///|
/// 完整游戏音乐资产：包含 GameMusicProject、导出 JSON、browser events
pub(all) struct DemoGameAsset {
  /// 游戏音乐项目
  project : @game.GameMusicProject
  /// 游戏项目导出 JSON 字符串
  export_json : String
  /// 浏览器播放事件 JSON 字符串（基于 loop cue）
  browser_events_json : String
  /// 可恢复警告
  warnings : Array[DemoWarning]
}

///|
/// 主入口：将 score + timeline 打包为游戏音乐资产
/// 供 demo 流水线使用，接受已拆解的独立字段（避免 NormalizedCompositionRequest 移动问题）
pub fn package_score_as_game_assets_checked(
  score : @score.SimpleScore,
  timeline : @timeline.PlaybackTimeline,
  tempo_bpm : Int,
  bars : Int,
  style : CompositionStyle,
) -> Result[DemoGameAsset, DemoError] {
  if tempo_bpm <= 0 {
    return Err(InvalidRequest("tempo must be > 0, got \{tempo_bpm}"))
  }
  if bars <= 0 {
    return Err(InvalidRequest("bars must be > 0, got \{bars}"))
  }
  let beats_per_bar = score.time_signature.measure_beats().to_int()
  build_demo_game_asset(timeline, tempo_bpm, bars, beats_per_bar, style)
}

///|
/// 构建完整 Demo Game Asset（接受完整 NormalizedCompositionRequest，用于测试）
pub fn demo_game_asset_checked(
  score : @score.SimpleScore,
  timeline : @timeline.PlaybackTimeline,
  request : NormalizedCompositionRequest,
) -> Result[DemoGameAsset, DemoError] {
  let beats_per_bar = score.time_signature.measure_beats().to_int()
  build_demo_game_asset(
    timeline,
    request.tempo.bpm,
    request.bars,
    beats_per_bar,
    request.style,
  )
}

///|
/// 构建包含五类 cue（intro/loop/layer/transition/stinger）的 GameMusicProject
/// 接受完整 NormalizedCompositionRequest，用于测试
pub fn demo_game_project_checked(
  timeline : @timeline.PlaybackTimeline,
  request : NormalizedCompositionRequest,
) -> Result[@game.GameMusicProject, DemoError] {
  let default_beats = 4
  build_game_project(
    timeline,
    request.tempo.bpm,
    request.bars,
    default_beats,
    request.style,
  )
}

///|
/// 将 DemoGameAsset 序列化为 JSON 摘要
pub fn demo_game_asset_to_json_checked(
  asset : DemoGameAsset,
) -> Result[String, DemoError] {
  let project = asset.project
  let fields : Array[@json.JsonField] = [
    @json.json_field("project_id", @json.json_string(project.id)),
    @json.json_field("project_name", @json.json_string(project.name)),
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
    @json.json_field("warning_count", @json.json_int(asset.warnings.length())),
    @json.json_field(
      "has_export_json",
      @json.json_bool(asset.export_json.length() > 0),
    ),
    @json.json_field(
      "has_browser_events",
      @json.json_bool(asset.browser_events_json.length() > 0),
    ),
  ]
  Ok(@json.json_stringify(@json.json_object(fields)))
}

// ============================================================
// 内部实现
// ============================================================

///|
/// 内部：根据风格派生 mood 和默认 intensity
fn style_mood_tag(style : CompositionStyle) -> String {
  match style {
    StyleGame => "game"
    StyleAmbient => "ambient"
    StyleCinematic => "cinematic"
    StylePop => "pop"
    StyleStudy => "study"
    StyleCustom(_) => "custom"
  }
}

///|
/// 内部：根据风格派生默认强度值
fn style_default_intensity(style : CompositionStyle) -> Double {
  match style {
    StyleGame => 0.7
    StyleAmbient => 0.3
    StyleCinematic => 0.8
    StylePop => 0.5
    StyleStudy => 0.4
    StyleCustom(_) => 0.5
  }
}

///|
/// 内部：构建 DemoGameAsset（共享实现）
fn build_demo_game_asset(
  timeline : @timeline.PlaybackTimeline,
  tempo_bpm : Int,
  bars : Int,
  beats_per_bar : Int,
  style : CompositionStyle,
) -> Result[DemoGameAsset, DemoError] {
  let warnings : Array[DemoWarning] = []

  let project = match
    build_game_project(timeline, tempo_bpm, bars, beats_per_bar, style) {
    Ok(p) => p
    Err(e) => {
      warnings.push(demo_warning("game_asset", "project_failed", e.to_string()))
      return Err(e)
    }
  }

  let export_json = match
    @game.game_project_to_json_checked(
      project,
      @game.default_game_export_options(),
    ) {
    Ok(json) => json
    Err(e) => {
      let msg = "game export JSON: " + e.to_string()
      warnings.push(demo_warning("game_asset", "export_json", msg))
      return Err(SerializationFailed(msg))
    }
  }

  let browser_events_json = match
    @game.game_project_to_browser_events_checked(
      project,
      "loop",
      @game.default_game_browser_export_options(),
    ) {
    Ok(doc) => browser_doc_to_json(doc)
    Err(e) => {
      warnings.push(demo_warning("game_asset", "browser_events", e.to_string()))
      "{}"
    }
  }

  Ok({ project, export_json, browser_events_json, warnings })
}

// ============================================================
// Game Project 构建
// ============================================================

///|
/// 内部：构建包含 intro/loop/layer/transition/stinger 五类 cue 的 GameMusicProject
fn build_game_project(
  timeline : @timeline.PlaybackTimeline,
  tempo_bpm : Int,
  bars : Int,
  beats_per_bar : Int,
  style : CompositionStyle,
) -> Result[@game.GameMusicProject, DemoError] {
  let ppq = 480
  let game_source = @game.game_timeline_from_note_events(timeline.events, ppq)

  // bar_ticks: 一个小节对应的 tick 数（基于秒→tick 转换，与 timeline 一致）
  let seconds_per_beat = 60.0 / tempo_bpm.to_double()
  let seconds_per_bar = seconds_per_beat * beats_per_bar.to_double()
  let mut bar_ticks = (seconds_per_bar * ppq.to_double()).to_int()
  if bar_ticks <= 0 {
    bar_ticks = ppq
  }

  let warnings : Array[DemoWarning] = []

  // 1. Intro segment（前 1 小节）
  let intro_source = sub_timeline(game_source, 0, bar_ticks, ppq)
  let intro_segment = match
    fallback_segment("intro_seg", "Intro", intro_source) {
    Ok(s) => Some(s)
    Err(e) => {
      warnings.push(demo_warning("game_asset", "intro_segment", e.to_string()))
      None
    }
  }

  // 2. Loop segment（完整 timeline）
  let loop_segment = match
    fallback_segment("loop_seg", "Main Loop", game_source) {
    Ok(s) => Some(s)
    Err(e) => {
      warnings.push(demo_warning("game_asset", "loop_segment", e.to_string()))
      None
    }
  }

  // 3. Layer segment（完整 timeline，降低 intensity）
  let layer_segment = match
    fallback_segment_low("layer_seg", "Layer", game_source) {
    Ok(s) => Some(s)
    Err(e) => {
      warnings.push(demo_warning("game_asset", "layer_segment", e.to_string()))
      None
    }
  }

  // 4. Transition segment（前 1 小节，与 intro 同源）
  let trans_segment = match
    fallback_segment("trans_seg", "Transition", intro_source) {
    Ok(s) => Some(s)
    Err(e) => {
      warnings.push(demo_warning("game_asset", "trans_segment", e.to_string()))
      None
    }
  }

  // 5. Stinger segment（前半小节）
  let stinger_ticks = if bar_ticks > ppq { bar_ticks / 2 } else { ppq / 2 }
  let stinger_source = sub_timeline(game_source, 0, stinger_ticks, ppq)
  let stinger_segment = match
    fallback_segment("stinger_seg", "Stinger", stinger_source) {
    Ok(s) => Some(s)
    Err(e) => {
      warnings.push(
        demo_warning("game_asset", "stinger_segment", e.to_string()),
      )
      None
    }
  }

  // --- 构建 cues ---
  let cues : Array[@game.GameCue] = []

  // Intro cue (LinearCue)
  match intro_segment {
    Some(seg) =>
      match @game.game_cue_checked("intro", "Intro", @game.LinearCue, [seg]) {
        Ok(c) => {
          let tagged = { ..c, tags: [style_mood_tag(style), "intro"] }
          cues.push(tagged)
        }
        Err(e) =>
          warnings.push(demo_warning("game_asset", "intro_cue", e.to_string()))
      }
    None => ()
  }

  // Loop cue (LoopCue) + loop region
  match loop_segment {
    Some(seg) =>
      match @game.game_cue_checked("loop", "Main Loop", @game.LoopCue, [seg]) {
        Ok(c) => {
          let loop_end = @game.musical_time(bars, 0.0, 0)
          let lr = match
            @game.loop_region_checked(
              "main_loop",
              @game.musical_time_zero(),
              loop_end,
              @game.NextBar,
            ) {
            Ok(r) => Some(r)
            Err(e) => {
              warnings.push(
                demo_warning("game_asset", "loop_region", e.to_string()),
              )
              None
            }
          }
          let c_with_loop = {
            ..c,
            default_loop: lr,
            tags: [style_mood_tag(style), "loop", "main"],
          }
          cues.push(c_with_loop)
        }
        Err(e) =>
          warnings.push(demo_warning("game_asset", "loop_cue", e.to_string()))
      }
    None => ()
  }

  // Layer cue (LayeredCue)
  match layer_segment {
    Some(seg) =>
      match @game.game_cue_checked("layer", "Layer", @game.LayeredCue, [seg]) {
        Ok(c) => {
          let tagged = {
            ..c,
            tags: [style_mood_tag(style), "layer", "low_intensity"],
          }
          cues.push(tagged)
        }
        Err(e) =>
          warnings.push(demo_warning("game_asset", "layer_cue", e.to_string()))
      }
    None => ()
  }

  // Transition cue (TransitionCue)
  match trans_segment {
    Some(seg) =>
      match
        @game.game_cue_checked("trans", "Transition", @game.TransitionCue, [seg]) {
        Ok(c) => {
          let tagged = { ..c, tags: [style_mood_tag(style), "transition"] }
          cues.push(tagged)
        }
        Err(e) =>
          warnings.push(demo_warning("game_asset", "trans_cue", e.to_string()))
      }
    None => ()
  }

  // Stinger cue (StingerCue)
  match stinger_segment {
    Some(seg) =>
      match
        @game.game_cue_checked("stinger", "Stinger", @game.StingerCue, [seg]) {
        Ok(c) => {
          let tagged = { ..c, tags: [style_mood_tag(style), "stinger"] }
          cues.push(tagged)
        }
        Err(e) =>
          warnings.push(
            demo_warning("game_asset", "stinger_cue", e.to_string()),
          )
      }
    None => ()
  }

  // --- 状态 ---
  let states = [
    @game.MusicState::{ id: "default", name: "Default", default_cue: "loop" },
  ]

  // --- 参数 ---
  let intensity_param = @game.MusicParameter::{
    id: "intensity",
    name: "Intensity",
    min_value: 0.0,
    max_value: 1.0,
    default_value: style_default_intensity(style),
  }

  // --- 过渡规则 ---
  let transitions : Array[@game.TransitionRule] = []
  let has_intro = cue_exists(cues, "intro")
  let has_trans = cue_exists(cues, "trans")
  let has_loop = cue_exists(cues, "loop")

  // intro → loop
  if has_intro && has_loop {
    match
      @game.transition_rule_checked(
        "intro_to_loop",
        "intro",
        "loop",
        @game.TriggerOnState("default"),
        @game.NextBar,
        @game.Crossfade(0.5),
      ) {
      Ok(r) => transitions.push(r)
      Err(e) =>
        warnings.push(
          demo_warning("game_asset", "trule_intro_to_loop", e.to_string()),
        )
    }
  }

  // transition → loop / layer
  if has_trans && has_loop {
    match
      @game.transition_rule_checked(
        "trans_to_loop",
        "trans",
        "loop",
        @game.TriggerOnParameter("intensity", @game.GreaterThan, 0.5),
        @game.NextBeat,
        @game.Crossfade(0.3),
      ) {
      Ok(r) => transitions.push(r)
      Err(e) =>
        warnings.push(
          demo_warning("game_asset", "trule_trans_to_loop", e.to_string()),
        )
    }

    match
      @game.transition_rule_checked(
        "trans_to_layer",
        "trans",
        "layer",
        @game.TriggerOnParameter("intensity", @game.LessOrEqual, 0.5),
        @game.NextBeat,
        @game.Crossfade(0.3),
      ) {
      Ok(r) => transitions.push(r)
      Err(e) =>
        warnings.push(
          demo_warning("game_asset", "trule_trans_to_layer", e.to_string()),
        )
    }
  }

  // stinger → loop（短促反馈后回到主循环）
  if cue_exists(cues, "stinger") && has_loop {
    match
      @game.transition_rule_checked(
        "stinger_to_loop",
        "stinger",
        "loop",
        @game.TriggerImmediate,
        @game.Immediate,
        @game.Cut,
      ) {
      Ok(r) => transitions.push(r)
      Err(e) =>
        warnings.push(
          demo_warning("game_asset", "trule_stinger_to_loop", e.to_string()),
        )
    }
  }

  // --- 元数据 ---
  let metadata = @game.GameMusicMetadata::{
    composer: "moonsic demo",
    description: "Game music asset — " + style.to_string(),
    tags: [style_mood_tag(style), "demo", "generated"],
  }

  // --- 构建 project ---
  match
    @game.game_project_full_checked(
      "demo_game",
      "Moonsic Game Asset",
      cues,
      states,
      [intensity_param],
      transitions,
    ) {
    Ok(p) => Ok({ ..p, metadata, })
    Err(e) => Err(SerializationFailed("game project: " + e.to_string()))
  }
}

// ============================================================
// 内部 helper
// ============================================================

///|
/// 从 GameTimelineSource 中截取子时间轴（按 tick 范围过滤）
fn sub_timeline(
  source : @game.GameTimelineSource,
  start_tick : Int,
  end_tick : Int,
  ppq : Int,
) -> @game.GameTimelineSource {
  let entries : Array[@game.GameTimelineEntry] = []
  for entry in source.entries {
    if entry.tick >= start_tick && entry.tick < end_tick {
      entries.push(entry)
    }
  }
  { entries, ppq, total_ticks: end_tick - start_tick }
}

///|
/// 创建 segment（默认 intensity=5）
fn fallback_segment(
  id : String,
  label : String,
  source : @game.GameTimelineSource,
) -> Result[@game.GameSegment, DemoError] {
  match @game.game_segment_from_timeline_checked(id, label, source) {
    Ok(seg) => Ok({ ..seg, intensity_level: 5 })
    Err(e) => Err(SerializationFailed("game segment: " + e.to_string()))
  }
}

///|
/// 创建低 intensity segment（intensity=3）
fn fallback_segment_low(
  id : String,
  label : String,
  source : @game.GameTimelineSource,
) -> Result[@game.GameSegment, DemoError] {
  match @game.game_segment_from_timeline_checked(id, label, source) {
    Ok(seg) => Ok({ ..seg, intensity_level: 3 })
    Err(e) => Err(SerializationFailed("game segment: " + e.to_string()))
  }
}

///|
/// 检查 cues 数组中是否存在指定 id
fn cue_exists(cues : Array[@game.GameCue], id : String) -> Bool {
  for cue in cues {
    if cue.id == id {
      return true
    }
  }
  false
}

///|
/// 将 BrowserEventDocument 序列化为 JSON
fn browser_doc_to_json(doc : @game.BrowserEventDocument) -> String {
  let items : Array[@json.JsonValue] = []
  for event in doc.events {
    items.push(
      @json.json_object([
        @json.json_field("tick", @json.json_int(event.tick)),
        @json.json_field("channel", @json.json_int(event.channel)),
        @json.json_field("note", @json.json_int(event.note)),
        @json.json_field("velocity", @json.json_int(event.velocity)),
        @json.json_field("is_note_on", @json.json_bool(event.is_note_on)),
        @json.json_field("duration_ticks", @json.json_int(event.duration_ticks)),
      ]),
    )
  }
  let fields : Array[@json.JsonField] = [
    @json.json_field("ppq", @json.json_int(doc.ppq)),
    @json.json_field("tempo_bpm", @json.json_int(doc.tempo_bpm)),
    @json.json_field("loop_enabled", @json.json_bool(doc.loop_enabled)),
    @json.json_field("loop_start_ticks", @json.json_int(doc.loop_start_ticks)),
    @json.json_field("loop_end_ticks", @json.json_int(doc.loop_end_ticks)),
    @json.json_field("events", @json.json_array(items)),
  ]
  @json.json_stringify(@json.json_object(fields))
}
