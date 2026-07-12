// ============================================================
// Partial Success — 收集 warnings，继续部分失败
// ============================================================

///|
/// 将 MIDI 导出结果写入 bundle
pub fn set_midi_bytes(
  bundle : CompositionAssetBundle,
  bytes : Bytes,
) -> CompositionAssetBundle {
  { ..bundle, midi_bytes: Some(bytes) }
}

///|
/// 将 MusicXML 导出结果写入 bundle
pub fn set_musicxml(
  bundle : CompositionAssetBundle,
  xml : String,
) -> CompositionAssetBundle {
  { ..bundle, musicxml: Some(xml) }
}

///|
/// 将 WAV 导出结果写入 bundle
pub fn set_wav_bytes(
  bundle : CompositionAssetBundle,
  bytes : Bytes,
) -> CompositionAssetBundle {
  { ..bundle, wav_bytes: Some(bytes) }
}

///|
/// 将 Web events 导出结果写入 bundle
pub fn set_web_events(
  bundle : CompositionAssetBundle,
  json : String,
) -> CompositionAssetBundle {
  { ..bundle, web_events_json: Some(json) }
}

///|
/// 将 Game IR 导出结果写入 bundle
pub fn set_game_ir(
  bundle : CompositionAssetBundle,
  json : String,
) -> CompositionAssetBundle {
  { ..bundle, game_ir_json: Some(json) }
}

///|
/// 将 score JSON 写入 bundle
pub fn set_score_json(
  bundle : CompositionAssetBundle,
  json : String,
) -> CompositionAssetBundle {
  { ..bundle, score_json: Some(json) }
}

///|
/// 将 validation JSON 写入 bundle
pub fn set_validation_json(
  bundle : CompositionAssetBundle,
  json : String,
) -> CompositionAssetBundle {
  { ..bundle, validation_json: Some(json) }
}
