// MIDI-facing convenience methods.
//
// The semantic MIDI event model and checked byte export live in
// score_midi.mbt. This file keeps the older method-style API as a thin
// compatibility layer so there is only one MIDI sorting/export path.

///|
pub fn NoteEvent::frequency(self : NoteEvent) -> Double {
  midi_to_frequency(self.midi_note)
}

///|
pub fn Score::to_midi_bytes(self : Score) -> Bytes {
  self.to_midi_bytes_with_ppq(DEFAULT_PPQ)
}

///|
/// @deprecated Use to_midi_bytes_with_ppq_checked instead.
/// Legacy throwing MIDI export.
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
