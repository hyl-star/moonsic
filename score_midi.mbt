// MIDI semantic adapter: Score -> absolute-tick MIDI events -> CAIMEOX/midi bytes.

///|
pub(all) enum MidiError {
  InvalidMidiTick(Int)
  InvalidMidiChannel(Int)
  InvalidMidiNote(Int)
  InvalidMidiVelocity(Int)
  InvalidMidiProgram(Int)
  InvalidMidiController(Int)
  InvalidMidiTempo(Int)
  InvalidMidiPPQ(Int)
  MidiExportError(String)
}

///|
pub fn MidiError::to_string(self : MidiError) -> String {
  match self {
    InvalidMidiTick(v) => "invalid MIDI tick: \{v}"
    InvalidMidiChannel(v) => "invalid MIDI channel: \{v}"
    InvalidMidiNote(v) => "invalid MIDI note: \{v}"
    InvalidMidiVelocity(v) => "invalid MIDI velocity: \{v}"
    InvalidMidiProgram(v) => "invalid MIDI program: \{v}"
    InvalidMidiController(v) => "invalid MIDI controller: \{v}"
    InvalidMidiTempo(v) => "invalid MIDI tempo: \{v}"
    InvalidMidiPPQ(v) => "invalid MIDI PPQ: \{v}"
    MidiExportError(msg) => "MIDI export error: \{msg}"
  }
}

///|
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
pub(all) struct MidiEvent {
  tick : Int
  kind : MidiEventKind
}

///|
pub(all) struct MidiTrack {
  name : String
  program : Int
  channel : Int
  events : Array[MidiEvent]
}

///|
pub(all) struct MidiScore {
  ppq : Int
  tracks : Array[MidiTrack]
}

///|
pub fn validate_midi_note(note : Int) -> Bool {
  note >= MIN_MIDI_NOTE && note <= MAX_MIDI_NOTE
}

///|
pub fn validate_velocity(vel : Int) -> Bool {
  vel >= MIN_VELOCITY && vel <= MAX_VELOCITY
}

///|
pub fn validate_channel(ch : Int) -> Bool {
  ch >= MIN_CHANNEL && ch <= MAX_CHANNEL
}

///|
pub fn validate_program(prog : Int) -> Bool {
  prog >= 0 && prog <= 127
}

///|
pub fn validate_controller(ctrl : Int) -> Bool {
  ctrl >= 0 && ctrl <= 127
}

///|
pub fn validate_tick(tick : Int) -> Bool {
  tick >= 0
}

///|
pub fn validate_ppq(ppq : Int) -> Bool {
  ppq > 0
}

///|
pub fn note_on(
  tick : Int,
  channel : Int,
  note : Int,
  velocity : Int,
) -> Result[MidiEvent, MidiError] {
  if !validate_tick(tick) {
    return Err(InvalidMidiTick(tick))
  }
  if !validate_channel(channel) {
    return Err(InvalidMidiChannel(channel))
  }
  if !validate_midi_note(note) {
    return Err(InvalidMidiNote(note))
  }
  if !validate_velocity(velocity) {
    return Err(InvalidMidiVelocity(velocity))
  }
  Ok({ tick, kind: NoteOn(channel~, note~, velocity~) })
}

///|
pub fn note_off(
  tick : Int,
  channel : Int,
  note : Int,
  velocity : Int,
) -> Result[MidiEvent, MidiError] {
  if !validate_tick(tick) {
    return Err(InvalidMidiTick(tick))
  }
  if !validate_channel(channel) {
    return Err(InvalidMidiChannel(channel))
  }
  if !validate_midi_note(note) {
    return Err(InvalidMidiNote(note))
  }
  if !validate_velocity(velocity) {
    return Err(InvalidMidiVelocity(velocity))
  }
  Ok({ tick, kind: NoteOff(channel~, note~, velocity~) })
}

///|
pub fn program_change(
  tick : Int,
  channel : Int,
  program : Int,
) -> Result[MidiEvent, MidiError] {
  if !validate_tick(tick) {
    return Err(InvalidMidiTick(tick))
  }
  if !validate_channel(channel) {
    return Err(InvalidMidiChannel(channel))
  }
  if !validate_program(program) {
    return Err(InvalidMidiProgram(program))
  }
  Ok({ tick, kind: ProgramChange(channel~, program~) })
}

