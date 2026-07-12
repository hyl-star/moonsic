///|
pub(all) enum WebTimeUnit {
  Seconds
  Ticks
  Beats
}

///|
pub fn WebTimeUnit::to_string(self : WebTimeUnit) -> String {
  match self {
    Seconds => "seconds"
    Ticks => "ticks"
    Beats => "beats"
  }
}

///|
pub(all) struct WebPlaybackConfig {
  tempo_bpm : Int
  ppq : Int
  include_note_off : Bool
  time_unit : WebTimeUnit
}

///|
pub fn default_web_playback_config() -> WebPlaybackConfig {
  { tempo_bpm: 120, ppq: 480, include_note_off: false, time_unit: Seconds }
}

///|
pub(all) struct WebPlaybackEvent {
  time : Double
  duration : Double
  midi_note : Int
  velocity : Int
  channel : Int
  event_type : String
}

///|
pub(all) struct WebEventDocument {
  schema_version : String
  events : Array[WebPlaybackEvent]
  total_seconds : Double
}
