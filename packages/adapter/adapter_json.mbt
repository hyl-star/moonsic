///|
fn scale_kind_to_tag(kind : @scale.ScaleKind) -> String {
  match kind {
    @scale.Major => "Major"
    @scale.NaturalMinor => "NaturalMinor"
    @scale.MajorPentatonic => "MajorPentatonic"
    @scale.MinorPentatonic => "MinorPentatonic"
    @scale.HarmonicMinor => "HarmonicMinor"
    @scale.MelodicMinor => "MelodicMinor"
    @scale.Dorian => "Dorian"
    @scale.Phrygian => "Phrygian"
    @scale.Lydian => "Lydian"
    @scale.Mixolydian => "Mixolydian"
    @scale.Locrian => "Locrian"
    @scale.Chromatic => "Chromatic"
  }
}

///|
fn scale_kind_from_tag(
  value : String,
) -> Result[@scale.ScaleKind, AdapterError] {
  match value {
    "Major" => Ok(@scale.Major)
    "NaturalMinor" => Ok(@scale.NaturalMinor)
    "MajorPentatonic" => Ok(@scale.MajorPentatonic)
    "MinorPentatonic" => Ok(@scale.MinorPentatonic)
    "HarmonicMinor" => Ok(@scale.HarmonicMinor)
    "MelodicMinor" => Ok(@scale.MelodicMinor)
    "Dorian" => Ok(@scale.Dorian)
    "Phrygian" => Ok(@scale.Phrygian)
    "Lydian" => Ok(@scale.Lydian)
    "Mixolydian" => Ok(@scale.Mixolydian)
    "Locrian" => Ok(@scale.Locrian)
    "Chromatic" => Ok(@scale.Chromatic)
    _ => Err(AdapterJsonError("unknown scale kind: \{value}"))
  }
}

///|
fn key_to_json_value(key : @scale.Key) -> @json.JsonValue {
  @json.json_object([
    @json.json_field("tonic", pitch_to_json_value(key.tonic)),
    @json.json_field("kind", @json.json_string(scale_kind_to_tag(key.kind))),
  ])
}

