//
// TimeSignature — 拍号类型（v2 time 包内联，不依赖 score 包）
//

///|
/// 拍号，如 4/4, 3/4, 6/8
pub(all) struct TimeSignature {
  numerator : Int
  denominator : Int
}

///|
pub fn time_signature(numerator : Int, denominator : Int) -> TimeSignature {
  { numerator, denominator }
}

///|
pub fn four_four() -> TimeSignature {
  { numerator: 4, denominator: 4 }
}

///|
/// 每小节的拍数
pub fn TimeSignature::measure_beats(self : TimeSignature) -> Double {
  self.numerator.to_double() * (4.0 / self.denominator.to_double())
}

///|
pub fn TimeSignature::to_string(self : TimeSignature) -> String {
  "\{self.numerator}/\{self.denominator}"
}

///|
pub fn is_valid_time_signature(numerator : Int, denominator : Int) -> Bool {
  if numerator <= 0 {
    return false
  }
  match denominator {
    1 | 2 | 4 | 8 | 16 | 32 | 64 => true
    _ => false
  }
}
