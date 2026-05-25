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

// --- checked frequency 转换 (v2 stabilization) ---

///|
/// Safe frequency conversion. Validates that the pitch is within MIDI range (0..127).
/// Returns the frequency in Hz.
pub fn pitch_to_frequency_checked(pitch : Pitch) -> Result[Double, TheoryError] {
  let midi = pitch.to_midi()
  if !is_valid_midi_note(midi) {
    Err(MidiOutOfRange(midi))
  } else {
    Ok(midi_to_frequency(midi))
  }
}

///|
/// Safe frequency-to-nearest-MIDI-note conversion.
/// Uses linear search over MIDI 0..127 to find the closest note.
/// Returns InvalidFrequency when hz <= 0.0.
pub fn frequency_to_nearest_midi_checked(
  hz : Double,
) -> Result[Int, TheoryError] {
  if hz <= 0.0 {
    Err(InvalidFrequency(hz))
  } else if hz <= midi_to_frequency(MIN_MIDI_NOTE) {
    Ok(MIN_MIDI_NOTE)
  } else if hz >= midi_to_frequency(MAX_MIDI_NOTE) {
    Ok(MAX_MIDI_NOTE)
  } else {
    let mut best_midi = 0
    let mut best_diff = (hz - midi_to_frequency(0)).abs()
    for midi = 1; midi <= MAX_MIDI_NOTE; midi = midi + 1 {
      let freq = midi_to_frequency(midi)
      let diff = (hz - freq).abs()
      if diff < best_diff {
        best_diff = diff
        best_midi = midi
      }
    }
    Ok(best_midi)
  }
}
