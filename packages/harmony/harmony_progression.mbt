//
// 和声进行 — Roman numeral → 和弦音高数组
//

///|
/// 将罗马数字进行转为和弦音高数组列表。
/// 返回 Array[Array[Pitch]]，每个内层数组是一个和弦的拼写音高。
pub fn roman_progression_checked(
  key : @scale.Key,
  numerals : Array[RomanNumeral],
  base_octave : Int,
) -> Result[Array[Array[@pitch.Pitch]], HarmonyError] {
  if numerals.length() == 0 {
    return Err(EmptyProgression("roman numerals must not be empty"))
  }
  let kind = key.scale_kind()
  let chords = []
  for i = 0; i < numerals.length(); i = i + 1 {
    let rn = numerals[i]
    let degree = roman_to_degree(rn)
    let root = match key.key_degree_checked(degree, base_octave) {
      Ok(p) => p
      Err(_) =>
        return Err(
          InvalidProgression("failed to get degree \{degree} from key"),
        )
    }
    let quality = roman_chord_quality(kind, rn)
    let pitches = @chord.chord_pitches(root, quality)
    chords.push(pitches)
  }
  Ok(chords)
}

///|
/// 从文本解析并生成和声进行。
/// 例如 "I V vi IV" 在 C 大调中返回 C-G-Am-F 四个和弦的音高数组。
pub fn roman_progression_text_checked(
  key : @scale.Key,
  text : String,
  base_octave : Int,
) -> Result[Array[Array[@pitch.Pitch]], HarmonyError] {
  let numerals = parse_roman_text(text)
  roman_progression_checked(key, numerals, base_octave)
}
