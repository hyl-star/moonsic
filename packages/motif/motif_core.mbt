///|
pub fn motif_checked(
  degrees : Array[Int],
  rhythm : @rhythm.RhythmPattern,
) -> Result[Motif, MotifError] {
  if degrees.length() == 0 {
    return Err(EmptyMotif("degrees cannot be empty"))
  }
  if rhythm.cells.length() == 0 {
    return Err(EmptyMotif("rhythm cells cannot be empty"))
  }
  if degrees.length() != rhythm.cells.length() {
    return Err(InvalidMotif("degrees and rhythm cells length mismatch"))
  }
  let events : Array[MotifEvent] = []
  for i = 0; i < degrees.length(); i = i + 1 {
    events.push({ degree: degrees[i], cell: rhythm.cells[i] })
  }
  Ok({ events, total_beats: motif_events_beats(events) })
}

///|
pub fn motif(degrees : Array[Int], rhythm : @rhythm.RhythmPattern) -> Motif {
  match motif_checked(degrees, rhythm) {
    Ok(result) => result
    Err(_) => {
      let limit = if degrees.length() < rhythm.cells.length() {
        degrees.length()
      } else {
        rhythm.cells.length()
      }
      let events : Array[MotifEvent] = []
      for i = 0; i < limit; i = i + 1 {
        events.push({ degree: degrees[i], cell: rhythm.cells[i] })
      }
      { events, total_beats: motif_events_beats(events) }
    }
  }
}

///|
pub fn transform_motif_checked(
  motif : Motif,
  transform : MotifTransform,
) -> Result[Motif, MotifError] {
  if motif.events.length() == 0 {
    return Err(EmptyMotif("motif events cannot be empty"))
  }
  match transform {
    TransposeDegrees(offset) => {
      let events : Array[MotifEvent] = []
      for event in motif.events {
        events.push({ degree: event.degree + offset, cell: event.cell })
      }
      Ok({ events, total_beats: motif.total_beats })
    }
    InvertAround(axis) => {
      let events : Array[MotifEvent] = []
      for event in motif.events {
        events.push({ degree: 2 * axis - event.degree, cell: event.cell })
      }
      Ok({ events, total_beats: motif.total_beats })
    }
    Retrograde => {
      let events : Array[MotifEvent] = []
      let count = motif.events.length()
      for i = 0; i < count; i = i + 1 {
        events.push(motif.events[count - 1 - i])
      }
      Ok({ events, total_beats: motif.total_beats })
    }
    Augment => stretch_motif_checked(motif, 2.0)
    Diminish => stretch_motif_checked(motif, 0.5)
    Rotate(offset) => rotate_motif_checked(motif, offset)
    Repeat(count) => repeat_motif_as_motif_checked(motif, count)
    KeepRhythmChangeDegrees(degrees) => {
      if degrees.length() != motif.events.length() {
        return Err(InvalidTransform("degree count does not match motif"))
      }
      let events : Array[MotifEvent] = []
      for i = 0; i < motif.events.length(); i = i + 1 {
        events.push({ degree: degrees[i], cell: motif.events[i].cell })
      }
      Ok({ events, total_beats: motif.total_beats })
    }
    KeepDegreesChangeRhythm(rhythm) => {
      if rhythm.cells.length() != motif.events.length() {
        return Err(InvalidTransform("rhythm cell count does not match motif"))
      }
      let events : Array[MotifEvent] = []
      for i = 0; i < motif.events.length(); i = i + 1 {
        events.push({ degree: motif.events[i].degree, cell: rhythm.cells[i] })
      }
      Ok({ events, total_beats: motif_events_beats(events) })
    }
  }
}

///|
pub fn vary_motif_checked(
  motif : Motif,
  strategy : MotifVariationStrategy,
) -> Result[Motif, MotifError] {
  match strategy {
    ExactRepeat => transform_motif_checked(motif, Repeat(2))
    SequenceUp => transform_motif_checked(motif, TransposeDegrees(1))
    SequenceDown => transform_motif_checked(motif, TransposeDegrees(-1))
    Inversion => {
      if motif.events.length() == 0 {
        return Err(EmptyMotif("motif events cannot be empty"))
      }
      transform_motif_checked(motif, InvertAround(motif.events[0].degree))
    }
    RetrogradeVariation => transform_motif_checked(motif, Retrograde)
    RhythmicAugmentation => transform_motif_checked(motif, Augment)
    RhythmicDiminution => transform_motif_checked(motif, Diminish)
    CallResponse => {
      let repeated = match transform_motif_checked(motif, Repeat(2)) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      transform_motif_checked(repeated, TransposeDegrees(2))
    }
  }
}

///|
fn stretch_motif_checked(
  motif : Motif,
  factor : Double,
) -> Result[Motif, MotifError] {
  let events : Array[MotifEvent] = []
  for event in motif.events {
    let cell = event.cell
    events.push({
      degree: event.degree,
      cell: {
        duration: stretch_duration(cell.duration, factor),
        is_rest: cell.is_rest,
        accent: cell.accent,
        tie_to_next: cell.tie_to_next,
      },
    })
  }
  Ok({ events, total_beats: motif_events_beats(events) })
}

///|
fn rotate_motif_checked(
  motif : Motif,
  offset : Int,
) -> Result[Motif, MotifError] {
  let count = motif.events.length()
  if count == 0 {
    return Err(EmptyMotif("motif events cannot be empty"))
  }
  let shift = (offset % count + count) % count
  let events : Array[MotifEvent] = []
  for i = 0; i < count; i = i + 1 {
    events.push(motif.events[(i + shift) % count])
  }
  Ok({ events, total_beats: motif.total_beats })
}

///|
fn repeat_motif_as_motif_checked(
  motif : Motif,
  count : Int,
) -> Result[Motif, MotifError] {
  if count <= 0 {
    return Err(InvalidRepeatCount("repeat count must be > 0"))
  }
  let events : Array[MotifEvent] = []
  for repeat_index = 0; repeat_index < count; repeat_index = repeat_index + 1 {
    for event in motif.events {
      events.push(event)
    }
  }
  Ok({ events, total_beats: motif_events_beats(events) })
}
