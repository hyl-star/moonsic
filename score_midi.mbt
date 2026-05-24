// ============================================================
// MIDI 语义适配层 — Score 转标准 MIDI track 结构
// ============================================================

// --- MIDI 事件类型 ---

///|
/// MIDI 事件类型：NoteOn/NoteOff/ProgramChange/ControlChange/元事件
pub(all) enum MidiEventKind {
  NoteOn(channel~ : Int, note~ : Int, velocity~ : Int)
  NoteOff(channel~ : Int, note~ : Int, velocity~ : Int)
  ProgramChange(channel~ : Int, program~ : Int)
  ControlChange(channel~ : Int, controller~ : Int, value~ : Int)
  TempoChange(bpm~ : Int)
  TimeSignatureMeta(numerator~ : Int, denominator~ : Int)
  TrackName(name~ : String)
  EndOfTrack
}

///|
/// 绝对 tick MIDI 事件
pub(all) struct MidiEvent {
  tick : Int
  kind : MidiEventKind
}

///|
/// MIDI 语义轨道：名称、乐器号、通道、事件列表
pub(all) struct MidiTrack {
  name : String
  program : Int // -1 = 未设置乐器
  channel : Int
  events : Array[MidiEvent]
}

///|
/// MIDI 语义乐谱：ppq + 轨道列表
pub(all) struct MidiScore {
  ppq : Int
  tracks : Array[MidiTrack]
}

// --- 简单验证 ---

///|
/// 验证 MIDI 音符范围 0..127
pub fn validate_midi_note(note : Int) -> Bool {
  note >= 0 && note <= MAX_MIDI_NOTE
}

///|
/// 验证力度范围 0..127
pub fn validate_velocity(vel : Int) -> Bool {
  vel >= MIN_VELOCITY && vel <= MAX_VELOCITY
}

///|
/// 验证 MIDI 通道范围 0..15
pub fn validate_channel(ch : Int) -> Bool {
  ch >= MIN_CHANNEL && ch <= MAX_CHANNEL
}

///|
/// 验证乐器号范围 0..127
pub fn validate_program(prog : Int) -> Bool {
  prog >= 0 && prog <= 127
}

///|
/// 验证控制器编号/值范围 0..127
pub fn validate_controller(ctrl : Int) -> Bool {
  ctrl >= 0 && ctrl <= 127
}

///|
/// 验证 tick >= 0
pub fn validate_tick(tick : Int) -> Bool {
  tick >= 0
}

///|
/// 验证 ppq > 0
pub fn validate_ppq(ppq : Int) -> Bool {
  ppq > 0
}

// --- 事件构造 ---

///|
/// 构造 NoteOn 事件
pub fn note_on(
  tick : Int,
  channel : Int,
  note : Int,
  velocity : Int,
) -> Result[MidiEvent, String] {
  if !validate_tick(tick) {
    return Err("invalid tick")
  }
  if !validate_channel(channel) {
    return Err("invalid channel")
  }
  if !validate_midi_note(note) {
    return Err("invalid MIDI note")
  }
  if !validate_velocity(velocity) {
    return Err("invalid velocity")
  }
  Ok({ tick, kind: NoteOn(channel~, note~, velocity~) })
}

///|
/// 构造 NoteOff 事件
pub fn note_off(
  tick : Int,
  channel : Int,
  note : Int,
  velocity : Int,
) -> Result[MidiEvent, String] {
  if !validate_tick(tick) {
    return Err("invalid tick")
  }
  if !validate_channel(channel) {
    return Err("invalid channel")
  }
  if !validate_midi_note(note) {
    return Err("invalid MIDI note")
  }
  if !validate_velocity(velocity) {
    return Err("invalid velocity")
  }
  Ok({ tick, kind: NoteOff(channel~, note~, velocity~) })
}

///|
/// 构造 ProgramChange 事件（0 基 program 0..127）
pub fn program_change(
  tick : Int,
  channel : Int,
  program : Int,
) -> Result[MidiEvent, String] {
  if !validate_tick(tick) {
    return Err("invalid tick")
  }
  if !validate_channel(channel) {
    return Err("invalid channel")
  }
  if !validate_program(program) {
    return Err("invalid program")
  }
  Ok({ tick, kind: ProgramChange(channel~, program~) })
}

