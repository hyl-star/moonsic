///|
pub(all) struct SongSection {
  name : String
  tracks : Array[@score.SimpleTrack]
}

///|
pub fn section(
  name : String,
  tracks : Array[@score.SimpleTrack],
) -> Result[SongSection, StructureError] {
  if name == "" {
    return Err(InvalidSection("section name cannot be empty"))
  }
  Ok({ name, tracks })
}

///|
pub fn intro(
  tracks : Array[@score.SimpleTrack],
) -> Result[SongSection, StructureError] {
  section("intro", tracks)
}

///|
pub fn verse(
  tracks : Array[@score.SimpleTrack],
) -> Result[SongSection, StructureError] {
  section("verse", tracks)
}

///|
pub fn chorus(
  tracks : Array[@score.SimpleTrack],
) -> Result[SongSection, StructureError] {
  section("chorus", tracks)
}

///|
pub fn bridge(
  tracks : Array[@score.SimpleTrack],
) -> Result[SongSection, StructureError] {
  section("bridge", tracks)
}

///|
pub fn outro(
  tracks : Array[@score.SimpleTrack],
) -> Result[SongSection, StructureError] {
  section("outro", tracks)
}

///|
pub fn section_duration_beats(section : SongSection) -> Double {
  let mut max_duration = 0.0
  for track in section.tracks {
    let duration = simple_track_duration_beats(track)
    if duration > max_duration {
      max_duration = duration
    }
  }
  max_duration
}

///|
pub fn simple_track_duration_beats(track : @score.SimpleTrack) -> Double {
  let mut total = 0.0
  for event in track.events {
    let duration = match event {
      @score.Note(note) => note.duration
      @score.Rest(rest) => rest.duration
      @score.Chord(chord) => chord.duration
    }
    let fraction = @time.rhythm_duration_to_fraction(duration)
    total = total + @time.rational_to_double(fraction)
  }
  total
}

///|
pub fn simple_track_concat(
  left : @score.SimpleTrack,
  right : @score.SimpleTrack,
) -> @score.SimpleTrack {
  let events : Array[@score.SimpleEvent] = []
  for event in left.events {
    events.push(event)
  }
  for event in right.events {
    events.push(event)
  }
  {
    events,
    channel: left.channel,
    program: left.program,
    volume: left.volume,
    pan: left.pan,
    mute: left.mute,
  }
}

///|
pub fn simple_track_pad_to_checked(
  track : @score.SimpleTrack,
  target_beats : Double,
) -> Result[@score.SimpleTrack, StructureError] {
  if target_beats < 0.0 {
    return Err(InvalidArrangement("target beats cannot be negative"))
  }
  let current = simple_track_duration_beats(track)
  if current >= target_beats {
    return Ok(track)
  }
  let events : Array[@score.SimpleEvent] = []
  for event in track.events {
    events.push(event)
  }
  let mut gap = target_beats - current
  while gap > 0.0001 {
    let duration = duration_from_gap(gap)
    match @score.simple_rest_checked(duration) {
      Ok(event) => events.push(event)
      Err(e) => return Err(StructureScoreError(e.to_string()))
    }
    let fraction = @time.rhythm_duration_to_fraction(duration)
    gap = gap - @time.rational_to_double(fraction)
  }
  Ok({
    events,
    channel: track.channel,
    program: track.program,
    volume: track.volume,
    pan: track.pan,
    mute: track.mute,
  })
}

///|
pub fn bass_roots_checked(
  chords : @score.SimpleTrack,
  duration : @time.RhythmDuration,
) -> Result[@score.SimpleTrack, StructureError] {
  let events : Array[@score.SimpleEvent] = []
  for event in chords.events {
    match event {
      @score.Chord(chord) =>
        if chord.pitches.length() == 0 {
          match @score.simple_rest_checked(duration) {
            Ok(rest) => events.push(rest)
            Err(e) => return Err(StructureScoreError(e.to_string()))
          }
        } else {
          match
            @score.simple_note_checked(
              chord.pitches[0],
              duration,
              Some(chord.velocity),
            ) {
            Ok(note) => events.push(note)
            Err(e) => return Err(StructureScoreError(e.to_string()))
          }
        }
      _ =>
        match @score.simple_rest_checked(duration) {
          Ok(rest) => events.push(rest)
          Err(e) => return Err(StructureScoreError(e.to_string()))
        }
    }
  }
  match @score.simple_track_checked(events, chords.channel, chords.program) {
    Ok(result) => Ok(result)
    Err(e) => Err(StructureScoreError(e.to_string()))
  }
}

///|
pub fn melody_degrees_checked(
  key : @scale.Key,
  degrees : Array[Int],
  duration : @time.RhythmDuration,
) -> Result[@score.SimpleTrack, StructureError] {
  if degrees.length() == 0 {
    return Err(InvalidDegree("degrees cannot be empty"))
  }
  let events : Array[@score.SimpleEvent] = []
  for degree in degrees {
    let pitch = match key.key_degree_checked(degree, 4) {
      Ok(result) => result
      Err(e) => return Err(InvalidDegree(e.to_string()))
    }
    match @score.simple_note_checked(pitch, duration, None) {
      Ok(event) => events.push(event)
      Err(e) => return Err(StructureScoreError(e.to_string()))
    }
  }
  match @score.simple_track_checked(events, None, None) {
    Ok(result) => Ok(result)
    Err(e) => Err(StructureScoreError(e.to_string()))
  }
}

///|
pub fn melody_degrees_from_tonic_checked(
  tonic : @pitch.Pitch,
  kind : @scale.ScaleKind,
  degrees : Array[Int],
  duration : @time.RhythmDuration,
) -> Result[@score.SimpleTrack, StructureError] {
  melody_degrees_checked(@scale.key(tonic, kind), degrees, duration)
}

///|
fn duration_from_gap(gap : Double) -> @time.RhythmDuration {
  if gap >= 4.0 {
    @time.rhythm_duration(@time.DurWhole, 0, None)
  } else if gap >= 2.0 {
    @time.rhythm_duration(@time.DurHalf, 0, None)
  } else if gap >= 1.0 {
    @time.rhythm_duration(@time.DurQuarter, 0, None)
  } else if gap >= 0.5 {
    @time.rhythm_duration(@time.DurEighth, 0, None)
  } else {
    @time.rhythm_duration(@time.DurSixteenth, 0, None)
  }
}
