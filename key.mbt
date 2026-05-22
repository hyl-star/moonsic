// ============================================================
// v3 调性与拼写 — Key 类型 + 调号感知拼写表
// ============================================================

///|
pub(all) struct Key {
  tonic : Pitch
  kind : ScaleKind
}

///|
pub fn key(tonic : Pitch, kind : ScaleKind) -> Key {
  { tonic, kind }
}

///|
pub fn Key::tonic_pitch(self : Key) -> Pitch {
  self.tonic
}

///|
pub fn Key::scale_kind(self : Key) -> ScaleKind {
  self.kind
}

///|
/// 调号拼写表：index 0=I, 1=II, ..., 6=VII
fn key_spelling(tonic_midi : Int) -> Array[Accidental] {
  let ts = tonic_midi % 12
  match ts {
    // Sharp 调
    0 => [Natural, Natural, Natural, Natural, Natural, Natural, Natural] // C
    7 => [Natural, Natural, Natural, Natural, Natural, Natural, Sharp] // G:F#
    2 => [Natural, Natural, Sharp, Natural, Natural, Natural, Sharp] // D:F#C#
    9 => [Natural, Natural, Sharp, Natural, Natural, Sharp, Sharp] // A:F#C#G#
    4 => [Natural, Sharp, Sharp, Natural, Natural, Sharp, Sharp] // E:F#C#G#D#
    11 => [Sharp, Sharp, Sharp, Natural, Natural, Sharp, Sharp] // B:F#C#G#D#A#
    // Flat 调
    5 => [Natural, Natural, Natural, Flat, Natural, Natural, Natural] // F:Bb
    10 => [Flat, Natural, Natural, Flat, Natural, Natural, Natural] // Bb:BbEb
    3 => [Flat, Natural, Natural, Flat, Flat, Natural, Natural] // Eb:BbEbAb
    8 => [Flat, Flat, Natural, Flat, Flat, Natural, Natural] // Ab:BbEbAbDb
    1 => [Flat, Flat, Natural, Flat, Flat, Flat, Natural] // Db:BbEbAbDbGb
    _ => [Natural, Natural, Natural, Natural, Natural, Natural, Natural]
  }
}

///|
pub fn Key::degree(self : Key, deg : Int, base_octave : Int) -> Pitch {
  let intervals = self.kind.intervals()
  let spellings = key_spelling(self.tonic.to_midi())
  let octave_shift = (deg - 1) / intervals.length()
  let idx = (deg - 1) % intervals.length()
  // 音名由音级决定（1=F, 2=G, 3=A, 4=B, ...）
  let tonic_class_idx = match self.tonic.class {
    C => 0
    D => 1
    E => 2
    F => 3
    G => 4
    A => 5
    B => 6
  }
  let class_idx = (tonic_class_idx + idx) % 7
  let class = match class_idx {
    0 => C
    1 => D
    2 => E
    3 => F
    4 => G
    5 => A
    6 => B
    _ => C
  }
  let accidental = if idx < spellings.length() {
    spellings[idx]
  } else {
    Natural
  }
  let target_octave = base_octave + octave_shift
  pitch(class, accidental, target_octave)
}

///|
pub fn Key::scale(self : Key, octave : Int, count : Int) -> Array[Pitch] {
  let n = self.kind.intervals().length()
  let pitches = []
  for i = 1; i <= count * n; i = i + 1 {
    pitches.push(self.degree(i, octave))
  }
  pitches
}
