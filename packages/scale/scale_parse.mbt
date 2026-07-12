//
// Scale parsing
//

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
) -> Result[(ScaleKind, Int), ScaleError] {
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
  } else if match_at(input, pos, "ionian") {
    Ok((Major, pos + "ionian".length()))
  } else if match_at(input, pos, "minor") {
    Ok((NaturalMinor, pos + "minor".length()))
  } else if match_at(input, pos, "aeolian") {
    Ok((NaturalMinor, pos + "aeolian".length()))
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
/// Parse scale strings such as "C major", "F# major", "Bb minor", or "D dorian".
pub fn parse_scale(input : String) -> Result[Scale, ScaleError] {
  let trimmed = input.trim().to_owned()
  if trimmed.length() == 0 {
    return Err(InvalidScale("empty scale string"))
  }
  let root_class = match trimmed[0] {
    'C' => @pitch.C
    'D' => @pitch.D
    'E' => @pitch.E
    'F' => @pitch.F
    'G' => @pitch.G
    'A' => @pitch.A
    'B' => @pitch.B
    _ => return Err(InvalidScale("invalid scale root: \{input}"))
  }
  let mut pos = 1
  let mut accidental = @pitch.Natural
  if pos < trimmed.length() && (trimmed[pos] == '#' || trimmed[pos] == 'b') {
    accidental = if trimmed[pos] == '#' { @pitch.Sharp } else { @pitch.Flat }
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
