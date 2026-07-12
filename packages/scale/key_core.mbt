//
// Key — 调性与拼写，Key 类型 + 调号感知拼写表
//

///|
pub(all) struct Key {
  tonic : @pitch.Pitch
  kind : ScaleKind
}

///|
pub fn key(tonic : @pitch.Pitch, kind : ScaleKind) -> Key {
  { tonic, kind }
}

///|
pub fn Key::tonic_pitch(self : Key) -> @pitch.Pitch {
  self.tonic
}

///|
pub fn Key::scale_kind(self : Key) -> ScaleKind {
  self.kind
}

///|
/// 调号拼写表：index 0=I, 1=II, ..., 6=VII
fn key_spelling(tonic_midi : Int) -> Array[@pitch.Accidental] {
  let ts = tonic_midi % 12
  match ts {
    // Sharp 调
    0 =>
      [
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
      ] // C
    7 =>
      [
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Sharp,
      ] // G:F#
    2 =>
      [
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Sharp,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Sharp,
      ] // D:F#C#
    9 =>
      [
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Sharp,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Sharp,
        @pitch.Sharp,
      ] // A:F#C#G#
    4 =>
      [
        @pitch.Natural,
        @pitch.Sharp,
        @pitch.Sharp,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Sharp,
        @pitch.Sharp,
      ] // E:F#C#G#D#
    11 =>
      [
        @pitch.Sharp,
        @pitch.Sharp,
        @pitch.Sharp,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Sharp,
        @pitch.Sharp,
      ] // B:F#C#G#D#A#
    6 =>
      [
        @pitch.Sharp,
        @pitch.Sharp,
        @pitch.Sharp,
        @pitch.Natural,
        @pitch.Sharp,
        @pitch.Sharp,
        @pitch.Sharp,
      ] // F#:F#G#A#BC#D#E#
    // Flat 调
    5 =>
      [
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Flat,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
      ] // F:Bb
    10 =>
      [
        @pitch.Flat,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Flat,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
      ] // Bb:BbEb
    3 =>
      [
        @pitch.Flat,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Flat,
        @pitch.Flat,
        @pitch.Natural,
        @pitch.Natural,
      ] // Eb:BbEbAb
    8 =>
      [
        @pitch.Flat,
        @pitch.Flat,
        @pitch.Natural,
        @pitch.Flat,
        @pitch.Flat,
        @pitch.Natural,
        @pitch.Natural,
      ] // Ab:BbEbAbDb
    1 =>
      [
        @pitch.Flat,
        @pitch.Flat,
        @pitch.Natural,
        @pitch.Flat,
        @pitch.Flat,
        @pitch.Flat,
        @pitch.Natural,
      ] // Db:BbEbAbDbGb
    _ =>
      [
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
        @pitch.Natural,
      ]
  }
}

///|
/// @deprecated Use key_degree_checked instead.
/// Legacy degree accessor. Aborts on invalid input.
pub fn Key::degree(self : Key, deg : Int, base_octave : Int) -> @pitch.Pitch {
  match self.key_degree_checked(deg, base_octave) {
    Ok(p) => p
    Err(e) => abort(e.to_string())
  }
}

///|
/// Checked key-aware scale degree accessor.
/// Returns the pitch for a given scale degree (1-based), respecting the key's
/// spelling (accidentals from the key signature).
pub fn Key::key_degree_checked(
  self : Key,
  deg : Int,
  base_octave : Int,
) -> Result[@pitch.Pitch, ScaleError] {
  if deg <= 0 {
    return Err(InvalidDegree("scale degree must be > 0, got \{deg}"))
  }
  let intervals = self.kind.intervals()
  let spellings = key_spelling(self.tonic.to_midi())
  let idx = (deg - 1) % intervals.length()
  let tonic_class_idx = match self.tonic.pitch_class() {
    @pitch.C => 0
    @pitch.D => 1
    @pitch.E => 2
    @pitch.F => 3
    @pitch.G => 4
    @pitch.A => 5
    @pitch.B => 6
  }
  let class_idx = (tonic_class_idx + idx) % 7
  let class = match class_idx {
    0 => @pitch.C
    1 => @pitch.D
    2 => @pitch.E
    3 => @pitch.F
    4 => @pitch.G
    5 => @pitch.A
    6 => @pitch.B
    _ => @pitch.C
  }
  let accidental = if idx < spellings.length() {
    spellings[idx]
  } else {
    @pitch.Natural
  }
  let letter_wrap = (tonic_class_idx + idx) / 7
  let degree_octave = (deg - 1) / intervals.length()
  let target_octave = base_octave + letter_wrap + degree_octave
  Ok(@pitch.pitch(class, accidental, target_octave))
}

///|
pub fn Key::scale(self : Key, octave : Int, count : Int) -> Array[@pitch.Pitch] {
  let n = self.kind.intervals().length()
  let pitches = []
  for i = 1; i <= count * n; i = i + 1 {
    pitches.push(self.degree(i, octave))
  }
  pitches
}
