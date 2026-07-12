///|
pub fn ffi_generate_melody_json(input : String) -> String {
  match generate_melody_json_checked(input) {
    Ok(data) => ffi_ok(data)
    Err(e) => ffi_error(e)
  }
}

///|
pub fn ffi_generate_game_loop_json(input : String) -> String {
  match generate_game_loop_json_checked(input) {
    Ok(data) => ffi_ok(data)
    Err(e) => ffi_error(e)
  }
}

///|
fn generate_melody_json_checked(input : String) -> Result[String, FfiError] {
  let fields = match input_fields(input) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let key = match read_key(fields) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let rhythm_kind = match
    field_string_or(fields, "rhythm_kind", "FourQuarters") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let rhythm = match parse_rhythm_kind(rhythm_kind) {
    Ok(result) => @rhythm.rhythm_template(result)
    Err(e) => return Err(e)
  }
  let contour_text = match field_string_or(fields, "contour", "StepwiseUp") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let contour = match parse_contour(contour_text) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let tempo = match read_tempo(fields) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let signature = match read_signature(fields) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let config = melody_config(contour)
  let track = match @generate.generate_melody_checked(key, rhythm, config) {
    Ok(result) => result
    Err(e) => return Err(FfiGenerateError(e.to_string()))
  }
  let score = match @score.simple_score_checked([track], tempo, signature) {
    Ok(result) => result
    Err(e) => return Err(FfiGenerateError(e.to_string()))
  }
  match @adapter.simple_score_to_json_checked(score) {
    Ok(result) => Ok(result)
    Err(e) => Err(FfiGenerateError(e.to_string()))
  }
}

///|
fn generate_game_loop_json_checked(input : String) -> Result[String, FfiError] {
  let fields = match input_fields(input) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let key = match read_key(fields) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let tempo = match read_tempo(fields) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let signature = match read_signature(fields) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let bars = match field_int_or(fields, "bars", 1) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let progression = match
    field_int_array_or(fields, "progression", [1, 5, 6, 4]) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let contour_text = match field_string_or(fields, "contour", "StepwiseUp") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let contour = match parse_contour(contour_text) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let context = @generate.GenerationContext::{
    key,
    progression,
    time_signature: signature,
    tempo,
    bars,
  }
  let score = match
    @generate.generate_game_loop_checked(context, bars, melody_config(contour)) {
    Ok(result) => result
    Err(e) => return Err(FfiGenerateError(e.to_string()))
  }
  match @adapter.simple_score_to_json_checked(score) {
    Ok(result) => Ok(result)
    Err(e) => Err(FfiGenerateError(e.to_string()))
  }
}

///|
fn read_key(fields : Array[@json.JsonField]) -> Result[@scale.Key, FfiError] {
  let scale_text = match field_string(fields, "scale") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let scale = match @scale.parse_scale(scale_text) {
    Ok(result) => result
    Err(e) => return Err(FfiGenerateError(e.to_string()))
  }
  if scale.spelled_tones.length() == 0 {
    return Err(FfiGenerateError("scale has no tones"))
  }
  Ok(@scale.key(scale.spelled_tones[0], scale.scale_type))
}

///|
fn read_tempo(
  fields : Array[@json.JsonField],
) -> Result[@score.Tempo, FfiError] {
  let bpm = match field_int_or(fields, "tempo", 120) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  match @score.tempo_checked(bpm) {
    Ok(result) => Ok(result)
    Err(e) => Err(FfiGenerateError(e.to_string()))
  }
}

///|
fn read_signature(
  fields : Array[@json.JsonField],
) -> Result[@time.TimeSignature, FfiError] {
  let numerator = match field_int_or(fields, "numerator", 4) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let denominator = match field_int_or(fields, "denominator", 4) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  if !@time.is_valid_time_signature(numerator, denominator) {
    return Err(InvalidFfiField("invalid time signature"))
  }
  Ok(@time.time_signature(numerator, denominator))
}

///|
fn melody_config(
  contour : @generate.MelodyContour,
) -> @generate.GenerationConfig {
  let base = @generate.default_generation_config()
  {
    mode: base.mode,
    contour,
    range_low: @pitch.c(4),
    range_high: @pitch.c(6),
    seed: base.seed,
    voice_leading: base.voice_leading,
    allow_rests: base.allow_rests,
    max_leap: base.max_leap,
  }
}

///|
fn parse_rhythm_kind(
  text : String,
) -> Result[@rhythm.RhythmTemplateKind, FfiError] {
  match text {
    "FourQuarters" => Ok(@rhythm.FourQuarters)
    "TwoHalves" => Ok(@rhythm.TwoHalves)
    "WholePad" | "Whole" => Ok(@rhythm.WholePad)
    "EighthFlow" => Ok(@rhythm.EighthFlow)
    "Syncopated" => Ok(@rhythm.Syncopated)
    "LongShort" => Ok(@rhythm.LongShort)
    "ShortShortLong" => Ok(@rhythm.ShortShortLong)
    "Waltz" => Ok(@rhythm.Waltz)
    "Tresillo" => Ok(@rhythm.Tresillo)
    "RestLead" => Ok(@rhythm.RestLead)
    _ => Err(InvalidFfiField("unknown rhythm kind: " + text))
  }
}

///|
fn parse_contour(text : String) -> Result[@generate.MelodyContour, FfiError] {
  match text {
    "StepwiseUp" => Ok(@generate.StepwiseUp)
    "StepwiseDown" => Ok(@generate.StepwiseDown)
    "Arch" => Ok(@generate.Arch)
    "InvertedArch" => Ok(@generate.InvertedArch)
    "Wave" => Ok(@generate.Wave)
    "Static" => Ok(@generate.Static)
    "ChordTone" => Ok(@generate.ChordTone)
    _ => Err(InvalidFfiField("unknown contour: " + text))
  }
}
