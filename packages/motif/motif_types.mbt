///|
pub(all) enum MotifTransform {
  TransposeDegrees(Int)
  InvertAround(Int)
  Retrograde
  Augment
  Diminish
  Rotate(Int)
  Repeat(Int)
  KeepRhythmChangeDegrees(Array[Int])
  KeepDegreesChangeRhythm(@rhythm.RhythmPattern)
}

///|
pub(all) enum MotifVariationStrategy {
  ExactRepeat
  SequenceUp
  SequenceDown
  Inversion
  RetrogradeVariation
  RhythmicAugmentation
  RhythmicDiminution
  CallResponse
}

///|
pub(all) struct MotifEvent {
  degree : Int
  cell : @rhythm.RhythmCell
}

///|
pub(all) struct Motif {
  events : Array[MotifEvent]
  total_beats : Double
}

///|
fn motif_events_beats(events : Array[MotifEvent]) -> Double {
  let mut total = 0.0
  for event in events {
    match @time.rhythm_duration_to_fraction_checked(event.cell.duration) {
      Ok(fraction) => total = total + @time.rational_to_double(fraction)
      Err(_) => ()
    }
  }
  total
}

///|
fn stretch_duration(
  duration : @time.RhythmDuration,
  factor : Double,
) -> @time.RhythmDuration {
  let beats = match @time.rhythm_duration_to_fraction_checked(duration) {
    Ok(fraction) => @time.rational_to_double(fraction) * factor
    Err(_) => 1.0
  }
  duration_from_beats(beats)
}

///|
fn duration_from_beats(beats : Double) -> @time.RhythmDuration {
  if beats >= 3.75 {
    @time.rhythm_duration(@time.DurWhole, 0, None)
  } else if beats >= 2.75 {
    @time.rhythm_duration(@time.DurHalf, 1, None)
  } else if beats >= 1.75 {
    @time.rhythm_duration(@time.DurHalf, 0, None)
  } else if beats >= 1.25 {
    @time.rhythm_duration(@time.DurQuarter, 1, None)
  } else if beats >= 0.75 {
    @time.rhythm_duration(@time.DurQuarter, 0, None)
  } else if beats >= 0.375 {
    @time.rhythm_duration(@time.DurEighth, 0, None)
  } else {
    @time.rhythm_duration(@time.DurSixteenth, 0, None)
  }
}
