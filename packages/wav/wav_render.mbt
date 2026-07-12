///|
pub fn note_events_to_wav_bytes_checked(
  events : Array[@timeline.NoteEvent],
  config : WavRenderConfig,
) -> Result[Bytes, WavError] {
  if config.sample_rate <= 0 {
    return Err(InvalidSampleRate(config.sample_rate))
  }
  if config.master_gain < 0.0 {
    return Err(InvalidGain(config.master_gain))
  }
  let total_seconds = @timeline.note_events_last_end(events) +
    config.tail_seconds
  if total_seconds < 0.0 {
    return Err(InvalidDuration(total_seconds))
  }
  let num_samples = (total_seconds * config.sample_rate.to_double()).to_int()
  let samples : Array[Double] = []
  for i = 0; i < num_samples; i = i + 1 {
    samples.push(0.0)
  }
  for event in events {
    render_event(samples, event, config.sample_rate)
  }
  normalize(samples, config.master_gain)
  Ok(samples_to_wav_bytes(samples, config.sample_rate))
}

///|
pub fn playback_timeline_to_wav_bytes_checked(
  timeline : @timeline.PlaybackTimeline,
  config : WavRenderConfig,
) -> Result[Bytes, WavError] {
  note_events_to_wav_bytes_checked(timeline.events, config)
}

///|
fn render_event(
  samples : Array[Double],
  event : @timeline.NoteEvent,
  sample_rate : Int,
) -> Unit {
  let freq = @pitch.midi_to_frequency(event.midi_note)
  let gain = event.velocity.to_double() / 127.0 * 0.3
  let start_sample = (event.start * sample_rate.to_double()).to_int()
  let duration_samples = (event.duration * sample_rate.to_double()).to_int()
  let attack = (0.005 * sample_rate.to_double()).to_int()
  let release = (0.02 * sample_rate.to_double()).to_int()
  for i = 0
      i < duration_samples && start_sample + i < samples.length()
      i = i + 1 {
    let t = i.to_double() / sample_rate.to_double()
    let sample = sin2pi(freq * t) * gain
    let mut env = 1.0
    if attack > 0 && i < attack {
      env = i.to_double() / attack.to_double()
    } else if release > 0 && duration_samples - i < release {
      env = (duration_samples - i).to_double() / release.to_double()
    }
    let idx = start_sample + i
    samples[idx] = samples[idx] + sample * env
  }
}

///|
fn normalize(samples : Array[Double], master_gain : Double) -> Unit {
  let mut peak = 0.0
  for sample in samples {
    let abs = if sample < 0.0 { -sample } else { sample }
    if abs > peak {
      peak = abs
    }
  }
  let scale = if peak > 0.0 && peak > 1.0 {
    master_gain / peak
  } else {
    master_gain
  }
  for i = 0; i < samples.length(); i = i + 1 {
    samples[i] = samples[i] * scale
  }
}

///|
fn samples_to_wav_bytes(samples : Array[Double], sample_rate : Int) -> Bytes {
  let buf : Array[Byte] = []
  for i = 0; i < 44; i = i + 1 {
    buf.push((0).to_byte())
  }
  write_wav_header_arr(buf, samples.length(), sample_rate)
  for sample in samples {
    let scaled = sample * 32767.0
    let value = if scaled > 32767.0 {
      32767
    } else if scaled < -32768.0 {
      -32768
    } else {
      scaled.to_int()
    }
    buf.push((value & 0xFF).to_byte())
    buf.push(((value >> 8) & 0xFF).to_byte())
  }
  Bytes::from_array(buf)
}

///|
fn sin2pi(x : Double) -> Double {
  @math.sin(2.0 * 3.141592653589793 * x)
}
