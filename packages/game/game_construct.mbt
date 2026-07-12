///|
pub fn game_project_checked(
  id : String,
  name : String,
  cues : Array[GameCue],
) -> Result[GameMusicProject, GameMusicError] {
  game_project_full_checked(id, name, cues, [], [], [])
}

///|
pub fn game_project_full_checked(
  id : String,
  name : String,
  cues : Array[GameCue],
  states : Array[MusicState],
  parameters : Array[MusicParameter],
  transitions : Array[TransitionRule],
) -> Result[GameMusicProject, GameMusicError] {
  if id == "" {
    return Err(InvalidProjectId("project id cannot be empty"))
  }
  let cue_ids = extract_cue_ids(cues)
  if has_duplicate_string(cue_ids) {
    return Err(DuplicateCueId("duplicate cue id"))
  }
  for transition in transitions {
    if !array_contains_string(cue_ids, transition.from_cue) {
      return Err(MissingTransitionTarget("from cue: " + transition.from_cue))
    }
    if !array_contains_string(cue_ids, transition.to_cue) {
      return Err(MissingTransitionTarget("to cue: " + transition.to_cue))
    }
  }
  Ok({
    id,
    name,
    tempo_bpm: 120,
    time_signature: @time.time_signature(4, 4),
    cues,
    states,
    parameters,
    transitions,
    metadata: empty_game_metadata(),
  })
}

///|
pub fn game_cue_checked(
  id : String,
  name : String,
  kind : GameCueKind,
  segments : Array[GameSegment],
) -> Result[GameCue, GameMusicError] {
  if id == "" {
    return Err(InvalidCue("cue id cannot be empty"))
  }
  Ok({ id, name, kind, segments, default_loop: None, tags: [] })
}

///|
pub fn game_segment_from_timeline_checked(
  id : String,
  label : String,
  timeline : GameTimelineSource,
) -> Result[GameSegment, GameMusicError] {
  if id == "" {
    return Err(EmptySegment("segment id cannot be empty"))
  }
  let duration_beats = timeline.total_ticks.to_double() /
    timeline.ppq.to_double()
  if duration_beats <= 0.0 {
    return Err(InvalidSegmentDuration("timeline is empty"))
  }
  Ok({
    id,
    label,
    source: TimelineSource(timeline),
    start: musical_time_zero(),
    duration_beats,
    loop_region: None,
    intensity_level: 5,
    tags: [],
  })
}

///|
pub fn loop_region_checked(
  id : String,
  start : MusicalTime,
  end : MusicalTime,
  quantization : TransitionQuantization,
) -> Result[LoopRegion, GameMusicError] {
  if end.bar < start.bar || (end.bar == start.bar && end.beat <= start.beat) {
    return Err(InvalidLoopRegion("loop end must be after loop start"))
  }
  Ok({ id, start, end, quantization, max_repeats: None })
}

///|
pub fn transition_rule_checked(
  id : String,
  from_cue : String,
  to_cue : String,
  trigger : GameTrigger,
  quantization : TransitionQuantization,
  behavior : TransitionBehavior,
) -> Result[TransitionRule, GameMusicError] {
  if id == "" {
    return Err(InvalidTransitionRule("transition id cannot be empty"))
  }
  if from_cue == "" || to_cue == "" {
    return Err(InvalidTransitionRule("transition endpoints cannot be empty"))
  }
  if from_cue == to_cue {
    return Err(InvalidTransitionRule("transition endpoints cannot match"))
  }
  Ok({ id, from_cue, to_cue, trigger, quantization, behavior, priority: 0 })
}
