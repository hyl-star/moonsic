// ============================================================
// Generate module -- deterministic rule-based music generation
// ============================================================

// --- GenerateError ---

///|
/// Generate error type.
pub(all) enum GenerateError {
  InvalidGenerationConfig(String)
  EmptyRhythmPattern(String)
  EmptyProgression(String)
  UnsupportedGenerateMode(String)
  InvalidDegree(String)
  RangeTooSmall(String)
  GenerationFailed(String)
}

///|
/// Human-readable error messages (Chinese).
pub fn GenerateError::to_string(self : GenerateError) -> String {
  match self {
    InvalidGenerationConfig(msg) => "生成配置无效：\{msg}"
    EmptyRhythmPattern(msg) => "节奏模板为空：\{msg}"
    EmptyProgression(msg) => "和弦进行为空：\{msg}"
    UnsupportedGenerateMode(msg) => "不支持的生成模式：\{msg}"
    InvalidDegree(msg) => "无效音级：\{msg}"
    RangeTooSmall(msg) => "音域过小：\{msg}"
    GenerationFailed(msg) => "生成失败：\{msg}"
  }
}

// --- GenerateMode ---

///|
/// Generation mode: selects which pipeline to run.
pub(all) enum GenerateMode {
  MelodyOnly
  ChordsOnly
  BassOnly
  Accompaniment
  GameLoop
}

// --- MelodyContour ---

///|
/// Melody contour: controls the direction of melodic motion.
pub(all) enum MelodyContour {
  StepwiseUp
  StepwiseDown
  Arch
  InvertedArch
  Wave
  Static
  ChordTone
}

// --- AccompanimentPattern ---

///|
/// Accompaniment pattern: chord, arpeggio, bass variations.
pub(all) enum AccompanimentPattern {
  BlockChord
  ArpeggioUp
  ArpeggioDown
  ArpeggioUpDown
  Alberti
  Pad
  RootBass
  RootFifthBass
  WalkingBass
}

// --- VoiceLeadingStrategy ---

///|
/// Voice leading strategy.
pub(all) enum VoiceLeadingStrategy {
  None
  Nearest
  KeepInRange
  Smooth
  ChordToneAnchor
}

// --- GenerationConfig ---

///|
/// Generation configuration.
pub(all) struct GenerationConfig {
  mode : GenerateMode
  contour : MelodyContour
  range_low : Pitch
  range_high : Pitch
  seed : Int?
  voice_leading : VoiceLeadingStrategy
  allow_rests : Bool
  max_leap : Int
}

// --- GenerationContext ---

///|
/// Generation context: key, scale, progression, meter, tempo, bar count.
pub(all) struct GenerationContext {
  key : Key
  scale : Scale
  progression : Array[Int]
  time_signature : TimeSignature
  tempo : Tempo
  bars : Int
}

// --- GeneratedPhrase ---

///|
/// Generated phrase: a track with metadata.
pub(all) struct GeneratedPhrase {
  track : Track
  start_degree : Int
  end_degree : Int
  total_beats : Double
}

// --- GenerationResult ---

///|
/// FFI unified result type.
pub(all) struct GenerationResult {
  ok : Bool
  data : String
  error : String
  message : String
}

// ==================== internal rule tables ====================

///|
/// MelodyContour -> degree step sequence lookup.
fn contour_degrees(contour : MelodyContour) -> Array[Int] {
  match contour {
    StepwiseUp => [1, 2, 3, 4, 5, 6, 7, 8]
    StepwiseDown => [8, 7, 6, 5, 4, 3, 2, 1]
    Arch => [1, 2, 3, 5, 6, 5, 3, 2]
    InvertedArch => [5, 4, 3, 2, 1, 2, 3, 5]
    Wave => [1, 3, 2, 4, 3, 5, 4, 6]
    Static => [1, 1, 1, 1]
    ChordTone => [1, 3, 5, 3, 1]
  }
}

