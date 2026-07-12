// Shared pitch-class letter ordering helpers.

///|
pub fn class_index(pc : PitchClass) -> Int {
  match pc {
    C => 0
    D => 1
    E => 2
    F => 3
    G => 4
    A => 5
    B => 6
  }
}

///|
pub fn class_from_index(idx : Int) -> PitchClass {
  let m = idx % 7
  match m {
    0 => C
    1 => D
    2 => E
    3 => F
    4 => G
    5 => A
    6 => B
    _ => C
  }
}
