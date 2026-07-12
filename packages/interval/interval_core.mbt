///|
pub(all) enum IntervalQuality {
  Perfect
  Major
  Minor
  Augmented
  Diminished
}

///|
pub fn IntervalQuality::to_string(self : IntervalQuality) -> String {
  match self {
    Perfect => "P"
    Major => "M"
    Minor => "m"
    Augmented => "A"
    Diminished => "d"
  }
}

///|
pub(all) struct Interval {
  quality : IntervalQuality
  number : Int
  semitones : Int
}

///|
pub fn interval_between(a : @pitch.Pitch, b : @pitch.Pitch) -> Interval {
  let a_midi = a.to_midi()
  let b_midi = b.to_midi()
  let (low, high) = if a_midi <= b_midi { (a, b) } else { (b, a) }
  let semitones = high.to_midi() - low.to_midi()
  let low_total = low.octave() * 7 + @pitch.class_index(low.pitch_class())
  let high_total = high.octave() * 7 + @pitch.class_index(high.pitch_class())
  let number = high_total - low_total + 1
  let simple_number = if number <= 8 { number } else { (number - 1) % 7 + 1 }
  let octaves = if number <= 8 { 0 } else { (number - 1) / 7 }
  let simple_semitones = semitones - octaves * 12
  {
    quality: determine_quality(simple_number, simple_semitones),
    number,
    semitones,
  }
}

///|
pub fn invert_interval(interval : Interval) -> Interval {
  let new_number = 9 - interval.number
  let new_semitones = 12 - interval.semitones
  let new_quality = match interval.quality {
    Perfect => Perfect
    Major => Minor
    Minor => Major
    Augmented => Diminished
    Diminished => Augmented
  }
  { quality: new_quality, number: new_number, semitones: new_semitones }
}

///|
pub fn parse_interval(input : String) -> Result[Interval, IntervalError] {
  if input.length() < 2 {
    return Err(InvalidInterval("expected interval like M3, m7, P5, A4, or d5"))
  }
  let quality = match input[0] {
    'P' => Perfect
    'M' => Major
    'm' => Minor
    'A' => Augmented
    'd' => Diminished
    _ => return Err(InvalidInterval("unknown interval quality in \{input}"))
  }
  let mut number = 0
  let mut index = 1
  while index < input.length() && input[index] >= '0' && input[index] <= '9' {
    number = number * 10 + (input[index].to_int() - '0'.to_int())
    index = index + 1
  }
  if number <= 0 {
    return Err(InvalidInterval("invalid interval number in \{input}"))
  }
  if index < input.length() {
    return Err(InvalidInterval("trailing characters in \{input}"))
  }
  Ok({ quality, number, semitones: compute_semitones(quality, number) })
}

///|
fn is_perfect_type(simple_number : Int) -> Bool {
  simple_number == 1 ||
  simple_number == 4 ||
  simple_number == 5 ||
  simple_number == 8
}

///|
fn base_semitones_for_number(simple_number : Int) -> Int {
  match simple_number {
    1 => 0
    2 => 2
    3 => 4
    4 => 5
    5 => 7
    6 => 9
    7 => 11
    8 => 12
    _ => 0
  }
}

///|
fn determine_quality(
  simple_number : Int,
  simple_semitones : Int,
) -> IntervalQuality {
  let base = base_semitones_for_number(simple_number)
  let diff = simple_semitones - base
  if is_perfect_type(simple_number) {
    if diff == 0 {
      Perfect
    } else if diff > 0 {
      Augmented
    } else {
      Diminished
    }
  } else if diff == 0 {
    Major
  } else if diff == -1 {
    Minor
  } else if diff == 1 {
    Augmented
  } else {
    Diminished
  }
}

///|
fn compute_semitones(quality : IntervalQuality, number : Int) -> Int {
  let octaves = (number - 1) / 7
  let simple_number = if number <= 7 { number } else { (number - 1) % 7 + 1 }
  let base = base_semitones_for_number(simple_number)
  let simple_semitones = if is_perfect_type(simple_number) {
    match quality {
      Perfect => base
      Augmented => base + 1
      Diminished => base - 1
      _ => base
    }
  } else {
    match quality {
      Major => base
      Minor => base - 1
      Augmented => base + 1
      Diminished => base - 2
      _ => base
    }
  }
  simple_semitones + octaves * 12
}
