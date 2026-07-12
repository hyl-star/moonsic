// ============================================================
// MidiError — v2 MIDI 包错误类型
// ============================================================

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
  MidiImportError(String)
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
    MidiImportError(msg) => "MIDI import error: \{msg}"
  }
}
