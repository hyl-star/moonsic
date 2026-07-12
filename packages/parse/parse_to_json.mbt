///|
pub fn parse_to_json_checked(
  input : String,
  kind : String,
) -> Result[String, ParseFacadeError] {
  match kind {
    "pitch" =>
      match @pitch.parse_pitch(input) {
        Ok(value) => Ok(@json.json_stringify(pitch_json(value)))
        Err(e) => Err(ParseFailed(e.to_string()))
      }
    "chord" =>
      match @chord.parse_chord(input) {
        Ok(value) => Ok(@json.json_stringify(chord_json(value)))
        Err(e) => Err(ParseFailed(e.to_string()))
      }
    "scale" =>
      match @scale.parse_scale(input) {
        Ok(value) => Ok(@json.json_stringify(scale_json(value)))
        Err(e) => Err(ParseFailed(e.to_string()))
      }
    "interval" =>
      match @interval.parse_interval(input) {
        Ok(value) => Ok(@json.json_stringify(interval_json(value)))
        Err(e) => Err(ParseFailed(e.to_string()))
      }
    "time" =>
      match @time.parse_time_sig(input) {
        Ok(value) => Ok(@json.json_stringify(time_signature_json(value)))
        Err(e) => Err(ParseFailed(e.to_string()))
      }
    "tempo" =>
      match @time.parse_tempo(input) {
        Ok(value) =>
          Ok(
            @json.json_stringify(
              @json.json_object([
                @json.json_field("bpm", @json.json_number(value)),
              ]),
            ),
          )
        Err(e) => Err(ParseFailed(e.to_string()))
      }
    _ => Err(UnsupportedParseKind(kind))
  }
}

///|
pub fn parse_to_json(input : String, kind : String) -> String {
  match parse_to_json_checked(input, kind) {
    Ok(data) => "{\"ok\":true,\"data\":" + data + "}"
    Err(e) => parse_error_json(e)
  }
}

///|
fn parse_error_json(error : ParseFacadeError) -> String {
  "{\"ok\":false,\"error\":\"ParseFacadeError\",\"message\":\"" +
  @json.json_escape(error.to_string()) +
  "\"}"
}

///|
fn pitch_json(value : @pitch.Pitch) -> @json.JsonValue {
  @json.json_object([
    @json.json_field("name", @json.json_string(value.to_string())),
    @json.json_field("midi", @json.json_int(value.to_midi())),
    @json.json_field(
      "class",
      @json.json_string(value.pitch_class().to_string()),
    ),
    @json.json_field(
      "accidental",
      @json.json_string(value.accidental().to_string()),
    ),
    @json.json_field("octave", @json.json_int(value.octave())),
  ])
}

///|
fn chord_json(pitches : Array[@pitch.Pitch]) -> @json.JsonValue {
  let values : Array[@json.JsonValue] = []
  for value in pitches {
    values.push(pitch_json(value))
  }
  @json.json_object([
    @json.json_field("pitches", @json.json_array(values)),
    @json.json_field("count", @json.json_int(pitches.length())),
  ])
}

///|
fn scale_json(value : @scale.Scale) -> @json.JsonValue {
  let tones : Array[@json.JsonValue] = []
  for tone in value.spelled_tones {
    tones.push(pitch_json(tone))
  }
  @json.json_object([
    @json.json_field(
      "root",
      @json.json_string(
        value.root.to_string() + value.root_accidental.to_string(),
      ),
    ),
    @json.json_field(
      "kind",
      @json.json_string(scale_kind_name(value.scale_type)),
    ),
    @json.json_field("tones", @json.json_array(tones)),
  ])
}

///|
fn interval_json(value : @interval.Interval) -> @json.JsonValue {
  @json.json_object([
    @json.json_field("quality", @json.json_string(value.quality.to_string())),
    @json.json_field("number", @json.json_int(value.number)),
    @json.json_field("semitones", @json.json_int(value.semitones)),
  ])
}

///|
fn time_signature_json(value : @time.TimeSignature) -> @json.JsonValue {
  @json.json_object([
    @json.json_field("numerator", @json.json_int(value.numerator)),
    @json.json_field("denominator", @json.json_int(value.denominator)),
  ])
}

///|
fn scale_kind_name(kind : @scale.ScaleKind) -> String {
  match kind {
    @scale.Major => "major"
    @scale.NaturalMinor => "natural minor"
    @scale.MajorPentatonic => "major pentatonic"
    @scale.MinorPentatonic => "minor pentatonic"
    @scale.HarmonicMinor => "harmonic minor"
    @scale.MelodicMinor => "melodic minor"
    @scale.Dorian => "dorian"
    @scale.Phrygian => "phrygian"
    @scale.Lydian => "lydian"
    @scale.Mixolydian => "mixolydian"
    @scale.Locrian => "locrian"
    @scale.Chromatic => "chromatic"
  }
}
