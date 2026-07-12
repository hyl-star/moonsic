// ============================================================
// MIDI Import — Bytes → MidiEvent → SimpleScore
// 使用 CAIMEOX/midi 反序列化，将 .mid 字节转回 SimpleScore
// ============================================================

// --- CAIMEOX/midi event helpers ---

///|
/// Extract delta time (as Int) from any CAIMEOX/midi Event variant.
fn extract_delta(event : @midilib.Event) -> Int {
  match event {
    @midilib.NoteOn(delta~, ..)
    | @midilib.NoteOff(delta~, ..)
    | @midilib.ProgramChange(delta~, ..)
    | @midilib.ControlChange(delta~, ..)
    | @midilib.Tempo(delta~, ..)
    | @midilib.TimeSignature(delta~, ..)
    | @midilib.KeySignature(delta~, ..)
    | @midilib.Meta(delta~, ..)
    | @midilib.SysEx(delta~, ..)
    | @midilib.Aftertouch(delta~, ..)
    | @midilib.PolyTouch(delta~, ..)
    | @midilib.PitchWheel(delta~, ..)
    | @midilib.Clock(delta~)
    | @midilib.Start(delta~)
    | @midilib.Continue(delta~)
    | @midilib.Stop(delta~)
    | @midilib.ActiveSensing(delta~)
    | @midilib.Reset(delta~) => delta.reinterpret_as_int()
  }
}

///|
/// Convert a CAIMEOX/midi Event to our internal MidiEventKind.
/// Returns None for unsupported event types (PitchBend, SysEx,
/// PolyTouch, Aftertouch, KeySignature, generic Meta, Clock, etc.),
/// which are silently skipped during import.
fn import_event_to_kind(event : @midilib.Event) -> MidiEventKind? {
  match event {
    // Note On — velocity 0 is treated as NoteOff during pairing
    @midilib.NoteOn(delta=_, channel=ch, note=n, velocity=v) =>
      Some(NoteOn(channel=ch.to_int(), note=n.to_int(), velocity=v.to_int()))
    // Note Off
    @midilib.NoteOff(delta=_, channel=ch, note=n, velocity=v) =>
      Some(NoteOff(channel=ch.to_int(), note=n.to_int(), velocity=v.to_int()))
    // Program Change
    @midilib.ProgramChange(delta=_, channel=ch, program=p) =>
      Some(ProgramChange(channel=ch.to_int(), program=p.to_int()))
    // Control Change — recorded as warning-level event
    @midilib.ControlChange(delta=_, channel=ch, controller=ctrl, value=val) =>
      Some(
        ControlChange(
          channel=ch.to_int(),
          controller=ctrl.to_int(),
          value=val.to_int(),
        ),
      )
    // Tempo meta event (0x51) — microseconds per quarter → BPM
    @midilib.Tempo(delta=_, microseconds=us) => {
      let bpm = (60000000.0 / us.to_double()).to_int()
      Some(TempoChange(bpm~))
    }
    // Time Signature meta event (0x58)
    @midilib.TimeSignature(
      delta=_,
      numerator=num,
      denominator=den,
      clocks_per_beat=_,
      thirty_seconds_per_quarter=_
    ) =>
      Some(TimeSignatureMeta(numerator=num.to_int(), denominator=den.to_int()))
    // End of Track meta (0x2F)
    @midilib.Meta(delta=_, meta_type=0x2F, data=_) => Some(EndOfTrack)
    // Track Name meta (0x03)
    @midilib.Meta(delta=_, meta_type=0x03, data~) => {
      let name = bytes_to_ascii_string(data)
      Some(TrackName(name~))
    }
    // Unsupported events → silently skipped
    @midilib.PitchWheel(..)
    | @midilib.PolyTouch(..)
    | @midilib.Aftertouch(..)
    | @midilib.KeySignature(..)
    | @midilib.Meta(..)
    | @midilib.SysEx(..)
    | @midilib.Clock(_)
    | @midilib.Start(_)
    | @midilib.Continue(_)
    | @midilib.Stop(_)
    | @midilib.ActiveSensing(_)
    | @midilib.Reset(_) => None
  }
}

///|
/// Convert an Array[Byte] to an ASCII String, filtering non-printable chars.
fn bytes_to_ascii_string(data : Array[Byte]) -> String {
  let chars : Array[Char] = []
  for b in data {
    let i = b.to_int()
    if i >= 32 && i < 127 {
      chars.push(i.to_char().unwrap())
    }
  }
  if chars.length() == 0 {
    "Unnamed"
  } else {
    String::from_array(chars)
  }
}

