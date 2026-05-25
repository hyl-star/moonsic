// Scale structure and parsing.

///|
/// A scale keeps the legacy natural-letter view (`tones`) and the v1 spelling-aware view (`spelled_tones`).
pub(all) struct Scale {
  root : PitchClass
  root_accidental : Accidental
  scale_type : ScaleKind
  tones : Array[PitchClass]
  spelled_tones : Array[Pitch]
}

///|
fn match_at(s : String, pos : Int, target : String) -> Bool {
  let len = target.length()
  if pos + len > s.length() {
    return false
  }
  let mut i = 0
  while i < len {
    if s[pos + i] != target[i] {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn skip_scale_spaces(s : String, pos : Int) -> Int {
  let mut p = pos
  while p < s.length() && (s[p] == ' ' || s[p] == '\t') {
    p = p + 1
  }
  p
}

///|
fn parse_scale_kind_at(
  input : String,
  pos : Int,
) -> Result[(ScaleKind, Int), TheoryError] {
  if match_at(input, pos, "major pentatonic") {
    Ok((MajorPentatonic, pos + "major pentatonic".length()))
  } else if match_at(input, pos, "minor pentatonic") {
    Ok((MinorPentatonic, pos + "minor pentatonic".length()))
  } else if match_at(input, pos, "harmonic minor") {
    Ok((HarmonicMinor, pos + "harmonic minor".length()))
  } else if match_at(input, pos, "melodic minor") {
    Ok((MelodicMinor, pos + "melodic minor".length()))
  } else if match_at(input, pos, "natural minor") {
    Ok((NaturalMinor, pos + "natural minor".length()))
  } else if match_at(input, pos, "major") {
    Ok((Major, pos + "major".length()))
  } else if match_at(input, pos, "minor") {
    Ok((NaturalMinor, pos + "minor".length()))
  } else if match_at(input, pos, "dorian") {
    Ok((Dorian, pos + "dorian".length()))
  } else if match_at(input, pos, "phrygian") {
    Ok((Phrygian, pos + "phrygian".length()))
  } else if match_at(input, pos, "lydian") {
    Ok((Lydian, pos + "lydian".length()))
  } else if match_at(input, pos, "mixolydian") {
    Ok((Mixolydian, pos + "mixolydian".length()))
  } else if match_at(input, pos, "locrian") {
    Ok((Locrian, pos + "locrian".length()))
  } else if match_at(input, pos, "chromatic") {
    Ok((Chromatic, pos + "chromatic".length()))
  } else {
    Err(InvalidScale("unknown scale type: \{input}"))
  }
}

///|
fn spell_pitch_for_class(midi : Int, cls : PitchClass) -> Pitch {
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
    -2 => DoubleFlat
    -1 => Flat
    0 => Natural
    1 => Sharp
    2 => DoubleSharp
    _ => Natural
  }
  pitch(cls, accidental, octave)
}

///|
pub fn build_scale(root : PitchClass, scale_type : ScaleKind) -> Scale {
  build_scale_spelled(root, Natural, scale_type)
}

///|
/// Build a scale with accidental-aware spelling. Pitches use octave 4.
pub fn build_scale_spelled(
  root : PitchClass,
  accidental : Accidental,
  scale_type : ScaleKind,
) -> Scale {
  let intervals = scale_type.intervals()
  let root_idx = class_index(root)
  let root_midi = pitch(root, accidental, 4).to_midi()
  let tones = []
  let spelled_tones = []
  for i = 0; i < intervals.length(); i = i + 1 {
    let letter_idx = (root_idx + i) % 7
    let cls = class_from_index(letter_idx)
    tones.push(cls)
    spelled_tones.push(spell_pitch_for_class(root_midi + intervals[i], cls))
  }
  { root, root_accidental: accidental, scale_type, tones, spelled_tones }
}

///|
/// Parse scale strings such as "C major", "F# major", "Bb minor", or "D dorian".
pub fn parse_scale(input : String) -> Result[Scale, TheoryError] {
  let trimmed = input.trim().to_owned()
  if trimmed.length() == 0 {
    return Err(InvalidScale("empty scale string"))
  }
  let root_class = match trimmed[0] {
    'C' => C
    'D' => D
    'E' => E
    'F' => F
    'G' => G
    'A' => A
    'B' => B
    _ => return Err(InvalidScale("invalid scale root: \{input}"))
  }
  let mut pos = 1
  let mut accidental = Natural
  if pos < trimmed.length() && (trimmed[pos] == '#' || trimmed[pos] == 'b') {
    accidental = if trimmed[pos] == '#' { Sharp } else { Flat }
    pos = pos + 1
  }
  pos = skip_scale_spaces(trimmed, pos)
  let (scale_type, end_pos) = match parse_scale_kind_at(trimmed, pos) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let final_pos = skip_scale_spaces(trimmed, end_pos)
  if final_pos != trimmed.length() {
    return Err(
      InvalidScale(
        "trailing scale suffix: \{trimmed[final_pos:trimmed.length()].to_owned()}",
      ),
    )
  }
  Ok(build_scale_spelled(root_class, accidental, scale_type))
}