///|
pub fn control_change(
  tick : Int,
  channel : Int,
  controller : Int,
  value : Int,
) -> Result[MidiEvent, MidiError] {
  if !validate_tick(tick) {
    return Err(InvalidMidiTick(tick))
  }
  if !validate_channel(channel) {
    return Err(InvalidMidiChannel(channel))
  }
  if !validate_controller(controller) {
    return Err(InvalidMidiController(controller))
  }
  if !validate_controller(value) {
    return Err(InvalidMidiController(value))
  }
  Ok({ tick, kind: ControlChange(channel~, controller~, value~) })
}

///|
pub fn tempo_change(tick : Int, bpm : Int) -> Result[MidiEvent, MidiError] {
  if !validate_tick(tick) {
    return Err(InvalidMidiTick(tick))
  }
  if bpm <= 0 {
    return Err(InvalidMidiTempo(bpm))
  }
  Ok({ tick, kind: TempoChange(bpm~) })
}

///|
pub fn track_name(tick : Int, name : String) -> Result[MidiEvent, MidiError] {
  if !validate_tick(tick) {
    return Err(InvalidMidiTick(tick))
  }
  Ok({ tick, kind: TrackName(name~) })
}

///|
pub fn end_of_track(tick : Int) -> Result[MidiEvent, MidiError] {
  if !validate_tick(tick) {
    return Err(InvalidMidiTick(tick))
  }
  Ok({ tick, kind: EndOfTrack })
}

///|
/// 构造 TimeSignatureMeta 事件。
/// tick 必须 >= 0，numerator > 0，denominator 必须是合法拍号分母 (1/2/4/8/16/32/64)。
pub fn midi_time_signature(
  tick : Int,
  numerator : Int,
  denominator : Int,
) -> Result[MidiEvent, MidiError] {
  if !validate_tick(tick) {
    return Err(InvalidMidiTick(tick))
  }
  if !is_valid_time_signature(numerator, denominator) {
    return Err(
      MidiExportError("invalid time signature: \{numerator}/\{denominator}"),
    )
  }
  Ok({ tick, kind: TimeSignatureMeta(numerator~, denominator~) })
}

///|
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
fn event_priority(kind : MidiEventKind) -> Int {
  match kind {
    TrackName(name=_) => 0
    TimeSignatureMeta(numerator=_, denominator=_) => 1
    TempoChange(bpm=_) => 3
    ProgramChange(channel=_, program=_) => 4
    ControlChange(channel=_, controller=_, value=_) => 5
    NoteOff(channel=_, note=_, velocity=_) => 7
    NoteOn(channel=_, note=_, velocity=_) => 8
    EndOfTrack => 13
  }
}

///|
fn validate_midi_event(event : MidiEvent) -> Result[Unit, MidiError] {
  if !validate_tick(event.tick) {
    return Err(InvalidMidiTick(event.tick))
  }
  match event.kind {
    NoteOn(channel=ch, note=n, velocity=v)
    | NoteOff(channel=ch, note=n, velocity=v) => {
      if !validate_channel(ch) {
        return Err(InvalidMidiChannel(ch))
      }
      if !validate_midi_note(n) {
        return Err(InvalidMidiNote(n))
      }
      if !validate_velocity(v) {
        return Err(InvalidMidiVelocity(v))
      }
      Ok(())
    }
    ProgramChange(channel=ch, program=prog) => {
      if !validate_channel(ch) {
        return Err(InvalidMidiChannel(ch))
      }
      if !validate_program(prog) {
        return Err(InvalidMidiProgram(prog))
      }
      Ok(())
    }
    ControlChange(channel=ch, controller=ctrl, value=val) => {
      if !validate_channel(ch) {
        return Err(InvalidMidiChannel(ch))
      }
      if !validate_controller(ctrl) {
        return Err(InvalidMidiController(ctrl))
      }
      if !validate_controller(val) {
        return Err(InvalidMidiController(val))
      }
      Ok(())
    }
    TempoChange(bpm=bpm_val) =>
      if bpm_val <= 0 {
        Err(InvalidMidiTempo(bpm_val))
      } else {
        Ok(())
      }
    TimeSignatureMeta(numerator=num, denominator=den) =>
      if !is_valid_time_signature(num, den) {
        Err(MidiExportError("invalid time signature: \{num}/\{den}"))
      } else {
        Ok(())
      }
    TrackName(name=_) | EndOfTrack => Ok(())
  }
}