// --- internal parser wrapper (catches CAIMEOX/midi raise errors) ---

///|
/// Internal: call @midilib.parse and convert raise→Result.
fn try_parse_midi(bytes : Bytes) -> Result[@midilib.MidiFile, MidiError] {
  Ok(@midilib.parse(bytes)) catch {
    _ =>
      Err(MidiImportError("MIDI parse failed: invalid or unsupported format"))
  }
}

///|
/// Internal: convert a @midilib.MidiFile to flat absolute-tick MidiEvents.
fn midi_file_to_events(file : @midilib.MidiFile) -> Array[MidiEvent] {
  let result : Array[MidiEvent] = []
  for track in file.tracks {
    let mut abs_tick = 0
    for evt in track.events {
      abs_tick = abs_tick + extract_delta(evt)
      match import_event_to_kind(evt) {
        Some(kind) => result.push({ tick: abs_tick, kind })
        None => ()
      }
    }
  }
  result
}

// ============================================================
// ticks → RhythmDuration helpers
// ============================================================

///|
/// Map MIDI tick duration to a known RhythmDuration using exact integer
/// comparison against PPQ. Returns Err if ticks do not match any
/// common duration (whole, half, quarter, eighth, sixteenth, dotted
/// half/quarter/eighth, quarter triplet, eighth triplet).
///
/// Comparison uses integer arithmetic to avoid floating-point drift.
fn ticks_to_rhythm_duration_checked(
  ticks : Int,
  ppq : Int,
) -> Result[@time.RhythmDuration, MidiError] {
  let rd = @time.rhythm_duration
  // Standard durations
  if ticks == ppq * 4 {
    return Ok(rd(@time.DurWhole, 0, None))
  }
  // Dotted half = half * 3/2 = 3 quarters = 3 * ppq
  if ticks == ppq * 3 {
    return Ok(rd(@time.DurHalf, 1, None))
  }
  // Half = 2 quarters
  if ticks == ppq * 2 {
    return Ok(rd(@time.DurHalf, 0, None))
  }
  // Dotted quarter = quarter * 3/2 = 3/2 quarters
  if ticks * 2 == ppq * 3 {
    return Ok(rd(@time.DurQuarter, 1, None))
  }
  // Quarter = 1 quarter
  if ticks == ppq {
    return Ok(rd(@time.DurQuarter, 0, None))
  }
  // Dotted eighth = eighth * 3/2 = 3/4 quarters
  if ticks * 4 == ppq * 3 {
    return Ok(rd(@time.DurEighth, 1, None))
  }
  // Eighth = 1/2 quarter
  if ticks * 2 == ppq {
    return Ok(rd(@time.DurEighth, 0, None))
  }
  // Sixteenth = 1/4 quarter
  if ticks * 4 == ppq {
    return Ok(rd(@time.DurSixteenth, 0, None))
  }
  // Quarter triplet: 3 notes span 2 quarters → each = 2/3 quarter
  if ticks * 3 == ppq * 2 {
    return Ok(
      rd(@time.DurQuarter, 0, Some(@time.TupletRatio::{ actual: 3, normal: 2 })),
    )
  }
  // Eighth triplet: 3 notes span 2 eighths (1 quarter) → each = 1/3 quarter
  if ticks * 3 == ppq {
    return Ok(
      rd(@time.DurEighth, 0, Some(@time.TupletRatio::{ actual: 3, normal: 2 })),
    )
  }
  Err(
    MidiImportError(
      "Cannot map ticks=\{ticks} ppq=\{ppq} to exact RhythmDuration",
    ),
  )
}

///|
/// Fallback: map MIDI tick duration to the nearest known RhythmDuration
/// when exact match fails. The known-duration denominator list is ordered
/// with longer durations first as a tie-breaker.
///
/// Uses absolute difference in quarter-note un-normalized ticks to find
/// the closest match.
fn nearest_ticks_to_rhythm_duration(
  ticks : Int,
  ppq : Int,
) -> @time.RhythmDuration {
  let rd = @time.rhythm_duration
  // (num_quarters, den_quarters, duration)
  // num_quarters / den_quarters = fraction of a quarter note
  let known : Array[(Int, Int, @time.RhythmDuration)] = [
    (4, 1, rd(@time.DurWhole, 0, None)),
    (3, 1, rd(@time.DurHalf, 1, None)),
    (2, 1, rd(@time.DurHalf, 0, None)),
    (3, 2, rd(@time.DurQuarter, 1, None)),
    (1, 1, rd(@time.DurQuarter, 0, None)),
    (3, 4, rd(@time.DurEighth, 1, None)),
    (1, 2, rd(@time.DurEighth, 0, None)),
    (1, 4, rd(@time.DurSixteenth, 0, None)),
  ]
  let mut best_dur = rd(@time.DurQuarter, 0, None)
  let mut best_err : Int = -1

  for pair in known {
    let (num, den, dur) = pair
    // Un-normalized tick error: |ticks*den - num*ppq|
    let err = (ticks * den - num * ppq).abs()
    if best_err < 0 || err < best_err {
      best_err = err
      best_dur = dur
    }
  }
  best_dur
}

