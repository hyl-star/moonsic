//
// Scale core — Scale struct, build_scale, spelling helpers
//

///|
/// A scale keeps the legacy natural-letter view (`tones`) and the v1 spelling-aware view (`spelled_tones`).
pub(all) struct Scale {
  root : @pitch.PitchClass
  root_accidental : @pitch.Accidental
  scale_type : ScaleKind
  tones : Array[@pitch.PitchClass]
  spelled_tones : Array[@pitch.Pitch]
}

///|
fn spell_pitch_for_class(midi : Int, cls : @pitch.PitchClass) -> @pitch.Pitch {
  let mut octave = midi / 12 - 1
  let mut natural_midi = (octave + 1) * 12 + cls.base_semitone()
  let mut diff = midi - natural_midi
  if diff > 6 {
    octave = octave + 1
    natural_midi = (octave + 1) * 12 + cls.base_semitone()
    diff = midi - natural_midi
  } else if diff < -6 {
    octave = octave - 1
    natural_midi = (octave + 1) * 12 + cls.base_semitone()
    diff = midi - natural_midi
  }
  let accidental = match diff {
    -2 => @pitch.DoubleFlat
    -1 => @pitch.Flat
    0 => @pitch.Natural
    1 => @pitch.Sharp
    2 => @pitch.DoubleSharp
    _ => @pitch.Natural
  }
  @pitch.pitch(cls, accidental, octave)
}

///|
pub fn build_scale(root : @pitch.PitchClass, scale_type : ScaleKind) -> Scale {
  build_scale_spelled(root, @pitch.Natural, scale_type)
}

///|
/// Build a scale with accidental-aware spelling. Pitches use octave 4.
pub fn build_scale_spelled(
  root : @pitch.PitchClass,
  accidental : @pitch.Accidental,
  scale_type : ScaleKind,
) -> Scale {
  let intervals = scale_type.intervals()
  let root_idx = @pitch.class_index(root)
  let root_midi = @pitch.pitch(root, accidental, 4).to_midi()
  let tones = []
  let spelled_tones = []
  for i = 0; i < intervals.length(); i = i + 1 {
    let letter_idx = (root_idx + i) % 7
    let cls = @pitch.class_from_index(letter_idx)
    tones.push(cls)
    spelled_tones.push(spell_pitch_for_class(root_midi + intervals[i], cls))
  }
  { root, root_accidental: accidental, scale_type, tones, spelled_tones }
}
