// ============================================================
// v1.5 音高快捷构造 — 让简单旋律更短
// ============================================================

// --- 音高快捷构造 ---

///|
/// 自然音高快捷构造：c(4) = pitch(C, Natural, 4)
pub fn c(octave : Int) -> Pitch {
  pitch(C, Natural, octave)
}

///|
pub fn d(octave : Int) -> Pitch {
  pitch(D, Natural, octave)
}

///|
pub fn e(octave : Int) -> Pitch {
  pitch(E, Natural, octave)
}

///|
pub fn f(octave : Int) -> Pitch {
  pitch(F, Natural, octave)
}

///|
pub fn g(octave : Int) -> Pitch {
  pitch(G, Natural, octave)
}

///|
pub fn a(octave : Int) -> Pitch {
  pitch(A, Natural, octave)
}

///|
pub fn b(octave : Int) -> Pitch {
  pitch(B, Natural, octave)
}

// --- 升号快捷构造 ---

///|
/// 升号音高：cs(4) = pitch(C, Sharp, 4) = C#4
pub fn cs(octave : Int) -> Pitch {
  pitch(C, Sharp, octave)
}

///|
pub fn ds(octave : Int) -> Pitch {
  pitch(D, Sharp, octave)
}

///|
pub fn fs(octave : Int) -> Pitch {
  pitch(F, Sharp, octave)
}

///|
pub fn gs(octave : Int) -> Pitch {
  pitch(G, Sharp, octave)
}

///|
// as(octave) 因 as 是 MoonBit 关键字，v1.5 不提供。请用 pitch(A, Sharp, octave)

// --- 降号快捷构造 ---

///|
/// 降号音高：db(4) = pitch(D, Flat, 4) = Db4
pub fn db(octave : Int) -> Pitch {
  pitch(D, Flat, octave)
}

///|
pub fn eb(octave : Int) -> Pitch {
  pitch(E, Flat, octave)
}

///|
pub fn gb(octave : Int) -> Pitch {
  pitch(G, Flat, octave)
}

///|
pub fn ab(octave : Int) -> Pitch {
  pitch(A, Flat, octave)
}

///|
pub fn bb(octave : Int) -> Pitch {
  pitch(B, Flat, octave)
}
