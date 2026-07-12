///|
pub fn layer_checked(
  tracks : Array[@score.SimpleTrack],
  tempo : @score.Tempo,
  signature : @time.TimeSignature,
) -> Result[@score.SimpleScore, StructureError] {
  if tracks.length() == 0 {
    return Err(EmptyStructure("tracks cannot be empty"))
  }
  match @score.simple_score_checked(tracks, tempo, signature) {
    Ok(result) => Ok(result)
    Err(e) => Err(StructureScoreError(e.to_string()))
  }
}

///|
pub fn arrange_checked(
  sections : Array[SongSection],
  tempo : @score.Tempo,
  signature : @time.TimeSignature,
) -> Result[@score.SimpleScore, StructureError] {
  if sections.length() == 0 {
    return Err(EmptyStructure("sections cannot be empty"))
  }
  let mut max_tracks = 0
  for section in sections {
    if section.tracks.length() > max_tracks {
      max_tracks = section.tracks.length()
    }
  }
  if max_tracks == 0 {
    return Err(EmptyStructure("sections contain no tracks"))
  }
  let arranged : Array[@score.SimpleTrack] = []
  for i = 0; i < max_tracks; i = i + 1 {
    arranged.push(empty_track())
  }
  for section in sections {
    let duration = section_duration_beats(section)
    for i = 0; i < max_tracks; i = i + 1 {
      let source = if i < section.tracks.length() {
        section.tracks[i]
      } else {
        empty_track()
      }
      let padded = match simple_track_pad_to_checked(source, duration) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      arranged[i] = simple_track_concat(arranged[i], padded)
    }
  }
  match @score.simple_score_checked(arranged, tempo, signature) {
    Ok(result) => Ok(result)
    Err(e) => Err(StructureScoreError(e.to_string()))
  }
}

///|
fn empty_track() -> @score.SimpleTrack {
  @score.simple_track_checked([], None, None).unwrap()
}