///|
pub fn validate_midi_score(score : MidiScore) -> Result[Unit, MidiError] {
  if !validate_ppq(score.ppq) {
    return Err(InvalidMidiPPQ(score.ppq))
  }
  for track in score.tracks {
    if track.program != -1 && !validate_program(track.program) {
      return Err(InvalidMidiProgram(track.program))
    }
    if !validate_channel(track.channel) {
      return Err(InvalidMidiChannel(track.channel))
    }
    for event in track.events {
      match validate_midi_event(event) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
    }
  }
  Ok(())
}

///|
/// 深度校验 MidiScore：ppq > 0、每个轨道至少 1 个事件、每个轨道以 EndOfTrack 结尾。
pub fn validate_midi_file(score : MidiScore) -> Result[Unit, MidiError] {
  if !validate_ppq(score.ppq) {
    return Err(InvalidMidiPPQ(score.ppq))
  }
  if score.tracks.length() == 0 {
    return Err(MidiExportError("MIDI file has no tracks"))
  }
  for track in score.tracks {
    if track.events.length() == 0 {
      return Err(MidiExportError("track '\{track.name}' has no events"))
    }
    if track.program != -1 && !validate_program(track.program) {
      return Err(InvalidMidiProgram(track.program))
    }
    if !validate_channel(track.channel) {
      return Err(InvalidMidiChannel(track.channel))
    }
    for event in track.events {
      match validate_midi_event(event) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
    }
    // 每个轨道必须以 EndOfTrack 结尾
    let last_event = track.events[track.events.length() - 1]
    match last_event.kind {
      EndOfTrack => ()
      _ =>
        return Err(
          MidiExportError("track '\{track.name}' does not end with EndOfTrack"),
        )
    }
  }
  Ok(())
}

///|
pub fn score_to_midi_score(score : Score, ppq : Int) -> MidiScore {
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

  for track in score.tracks {
    let midi_events : Array[MidiEvent] = []
    midi_events.push({
      tick: 0,
      kind: TrackName(name="Track ch=\{track.channel}"),
    })
    if track.program >= 0 {
      midi_events.push({
        tick: 0,
        kind: ProgramChange(channel=track.channel, program=track.program),
      })
    }
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

///|
pub fn score_to_midi_score_checked(
  score : Score,
  ppq : Int,
) -> Result[MidiScore, MidiError] {
  if !validate_ppq(ppq) {
    return Err(InvalidMidiPPQ(ppq))
  }
  if score.tempo.bpm <= 0 {
    return Err(InvalidMidiTempo(score.tempo.bpm))
  }
  let midi_score = score_to_midi_score(score, ppq)
  match validate_midi_score(midi_score) {
    Ok(_) => Ok(midi_score)
    Err(e) => Err(e)
  }
}

///|
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
/// @deprecated Use midi_score_to_bytes_checked instead.
pub fn midi_score_to_bytes(score : MidiScore) -> Bytes {
  match midi_score_to_bytes_checked(score) {
    Ok(bytes) => bytes
    Err(e) => abort(e.to_string())
  }
}

///|
pub fn midi_score_to_bytes_checked(
  score : MidiScore,
) -> Result[Bytes, MidiError] {
  match validate_midi_score(score) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
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
  Ok(@midi.serialize(file))
}

///|
/// @deprecated Use score_to_midi_bytes_checked instead.
pub fn score_to_midi_bytes(score : Score, ppq : Int) -> Bytes {
  match score_to_midi_bytes_checked(score, ppq) {
    Ok(bytes) => bytes
    Err(e) => abort(e.to_string())
  }
}

///|
pub fn score_to_midi_bytes_checked(
  score : Score,
  ppq : Int,
) -> Result[Bytes, MidiError] {
  match score_to_midi_score_checked(score, ppq) {
    Ok(midi_score) => midi_score_to_bytes_checked(midi_score)
    Err(e) => Err(e)
  }
}
