// ============================================================
// Score Assembly — 生成 + 组装 + 校验
// ============================================================

///|
/// score 组装结果
pub(all) struct DemoScoreAssembly {
  score : @score.SimpleScore
  score_json : String
  validation_json : String
  warnings : Array[DemoWarning]
}

///|
/// 校验汇总
pub(all) struct DemoValidationSummary {
  error_count : Int
  warning_count : Int
  info_count : Int
  json : String
}

///|
/// 根据标准化请求生成并组装 score
/// bars 参数控制旋律节奏长度和和弦级数数量
pub fn assemble_demo_score_checked(
  request : NormalizedCompositionRequest,
) -> Result[DemoScoreAssembly, DemoError] {
  let warnings : Array[DemoWarning] = []
  let time_sig = @time.four_four()
  let tracks : Array[@score.SimpleTrack] = []

  // --- 生成旋律（bars 控制节奏长度）---
  let rhythm = match demo_rhythm_for_bars_checked(request.bars) {
    Ok(r) => r
    Err(e) => return Err(e)
  }
  let melody_config = melody_generation_config(request.style, request.seed)
  let melody_track = match
    @generate.generate_melody_checked(request.key_obj, rhythm, melody_config) {
    Ok(t) => {
      let ch = match @score.midi_channel_checked(0) {
        Ok(c) => Some(c)
        Err(_) => (None : @score.MidiChannel?)
      }
      let prog = match @score.midi_program_checked(0) {
        Ok(p) => Some(p)
        Err(_) => (None : @score.MidiProgram?)
      }
      match @score.simple_track_checked(t.events, ch, prog) {
        Ok(train) => Some(train)
        Err(e) => {
          warnings.push(demo_warning("assembly", "melody_track", e.to_string()))
          None
        }
      }
    }
    Err(e) => {
      warnings.push(
        demo_warning_fatal("generation", "melody_failed", e.to_string()),
      )
      None
    }
  }

  match melody_track {
    Some(t) => tracks.push(t)
    None => return Err(GenerationFailed("failed to generate melody track"))
  }

  // --- 生成和弦进行（bars 控制 chord degree 数量）---
  if request.chord_degrees.length() > 0 {
    let fitted_degrees = fit_chord_degrees_to_bars(
      request.chord_degrees,
      request.bars,
    )
    let chord_config = chord_generation_config(request.style, request.seed)
    // Each chord = one whole note → covers one bar in 4/4
    let chord_dur = @time.rhythm_duration(@time.DurWhole, 0, None)
    match
      @generate.generate_chord_progression_checked(
        request.key_obj,
        fitted_degrees,
        chord_dur,
        chord_config,
      ) {
      Ok(t) => {
        let ch = match @score.midi_channel_checked(1) {
          Ok(c) => Some(c)
          Err(_) => (None : @score.MidiChannel?)
        }
        let prog = match @score.midi_program_checked(0) {
          Ok(p) => Some(p)
          Err(_) => (None : @score.MidiProgram?)
        }
        match @score.simple_track_checked(t.events, ch, prog) {
          Ok(train) => tracks.push(train)
          Err(e) =>
            warnings.push(
              demo_warning("assembly", "chord_track", e.to_string()),
            )
        }
      }
      Err(e) =>
        warnings.push(demo_warning("generation", "chord_failed", e.to_string()))
    }
  }

  // --- 构建 score ---
  let score = match
    @score.simple_score_checked(tracks, request.tempo, time_sig) {
    Ok(s) => s
    Err(e) => return Err(GenerationFailed("score assembly: " + e.to_string()))
  }

  // --- Score JSON ---
  let score_json = match demo_score_to_json_checked(score) {
    Ok(json) => json
    Err(e) => {
      warnings.push(demo_warning("assembly", "score_json", e.to_string()))
      "{}"
    }
  }

  // --- Validation ---
  let validation_summary = validate_demo_score(score)
  let validation_json = validation_summary.json

  Ok({ score, score_json, validation_json, warnings })
}

///|
/// 输出 Score JSON
pub fn demo_score_to_json_checked(
  score : @score.SimpleScore,
) -> Result[String, DemoError] {
  match @adapter.simple_score_to_json_checked(score) {
    Ok(json) => Ok(json)
    Err(e) => Err(SerializationFailed("score to JSON: " + e.to_string()))
  }
}

