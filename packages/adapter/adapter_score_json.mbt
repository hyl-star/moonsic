///|
fn pitch_to_json_value(pitch : @pitch.Pitch) -> @json.JsonValue {
  @json.json_object([
    @json.json_field("name", @json.json_string(pitch.to_string())),
    @json.json_field("midi", @json.json_int(pitch.to_midi())),
  ])
}

///|
fn pitch_from_json_value(
  value : @json.JsonValue,
) -> Result[@pitch.Pitch, AdapterError] {
  match value {
    @json.JString(text) =>
      match @pitch.parse_pitch(text) {
        Ok(pitch) => Ok(pitch)
        Err(e) => Err(AdapterJsonError(e.to_string()))
      }
    _ => {
      let fields = match json_object_fields(value) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      let name = match json_string_required(fields, "name") {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      match @pitch.parse_pitch(name) {
        Ok(pitch) => Ok(pitch)
        Err(e) => Err(AdapterJsonError(e.to_string()))
      }
    }
  }
}

///|
fn duration_unit_to_json(unit : @time.DurUnit) -> String {
  match unit {
    @time.DurWhole => "whole"
    @time.DurHalf => "half"
    @time.DurQuarter => "quarter"
    @time.DurEighth => "eighth"
    @time.DurSixteenth => "sixteenth"
    @time.ThirtySecond => "thirty_second"
    @time.SixtyFourth => "sixty_fourth"
    @time.OneTwentyEighth => "one_twenty_eighth"
  }
}

///|
fn duration_unit_from_json(
  value : String,
) -> Result[@time.DurUnit, AdapterError] {
  match value {
    "whole" | "w" => Ok(@time.DurWhole)
    "half" | "h" => Ok(@time.DurHalf)
    "quarter" | "q" => Ok(@time.DurQuarter)
    "eighth" | "8" => Ok(@time.DurEighth)
    "sixteenth" | "16" => Ok(@time.DurSixteenth)
    "thirty_second" | "32" => Ok(@time.ThirtySecond)
    "sixty_fourth" | "64" => Ok(@time.SixtyFourth)
    "one_twenty_eighth" | "128" => Ok(@time.OneTwentyEighth)
    _ => Err(AdapterJsonError("unknown duration unit: \{value}"))
  }
}

///|
fn duration_to_json_value(duration : @time.RhythmDuration) -> @json.JsonValue {
  let tuplet = match duration.tuplet {
    Some(ratio) =>
      @json.json_object([
        @json.json_field("actual", @json.json_int(ratio.actual)),
        @json.json_field("normal", @json.json_int(ratio.normal)),
      ])
    None => @json.json_null()
  }
  @json.json_object([
    @json.json_field(
      "unit",
      @json.json_string(duration_unit_to_json(duration.unit)),
    ),
    @json.json_field("dots", @json.json_int(duration.dots)),
    @json.json_field("tuplet", tuplet),
  ])
}

///|
fn duration_from_json_value(
  value : @json.JsonValue,
) -> Result[@time.RhythmDuration, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let unit_text = match json_string_required(fields, "unit") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let unit = match duration_unit_from_json(unit_text) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let dots = match json_lookup_optional(fields, "dots") {
    Some(jv) =>
      match @json.json_as_int(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => 0
  }
  let tuplet = match json_lookup_optional(fields, "tuplet") {
    Some(@json.JNull) | None => (None : @time.TupletRatio?)
    Some(jv) => {
      let ratio_fields = match json_object_fields(jv) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      let actual = match json_int_required(ratio_fields, "actual") {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      let normal = match json_int_required(ratio_fields, "normal") {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      Some({ actual, normal })
    }
  }
  Ok(@time.rhythm_duration(unit, dots, tuplet))
}

///|
fn tempo_to_json_value(tempo : @score.Tempo) -> @json.JsonValue {
  @json.json_object([@json.json_field("bpm", @json.json_int(tempo.bpm))])
}

///|
fn tempo_from_json_value(
  value : @json.JsonValue,
) -> Result[@score.Tempo, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let bpm = match json_int_required(fields, "bpm") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  match @score.tempo_checked(bpm) {
    Ok(tempo) => Ok(tempo)
    Err(e) => Err(AdapterScoreError(e.to_string()))
  }
}

///|
fn time_signature_to_json_value(
  signature : @time.TimeSignature,
) -> @json.JsonValue {
  @json.json_object([
    @json.json_field("numerator", @json.json_int(signature.numerator)),
    @json.json_field("denominator", @json.json_int(signature.denominator)),
  ])
}

///|
fn time_signature_from_json_value(
  value : @json.JsonValue,
) -> Result[@time.TimeSignature, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let numerator = match json_int_required(fields, "numerator") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let denominator = match json_int_required(fields, "denominator") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  if !@time.is_valid_time_signature(numerator, denominator) {
    return Err(AdapterJsonError("invalid time signature"))
  }
  Ok(@time.time_signature(numerator, denominator))
}

///|
fn simple_event_to_json_value(event : @score.SimpleEvent) -> @json.JsonValue {
  match event {
    @score.Note(note) =>
      @json.json_object([
        @json.json_field("type", @json.json_string("note")),
        @json.json_field("pitch", pitch_to_json_value(note.pitch)),
        @json.json_field("duration", duration_to_json_value(note.duration)),
        @json.json_field("velocity", @json.json_int(note.velocity.value)),
      ])
    @score.Rest(rest) =>
      @json.json_object([
        @json.json_field("type", @json.json_string("rest")),
        @json.json_field("duration", duration_to_json_value(rest.duration)),
      ])
    @score.Chord(chord) => {
      let pitches : Array[@json.JsonValue] = []
      for pitch in chord.pitches {
        pitches.push(pitch_to_json_value(pitch))
      }
      @json.json_object([
        @json.json_field("type", @json.json_string("chord")),
        @json.json_field("pitches", @json.json_array(pitches)),
        @json.json_field("duration", duration_to_json_value(chord.duration)),
        @json.json_field("velocity", @json.json_int(chord.velocity.value)),
      ])
    }
  }
}

///|
fn simple_event_from_json_value(
  value : @json.JsonValue,
) -> Result[@score.SimpleEvent, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let event_type = match json_string_required(fields, "type") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let duration_value = match json_lookup_required(fields, "duration") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let duration = match duration_from_json_value(duration_value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let velocity = match json_lookup_optional(fields, "velocity") {
    Some(jv) =>
      match @json.json_as_int(jv) {
        Ok(number) =>
          match @score.velocity_checked(number) {
            Ok(result) => Some(result)
            Err(e) => return Err(AdapterScoreError(e.to_string()))
          }
        Err(e) => return Err(json_type_error(e))
      }
    None => (None : @score.Velocity?)
  }
  match event_type {
    "note" => {
      let pitch_value = match json_lookup_required(fields, "pitch") {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      let pitch = match pitch_from_json_value(pitch_value) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      match @score.simple_note_checked(pitch, duration, velocity) {
        Ok(result) => Ok(result)
        Err(e) => Err(AdapterScoreError(e.to_string()))
      }
    }
    "rest" =>
      match @score.simple_rest_checked(duration) {
        Ok(result) => Ok(result)
        Err(e) => Err(AdapterScoreError(e.to_string()))
      }
    "chord" => {
      let pitch_values = match json_array_required(fields, "pitches") {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      let pitches : Array[@pitch.Pitch] = []
      for pitch_value in pitch_values {
        match pitch_from_json_value(pitch_value) {
          Ok(pitch) => pitches.push(pitch)
          Err(e) => return Err(e)
        }
      }
      match @score.simple_chord_checked(pitches, duration, velocity) {
        Ok(result) => Ok(result)
        Err(e) => Err(AdapterScoreError(e.to_string()))
      }
    }
    _ => Err(AdapterJsonError("unknown simple event type: \{event_type}"))
  }
}

///|
fn optional_channel_to_json(channel : @score.MidiChannel?) -> @json.JsonValue {
  match channel {
    Some(value) => @json.json_int(value.value)
    None => @json.json_null()
  }
}

///|
fn optional_program_to_json(program : @score.MidiProgram?) -> @json.JsonValue {
  match program {
    Some(value) => @json.json_int(value.value)
    None => @json.json_null()
  }
}

///|
fn optional_channel_from_fields(
  fields : Array[@json.JsonField],
) -> Result[@score.MidiChannel?, AdapterError] {
  match json_lookup_optional(fields, "channel") {
    Some(@json.JNull) | None => Ok(None)
    Some(jv) =>
      match @json.json_as_int(jv) {
        Ok(number) =>
          match @score.midi_channel_checked(number) {
            Ok(channel) => Ok(Some(channel))
            Err(e) => Err(AdapterScoreError(e.to_string()))
          }
        Err(e) => Err(json_type_error(e))
      }
  }
}

///|
fn optional_program_from_fields(
  fields : Array[@json.JsonField],
) -> Result[@score.MidiProgram?, AdapterError] {
  match json_lookup_optional(fields, "program") {
    Some(@json.JNull) | None => Ok(None)
    Some(jv) =>
      match @json.json_as_int(jv) {
        Ok(number) =>
          match @score.midi_program_checked(number) {
            Ok(program) => Ok(Some(program))
            Err(e) => Err(AdapterScoreError(e.to_string()))
          }
        Err(e) => Err(json_type_error(e))
      }
  }
}

///|
fn simple_track_to_json_value(track : @score.SimpleTrack) -> @json.JsonValue {
  let events : Array[@json.JsonValue] = []
  for event in track.events {
    events.push(simple_event_to_json_value(event))
  }
  @json.json_object([
    @json.json_field("channel", optional_channel_to_json(track.channel)),
    @json.json_field("program", optional_program_to_json(track.program)),
    @json.json_field("volume", @json.json_number(track.volume)),
    @json.json_field("pan", @json.json_number(track.pan)),
    @json.json_field("mute", @json.json_bool(track.mute)),
    @json.json_field("events", @json.json_array(events)),
  ])
}

///|
fn simple_track_from_json_value(
  value : @json.JsonValue,
) -> Result[@score.SimpleTrack, AdapterError] {
  let fields = match json_object_fields(value) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let channel = match optional_channel_from_fields(fields) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let program = match optional_program_from_fields(fields) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let event_values = match json_array_required(fields, "events") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let events : Array[@score.SimpleEvent] = []
  for event_value in event_values {
    match simple_event_from_json_value(event_value) {
      Ok(event) => events.push(event)
      Err(e) => return Err(e)
    }
  }
  let volume = match json_lookup_optional(fields, "volume") {
    Some(jv) =>
      match @json.json_as_double(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => 1.0
  }
  let pan = match json_lookup_optional(fields, "pan") {
    Some(jv) =>
      match @json.json_as_double(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => 0.0
  }
  let mute = match json_lookup_optional(fields, "mute") {
    Some(jv) =>
      match @json.json_as_bool(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => false
  }
  let track : @score.SimpleTrack = {
    events,
    channel,
    program,
    volume,
    pan,
    mute,
  }
  Ok(track)
}

///|
fn simple_score_to_json_value(score : @score.SimpleScore) -> @json.JsonValue {
  let tracks : Array[@json.JsonValue] = []
  for track in score.tracks {
    tracks.push(simple_track_to_json_value(track))
  }
  @json.json_object([
    @json.json_field("schema", @json.json_string("moonsic.simple_score")),
    @json.json_field("version", @json.json_int(2)),
    @json.json_field("tempo", tempo_to_json_value(score.tempo)),
    @json.json_field(
      "time_signature",
      time_signature_to_json_value(score.time_signature),
    ),
    @json.json_field("master_gain", @json.json_number(score.master_gain)),
    @json.json_field("tracks", @json.json_array(tracks)),
  ])
}

///|
fn simple_score_from_json_value(
  value : @json.JsonValue,
) -> Result[@score.SimpleScore, AdapterError] {
  let fields = match json_object_fields(value) {
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
  let signature_value = match json_lookup_required(fields, "time_signature") {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let signature = match time_signature_from_json_value(signature_value) {
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
  let master_gain = match json_lookup_optional(fields, "master_gain") {
    Some(jv) =>
      match @json.json_as_double(jv) {
        Ok(result) => result
        Err(e) => return Err(json_type_error(e))
      }
    None => 0.85
  }
  let score : @score.SimpleScore = {
    tempo,
    time_signature: signature,
    tracks,
    master_gain,
  }
  Ok(score)
}

///|
pub fn simple_score_to_json_checked(
  score : @score.SimpleScore,
) -> Result[String, AdapterError] {
  Ok(@json.json_stringify(simple_score_to_json_value(score)))
}

///|
pub fn simple_score_from_json_checked(
  input : String,
) -> Result[@score.SimpleScore, AdapterError] {
  match @json.json_parse(input) {
    Ok(value) => simple_score_from_json_value(value)
    Err(e) => Err(json_type_error(e))
  }
}
