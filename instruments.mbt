// ============================================================
// v2 MIDI 乐器 — General MIDI 乐器常量和轨道乐器设置
// ============================================================

// --- 精选 GM 乐器 ---

///|
pub fn acoustic_grand_piano() -> Int {
  0
}

///|
pub fn electric_piano_1() -> Int {
  4
}

///|
pub fn violin() -> Int {
  40
}

///|
pub fn cello() -> Int {
  42
}

///|
pub fn acoustic_guitar_steel() -> Int {
  25
}

///|
pub fn electric_bass_finger() -> Int {
  33
}

///|
pub fn synth_lead_square() -> Int {
  80
}

///|
pub fn synth_pad_warm() -> Int {
  89
}

///|
/// 为轨道设置 MIDI 乐器（program 0-127）
pub fn instrument(track : Track, program : Int) -> Track {
  {
    events: track.events,
    channel: track.channel,
    program,
    volume: track.volume,
    pan: track.pan,
    mute: track.mute,
  }
}