///|
/// 构造 ControlChange 事件
pub fn control_change(
  tick : Int,
  channel : Int,
  controller : Int,
  value : Int,
) -> Result[MidiEvent, String] {
  if !validate_tick(tick) {
    return Err("invalid tick")
  }
  if !validate_channel(channel) {
    return Err("invalid channel")
  }
  if !validate_controller(controller) {
    return Err("invalid controller number")
  }
  if !validate_controller(value) {
    return Err("invalid controller value")
  }
  Ok({ tick, kind: ControlChange(channel~, controller~, value~) })
}

///|
/// 构造 TempoChange 事件（BPM 输入）
pub fn tempo_change(tick : Int, bpm : Int) -> Result[MidiEvent, String] {
  if !validate_tick(tick) {
    return Err("invalid tick")
  }
  if bpm <= 0 {
    return Err("invalid bpm")
  }
  Ok({ tick, kind: TempoChange(bpm~) })
}

///|
/// 构造 TrackName 元事件
pub fn track_name(tick : Int, name : String) -> Result[MidiEvent, String] {
  if !validate_tick(tick) {
    return Err("invalid tick")
  }
  Ok({ tick, kind: TrackName(name~) })
}

///|
/// 构造 EndOfTrack 事件
pub fn end_of_track(tick : Int) -> Result[MidiEvent, String] {
  if !validate_tick(tick) {
    return Err("invalid tick")
  }
  Ok({ tick, kind: EndOfTrack })
}

// --- 事件排序 ---

///|
/// 按绝对 tick 升序排序，同一 tick 内按事件优先级排序
/// 优先级：TrackName(0) < TimeSignatureMeta(1) < TempoChange(2) <
///         ProgramChange(4) < ControlChange(5) < NoteOff(7) <
///         NoteOn(8) < EndOfTrack(13)
pub fn sort_midi_events(events : Array[MidiEvent]) -> Array[MidiEvent] {
  let n = events.length()
  for i = 1; i < n; i = i + 1 {
    let key = events[i]
    let mut j = i - 1
    while j >= 0 {
      let cur = events[j]
      if cur.tick > key.tick ||
        (
          cur.tick == key.tick &&
          event_priority(cur.kind) > event_priority(key.kind)
        ) {
        events[j + 1] = cur
        j = j - 1
      } else {
        break
      }
    }
    events[j + 1] = key
  }
  events
}

///|
/// 获取事件类型的排序优先级
fn event_priority(kind : MidiEventKind) -> Int {
  match kind {
    TrackName(name=_) => 0
    TimeSignatureMeta(numerator=_, denominator=_) => 1
    TempoChange(bpm=_) => 2
    ProgramChange(channel=_, program=_) => 4
    ControlChange(channel=_, controller=_, value=_) => 5
    NoteOff(channel=_, note=_, velocity=_) => 7
    NoteOn(channel=_, note=_, velocity=_) => 8
    EndOfTrack => 13
  }
}

// --- 核心转换：Score -> MidiScore ---

///|
/// 将 Moonsic Score 转为 MIDI 语义乐谱 MidiScore
/// - 自动生成元数据轨道（速度、拍号）
/// - 每条 Track 生成对应 MidiTrack，包含 ProgramChange（如有乐器）、NoteOn/NoteOff、EndOfTrack
pub fn score_to_midi_score(score : Score, ppq : Int) -> MidiScore {
  // 元数据轨道：速度 + 拍号 + 轨道名 + EndOfTrack
  let meta_events : Array[MidiEvent] = []
  meta_events.push({ tick: 0, kind: TrackName(name="Meta") })
  meta_events.push({ tick: 0, kind: TempoChange(bpm=score.tempo.bpm) })
  meta_events.push({
    tick: 0,
    kind: TimeSignatureMeta(
      numerator=score.time_signature.numerator,
      denominator=score.time_signature.denominator,
    ),
  })
  meta_events.push({ tick: 0, kind: EndOfTrack })

  let all_tracks : Array[MidiTrack] = [
    { name: "Meta", program: -1, channel: 0, events: meta_events },
  ]

  // 每条 Score 轨道 → MidiTrack
  for track in score.tracks {
    let midi_events : Array[MidiEvent] = []

    // 轨道名称
    midi_events.push({
      tick: 0,
      kind: TrackName(name="Track ch=\{track.channel}"),
    })

    // 乐器 ProgramChange
    if track.program >= 0 {
      midi_events.push({
        tick: 0,
        kind: ProgramChange(channel=track.channel, program=track.program),
      })
    }

    // 音符展开为 NoteOn + NoteOff
    let note_events = track.to_note_events()
    for ne in note_events {
      let start_tick = ne.start_ticks(ppq)
      let dur_ticks = ne.duration_ticks(ppq)
      let end_tick = start_tick + dur_ticks
      midi_events.push({
        tick: start_tick,
        kind: NoteOn(
          channel=ne.channel,
          note=ne.midi_note,
          velocity=ne.velocity,
        ),
      })
      midi_events.push({
        tick: end_tick,
        kind: NoteOff(
          channel=ne.channel,
          note=ne.midi_note,
          velocity=ne.velocity,
        ),
      })
    }

    // 找到最大 tick 并追加 EndOfTrack
    let mut max_tick = 0
    for e in midi_events {
      if e.tick > max_tick {
        max_tick = e.tick
      }
    }
    midi_events.push({ tick: max_tick, kind: EndOfTrack })

    all_tracks.push({
      name: "Track ch=\{track.channel}",
      program: track.program,
      channel: track.channel,
      events: midi_events,
    })
  }

  { ppq, tracks: all_tracks }
}

