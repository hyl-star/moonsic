///|
pub fn generation_patch_checked(
  operations : Array[GenerationPatchOperation],
) -> Result[GenerationPatch, AdapterError] {
  if operations.length() == 0 {
    return Err(InvalidGenerationPatch("operations cannot be empty"))
  }
  for operation in operations {
    if operation.path.length() == 0 {
      return Err(InvalidGenerationPatch("operation path cannot be empty"))
    }
    match operation.kind {
      ReplaceTrack | RemoveTrack =>
        match operation.target {
          TrackTarget => ()
          _ =>
            return Err(
              InvalidGenerationPatch(
                "\{patch_kind_to_tag(operation.kind)} requires TrackTarget",
              ),
            )
        }
      InsertTrack | AppendTrack =>
        match operation.target {
          ScoreTarget | TrackTarget => ()
          _ =>
            return Err(
              InvalidGenerationPatch(
                "\{patch_kind_to_tag(operation.kind)} requires score or track target",
              ),
            )
        }
      AppendMeasure | ReplaceMeasure | InsertSection | AddNotation | SetTempo =>
        ()
    }
  }
  Ok({ operations, source: "moonsic-adapter" })
}

///|
pub fn validate_generation_patch(
  patch : GenerationPatch,
  context : ScoreContext,
) -> Result[Unit, AdapterError] {
  if patch.operations.length() == 0 {
    return Err(InvalidGenerationPatch("operations cannot be empty"))
  }
  for operation in patch.operations {
    match operation.kind {
      ReplaceTrack | RemoveTrack => {
        let index = match parse_track_index(operation.path) {
          Ok(result) => result
          Err(e) => return Err(e)
        }
        if index < 0 || index >= context.track_count {
          return Err(PatchTargetNotFound("track index out of range: \{index}"))
        }
      }
      InsertTrack => {
        let index = match parse_track_index(operation.path) {
          Ok(result) => result
          Err(e) => return Err(e)
        }
        if index < 0 || index > context.track_count {
          return Err(PatchTargetNotFound("insert index out of range: \{index}"))
        }
      }
      AppendTrack => ()
      AppendMeasure | ReplaceMeasure | InsertSection | AddNotation | SetTempo =>
        return Err(
          AdapterUnsupported(
            "\{patch_kind_to_tag(operation.kind)} is not supported yet",
          ),
        )
    }
  }
  Ok(())
}

///|
pub fn apply_generation_patch_checked(
  score : @score.SimpleScore,
  patch : GenerationPatch,
) -> Result[@score.SimpleScore, AdapterError] {
  let mut tracks : Array[@score.SimpleTrack] = []
  for track in score.tracks {
    tracks.push(track)
  }
  for operation in patch.operations {
    match operation.kind {
      AppendTrack => {
        let track = match payload_track(operation.payload_json) {
          Ok(result) => result
          Err(e) => return Err(e)
        }
        tracks.push(track)
      }
      InsertTrack => {
        let index = match parse_track_index(operation.path) {
          Ok(result) => result
          Err(e) => return Err(e)
        }
        if index < 0 || index > tracks.length() {
          return Err(PatchTargetNotFound("insert index out of range: \{index}"))
        }
        let track = match payload_track(operation.payload_json) {
          Ok(result) => result
          Err(e) => return Err(e)
        }
        let rebuilt : Array[@score.SimpleTrack] = []
        for i = 0; i < tracks.length(); i = i + 1 {
          if i == index {
            rebuilt.push(track)
          }
          rebuilt.push(tracks[i])
        }
        if index == tracks.length() {
          rebuilt.push(track)
        }
        tracks = rebuilt
      }
      ReplaceTrack => {
        let index = match parse_track_index(operation.path) {
          Ok(result) => result
          Err(e) => return Err(e)
        }
        if index < 0 || index >= tracks.length() {
          return Err(PatchTargetNotFound("track index out of range: \{index}"))
        }
        let track = match payload_track(operation.payload_json) {
          Ok(result) => result
          Err(e) => return Err(e)
        }
        tracks[index] = track
      }
      RemoveTrack => {
        let index = match parse_track_index(operation.path) {
          Ok(result) => result
          Err(e) => return Err(e)
        }
        if index < 0 || index >= tracks.length() {
          return Err(PatchTargetNotFound("track index out of range: \{index}"))
        }
        let rebuilt : Array[@score.SimpleTrack] = []
        for i = 0; i < tracks.length(); i = i + 1 {
          if i != index {
            rebuilt.push(tracks[i])
          }
        }
        tracks = rebuilt
      }
      AppendMeasure | ReplaceMeasure | InsertSection | AddNotation | SetTempo =>
        return Err(
          AdapterUnsupported(
            "\{patch_kind_to_tag(operation.kind)} is not supported yet",
          ),
        )
    }
  }
  let result : @score.SimpleScore = {
    tempo: score.tempo,
    time_signature: score.time_signature,
    tracks,
    master_gain: score.master_gain,
  }
  Ok(result)
}

///|
fn payload_track(
  payload_json : String,
) -> Result[@score.SimpleTrack, AdapterError] {
  match @json.json_parse(payload_json) {
    Ok(value) => simple_track_from_json_value(value)
    Err(e) => Err(json_type_error(e))
  }
}

///|
fn parse_track_index(path : String) -> Result[Int, AdapterError] {
  if path == "/score" || path == "/score/tracks" {
    return Ok(0)
  }
  let len = path.length()
  let mut index = len - 1
  while index >= 0 && !(path[index] >= '0' && path[index] <= '9') {
    index = index - 1
  }
  if index < 0 {
    return Err(PatchTargetNotFound("path has no numeric index: \{path}"))
  }
  let mut start = index
  while start > 0 && path[start - 1] >= '0' && path[start - 1] <= '9' {
    start = start - 1
  }
  let digits = path[start:index + 1].to_owned()
  let mut value = 0
  for i = 0; i < digits.length(); i = i + 1 {
    let char = digits[i]
    if char >= '0' && char <= '9' {
      value = value * 10 + (char.to_int() - '0'.to_int())
    }
  }
  Ok(value)
}
