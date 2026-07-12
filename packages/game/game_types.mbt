///|
pub(all) struct MusicalTime {
  bar : Int
  beat : Double
  tick : Int
}

///|
pub fn musical_time(bar : Int, beat : Double, tick : Int) -> MusicalTime {
  { bar, beat, tick }
}

///|
pub fn musical_time_zero() -> MusicalTime {
  { bar: 0, beat: 0.0, tick: 0 }
}

///|
pub(all) struct GameTimelineEntry {
  tick : Int
  channel : Int
  note : Int
  velocity : Int
  is_note_on : Bool
  duration_ticks : Int
}

///|
pub(all) struct GameTimelineSource {
  entries : Array[GameTimelineEntry]
  ppq : Int
  total_ticks : Int
}

///|
pub fn game_timeline_from_note_events(
  events : Array[@timeline.NoteEvent],
  ppq : Int,
) -> GameTimelineSource {
  let entries : Array[GameTimelineEntry] = []
  let mut max_tick = 0
  for event in events {
    let start_tick = event.start_ticks(ppq)
    let duration_ticks = event.duration_ticks(ppq)
    entries.push({
      tick: start_tick,
      channel: event.channel,
      note: event.midi_note,
      velocity: event.velocity,
      is_note_on: true,
      duration_ticks,
    })
    if start_tick + duration_ticks > max_tick {
      max_tick = start_tick + duration_ticks
    }
  }
  { entries, ppq, total_ticks: max_tick }
}

///|
pub(all) struct AudioAssetRef {
  uri : String
  asset_type : String
  format : String
}

///|
pub(all) enum GameCueKind {
  LinearCue
  LoopCue
  StingerCue
  TransitionCue
  LayeredCue
  AdaptiveCue
  MenuCue
  CombatCue
  AmbienceCue
}

///|
pub fn GameCueKind::is_default_loop(self : GameCueKind) -> Bool {
  match self {
    LinearCue | StingerCue | TransitionCue => false
    LoopCue | MenuCue | CombatCue | AmbienceCue => true
    LayeredCue | AdaptiveCue => false
  }
}

///|
pub fn GameCueKind::to_string(self : GameCueKind) -> String {
  match self {
    LinearCue => "linear"
    LoopCue => "loop"
    StingerCue => "stinger"
    TransitionCue => "transition"
    LayeredCue => "layered"
    AdaptiveCue => "adaptive"
    MenuCue => "menu"
    CombatCue => "combat"
    AmbienceCue => "ambience"
  }
}

///|
pub(all) enum TransitionQuantization {
  Immediate
  NextBeat
  NextBar
  NextPhrase(Int)
  AtMarker(String)
}

///|
pub fn TransitionQuantization::to_string(
  self : TransitionQuantization,
) -> String {
  match self {
    Immediate => "immediate"
    NextBeat => "next-beat"
    NextBar => "next-bar"
    NextPhrase(n) => "next-phrase-" + n.to_string()
    AtMarker(id) => "at-marker-" + id
  }
}

///|
pub(all) struct LoopRegion {
  id : String
  start : MusicalTime
  end : MusicalTime
  quantization : TransitionQuantization
  max_repeats : Int?
}

///|
pub(all) enum ParameterCompare {
  Equal
  NotEqual
  GreaterThan
  GreaterOrEqual
  LessThan
  LessOrEqual
}

///|
pub(all) enum GameTrigger {
  TriggerImmediate
  TriggerOnState(String)
  TriggerOnParameter(String, ParameterCompare, Double)
  TriggerOnMarker(String)
  TriggerManual(String)
}

///|
pub(all) enum TransitionBehavior {
  Cut
  Crossfade(Double)
  PlayStingerThenSwitch(String)
  WaitThenSwitch(Double)
}

///|
pub(all) enum GameSegmentSource {
  TimelineSource(GameTimelineSource)
  AudioAssetSource(AudioAssetRef)
  EmptySource
}

///|
pub(all) struct GameSegment {
  id : String
  label : String
  source : GameSegmentSource
  start : MusicalTime
  duration_beats : Double
  loop_region : LoopRegion?
  intensity_level : Int
  tags : Array[String]
}

///|
pub(all) struct GameCue {
  id : String
  name : String
  kind : GameCueKind
  segments : Array[GameSegment]
  default_loop : LoopRegion?
  tags : Array[String]
}

///|
pub(all) struct MusicState {
  id : String
  name : String
  default_cue : String
}

///|
pub(all) struct MusicParameter {
  id : String
  name : String
  min_value : Double
  max_value : Double
  default_value : Double
}

///|
pub(all) struct TransitionRule {
  id : String
  from_cue : String
  to_cue : String
  trigger : GameTrigger
  quantization : TransitionQuantization
  behavior : TransitionBehavior
  priority : Int
}

///|
pub(all) struct GameMusicMetadata {
  composer : String
  description : String
  tags : Array[String]
}

///|
pub fn empty_game_metadata() -> GameMusicMetadata {
  { composer: "", description: "", tags: [] }
}

///|
pub(all) struct GameMusicProject {
  id : String
  name : String
  tempo_bpm : Int
  time_signature : @time.TimeSignature
  cues : Array[GameCue]
  states : Array[MusicState]
  parameters : Array[MusicParameter]
  transitions : Array[TransitionRule]
  metadata : GameMusicMetadata
}

///|
pub(all) struct GameExportOptions {
  schema_version : String
  strict : Bool
  include_validation_report : Bool
  include_timelines : Bool
}

///|
pub fn default_game_export_options() -> GameExportOptions {
  {
    schema_version: "moonsic.game.v2",
    strict: false,
    include_validation_report: true,
    include_timelines: true,
  }
}

///|
fn has_duplicate_string(values : Array[String]) -> Bool {
  for i = 0; i < values.length(); i = i + 1 {
    for j = i + 1; j < values.length(); j = j + 1 {
      if values[i] == values[j] {
        return true
      }
    }
  }
  false
}

///|
fn array_contains_string(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

///|
fn extract_cue_ids(cues : Array[GameCue]) -> Array[String] {
  let ids : Array[String] = []
  for cue in cues {
    ids.push(cue.id)
  }
  ids
}
