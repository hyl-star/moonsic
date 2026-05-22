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
/// 计算 2^x = exp(x * ln(2))
fn pow2(exp : Double) -> Double {
  let ln2 = 0.6931471805599453
  @math.exp(exp * ln2)
}

// --- MIDI 导出 ---

///|
/// 将乐谱导出为 MIDI 字节流（默认 PPQ=480）
pub fn Score::to_midi_bytes(self : Score) -> Bytes {
  self.to_midi_bytes_with_ppq(DEFAULT_PPQ)
}

///|
/// 将乐谱导出为 MIDI 字节流（指定 PPQ）
pub fn Score::to_midi_bytes_with_ppq(self : Score, ppq : Int) -> Bytes {
  let note_events = self.to_note_events()

  // 构建元数据轨道（track 0）：速度 + 拍号 + 轨道结束
  let meta_events : Array[@midi.Event] = []

  // 速度：BPM 转为微秒/四分音符
  let microseconds = 60000000U / self.tempo.bpm.reinterpret_as_uint()
  meta_events.push(Tempo(delta=0U, microseconds~))

  // 拍号：使用 Meta 事件（CAIMEOX/midi 的 TimeSignature 序列化尚未实现）
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

  // 按通道分组 NoteEvent，为每个通道创建一条 MIDI 轨道
  let channels = collect_channels(note_events)
  for ch in channels {
    let channel_events = filter_by_channel(note_events, ch)
    let midi_events = note_events_to_midi(channel_events, ppq)
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
/// 收集所有不重复的通道号
fn collect_channels(events : Array[NoteEvent]) -> Array[Int] {
  let channels = []
  for e in events {
    let mut found = false
    for c in channels {
      if c == e.channel {
        found = true
        break
      }
    }
    if !found {
      channels.push(e.channel)
    }
  }
  channels
}

///|
/// 按通道过滤 NoteEvent
fn filter_by_channel(
  events : Array[NoteEvent],
  channel : Int,
) -> Array[NoteEvent] {
  let result = []
  for e in events {
    if e.channel == channel {
      result.push(e)
    }
  }
  result
}

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