// --- CAIMEOX/midi 适配 ---

///|
/// 将 MidiEvent 转为一个 @midi.Event（需要 delta ticks）
fn midi_event_to_caimeox(event : MidiEvent, delta : Int) -> @midi.Event {
  match event.kind {
    NoteOn(channel=ch, note=n, velocity=v) =>
      @midi.NoteOn(
        delta=delta.reinterpret_as_uint(),
        channel=ch.to_byte(),
        note=n.to_byte(),
        velocity=v.to_byte(),
      )
    NoteOff(channel=ch, note=n, velocity=v) =>
      @midi.NoteOff(
        delta=delta.reinterpret_as_uint(),
        channel=ch.to_byte(),
        note=n.to_byte(),
        velocity=v.to_byte(),
      )
    ProgramChange(channel=ch, program=prog) =>
      @midi.ProgramChange(
        delta=delta.reinterpret_as_uint(),
        channel=ch.to_byte(),
        program=prog.to_byte(),
      )
    ControlChange(channel=ch, controller=ctrl, value=val) =>
      @midi.ControlChange(
        delta=delta.reinterpret_as_uint(),
        channel=ch.to_byte(),
        controller=ctrl.to_byte(),
        value=val.to_byte(),
      )
    TempoChange(bpm=bpm_val) => {
      let us = 60000000U / bpm_val.reinterpret_as_uint()
      @midi.Tempo(delta=delta.reinterpret_as_uint(), microseconds=us)
    }
    TimeSignatureMeta(numerator=num, denominator=den) => {
      let denom_power = match den {
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
        num.to_byte(),
        denom_power.to_byte(),
        (24).to_byte(),
        (8).to_byte(),
      ]
      @midi.Meta(
        delta=delta.reinterpret_as_uint(),
        meta_type=(0x58).to_byte(),
        data=ts_data,
      )
    }
    TrackName(name=name_str) => {
      let name_bytes : Array[Byte] = []
      for i = 0; i < name_str.length(); i = i + 1 {
        name_bytes.push(name_str[i].to_int().to_byte())
      }
      @midi.Meta(
        delta=delta.reinterpret_as_uint(),
        meta_type=(0x03).to_byte(),
        data=name_bytes,
      )
    }
    EndOfTrack =>
      @midi.Meta(
        delta=delta.reinterpret_as_uint(),
        meta_type=(0x2F).to_byte(),
        data=[],
      )
  }
}

///|
/// 将 MidiScore 转为 MIDI 字节流（调用 @midi.serialize）
/// 内部执行事件排序、delta 转换、EndOfTrack 补齐
pub fn midi_score_to_bytes(score : MidiScore) -> Bytes {
  let caimeox_tracks : Array[@midi.Track] = []
  for track in score.tracks {
    let sorted = sort_midi_events(track.events)
    let midi_events : Array[@midi.Event] = []
    let mut last_tick = 0
    for e in sorted {
      let delta = e.tick - last_tick
      midi_events.push(midi_event_to_caimeox(e, delta))
      last_tick = e.tick
    }
    caimeox_tracks.push(@midi.Track::{ events: midi_events })
  }

  let file = @midi.MidiFile::{
    format: (1).to_uint16(),
    division: score.ppq.to_uint16(),
    tracks: caimeox_tracks,
  }
  @midi.serialize(file)
}

///|
/// 一站式转换：Score -> MidiScore -> MIDI 字节流
pub fn score_to_midi_bytes(score : Score, ppq : Int) -> Bytes {
  midi_score_to_bytes(score_to_midi_score(score, ppq))
}