///|
/// Default generation config.
fn default_config() -> GenerationConfig {
  {
    mode: MelodyOnly,
    contour: StepwiseUp,
    range_low: c(4),
    range_high: c(6),
    seed: None,
    voice_leading: KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
}

// ==================== internal helpers ====================

///|
/// Convert an Int degree to a RomanNumeral, or None if out of range.
fn degree_to_roman(deg : Int) -> RomanNumeral? {
  match deg {
    1 => Some(I)
    2 => Some(II)
    3 => Some(III)
    4 => Some(IV)
    5 => Some(V)
    6 => Some(VI)
    7 => Some(VII)
    _ => None
  }
}

///|
/// Clamp a pitch into [low, high] by octave shifting.
fn clamp_to_range(p : Pitch, low : Pitch, high : Pitch) -> Pitch {
  let p_midi = p.to_midi()
  let low_midi = low.to_midi()
  let high_midi = high.to_midi()
  if p_midi < low_midi {
    let mut result = p
    let mut count = 0
    while result.to_midi() < low_midi && count < 12 {
      result = result.transpose(12)
      count = count + 1
    }
    if result.to_midi() > high_midi {
      low
    } else {
      result
    }
  } else if p_midi > high_midi {
    let mut result = p
    let mut count = 0
    while result.to_midi() > high_midi && count < 12 {
      result = result.transpose(-12)
      count = count + 1
    }
    if result.to_midi() < low_midi {
      high
    } else {
      result
    }
  } else {
    p
  }
}

///|
/// Choose the octave of p closest to prev_midi, clamped within [low, high].
fn nearest_octave(
  p : Pitch,
  prev_midi : Int,
  low : Pitch,
  high : Pitch,
) -> Pitch {
  let base_midi = p.to_midi()
  let mut best = base_midi
  let diff = base_midi - prev_midi
  let mut best_dist = if diff < 0 { -diff } else { diff }
  let mut octave_shift = -24
  while octave_shift <= 24 {
    let candidate = base_midi + octave_shift
    if candidate >= low.to_midi() && candidate <= high.to_midi() {
      let cdiff = candidate - prev_midi
      let cdist = if cdiff < 0 { -cdiff } else { cdiff }
      if cdist < best_dist {
        best_dist = cdist
        best = candidate
      }
    }
    octave_shift = octave_shift + 12
  }
  midi_to_pitch(best)
}

///|
/// Wrap rhythm_template from rhythm.mbt (RhythmTemplateKind -> RhythmPattern).
fn make_rhythm(kind : RhythmTemplateKind) -> RhythmPattern {
  rhythm_template(kind)
}

///|
/// Repeat an array of RhythmCell count times (concatenation).
fn repeat_cells(cells : Array[RhythmCell], count : Int) -> Array[RhythmCell] {
  let result : Array[RhythmCell] = []
  for _i = 0; _i < count; _i = _i + 1 {
    for c in cells {
      result.push(c)
    }
  }
  result
}

// ==================== checked API ====================

///|
/// Generate a melody track from a key, a RhythmPattern, and a GenerationConfig.
/// Returns Ok(Track) on success, or Err(GenerateError) on invalid input.
pub fn generate_melody_checked(
  key : Key,
  rhythm : RhythmPattern,
  config : GenerationConfig,
) -> Result[Track, GenerateError] {
  if rhythm.cells.length() == 0 {
    return Err(EmptyRhythmPattern("rhythm cells must not be empty"))
  }
  if config.range_low.to_midi() >= config.range_high.to_midi() {
    return Err(RangeTooSmall("range_low must be strictly below range_high"))
  }

  let degrees = contour_degrees(config.contour)
  let n_degrees = degrees.length()
  let events : Array[MusicEvent] = []
  let mut prev_midi = -1
  let base_octave = config.range_low.octave

  for i = 0; i < rhythm.cells.length(); i = i + 1 {
    let cell = rhythm.cells[i]
    let dur = cell.duration
    let deg = degrees[i % n_degrees]
    let is_cell_rest = cell.is_rest && config.allow_rests

    if is_cell_rest {
      events.push(Rest(rest(dur)))
    } else {
      let p = key.degree(deg, base_octave)
      let final_p = match config.voice_leading {
        Nearest =>
          if prev_midi >= 0 {
            nearest_octave(p, prev_midi, config.range_low, config.range_high)
          } else {
            clamp_to_range(p, config.range_low, config.range_high)
          }
        KeepInRange | Smooth | ChordToneAnchor =>
          clamp_to_range(p, config.range_low, config.range_high)
        None => p
      }
      events.push(Note(note(final_p, dur)))
      prev_midi = final_p.to_midi()
    }
  }
  Ok(track(events))
}

///|
/// Generate a phrase (melody/chords/bass) from a GenerationContext + config.
pub fn generate_phrase_checked(
  context : GenerationContext,
  config : GenerationConfig,
) -> Result[GeneratedPhrase, GenerateError] {
  let phrase_track = match config.mode {
    MelodyOnly => {
      let rhythm = make_rhythm(FourQuarters)
      match generate_melody_checked(context.key, rhythm, config) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
    }
    ChordsOnly => {
      if context.progression.length() == 0 {
        return Err(EmptyProgression("context.progression must not be empty"))
      }
      match
        generate_chord_progression_checked(
          context.key,
          context.progression,
          Quarter,
          config,
        ) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
    }
    _ => {
      let rhythm = make_rhythm(FourQuarters)
      match generate_melody_checked(context.key, rhythm, config) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
    }
  }
  let degs = contour_degrees(config.contour)
  Ok({
    track: phrase_track,
    start_degree: degs[0],
    end_degree: degs[degs.length() - 1],
    total_beats: phrase_track.duration_beats(),
  })
}

///|
/// Generate a chord progression from a key + scale degrees.
pub fn generate_chord_progression_checked(
  key : Key,
  degrees : Array[Int],
  dur : Duration,
  _config : GenerationConfig,
) -> Result[Track, GenerateError] {
  if degrees.length() == 0 {
    return Err(EmptyProgression("degrees must not be empty"))
  }
  for i = 0; i < degrees.length(); i = i + 1 {
    if degrees[i] < 1 || degrees[i] > 7 {
      return Err(InvalidDegree("degree must be 1-7, got \{degrees[i]}"))
    }
  }
  let events : Array[MusicEvent] = []
  let kind = key.scale_kind()
  for i = 0; i < degrees.length(); i = i + 1 {
    let deg = degrees[i]
    let root_pitch = key.degree(deg, 4)
    let rn = match degree_to_roman(deg) {
      Some(r) => r
      None => return Err(InvalidDegree("degree must be 1-7, got \{deg}"))
    }
    let event = if is_dim_in_key(kind, rn) {
      dim(root_pitch, dur)
    } else if is_major_in_key(kind, rn) {
      major(root_pitch, dur)
    } else {
      minor(root_pitch, dur)
    }
    events.push(event)
  }
  Ok(track(events))
}

///|
/// Generate a bass track from a chord progression.
pub fn generate_bass_checked(
  progression : Track,
  pattern : AccompanimentPattern,
  config : GenerationConfig,
) -> Result[Track, GenerateError] {
  let style = match pattern {
    RootBass => Root
    RootFifthBass => RootFifth
    WalkingBass => Walking
    _ =>
      return Err(
        GenerationFailed(
          "bass pattern required (RootBass/RootFifthBass/WalkingBass)",
        ),
      )
  }
  Ok(bass_from_progression(progression, style, config.range_low.octave))
}

///|
/// Generate an accompaniment score from a chord progression.
pub fn generate_accompaniment_checked(
  progression : Track,
  pattern : AccompanimentPattern,
  config : GenerationConfig,
) -> Result[Score, GenerateError] {
  let tracks = match pattern {
    BlockChord => [voice_lead(progression)]
    ArpeggioUp => [arpeggiate_with_style(progression, eighth(), Up)]
    ArpeggioDown => [arpeggiate_with_style(progression, eighth(), Down)]
    ArpeggioUpDown => [arpeggiate_with_style(progression, eighth(), UpDown)]
    Alberti => [arpeggiate_with_style(progression, eighth(), Alberti)]
    Pad => [voice_lead(progression)]
    RootBass =>
      [bass_from_progression(progression, Root, config.range_low.octave)]
    RootFifthBass =>
      [bass_from_progression(progression, RootFifth, config.range_low.octave)]
    WalkingBass =>
      [bass_from_progression(progression, Walking, config.range_low.octave)]
  }
  Ok(score_with_tempo(tracks, default_tempo(), four_four()))
}

///|
/// Generate a game-loop score (melody + chords) for the given bar count.
pub fn generate_game_loop_checked(
  context : GenerationContext,
  bars : Int,
  config : GenerationConfig,
) -> Result[Score, GenerateError] {
  if bars <= 0 {
    return Err(InvalidGenerationConfig("bars must be > 0, got \{bars}"))
  }

  let base_rhythm = make_rhythm(FourQuarters)
  let melody_cells = repeat_cells(base_rhythm.cells, bars)
  let melody_rhythm = match rhythm_pattern_checked(melody_cells) {
    Ok(p) => p
    Err(_) => return Err(EmptyRhythmPattern("failed to build melody rhythm"))
  }
  let melody_track = match
    generate_melody_checked(context.key, melody_rhythm, config) {
    Ok(t) => t
    Err(e) => return Err(e)
  }

  let chord_events : Array[MusicEvent] = []
  if context.progression.length() > 0 {
    for _b = 0; _b < bars; _b = _b + 1 {
      for i = 0; i < context.progression.length(); i = i + 1 {
        let deg = context.progression[i]
        if deg >= 1 && deg <= 7 {
          let root_pitch = context.key.degree(deg, 4)
          let rn = match degree_to_roman(deg) {
            Some(r) => r
            None => continue
          }
          let kind = context.key.scale_kind()
          let event = if is_dim_in_key(kind, rn) {
            dim(root_pitch, Quarter)
          } else if is_major_in_key(kind, rn) {
            major(root_pitch, Quarter)
          } else {
            minor(root_pitch, Quarter)
          }
          chord_events.push(event)
        }
      }
    }
  }
  let chord_track = track(chord_events)
  Ok(
    score_with_tempo(
      [melody_track, chord_track],
      context.tempo,
      context.time_signature,
    ),
  )
}

// ==================== convenience API ====================

///|
/// Generate a melody with default config. Falls back to empty track on error.
pub fn generate_melody(key : Key, rhythm : RhythmPattern) -> Track {
  match generate_melody_checked(key, rhythm, default_config()) {
    Ok(t) => t
    Err(_) => empty_track()
  }
}

///|
/// Generate a chord progression with default config. Falls back to empty track on error.
pub fn generate_chord_progression(
  key : Key,
  degrees : Array[Int],
  dur : Duration,
) -> Track {
  match
    generate_chord_progression_checked(key, degrees, dur, default_config()) {
    Ok(t) => t
    Err(_) => empty_track()
  }
}

///|
/// Generate a game loop with default config. Falls back to empty score on error.
pub fn generate_game_loop(context : GenerationContext, bars : Int) -> Score {
  match generate_game_loop_checked(context, bars, default_config()) {
    Ok(s) => s
    Err(_) => score([])
  }
}

// ==================== FFI API ====================

///|
/// FFI: parse JSON, call generate_melody_checked, return JSON result.
pub fn ffi_generate_melody_json(input : String) -> String {
  let fields = match json_parse(input) {
    Ok(v) =>
      match jv_get_fields(v) {
        Ok(f) => f
        Err(e) => return ffi_error("GenerateError", e)
      }
    Err(e) => return ffi_error("GenerateError", e)
  }
  let scale_str = match jv_lookup(fields, "scale") {
    Ok(v) =>
      match jv_as_string(v) {
        Ok(s) => s
        Err(e) => return ffi_error("GenerateError", e)
      }
    Err(e) => return ffi_error("GenerateError", e)
  }
  let rhythm_kind_str = match jv_lookup(fields, "rhythm_kind") {
    Ok(v) =>
      match jv_as_string(v) {
        Ok(s) => s
        Err(e) => return ffi_error("GenerateError", e)
      }
    Err(e) => return ffi_error("GenerateError", e)
  }
  let contour_str = match jv_lookup(fields, "contour") {
    Ok(v) =>
      match jv_as_string(v) {
        Ok(s) => s
        Err(_) => "StepwiseUp"
      }
    Err(_) => "StepwiseUp"
  }
  let scale = match parse_scale(scale_str) {
    Ok(s) => s
    Err(e) => return ffi_error("GenerateError", e.to_string())
  }
  let key = key(scale.spelled_tones[0], scale.scale_type)
  let rhythm = match parse_rhythm_kind(rhythm_kind_str) {
    Ok(k) => make_rhythm(k)
    Err(e) => return ffi_error("GenerateError", e)
  }
  let contour = match parse_contour(contour_str) {
    Ok(c) => c
    Err(e) => return ffi_error("GenerateError", e)
  }
  let config = {
    mode: MelodyOnly,
    contour,
    range_low: c(3),
    range_high: c(6),
    seed: None,
    voice_leading: KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  match generate_melody_checked(key, rhythm, config) {
    Ok(track) => {
      let data = "{\"events\":\{track.event_count()},\"beats\":\{track.duration_beats()}}"
      ffi_ok_data(data)
    }
    Err(e) => ffi_error("GenerateError", e.to_string())
  }
}

///|
/// FFI: parse JSON, call generate_accompaniment_checked, return JSON result.
pub fn ffi_generate_accompaniment_json(input : String) -> String {
  let fields = match json_parse(input) {
    Ok(v) =>
      match jv_get_fields(v) {
        Ok(f) => f
        Err(e) => return ffi_error("GenerateError", e)
      }
    Err(e) => return ffi_error("GenerateError", e)
  }
  let scale_str = match jv_lookup(fields, "scale") {
    Ok(v) =>
      match jv_as_string(v) {
        Ok(s) => s
        Err(e) => return ffi_error("GenerateError", e)
      }
    Err(e) => return ffi_error("GenerateError", e)
  }
  let degrees : Array[Int] = match jv_lookup(fields, "degrees") {
    Ok(v) =>
      match jv_as_array(v) {
        Ok(arr) => {
          let degs : Array[Int] = []
          for i = 0; i < arr.length(); i = i + 1 {
            match jv_as_int(arr[i]) {
              Ok(n) => degs.push(n)
              Err(e) => return ffi_error("GenerateError", e)
            }
          }
          degs
        }
        Err(e) => return ffi_error("GenerateError", e)
      }
    Err(e) => return ffi_error("GenerateError", e)
  }
  let pattern_str = match jv_lookup(fields, "pattern") {
    Ok(v) =>
      match jv_as_string(v) {
        Ok(s) => s
        Err(e) => return ffi_error("GenerateError", e)
      }
    Err(e) => return ffi_error("GenerateError", e)
  }
  let scale = match parse_scale(scale_str) {
    Ok(s) => s
    Err(e) => return ffi_error("GenerateError", e.to_string())
  }
  let key = key(scale.spelled_tones[0], scale.scale_type)
  let pattern = match parse_accompaniment_pattern(pattern_str) {
    Ok(p) => p
    Err(e) => return ffi_error("GenerateError", e)
  }
  let progression = match
    generate_chord_progression_checked(key, degrees, Quarter, default_config()) {
    Ok(t) => t
    Err(e) => return ffi_error("GenerateError", e.to_string())
  }
  match generate_accompaniment_checked(progression, pattern, default_config()) {
    Ok(score) => {
      let data = "{\"tracks\":\{score.track_count()},\"beats\":\{score.duration_beats()}}"
      ffi_ok_data(data)
    }
    Err(e) => ffi_error("GenerateError", e.to_string())
  }
}

// ==================== FFI parse helpers ====================

///|
/// Parse RhythmTemplateKind from string. Accepts aliases.
fn parse_rhythm_kind(s : String) -> Result[RhythmTemplateKind, String] {
  match s {
    "FourQuarters" => Ok(FourQuarters)
    "TwoHalves" => Ok(TwoHalves)
    "WholePad" | "WholeBeat" | "Whole" => Ok(WholePad)
    "EighthFlow" => Ok(EighthFlow)
    "Syncopated" => Ok(Syncopated)
    "LongShort" => Ok(LongShort)
    "ShortShortLong" => Ok(ShortShortLong)
    _ => Err("Unknown rhythm kind: \{s}")
  }
}

///|
/// Parse MelodyContour from string.
fn parse_contour(s : String) -> Result[MelodyContour, String] {
  match s {
    "StepwiseUp" => Ok(StepwiseUp)
    "StepwiseDown" => Ok(StepwiseDown)
    "Arch" => Ok(Arch)
    "InvertedArch" => Ok(InvertedArch)
    "Wave" => Ok(Wave)
    "Static" => Ok(Static)
    "ChordTone" => Ok(ChordTone)
    _ => Err("Unknown contour: \{s}")
  }
}

///|
/// Parse AccompanimentPattern from string.
fn parse_accompaniment_pattern(
  s : String,
) -> Result[AccompanimentPattern, String] {
  match s {
    "BlockChord" => Ok(BlockChord)
    "ArpeggioUp" => Ok(ArpeggioUp)
    "ArpeggioDown" => Ok(ArpeggioDown)
    "ArpeggioUpDown" => Ok(ArpeggioUpDown)
    "Alberti" => Ok(Alberti)
    "Pad" => Ok(Pad)
    "RootBass" => Ok(RootBass)
    "RootFifthBass" => Ok(RootFifthBass)
    "WalkingBass" => Ok(WalkingBass)
    _ => Err("Unknown accompaniment pattern: \{s}")
  }
}
