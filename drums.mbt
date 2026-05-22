// 鼓组 — GM 鼓音符常量 + 鼓事件 + basic_beat
//

///|
/// GM 鼓音符（通道 9）
pub const DRUM_CHANNEL : Int = 9

///|
pub const KICK : Int = 36

///|
pub const SNARE : Int = 38

///|
pub const CLOSED_HAT : Int = 42

///|
pub const OPEN_HAT : Int = 46

///|
pub const CLAP : Int = 39

///|
/// 创建鼓音符事件
pub fn drum_note(
  midi_note : Int,
  duration : Duration,
  velocity : Int,
) -> MusicEvent {
  let p = midi_to_pitch(midi_note)
  Note(note_with_velocity(p, duration, velocity))
}

///|
/// 底鼓
pub fn kick(duration : Duration) -> MusicEvent {
  drum_note(KICK, duration, 100)
}

///|
/// 军鼓
pub fn snare(duration : Duration) -> MusicEvent {
  drum_note(SNARE, duration, 80)
}

///|
/// 踩镲
pub fn hat(duration : Duration) -> MusicEvent {
  drum_note(CLOSED_HAT, duration, 60)
}

///|
/// 基础 4/4 节拍 — 返回三条轨道的乐谱（kick/snare/hat）
pub fn basic_beat(bars : Int) -> Score {
  let kick_events = []
  let snare_events = []
  let hat_events = []
  for bar = 0; bar < bars; bar = bar + 1 {
    for beat = 0; beat < 4; beat = beat + 1 {
      // hat：每拍两个八分（同时发声）
      hat_events.push(hat(eighth()))
      hat_events.push(hat(eighth()))
      // kick：第 1、3 拍
      if beat == 0 || beat == 2 {
        kick_events.push(kick(quarter()))
        snare_events.push(r(quarter()))
      } else if beat == 1 || beat == 3 {
        // snare：第 2、4 拍
        kick_events.push(r(quarter()))
        snare_events.push(snare(quarter()))
      }
    }
  }
  let kick_track = track_with_channel(kick_events, DRUM_CHANNEL)
  let snare_track = track_with_channel(snare_events, DRUM_CHANNEL)
  let hat_track = track_with_channel(hat_events, DRUM_CHANNEL)
  score([kick_track, snare_track, hat_track])
}
