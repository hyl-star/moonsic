// ============================================================
// MIDI 导出 — Score 转 MIDI 字节流，依赖 CAIMEOX/midi
// ============================================================

// --- 频率转换 ---

///|
/// MIDI 音符编号转频率（A4=440Hz 基准）
pub fn midi_to_frequency(midi : Int) -> Double {
  let exponent = (midi - A4_MIDI).to_double() / 12.0
  A4_FREQ * pow2(exponent)
}

///|
/// 音高直接转频率
pub fn Pitch::frequency(self : Pitch) -> Double {
  midi_to_frequency(self.to_midi())
}

///|
/// NoteEvent 直接取频率
pub fn NoteEvent::frequency(self : NoteEvent) -> Double {
  midi_to_frequency(self.midi_note)
}

///|
/// 计算 2^x = exp(x * ln(2))
fn pow2(exp : Double) -> Double {
  let ln2 = 0.6931471805599453
  @math.exp(exp * ln2)
}

// --- 导出前校验 ---

///|
/// 校验 Score 的所有值在合法范围内
fn validate_score(score : Score, ppq : Int) -> Unit {
  if score.tempo.bpm <= 0 {
    abort("MIDI 导出失败：BPM 必须 > 0，当前值：\{score.tempo.bpm}")
  }
  if ppq <= 0 {
    abort("MIDI 导出失败：PPQ 必须 > 0，当前值：\{ppq}")
  }
  for track in score.tracks {
    let events = track.to_note_events()
    for e in events {
      if e.midi_note < MIN_MIDI_NOTE || e.midi_note > MAX_MIDI_NOTE {
        abort(
          "MIDI 导出失败：MIDI 音符越界 \{e.midi_note}，合法范围 [\{MIN_MIDI_NOTE}, \{MAX_MIDI_NOTE}]",
        )
      }
      if e.velocity < MIN_VELOCITY || e.velocity > MAX_VELOCITY {
        abort(
          "MIDI 导出失败：力度越界 \{e.velocity}，合法范围 [\{MIN_VELOCITY}, \{MAX_VELOCITY}]",
        )
      }
      if e.channel < MIN_CHANNEL || e.channel > MAX_CHANNEL {
        abort(
          "MIDI 导出失败：通道越界 \{e.channel}，合法范围 [\{MIN_CHANNEL}, \{MAX_CHANNEL}]",
        )
      }
    }
  }
}

// --- MIDI 导出 ---

///|
/// 将乐谱导出为 MIDI 字节流（默认 PPQ=480）
pub fn Score::to_midi_bytes(self : Score) -> Bytes {
  self.to_midi_bytes_with_ppq(DEFAULT_PPQ)
}

///|
/// 将乐谱导出为 MIDI 字节流（指定 PPQ）
/// 导出前校验 BPM > 0、PPQ > 0、MIDI/力度/通道范围
pub fn Score::to_midi_bytes_with_ppq(self : Score, ppq : Int) -> Bytes {
  validate_score(self, ppq)

  // 构建元数据轨道（track 0）：速度 + 拍号 + 轨道结束
  let meta_events : Array[@midi.Event] = []

  // 速度：BPM 转为微秒/四分音符（BPM > 0 已在 validate_score 保证）
  let microseconds = 60000000U / self.tempo.bpm.reinterpret_as_uint()
  meta_events.push(Tempo(delta=0U, microseconds~))

  // 拍号
  let ts = self.time_signature
  let denom_power = match ts.denominator {
    1 => 0
    2 => 1
    4 => 2
    8 => 3
    16 => 4
    32 => 5
    64 => 6
    _ => 2
  }
  let ts_data : Array[Byte] = [
    ts.numerator.to_byte(),
    denom_power.to_byte(),
    (24).to_byte(),
    (8).to_byte(),
  ]
  meta_events.push(Meta(delta=0U, meta_type=(0x58).to_byte(), data=ts_data))

  // 轨道结束标记
  meta_events.push(Meta(delta=0U, meta_type=(0x2F).to_byte(), data=[]))

  let meta_track = @midi.Track::{ events: meta_events }
  let all_tracks = [meta_track]

  // 每条 Score 轨道对应一条 MIDI 轨道（保留用户轨道结构）
  for track in self.tracks {
    let track_events = track.to_note_events()
    let midi_events = note_events_to_midi(track_events, ppq)
    all_tracks.push(@midi.Track::{ events: midi_events })
  }

  let file = @midi.MidiFile::{
    format: (1).to_uint16(),
    division: ppq.to_uint16(),
    tracks: all_tracks,
  }
  @midi.serialize(file)
}

// --- 内部辅助函数 ---

///|
/// 将 NoteEvent 序列转为 MIDI delta-tick 事件
fn note_events_to_midi(
  events : Array[NoteEvent],
  ppq : Int,
) -> Array[@midi.Event] {
  // 第一步：创建绝对 tick 事件（NoteOn + NoteOff）
  let abs_events : Array[AbsMidiEvent] = []
  for e in events {
    let start_tick = e.start_ticks(ppq)
    let dur_ticks = e.duration_ticks(ppq)
    let end_tick = start_tick + dur_ticks

    abs_events.push({
      tick: start_tick,
      is_note_off: false,
      midi_note: e.midi_note,
      velocity: e.velocity,
      channel: e.channel,
    })
    abs_events.push({
      tick: end_tick,
      is_note_off: true,
      midi_note: e.midi_note,
      velocity: e.velocity,
      channel: e.channel,
    })
  }

  // 第二步：排序，同一 tick 下 NoteOff 先于 NoteOn
  sort_abs_events(abs_events)

  // 第三步：转为 delta-tick MIDI 事件
  let midi_events : Array[@midi.Event] = []
  let mut prev_tick = 0
  for abs in abs_events {
    let delta = abs.tick - prev_tick
    if abs.is_note_off {
      midi_events.push(
        NoteOff(
          delta=delta.reinterpret_as_uint(),
          channel=abs.channel.to_byte(),
          note=abs.midi_note.to_byte(),
          velocity=abs.velocity.to_byte(),
        ),
      )
    } else {
      midi_events.push(
        NoteOn(
          delta=delta.reinterpret_as_uint(),
          channel=abs.channel.to_byte(),
          note=abs.midi_note.to_byte(),
          velocity=abs.velocity.to_byte(),
        ),
      )
    }
    prev_tick = abs.tick
  }

  // 添加轨道结束事件
  midi_events.push(Meta(delta=0U, meta_type=(0x2F).to_byte(), data=[]))
  midi_events
}

///|
/// 内部绝对 MIDI 事件，用于排序
priv struct AbsMidiEvent {
  tick : Int
  is_note_off : Bool
  midi_note : Int
  velocity : Int
  channel : Int
}

///|
/// 绝对 MIDI 事件排序：按 tick 升序，同一 tick 下 NoteOff 先于 NoteOn
fn sort_abs_events(events : Array[AbsMidiEvent]) -> Unit {
  let n = events.length()
  for i = 1; i < n; i = i + 1 {
    let key = events[i]
    let mut j = i - 1
    while j >= 0 {
      let cur = events[j]
      if cur.tick > key.tick ||
        (cur.tick == key.tick && !cur.is_note_off && key.is_note_off) {
        events[j + 1] = cur
        j = j - 1
      } else {
        break
      }
    }
    events[j + 1] = key
  }
}
