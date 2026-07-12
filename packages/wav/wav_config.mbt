///|
pub(all) struct WavRenderConfig {
  sample_rate : Int
  master_gain : Double
  tail_seconds : Double
}

///|
pub fn default_wav_render_config() -> WavRenderConfig {
  { sample_rate: 44100, master_gain: 0.85, tail_seconds: 0.1 }
}

///|
pub fn wav_render_config_checked(
  sample_rate : Int,
  master_gain : Double,
  tail_seconds : Double,
) -> Result[WavRenderConfig, WavError] {
  if sample_rate <= 0 {
    return Err(InvalidSampleRate(sample_rate))
  }
  if master_gain < 0.0 {
    return Err(InvalidGain(master_gain))
  }
  if tail_seconds < 0.0 {
    return Err(InvalidDuration(tail_seconds))
  }
  Ok({ sample_rate, master_gain, tail_seconds })
}
