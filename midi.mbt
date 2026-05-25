// MIDI-facing convenience methods.
//
// The semantic MIDI event model and checked byte export live in
// score_midi.mbt. This file keeps the older method-style API as a thin
// compatibility layer so there is only one MIDI sorting/export path.

///|
pub fn midi_to_frequency(midi : Int) -> Double {
  let exponent = (midi - A4_MIDI).to_double() / 12.0
  A4_FREQ * pow2(exponent)
}

///|
pub fn Pitch::frequency(self : Pitch) -> Double {
  midi_to_frequency(self.to_midi())
}

///|
pub fn NoteEvent::frequency(self : NoteEvent) -> Double {
  midi_to_frequency(self.midi_note)
}

///|
fn pow2(exp : Double) -> Double {
  let ln2 = 0.6931471805599453
  @math.exp(exp * ln2)
}

///|
pub fn Score::to_midi_bytes(self : Score) -> Bytes {
  self.to_midi_bytes_with_ppq(DEFAULT_PPQ)
}

///|
/// Legacy throwing MIDI export. Prefer `to_midi_bytes_with_ppq_checked`.
pub fn Score::to_midi_bytes_with_ppq(self : Score, ppq : Int) -> Bytes {
  match self.to_midi_bytes_with_ppq_checked(ppq) {
    Ok(bytes) => bytes
    Err(e) => abort(e.to_string())
  }
}

///|
/// Result-returning MIDI export. Prefer this in library-facing code.
pub fn Score::to_midi_bytes_with_ppq_checked(
  self : Score,
  ppq : Int,
) -> Result[Bytes, MidiError] {
  score_to_midi_bytes_checked(self, ppq)
}
