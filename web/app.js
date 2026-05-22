// moonsic v2 Browser Playback — multi-waveform + drum synthesis

let audioContext = null
let activeNodes = []
let playbackTimer = null

// Drum MIDI notes
const KICK = 36, SNARE = 38, CLOSED_HAT = 42, OPEN_HAT = 46

const demoEvents = window.MOONSIC_DEMO_EVENTS || [
  { start: 0.0, duration: 0.5, midi: 60, velocity: 0.8, channel: 0 },
  { start: 0.5, duration: 0.5, midi: 62, velocity: 0.8, channel: 0 },
  { start: 1.0, duration: 0.5, midi: 64, velocity: 0.8, channel: 0 },
  { start: 1.5, duration: 0.5, midi: 67, velocity: 0.8, channel: 0 },
  { start: 2.0, duration: 1.0, midi: 72, velocity: 0.8, channel: 0 },
]

function midiToFrequency(midi) {
  return 440 * Math.pow(2, (midi - 69) / 12)
}

function getAudioContext() {
  if (!audioContext) {
    audioContext = new (window.AudioContext || window.webkitAudioContext)()
  }
  return audioContext
}

// --- Drum synthesis ---

function playKick(event, baseTime) {
  const ctx = getAudioContext()
  const osc = ctx.createOscillator()
  osc.type = 'sine'
  const startFreq = 150
  const endFreq = 30
  osc.frequency.setValueAtTime(startFreq, baseTime + event.start)
  osc.frequency.exponentialRampToValueAtTime(endFreq, baseTime + event.start + 0.12)

  const gain = ctx.createGain()
  const maxGain = 0.6 * event.velocity
  gain.gain.setValueAtTime(maxGain, baseTime + event.start)
  gain.gain.exponentialRampToValueAtTime(0.001, baseTime + event.start + 0.15)

  osc.connect(gain)
  gain.connect(ctx.destination)
  osc.start(baseTime + event.start)
  osc.stop(baseTime + event.start + 0.15)
  activeNodes.push(osc, gain)
}

function playSnare(event, baseTime) {
  const ctx = getAudioContext()
  // Noise burst
  const bufferSize = ctx.sampleRate * 0.1
  const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate)
  const data = buffer.getChannelData(0)
  for (let i = 0; i < bufferSize; i++) data[i] = Math.random() * 2 - 1

  const noise = ctx.createBufferSource()
  noise.buffer = buffer

  const gain = ctx.createGain()
  const maxGain = 0.3 * event.velocity
  gain.gain.setValueAtTime(maxGain, baseTime + event.start)
  gain.gain.exponentialRampToValueAtTime(0.001, baseTime + event.start + 0.08)

  // Body tone
  const osc = ctx.createOscillator()
  osc.type = 'triangle'
  osc.frequency.setValueAtTime(180, baseTime + event.start)
  const oscGain = ctx.createGain()
  oscGain.gain.setValueAtTime(0.15, baseTime + event.start)
  oscGain.gain.exponentialRampToValueAtTime(0.001, baseTime + event.start + 0.06)

  noise.connect(gain)
  osc.connect(oscGain)
  gain.connect(ctx.destination)
  oscGain.connect(ctx.destination)
  noise.start(baseTime + event.start)
  osc.start(baseTime + event.start)
  noise.stop(baseTime + event.start + 0.1)
  osc.stop(baseTime + event.start + 0.1)
  activeNodes.push(noise, osc, gain, oscGain)
}

function playHat(event, baseTime) {
  const ctx = getAudioContext()
  const bufferSize = ctx.sampleRate * 0.05
  const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate)
  const data = buffer.getChannelData(0)
  for (let i = 0; i < bufferSize; i++) data[i] = Math.random() * 2 - 1

  const noise = ctx.createBufferSource()
  noise.buffer = buffer

  const hp = ctx.createBiquadFilter()
  hp.type = 'highpass'
  hp.frequency.setValueAtTime(5000, baseTime + event.start)

  const gain = ctx.createGain()
  const maxGain = 0.12 * event.velocity
  gain.gain.setValueAtTime(maxGain, baseTime + event.start)
  gain.gain.exponentialRampToValueAtTime(0.001, baseTime + event.start + 0.04)

  noise.connect(hp)
  hp.connect(gain)
  gain.connect(ctx.destination)
  noise.start(baseTime + event.start)
  noise.stop(baseTime + event.start + 0.05)
  activeNodes.push(noise, gain)
}

// --- Melodic playback ---

function playMelodic(event, baseTime) {
  const ctx = getAudioContext()
  const freq = midiToFrequency(event.midi)

  const osc = ctx.createOscillator()
  // Pick waveform based on pitch range for variety
  if (freq < 200) osc.type = 'triangle'
  else if (freq < 500) osc.type = 'sine'
  else osc.type = 'sawtooth'
  osc.frequency.setValueAtTime(freq, baseTime + event.start)

  const gain = ctx.createGain()
  const maxGain = 0.15 * event.velocity
  const attack = 0.01
  const release = 0.03

  gain.gain.setValueAtTime(0, baseTime + event.start)
  gain.gain.linearRampToValueAtTime(maxGain, baseTime + event.start + attack)
  gain.gain.setValueAtTime(maxGain, baseTime + event.start + event.duration - release)
  gain.gain.linearRampToValueAtTime(0, baseTime + event.start + event.duration)

  osc.connect(gain)
  gain.connect(ctx.destination)
  osc.start(baseTime + event.start)
  osc.stop(baseTime + event.start + event.duration + release)
  activeNodes.push(osc, gain)
}

// --- Main ---

function playNote(event, baseTime) {
  if (event.channel === 9) {
    // Drums on channel 9
    if (event.midi === KICK) playKick(event, baseTime)
    else if (event.midi === SNARE) playSnare(event, baseTime)
    else if (event.midi === CLOSED_HAT || event.midi === OPEN_HAT) playHat(event, baseTime)
    else playMelodic(event, baseTime) // fallback
  } else {
    playMelodic(event, baseTime)
  }
}

function playEvents(events) {
  stopPlayback()
  const ctx = getAudioContext()
  const baseTime = ctx.currentTime + 0.05
  const totalDuration = Math.max(...events.map(e => e.start + e.duration)) + 0.2

  for (const event of events) {
    playNote(event, baseTime)
  }

  playbackTimer = setTimeout(() => {
    cleanupNodes()
    resetUI()
  }, (baseTime - ctx.currentTime + totalDuration) * 1000)

  updateUI('playing')
}

function cleanupNodes() {
  for (const node of activeNodes) {
    try { node.disconnect() } catch (e) { /* ignore */ }
  }
  activeNodes = []
}

function stopPlayback() {
  cleanupNodes()
  if (playbackTimer) {
    clearTimeout(playbackTimer)
    playbackTimer = null
  }
  updateUI('idle')
}

function updateUI(state) {
  document.getElementById('play-btn').disabled = state === 'playing'
  document.getElementById('stop-btn').disabled = state !== 'playing'
  document.getElementById('status').textContent = state === 'playing' ? 'playing...' : 'idle'
}

function resetUI() { updateUI('idle') }

document.getElementById('play-btn').addEventListener('click', () => playEvents(demoEvents))
document.getElementById('stop-btn').addEventListener('click', () => stopPlayback())
