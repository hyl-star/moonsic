// ============================================================
// SimpleScore — 快速作曲模型
// ============================================================

// --- SimpleNote / SimpleRest / SimpleChord ---

///|
pub(all) struct SimpleNote {
  pitch : @pitch.Pitch
  duration : @time.RhythmDuration
  velocity : Velocity
}

///|
pub(all) struct SimpleRest {
  duration : @time.RhythmDuration
}

///|
pub(all) struct SimpleChord {
  pitches : Array[@pitch.Pitch]
  duration : @time.RhythmDuration
  velocity : Velocity
}

///|
pub(all) enum SimpleEvent {
  Note(SimpleNote)
  Rest(SimpleRest)
  Chord(SimpleChord)
}

///|
pub(all) struct SimpleTrack {
  events : Array[SimpleEvent]
  channel : MidiChannel?
  program : MidiProgram?
  volume : Double
  pan : Double
  mute : Bool
}

///|
pub(all) struct SimpleScore {
  tempo : Tempo
  time_signature : @time.TimeSignature
  tracks : Array[SimpleTrack]
  master_gain : Double
}

// --- 构造器 ---

///|
pub fn tempo_checked(bpm : Int) -> Result[Tempo, ScoreError] {
  if bpm <= 0 {
    return Err(InvalidTempo("BPM 必须 > 0，当前：\{bpm}"))
  }
  Ok({ bpm, })
}

///|
pub fn ppq_checked(value : Int) -> Result[PPQ, ScoreError] {
  if value <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{value}"))
  }
  Ok({ value, })
}

///|
pub fn velocity_checked(value : Int) -> Result[Velocity, ScoreError] {
  if value < 0 || value > 127 {
    return Err(InvalidVelocity("力度必须在 0-127，当前：\{value}"))
  }
  Ok({ value, })
}

///|
pub fn midi_channel_checked(value : Int) -> Result[MidiChannel, ScoreError] {
  if value < 0 || value > 15 {
    return Err(InvalidChannel("通道必须在 0-15，当前：\{value}"))
  }
  Ok({ value, })
}

///|
pub fn midi_program_checked(value : Int) -> Result[MidiProgram, ScoreError] {
  if value < 0 || value > 127 {
    return Err(InvalidProgram("乐器必须在 0-127，当前：\{value}"))
  }
  Ok({ value, })
}

///|
pub fn simple_note_checked(
  pitch : @pitch.Pitch,
  duration : @time.RhythmDuration,
  velocity : Velocity?,
) -> Result[SimpleEvent, ScoreError] {
  let vel = match velocity {
    Some(v) => v
    None => { value: 100 }
  }
  Ok(Note({ pitch, duration, velocity: vel }))
}

///|
pub fn simple_rest_checked(
  duration : @time.RhythmDuration,
) -> Result[SimpleEvent, ScoreError] {
  Ok(Rest({ duration, }))
}

///|
pub fn simple_chord_checked(
  pitches : Array[@pitch.Pitch],
  duration : @time.RhythmDuration,
  velocity : Velocity?,
) -> Result[SimpleEvent, ScoreError] {
  if pitches.length() == 0 {
    return Err(InvalidEvent("和弦必须至少包含一个音高"))
  }
  let vel = match velocity {
    Some(v) => v
    None => { value: 100 }
  }
  Ok(Chord({ pitches, duration, velocity: vel }))
}

///|
pub fn simple_track_checked(
  events : Array[SimpleEvent],
  channel : MidiChannel?,
  program : MidiProgram?,
) -> Result[SimpleTrack, ScoreError] {
  Ok({ events, channel, program, volume: 1.0, pan: 0.0, mute: false })
}

///|
pub fn simple_score_checked(
  tracks : Array[SimpleTrack],
  tempo : Tempo,
  signature : @time.TimeSignature,
) -> Result[SimpleScore, ScoreError] {
  if tracks.length() == 0 {
    return Err(InvalidEvent("乐谱必须至少包含一条轨道"))
  }
  Ok({ tempo, time_signature: signature, tracks, master_gain: 0.85 })
}
