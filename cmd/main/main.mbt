///|
/// Minimal Example — generate a C major scale, export MIDI:
/// ```
/// let notes = @lib.melody_str("C4q D4q E4q F4q G4q A4q B4q C5q")
/// let song = @lib.score1(notes)
/// let _ = song.to_midi_bytes_with_ppq_checked(480)
/// ```

///|
/// 苏打绿 — 他夏了夏天（C 大调, 4/4, ♩=120）
/// 运行：`moon run cmd/main`
fn main {
  // I-V-vi-IV 和弦进行
  let chords = @lib.progression(
    @lib.c(3),
    @lib.Major,
    [@lib.I, @lib.V, @lib.VI, @lib.IV],
    @lib.half(),
  ).repeat(16)

  let arp = @lib.instrument(
    @lib.arpeggiate(chords, @lib.eighth()),
    @lib.electric_piano_1(),
  )
  let bass = @lib.instrument(
    @lib.bass_roots(chords, @lib.half()),
    @lib.electric_bass_finger(),
  )

  // 主歌
  let verse = @lib.melody_str(
    "C4q D4q E4q G4q | A4q G4q E4q D4q | C4q D4q E4q G4q | A4q G4q E4q D4q " +
    "C4q D4q E4q A4q | G4q E4q D4q C4q | B3q C4q D4q G4q | E4h D4q C4q",
  )

  // 副歌
  let chorus = @lib.melody_str(
    "C4q C4q D4q E4q | E4q D4q C4q G3q | A3q A3q G3q E3q | D3w " +
    "G3q G3q A3q C4q | C4q A3q G3q E3q | D3q E3q G3q A3q | G3w",
  )

  let lead = @lib.instrument(
    verse.concat(verse).concat(chorus).concat(chorus),
    @lib.synth_lead_square(),
  )
  let drums = @lib.basic_beat(32)

  let song = @lib.score_with(
    [arp, bass, lead, drums.tracks[0], drums.tracks[1], drums.tracks[2]],
    120,
    @lib.four_four(),
  )

  println(@lib.note_events_to_browser_js(song.to_note_events()))
}
