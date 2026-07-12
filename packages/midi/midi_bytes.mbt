// ============================================================
// MidiScore → Bytes export via CAIMEOX/midi
// ============================================================

///|
fn midi_event_to_caimeox(event : MidiEvent, delta : Int) -> @midilib.Event {
  match event.kind {
    NoteOn(channel=ch, note=n, velocity=v) =>
      @midilib.NoteOn(
        delta=delta.reinterpret_as_uint(),
        channel=ch.to_byte(),
        note=n.to_byte(),
        velocity=v.to_byte(),
      )
    NoteOff(channel=ch, note=n, velocity=v) =>
      @midilib.NoteOff(
        delta=delta.reinterpret_as_uint(),
        channel=ch.to_byte(),
        note=n.to_byte(),
        velocity=v.to_byte(),
      )
    ProgramChange(channel=ch, program=prog) =>
      @midilib.ProgramChange(
        delta=delta.reinterpret_as_uint(),
        channel=ch.to_byte(),
        program=prog.to_byte(),
      )
    ControlChange(channel=ch, controller=ctrl, value=val) =>
      @midilib.ControlChange(
        delta=delta.reinterpret_as_uint(),
        channel=ch.to_byte(),
        controller=ctrl.to_byte(),
        value=val.to_byte(),
      )
    TempoChange(bpm=bpm_val) => {
      let us = 60000000U / bpm_val.reinterpret_as_uint()
      @midilib.Tempo(delta=delta.reinterpret_as_uint(), microseconds=us)
    }
    TimeSignatureMeta(numerator=num, denominator=den) => {
      let denom_power = match den {
        1 => 0
        2 => 1
        4 => 2
        8 => 3
        16 => 4
        32 => 5
        64 => 6
        _ => 2
      }
      let ts_data : Array[Byte] = [
        num.to_byte(),
        denom_power.to_byte(),
        (24).to_byte(),
        (8).to_byte(),
      ]
      @midilib.Meta(
        delta=delta.reinterpret_as_uint(),
        meta_type=(0x58).to_byte(),
        data=ts_data,
      )
    }
    TrackName(name=name_str) => {
      let name_bytes : Array[Byte] = []
      for i = 0; i < name_str.length(); i = i + 1 {
        name_bytes.push(name_str[i].to_int().to_byte())
      }
      @midilib.Meta(
        delta=delta.reinterpret_as_uint(),
        meta_type=(0x03).to_byte(),
        data=name_bytes,
      )
    }
    EndOfTrack =>
      @midilib.Meta(
        delta=delta.reinterpret_as_uint(),
        meta_type=(0x2F).to_byte(),
        data=[],
      )
  }
}

///|
pub fn midi_score_to_bytes(score : MidiScore) -> Result[Bytes, MidiError] {
  let caimeox_tracks : Array[@midilib.Track] = []
  for track in score.tracks {
    let sorted = sort_midi_events(track.events)
    let midi_events : Array[@midilib.Event] = []
    let mut last_tick = 0
    for e in sorted {
      let delta = e.tick - last_tick
      midi_events.push(midi_event_to_caimeox(e, delta))
      last_tick = e.tick
    }
    caimeox_tracks.push(@midilib.Track::{ events: midi_events })
  }
  let file = @midilib.MidiFile::{
    format: (1).to_uint16(),
    division: score.ppq.to_uint16(),
    tracks: caimeox_tracks,
  }
  Ok(@midilib.serialize(file))
}

///|
pub fn simple_score_to_midi_bytes_checked(
  score : @score.SimpleScore,
  ppq : Int,
) -> Result[Bytes, MidiError] {
  let ms = simple_score_to_midi_score(score, ppq)
  midi_score_to_bytes(ms)
}