// --- public API ---

///|
/// Parse raw MIDI bytes into a flat array of absolute-tick MidiEvents
/// across all tracks. Uses CAIMEOX/midi for deserialization.
///
/// The returned events are not sorted by tick — they retain per-track
/// ordering. Callers should sort before further processing if needed.
pub fn midi_bytes_to_events(
  bytes : Bytes,
) -> Result[Array[MidiEvent], MidiError] {
  match try_parse_midi(bytes) {
    Ok(file) => Ok(midi_file_to_events(file))
    Err(e) => Err(e)
  }
}

///|
/// Convert a flat array of MidiEvent (absolute ticks) into a SimpleScore
/// by pairing NoteOn/NoteOff per channel into SimpleNote events.
///
/// - Only NoteOn (velocity > 0) / NoteOff / NoteOn (velocity == 0) events
///   participate in note pairing; other events are used for metadata
///   extraction.
/// - The first TempoChange event determines the score tempo; if none is
///   found, defaults to 120 BPM.
/// - The first TimeSignatureMeta event determines the time signature;
///   if none is found, defaults to 4/4.
/// - Notes are grouped into one SimpleTrack per MIDI channel.
/// - Unpaired active notes at the end of the stream are discarded silently.
/// - Note durations are reconstructed from MIDI note-on/off tick pairs
///   and mapped to known RhythmDuration values via PPQ-aware matching.
pub fn midi_events_to_score(
  events : Array[MidiEvent],
  ppq : Int,
) -> Result[@score.SimpleScore, MidiError] {
  // Validate ppq
  if ppq <= 0 {
    return Err(InvalidMidiPPQ(ppq))
  }

  // Extract global metadata: tempo and time signature
  let mut tempo_bpm = 120
  let mut sig_num = 4
  let mut sig_den = 4
  // Per-channel program (channel → program)
  let channel_programs : Array[(Int, Int)] = []

  for evt in events {
    match evt.kind {
      TempoChange(bpm=b) => if tempo_bpm == 120 { tempo_bpm = b }
      TimeSignatureMeta(numerator=n, denominator=d) =>
        if sig_num == 4 && sig_den == 4 {
          sig_num = n
          sig_den = d
        }
      ProgramChange(channel=ch, program=prog) => {
        let mut found = false
        for i = 0; i < channel_programs.length(); i = i + 1 {
          if channel_programs[i].0 == ch {
            channel_programs[i] = (ch, prog)
            found = true
            break
          }
        }
        if !found {
          channel_programs.push((ch, prog))
        }
      }
      _ => ()
    }
  }

  // Build Score metadata
  let time_sig = @time.time_signature(sig_num, sig_den)

  // Pair NoteOn/NoteOff per channel
  // active_notes: per channel, map from note → (start_tick, velocity)
  // Use per-channel arrays since channels are 0-15
  let active_notes : Array[Array[(Int, Int, Int)]] = Array::makei(16, fn(_) {
    []
  })
  // per-channel result notes: (tick, pitch, velocity, duration_ticks)
  let channel_notes : Array[Array[(Int, Int, Int, Int)]] = Array::makei(16, fn(
    _,
  ) {
    []
  })

  // Sort events by tick for correct temporal ordering
  let sorted_events = sort_midi_events(events)

  for evt in sorted_events {
    match evt.kind {
      NoteOn(channel=ch, note=n, velocity=v) =>
        if v > 0 {
          // Note start
          if ch >= 0 && ch < 16 {
            active_notes[ch].push((n, evt.tick, v))
          }
          // velocity 0 ≡ NoteOff
        } else if ch >= 0 && ch < 16 {
          // Find matching active note
          let mut idx = -1
          for i = 0; i < active_notes[ch].length(); i = i + 1 {
            if active_notes[ch][i].0 == n {
              idx = i
              break
            }
          }
          if idx >= 0 {
            let (_, start_tick, vel) = active_notes[ch][idx]
            let dur_ticks = evt.tick - start_tick
            if dur_ticks > 0 {
              channel_notes[ch].push((start_tick, n, vel, dur_ticks))
            }
            let _ = active_notes[ch].remove(idx)
          }
        }
      NoteOff(channel=ch, note=n, velocity=_) =>
        if ch >= 0 && ch < 16 {
          let mut idx = -1
          for i = 0; i < active_notes[ch].length(); i = i + 1 {
            if active_notes[ch][i].0 == n {
              idx = i
              break
            }
          }
          if idx >= 0 {
            let (_, start_tick, vel) = active_notes[ch][idx]
            let dur_ticks = evt.tick - start_tick
            if dur_ticks > 0 {
              channel_notes[ch].push((start_tick, n, vel, dur_ticks))
            }
            let _ = active_notes[ch].remove(idx)
          }
        }
      _ => ()
    }
  }

  // Discard any remaining active notes silently

  // Build SimpleTracks — one per channel that has notes
  let tracks : Array[@score.SimpleTrack] = []

  for ch = 0; ch < 16; ch = ch + 1 {
    if channel_notes[ch].length() == 0 {
      continue
    }

    // Sort notes by start tick within channel
    let notes = channel_notes[ch]
    // Simple bubble sort by tick
    for i = 1; i < notes.length(); i = i + 1 {
      let key = notes[i]
      let mut j = i - 1
      while j >= 0 && notes[j].0 > key.0 {
        notes[j + 1] = notes[j]
        j = j - 1
      }
      notes[j + 1] = key
    }

    // Convert to SimpleEvent array with duration reconstruction
    let sevents : Array[@score.SimpleEvent] = []
    for note in notes {
      let (_, midi_note, vel_val, dur_ticks) = note
      // Convert MIDI note → Pitch
      let pitch = @pitch.midi_to_pitch(midi_note)
      let vel = @score.Velocity::{ value: vel_val }
      // Map duration ticks to RhythmDuration:
      //   1. Try exact match via ticks_to_rhythm_duration_checked
      //   2. Fall back to nearest known duration on mismatch
      let dur = match ticks_to_rhythm_duration_checked(dur_ticks, ppq) {
        Ok(d) => d
        Err(_) => nearest_ticks_to_rhythm_duration(dur_ticks, ppq)
      }
      let sn = @score.SimpleNote::{ pitch, duration: dur, velocity: vel }
      sevents.push(@score.Note(sn))
    }

    // Look up program for this channel
    let mut prog : @score.MidiProgram? = None
    for i = 0; i < channel_programs.length(); i = i + 1 {
      if channel_programs[i].0 == ch {
        prog = Some(@score.MidiProgram::{ value: channel_programs[i].1 })
        break
      }
    }

    let track = @score.SimpleTrack::{
      events: sevents,
      channel: Some(@score.MidiChannel::{ value: ch }),
      program: prog,
      volume: 1.0,
      pan: 0.5,
      mute: false,
    }
    tracks.push(track)
  }

  // If no tracks have notes, create a single empty track
  if tracks.length() == 0 {
    let empty_evts : Array[@score.SimpleEvent] = []
    let empty_track = @score.SimpleTrack::{
      events: empty_evts,
      channel: None,
      program: None,
      volume: 1.0,
      pan: 0.5,
      mute: false,
    }
    tracks.push(empty_track)
  }

  let score = @score.SimpleScore::{
    tempo: @score.Tempo::{ bpm: tempo_bpm },
    time_signature: time_sig,
    tracks,
    master_gain: 1.0,
  }
  Ok(score)
}

///|
/// Parse raw MIDI bytes directly into a SimpleScore.
/// Convenience pipeline: bytes → CAIMEOX parse → flat MidiEvents → SimpleScore.
///
/// Internally extracts PPQ from the MIDI file header and delegates to
/// `midi_events_to_score` for note pairing and score construction.
pub fn midi_bytes_to_score(
  bytes : Bytes,
) -> Result[@score.SimpleScore, MidiError] {
  match try_parse_midi(bytes) {
    Ok(file) => {
      let ppq = file.division.to_int()
      let flat_events = midi_file_to_events(file)
      midi_events_to_score(flat_events, ppq)
    }
    Err(e) => Err(e)
  }
}