///|
/// 生成轻量 validation summary
pub fn validate_demo_score(score : @score.SimpleScore) -> DemoValidationSummary {
  let report = @validation.empty_validation_report()
  let report = if score.tracks.length() == 0 {
    @validation.report_add_issue(report, {
      severity: @validation.Warning,
      code: @validation.EmptyScore,
      path: "score",
      message: "score has no tracks",
    })
  } else {
    report
  }
  for i = 0; i < score.tracks.length(); i = i + 1 {
    let track = score.tracks[i]
    if track.events.length() == 0 {
      let _ = @validation.report_add_issue(report, {
        severity: @validation.Warning,
        code: @validation.EmptyVoice,
        path: "score.tracks[\{i}]",
        message: "track has no events",
      })
    }
  }
  let json = @validation.validation_report_to_json(report)
  {
    error_count: report.error_count,
    warning_count: report.warning_count,
    info_count: report.info_count,
    json,
  }
}

// ============================================================
// 内部 helper — 风格配置
// ============================================================

///|
fn melody_generation_config(
  style : CompositionStyle,
  seed : Int,
) -> @generate.GenerationConfig {
  match style {
    StylePop =>
      {
        mode: @generate.MelodyOnly,
        contour: @generate.StepwiseUp,
        range_low: @pitch.c(4),
        range_high: @pitch.c(6),
        seed: Some(seed),
        voice_leading: @generate.KeepInRange,
        allow_rests: false,
        max_leap: 12,
      }
    StyleAmbient =>
      {
        mode: @generate.MelodyOnly,
        contour: @generate.Static,
        range_low: @pitch.c(3),
        range_high: @pitch.c(5),
        seed: Some(seed),
        voice_leading: @generate.KeepInRange,
        allow_rests: true,
        max_leap: 7,
      }
    StyleGame =>
      {
        mode: @generate.MelodyOnly,
        contour: @generate.Arch,
        range_low: @pitch.c(4),
        range_high: @pitch.c(5),
        seed: Some(seed),
        voice_leading: @generate.KeepInRange,
        allow_rests: false,
        max_leap: 5,
      }
    StyleCinematic =>
      {
        mode: @generate.MelodyOnly,
        contour: @generate.InvertedArch,
        range_low: @pitch.c(3),
        range_high: @pitch.c(7),
        seed: Some(seed),
        voice_leading: @generate.Smooth,
        allow_rests: false,
        max_leap: 12,
      }
    StyleStudy =>
      {
        mode: @generate.MelodyOnly,
        contour: @generate.Wave,
        range_low: @pitch.c(4),
        range_high: @pitch.c(5),
        seed: Some(seed),
        voice_leading: @generate.KeepInRange,
        allow_rests: false,
        max_leap: 2,
      }
    StyleCustom(_) => @generate.default_generation_config()
  }
}

///|
fn chord_generation_config(
  _style : CompositionStyle,
  seed : Int,
) -> @generate.GenerationConfig {
  {
    mode: @generate.ChordsOnly,
    contour: @generate.Static,
    range_low: @pitch.c(3),
    range_high: @pitch.c(5),
    seed: Some(seed),
    voice_leading: @generate.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
}

// ============================================================
// 内部 helper — bars 感知
// ============================================================

///|
/// 根据 bars 参数生成重复后的节奏模板
/// 以 FourQuarters（4 个四分音符 = 1 个小节）为基础
/// bars=1 → 4 cells, bars=4 → 16 cells, bars=8 → 32 cells
fn demo_rhythm_for_bars_checked(
  bars : Int,
) -> Result[@rhythm.RhythmPattern, DemoError] {
  if bars <= 0 {
    return Err(InvalidRequest("bars must be > 0 for rhythm, got \{bars}"))
  }
  let template = @rhythm.rhythm_template(@rhythm.FourQuarters)
  let phrase = match @rhythm.repeat_pattern_checked(template, bars) {
    Ok(p) => p
    Err(e) => return Err(GenerationFailed("rhythm repeat: " + e.to_string()))
  }
  Ok(@rhythm.rhythm_pattern(phrase.cells))
}

///|
/// 根据 bars 数量调整和弦级数数组（循环填充）
/// 每 bar 一个 chord：不足则循环重复，多出则截断
/// [I, V, vi, IV] + bars=8 → [1,5,6,4, 1,5,6,4]
/// [I, V] + bars=3 → [1,5,1]
fn fit_chord_degrees_to_bars(degrees : Array[Int], bars : Int) -> Array[Int] {
  if degrees.length() == 0 {
    return degrees
  }
  if bars <= 0 {
    return degrees
  }
  let result : Array[Int] = []
  let mut i = 0
  while i < bars {
    result.push(degrees[i % degrees.length()])
    i = i + 1
  }
  result
}
