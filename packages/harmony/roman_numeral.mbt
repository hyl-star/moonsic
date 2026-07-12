//
// 罗马数字 — RomanNumeral 枚举 + 文本解析 + 进行生成
//

///|
pub(all) enum RomanNumeral {
  I
  II
  III
  IV
  V
  VI
  VII
}

///|
/// 罗马数字 → 音级度数
fn roman_to_degree(rn : RomanNumeral) -> Int {
  match rn {
    I => 1
    II => 2
    III => 3
    IV => 4
    V => 5
    VI => 6
    VII => 7
  }
}

///|
/// 判断罗马数字在指定调中是大三和弦
fn is_major_in_key(kind : @scale.ScaleKind, rn : RomanNumeral) -> Bool {
  match kind {
    @scale.Major =>
      match rn {
        I | IV | V => true
        _ => false
      }
    @scale.NaturalMinor =>
      match rn {
        III | VI | VII => true
        _ => false
      }
    _ =>
      match rn {
        I | IV | V => true
        _ => false
      }
  }
}

///|
/// 判断罗马数字在指定调中是减三和弦
fn is_dim_in_key(kind : @scale.ScaleKind, rn : RomanNumeral) -> Bool {
  match kind {
    @scale.Major =>
      match rn {
        VII => true
        _ => false
      }
    @scale.NaturalMinor =>
      match rn {
        II => true
        _ => false
      }
    _ => false
  }
}

///|
/// 罗马数字在指定调中的和弦品质
pub fn roman_chord_quality(
  kind : @scale.ScaleKind,
  rn : RomanNumeral,
) -> @chord.ChordQuality {
  if is_dim_in_key(kind, rn) {
    @chord.DiminishedTriad
  } else if is_major_in_key(kind, rn) {
    @chord.MajorTriad
  } else {
    @chord.MinorTriad
  }
}

///|
/// 解析 "I vi IV V" 文本
pub fn parse_roman_text(text : String) -> Array[RomanNumeral] {
  let numerals = []
  let len = text.length()
  let mut i = 0
  while i < len {
    if text[i] == ' ' {
      i = i + 1
      continue
    }
    if text[i] == 'I' {
      if i + 1 < len && text[i + 1] == 'V' {
        numerals.push(IV)
        i = i + 2
      } else if i + 2 < len && text[i + 1] == 'I' && text[i + 2] == 'I' {
        numerals.push(III)
        i = i + 3
      } else if i + 1 < len && text[i + 1] == 'I' {
        numerals.push(II)
        i = i + 2
      } else {
        numerals.push(I)
        i = i + 1
      }
    } else if text[i] == 'V' {
      if i + 2 < len && text[i + 1] == 'I' && text[i + 2] == 'I' {
        numerals.push(VII)
        i = i + 3
      } else if i + 1 < len && text[i + 1] == 'I' {
        numerals.push(VI)
        i = i + 2
      } else {
        numerals.push(V)
        i = i + 1
      }
    } else if text[i] >= 'a' && text[i] <= 'z' {
      if text[i] == 'i' {
        if i + 1 < len && text[i + 1] == 'v' {
          numerals.push(IV)
          i = i + 2
        } else if i + 2 < len && text[i + 1] == 'i' && text[i + 2] == 'i' {
          numerals.push(III)
          i = i + 3
        } else if i + 1 < len && text[i + 1] == 'i' {
          numerals.push(II)
          i = i + 2
        } else {
          numerals.push(I)
          i = i + 1
        }
      } else if text[i] == 'v' {
        if i + 2 < len && text[i + 1] == 'i' && text[i + 2] == 'i' {
          numerals.push(VII)
          i = i + 3
        } else if i + 1 < len && text[i + 1] == 'i' {
          numerals.push(VI)
          i = i + 2
        } else {
          numerals.push(V)
          i = i + 1
        }
      }
    } else {
      i = i + 1
    }
  }
  numerals
}
