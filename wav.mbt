// ============================================================
// WAV/PCM 导出 — Score → 16-bit 44100Hz mono PCM WAV
// ============================================================

///|
pub fn Score::to_wav_bytes(self : Score) -> Bytes {
  let sample_rate = 44100
  let events = self.to_note_events()
  let total_seconds = max_event_end(events) + 0.1
  let num_samples = (total_seconds * sample_rate.to_double()).to_int()
  let bpm = self.tempo.bpm

  // 分配采样缓冲
  let samples : Array[Double] = []
  for _i = 0; _i < num_samples; _i = _i + 1 {
    samples.push(0.0)
  }

  // 渲染每个音符
  for e in events {
    let freq = midi_to_frequency(e.midi_note)
    let gain = e.velocity.to_double() / 127.0 * 0.3
    let start_s = e.start_seconds(bpm)
    let dur_s = e.duration_seconds(bpm)
    let start_smp = (start_s * sample_rate.to_double()).to_int()
    let dur_smp = (dur_s * sample_rate.to_double()).to_int()
    let attack = (0.005 * sample_rate.to_double()).to_int()
    let release = (0.02 * sample_rate.to_double()).to_int()
    for i = 0; i < dur_smp && start_smp + i < num_samples; i = i + 1 {
      let t = i.to_double() / sample_rate.to_double()
      let sample = sin2pi(freq * t) * gain
      let mut env = 1.0
      if i < attack {
        env = i.to_double() / attack.to_double()
      } else if dur_smp - i < release && release > 0 {
        env = (dur_smp - i).to_double() / release.to_double()
      }
      let idx = start_smp + i
      samples[idx] = samples[idx] + sample * env
    }
  }

  // 转为 16-bit PCM
  let buf : Array[Byte] = []
  // RIFF header placeholder
  for _i = 0; _i < 44; _i = _i + 1 {
    buf.push((0).to_byte())
  }
  write_wav_header_arr(buf, num_samples, sample_rate)

  for i = 0; i < num_samples; i = i + 1 {
    let scaled = samples[i] * 32767.0
    let val = if scaled > 32767.0 {
      32767
    } else if scaled < -32768.0 {
      -32768
    } else {
      scaled.to_int()
    }
    buf.push((val & 0xFF).to_byte())
    buf.push(((val >> 8) & 0xFF).to_byte())
  }

  Bytes::from_array(buf)
}

///|
fn max_event_end(events : Array[NoteEvent]) -> Double {
  let mut max_end = 0.0
  for e in events {
    let end_t = e.start + e.duration
    if end_t > max_end {
      max_end = end_t
    }
  }
  max_end
}

///|
fn sin2pi(x : Double) -> Double {
  @math.sin(2.0 * 3.141592653589793 * x)
}

///|
fn write_wav_header_arr(
  buf : Array[Byte],
  num_samples : Int,
  sample_rate : Int,
) -> Unit {
  let byte_rate = sample_rate * 2
  let data_size = num_samples * 2
  let file_size = 36 + data_size

  // "RIFF"
  buf[0] = b'R'
  buf[1] = b'I'
  buf[2] = b'F'
  buf[3] = b'F'
  write_u32le(buf, 4, file_size)
  // "WAVE"
  buf[8] = b'W'
  buf[9] = b'A'
  buf[10] = b'V'
  buf[11] = b'E'
  // "fmt "
  buf[12] = b'f'
  buf[13] = b'm'
  buf[14] = b't'
  buf[15] = b' '
  write_u32le(buf, 16, 16)
  write_u16le(buf, 20, 1)
  write_u16le(buf, 22, 1)
  write_u32le(buf, 24, sample_rate)
  write_u32le(buf, 28, byte_rate)
  write_u16le(buf, 32, 2)
  write_u16le(buf, 34, 16)
  // "data"
  buf[36] = b'd'
  buf[37] = b'a'
  buf[38] = b't'
  buf[39] = b'a'
  write_u32le(buf, 40, data_size)
}

///|
fn write_u32le(buf : Array[Byte], offset : Int, value : Int) -> Unit {
  buf[offset] = (value & 0xFF).to_byte()
  buf[offset + 1] = ((value >> 8) & 0xFF).to_byte()
  buf[offset + 2] = ((value >> 16) & 0xFF).to_byte()
  buf[offset + 3] = ((value >> 24) & 0xFF).to_byte()
}

///|
fn write_u16le(buf : Array[Byte], offset : Int, value : Int) -> Unit {
  buf[offset] = (value & 0xFF).to_byte()
  buf[offset + 1] = ((value >> 8) & 0xFF).to_byte()
}