///|
fn key_from_json_value(
  value : @json.JsonValue,
) -> Result[@scale.Key, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let tonic_value = match json_lookup_required(fields, "tonic") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let tonic = match pitch_from_json_value(tonic_value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let kind_text = match json_string_required(fields, "kind") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let kind = match scale_kind_from_tag(kind_text) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  Ok(@scale.key(tonic, kind))
}

///|
fn score_context_to_json_value(context : ScoreContext) -> @json.JsonValue {
  @json.json_object([
    @json.json_field("score_summary", @json.json_string(context.score_summary)),
    @json.json_field(
      "key_hint",
      match context.key_hint {
        Some(key) => key_to_json_value(key)
        None => @json.json_null()
      },
    ),
    @json.json_field(
      "time_signature",
      time_signature_to_json_value(context.time_signature),
    ),
    @json.json_field("tempo", tempo_to_json_value(context.tempo)),
    @json.json_field("bars", @json.json_int(context.bars)),
    @json.json_field("track_count", @json.json_int(context.track_count)),
    @json.json_field("ppq", @json.json_int(context.ppq)),
  ])
}

///|
fn score_context_from_json_value(
  value : @json.JsonValue,
) -> Result[ScoreContext, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let score_summary = match json_string_required(fields, "score_summary") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let key_hint = match json_lookup_optional(fields, "key_hint") {
    Some(@json.JNull) | None => (None : @scale.Key?)
    Some(jv) =>
      match key_from_json_value(jv) {
        Ok(key) => Some(key)
        Err(e) => return Err(e)
      }
  }
  let signature_value = match json_lookup_required(fields, "time_signature") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let time_signature = match time_signature_from_json_value(signature_value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let tempo_value = match json_lookup_required(fields, "tempo") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let tempo = match tempo_from_json_value(tempo_value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let bars = match json_int_required(fields, "bars") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let track_count = match json_int_required(fields, "track_count") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let ppq = match json_int_required(fields, "ppq") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  Ok({ score_summary, key_hint, time_signature, tempo, bars, track_count, ppq })
}

///|
fn constraint_to_json_value(
  constraint : GenerationConstraint,
) -> @json.JsonValue {
  match constraint {
    MinBars(value) =>
      @json.json_object([
        @json.json_field("kind", @json.json_string("MinBars")),
        @json.json_field("value", @json.json_int(value)),
      ])
    MaxBars(value) =>
      @json.json_object([
        @json.json_field("kind", @json.json_string("MaxBars")),
        @json.json_field("value", @json.json_int(value)),
      ])
    AllowedScaleDegrees(degrees) => {
      let values : Array[@json.JsonValue] = []
      for degree in degrees {
        values.push(@json.json_int(degree))
      }
      @json.json_object([
        @json.json_field("kind", @json.json_string("AllowedScaleDegrees")),
        @json.json_field("degrees", @json.json_array(values)),
      ])
    }
    AllowedPitchRange(low, high) =>
      @json.json_object([
        @json.json_field("kind", @json.json_string("AllowedPitchRange")),
        @json.json_field("low", @json.json_int(low)),
        @json.json_field("high", @json.json_int(high)),
      ])
    RequiredStyle(tag) =>
      @json.json_object([
        @json.json_field("kind", @json.json_string("RequiredStyle")),
        @json.json_field("style", @json.json_string(style_tag_to_tag(tag))),
      ])
    MaxLeap(value) =>
      @json.json_object([
        @json.json_field("kind", @json.json_string("MaxLeap")),
        @json.json_field("value", @json.json_int(value)),
      ])
    TargetDensity(value) =>
      @json.json_object([
        @json.json_field("kind", @json.json_string("TargetDensity")),
        @json.json_field("value", @json.json_number(value)),
      ])
    MustFitTimeSignature =>
      @json.json_object([
        @json.json_field("kind", @json.json_string("MustFitTimeSignature")),
      ])
    MustLoop =>
      @json.json_object([
        @json.json_field("kind", @json.json_string("MustLoop")),
      ])
  }
}

///|
fn constraint_from_json_value(
  value : @json.JsonValue,
) -> Result[GenerationConstraint, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let kind = match json_string_required(fields, "kind") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  match kind {
    "MinBars" =>
      match json_int_required(fields, "value") {
        Ok(value) => Ok(MinBars(value))
        Err(e) => Err(e)
      }
    "MaxBars" =>
      match json_int_required(fields, "value") {
        Ok(value) => Ok(MaxBars(value))
        Err(e) => Err(e)
      }
    "AllowedScaleDegrees" => {
      let items = match json_array_required(fields, "degrees") {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      let degrees : Array[Int] = []
      for item in items {
        match @json.json_as_int(item) {
          Ok(degree) => degrees.push(degree)
          Err(e) => return Err(json_type_error(e))
        }
      }
      Ok(AllowedScaleDegrees(degrees))
    }
    "AllowedPitchRange" => {
      let low = match json_int_required(fields, "low") {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      let high = match json_int_required(fields, "high") {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      Ok(AllowedPitchRange(low, high))
    }
    "RequiredStyle" => {
      let style = match json_string_required(fields, "style") {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      match parse_style_tag_from_tag(style) {
        Ok(tag) => Ok(RequiredStyle(tag))
        Err(e) => Err(e)
      }
    }
    "MaxLeap" =>
      match json_int_required(fields, "value") {
        Ok(value) => Ok(MaxLeap(value))
        Err(e) => Err(e)
      }
    "TargetDensity" =>
      match json_double_required(fields, "value") {
        Ok(value) => Ok(TargetDensity(value))
        Err(e) => Err(e)
      }
    "MustFitTimeSignature" => Ok(MustFitTimeSignature)
    "MustLoop" => Ok(MustLoop)
    _ => Err(AdapterJsonError("unknown constraint: \{kind}"))
  }
}

///|
fn patch_operation_to_json_value(
  operation : GenerationPatchOperation,
) -> @json.JsonValue {
  @json.json_object([
    @json.json_field(
      "kind",
      @json.json_string(patch_kind_to_tag(operation.kind)),
    ),
    @json.json_field(
      "target",
      @json.json_string(patch_target_to_tag(operation.target)),
    ),
    @json.json_field("path", @json.json_string(operation.path)),
    @json.json_field("payload_json", @json.json_string(operation.payload_json)),
  ])
}

///|
fn patch_operation_from_json_value(
  value : @json.JsonValue,
) -> Result[GenerationPatchOperation, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let kind_text = match json_string_required(fields, "kind") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let kind = match parse_patch_kind_from_tag(kind_text) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let target_text = match json_string_required(fields, "target") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let target = match parse_patch_target_from_tag(target_text) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let path = match json_string_required(fields, "path") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let payload_json = match json_lookup_optional(fields, "payload_json") {
    Some(jv) =>
      match @json.json_as_string(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => ""
  }
  Ok({ kind, target, path, payload_json })
}

///|
pub fn generation_patch_to_json_value(
  patch : GenerationPatch,
) -> @json.JsonValue {
  let operations : Array[@json.JsonValue] = []
  for operation in patch.operations {
    operations.push(patch_operation_to_json_value(operation))
  }
  @json.json_object([
    @json.json_field("operations", @json.json_array(operations)),
    @json.json_field("source", @json.json_string(patch.source)),
  ])
}

///|
pub fn generation_patch_from_json_value(
  value : @json.JsonValue,
) -> Result[GenerationPatch, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let items = match json_array_required(fields, "operations") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let operations : Array[GenerationPatchOperation] = []
  for item in items {
    match patch_operation_from_json_value(item) {
      Ok(operation) => operations.push(operation)
      Err(e) => return Err(e)
    }
  }
  let source = match json_lookup_optional(fields, "source") {
    Some(jv) =>
      match @json.json_as_string(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => "unknown"
  }
  Ok({ operations, source })
}

///|
pub fn generation_request_to_json_value(
  request : GenerationRequest,
) -> @json.JsonValue {
  let styles : Array[@json.JsonValue] = []
  for tag in request.style_tags {
    styles.push(@json.json_string(style_tag_to_tag(tag)))
  }
  let constraints : Array[@json.JsonValue] = []
  for constraint in request.constraints {
    constraints.push(constraint_to_json_value(constraint))
  }
  @json.json_object([
    @json.json_field("id", @json.json_string(request.id)),
    @json.json_field("task", @json.json_string(task_kind_to_tag(request.task))),
    @json.json_field("context", score_context_to_json_value(request.context)),
    @json.json_field("style_tags", @json.json_array(styles)),
    @json.json_field("constraints", @json.json_array(constraints)),
    @json.json_field(
      "deterministic",
      @json.json_string(determinism_to_tag(request.deterministic)),
    ),
    @json.json_field(
      "seed",
      match request.seed {
        Some(seed) => @json.json_int(seed)
        None => @json.json_null()
      },
    ),
  ])
}

///|
pub fn generation_request_from_json_value(
  value : @json.JsonValue,
) -> Result[GenerationRequest, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let id = match json_string_required(fields, "id") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let task_text = match json_string_required(fields, "task") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let task = match parse_task_kind_from_tag(task_text) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let context_value = match json_lookup_required(fields, "context") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let context = match score_context_from_json_value(context_value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let styles : Array[GenerationStyleTag] = []
  match json_lookup_optional(fields, "style_tags") {
    Some(jv) => {
      let items = match @json.json_as_array(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
      for item in items {
        let text = match @json.json_as_string(item) {
          Ok(result) => result
          Err(e) => return Err(json_type_error(e))
        }
        match parse_style_tag_from_tag(text) {
          Ok(tag) => styles.push(tag)
          Err(e) => return Err(e)
        }
      }
    }
    None => ()
  }
  let constraints : Array[GenerationConstraint] = []
  match json_lookup_optional(fields, "constraints") {
    Some(jv) => {
      let items = match @json.json_as_array(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
      for item in items {
        match constraint_from_json_value(item) {
          Ok(constraint) => constraints.push(constraint)
          Err(e) => return Err(e)
        }
      }
    }
    None => ()
  }
  let deterministic = match json_lookup_optional(fields, "deterministic") {
    Some(jv) => {
      let text = match @json.json_as_string(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
      match parse_determinism_from_tag(text) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
    }
    None => Deterministic
  }
  let seed = match json_lookup_optional(fields, "seed") {
    Some(@json.JNull) | None => (None : Int?)
    Some(jv) =>
      match @json.json_as_int(jv) {
        Ok(result) => Some(result)
        Err(e) => return Err(json_type_error(e))
      }
  }
  generation_request_checked(
    id, task, context, styles, constraints, deterministic, seed,
  )
}

///|
fn fragment_to_json_value(fragment : ScoreFragment) -> @json.JsonValue {
  let tracks : Array[@json.JsonValue] = []
  for track in fragment.tracks {
    tracks.push(simple_track_to_json_value(track))
  }
  @json.json_object([
    @json.json_field("tracks", @json.json_array(tracks)),
    @json.json_field("start_bar", @json.json_int(fragment.start_bar)),
    @json.json_field("length_bars", @json.json_int(fragment.length_bars)),
  ])
}

///|
fn fragment_from_json_value(
  value : @json.JsonValue,
) -> Result[ScoreFragment, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let track_values = match json_array_required(fields, "tracks") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let tracks : Array[@score.SimpleTrack] = []
  for track_value in track_values {
    match simple_track_from_json_value(track_value) {
      Ok(track) => tracks.push(track)
      Err(e) => return Err(e)
    }
  }
  let start_bar = match json_lookup_optional(fields, "start_bar") {
    Some(jv) =>
      match @json.json_as_int(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => 0
  }
  let length_bars = match json_lookup_optional(fields, "length_bars") {
    Some(jv) =>
      match @json.json_as_int(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => 0
  }
  Ok({ tracks, start_bar, length_bars })
}

///|
fn candidate_to_json_value(candidate : GenerationCandidate) -> @json.JsonValue {
  @json.json_object([
    @json.json_field("fragment", fragment_to_json_value(candidate.fragment)),
    @json.json_field("confidence", @json.json_number(candidate.confidence)),
    @json.json_field("description", @json.json_string(candidate.description)),
  ])
}

///|
fn candidate_from_json_value(
  value : @json.JsonValue,
) -> Result[GenerationCandidate, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let fragment_value = match json_lookup_required(fields, "fragment") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let fragment = match fragment_from_json_value(fragment_value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let confidence = match json_lookup_optional(fields, "confidence") {
    Some(jv) =>
      match @json.json_as_double(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => 1.0
  }
  let description = match json_lookup_optional(fields, "description") {
    Some(jv) =>
      match @json.json_as_string(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => ""
  }
  Ok({ fragment, confidence, description })
}

///|
pub fn generation_response_to_json_value(
  response : GenerationResponse,
) -> @json.JsonValue {
  let candidates : Array[@json.JsonValue] = []
  for candidate in response.candidates {
    candidates.push(candidate_to_json_value(candidate))
  }
  @json.json_object([
    @json.json_field("request_id", @json.json_string(response.request_id)),
    @json.json_field("candidates", @json.json_array(candidates)),
    @json.json_field(
      "patch",
      match response.patch {
        Some(patch) => generation_patch_to_json_value(patch)
        None => @json.json_null()
      },
    ),
    @json.json_field("message", @json.json_string(response.message)),
  ])
}

///|
pub fn generation_response_from_json_value(
  value : @json.JsonValue,
) -> Result[GenerationResponse, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let request_id = match json_string_required(fields, "request_id") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let candidate_values = match json_lookup_optional(fields, "candidates") {
    Some(jv) =>
      match @json.json_as_array(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => []
  }
  let candidates : Array[GenerationCandidate] = []
  for candidate_value in candidate_values {
    match candidate_from_json_value(candidate_value) {
      Ok(candidate) => candidates.push(candidate)
      Err(e) => return Err(e)
    }
  }
  let patch = match json_lookup_optional(fields, "patch") {
    Some(@json.JNull) | None => (None : GenerationPatch?)
    Some(jv) =>
      match generation_patch_from_json_value(jv) {
        Ok(result) => Some(result)
        Err(e) => return Err(e)
      }
  }
  let message = match json_lookup_optional(fields, "message") {
    Some(jv) =>
      match @json.json_as_string(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => ""
  }
  Ok({ request_id, candidates, patch, message })
}

///|
pub fn generation_request_to_json(request : GenerationRequest) -> String {
  @json.json_stringify(generation_request_to_json_value(request))
}

///|
pub fn generation_request_from_json(
  input : String,
) -> Result[GenerationRequest, AdapterError] {
  match @json.json_parse(input) {
    Ok(value) => generation_request_from_json_value(value)
    Err(e) => Err(json_type_error(e))
  }
}

///|
pub fn generation_response_to_json(response : GenerationResponse) -> String {
  @json.json_stringify(generation_response_to_json_value(response))
}

///|
pub fn generation_response_from_json(
  input : String,
) -> Result[GenerationResponse, AdapterError] {
  match @json.json_parse(input) {
    Ok(value) => generation_response_from_json_value(value)
    Err(e) => Err(json_type_error(e))
  }
}
