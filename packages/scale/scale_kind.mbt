//
// 音阶种类 — ScaleKind 枚举及音程模式
//

///|
pub(all) enum ScaleKind {
  Major
  NaturalMinor
  MajorPentatonic
  MinorPentatonic
  HarmonicMinor
  MelodicMinor
  Dorian
  Phrygian
  Lydian
  Mixolydian
  Locrian
  Chromatic
}

///|
pub fn ScaleKind::intervals(self : ScaleKind) -> Array[Int] {
  match self {
    Major => [0, 2, 4, 5, 7, 9, 11]
    NaturalMinor => [0, 2, 3, 5, 7, 8, 10]
    MajorPentatonic => [0, 2, 4, 7, 9]
    MinorPentatonic => [0, 3, 5, 7, 10]
    HarmonicMinor => [0, 2, 3, 5, 7, 8, 11]
    MelodicMinor => [0, 2, 3, 5, 7, 9, 11]
    Dorian => [0, 2, 3, 5, 7, 9, 10]
    Phrygian => [0, 1, 3, 5, 7, 8, 10]
    Lydian => [0, 2, 4, 6, 7, 9, 11]
    Mixolydian => [0, 2, 4, 5, 7, 9, 10]
    Locrian => [0, 1, 3, 5, 6, 8, 10]
    Chromatic => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  }
}
