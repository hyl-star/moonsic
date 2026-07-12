// ============================================================
// MIDI event types + checked constructors
// ============================================================

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

// --- validators ---

///|
fn validate_tick(tick : Int) -> Bool {
  tick >= 0
}

///|
fn validate_channel(ch : Int) -> Bool {
  ch >= 0 && ch <= 15
}

///|
fn validate_midi_note(note : Int) -> Bool {
  note >= 0 && note <= 127
}

///|
fn validate_velocity(vel : Int) -> Bool {
  vel >= 0 && vel <= 127
}

///|
fn validate_program(prog : Int) -> Bool {
  prog >= 0 && prog <= 127
}

///|
fn validate_controller(ctrl : Int) -> Bool {
  ctrl >= 0 && ctrl <= 127
}

// --- constructors ---

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
pub fn midi_time_signature(
  tick : Int,
  numerator : Int,
  denominator : Int,
) -> Result[MidiEvent, MidiError] {
  if !validate_tick(tick) {
    return Err(InvalidMidiTick(tick))
  }
  if !@time.is_valid_time_signature(numerator, denominator) {
    return Err(
      MidiExportError("invalid time signature: \{numerator}/\{denominator}"),
    )
  }
  Ok({ tick, kind: TimeSignatureMeta(numerator~, denominator~) })
}
