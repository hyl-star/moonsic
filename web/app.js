// moonsic v4 Browser Playback Engine
// Scheduler + ADSR synth voices + loop + drum synthesis

let audioContext = null
let schedulerTimer = null
let activeNodes = []
let playbackState = 'idle' // idle | playing
let loopEnabled = false
let currentEvents = []
let currentBaseTime = 0
let totalDuration = 0
let nextEventIndex = 0

const LOOKAHEAD = 0.025  // seconds
const SCHEDULE_AHEAD = 0.1

// --- Synth Voice Presets ---

const VOICES = {
  sine_lead:   { type: 'sine',     attack: 0.01, decay: 0.05, sustain: 0.7, release: 0.05, gain: 0.18 },
  triangle_bass:{ type: 'triangle', attack: 0.005, decay: 0.03, sustain: 0.8, release: 0.03, gain: 0.22 },
  square_lead: { type: 'square',   attack: 0.01, decay: 0.04, sustain: 0.6, release: 0.04, gain: 0.12 },
  saw_pad:     { type: 'sawtooth', attack: 0.08, decay: 0.1,  sustain: 0.5, release: 0.15, gain: 0.08 },
  soft_bell:   { type: 'sine',     attack: 0.002, decay: 0.3, sustain: 0.0, release: 0.01, gain: 0.15 },
}

// Voice assignment: channel → voice name
function voiceForChannel(channel) {
  if (channel === 9) return null // drums handled separately
  if (channel === 0) return 'sine_lead'
  return 'triangle_bass'
}

// --- ADSR Envelope ---

function applyADSR(gainNode, voice, startTime, duration, baseTime) {
  const g = gainNode.gain
  const t = baseTime + startTime
  const a = voice.attack, d = voice.decay, s = voice.sustain, r = voice.release, v = voice.gain

  g.setValueAtTime(0, t)
  g.linearRampToValueAtTime(v, t + a)
  if (duration > a + d + r) {
    g.linearRampToValueAtTime(v * s, t + a + d)
    g.setValueAtTime(v * s, t + duration - r)
    g.linearRampToValueAtTime(0, t + duration)
  } else {
    // short note: simplified envelope
    const hold = Math.max(0.01, duration * 0.6)
    g.linearRampToValueAtTime(v * s, t + a + d)
    g.setValueAtTime(v * s, t + hold)
    g.linearRampToValueAtTime(0, t + duration)
  }
}

// --- Synth Voice Playback ---

function playSynthNote(event, baseTime) {
  const ctx = audioContext
  const freq = 440 * Math.pow(2, (event.midi - 69) / 12)
  const voiceName = voiceForChannel(event.channel)
  if (!voiceName) return
  const voice = VOICES[voiceName]

  const osc = ctx.createOscillator()
  osc.type = voice.type
  osc.frequency.setValueAtTime(freq, baseTime + event.start)

  const gain = ctx.createGain()
  applyADSR(gain, voice, event.start, event.duration, baseTime)

  osc.connect(gain)
  gain.connect(ctx.destination)
  osc.start(baseTime + event.start)
  osc.stop(baseTime + event.start + event.duration + voice.release)
  activeNodes.push(osc, gain)
}

// --- Drum Synthesis ---

function playDrumNote(event, baseTime) {
  const ctx = audioContext
  const t = baseTime + event.start
  const midi = event.midi

  if (midi === 36) { // Kick
    const osc = ctx.createOscillator()
    osc.type = 'sine'
    osc.frequency.setValueAtTime(150, t)
    osc.frequency.exponentialRampToValueAtTime(30, t + 0.12)
    const gain = ctx.createGain()
    gain.gain.setValueAtTime(0.6 * event.velocity, t)
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.15)
    osc.connect(gain); gain.connect(ctx.destination)
    osc.start(t); osc.stop(t + 0.15)
    activeNodes.push(osc, gain)
  } else if (midi === 38) { // Snare
    const bufSize = ctx.sampleRate * 0.1
    const buf = ctx.createBuffer(1, bufSize, ctx.sampleRate)
    const d = buf.getChannelData(0)
    for (let i = 0; i < bufSize; i++) d[i] = Math.random() * 2 - 1
    const noise = ctx.createBufferSource(); noise.buffer = buf
    const g1 = ctx.createGain()
    g1.gain.setValueAtTime(0.3 * event.velocity, t)
    g1.gain.exponentialRampToValueAtTime(0.001, t + 0.08)
    noise.connect(g1); g1.connect(ctx.destination)
    const osc = ctx.createOscillator(); osc.type = 'triangle'
    osc.frequency.setValueAtTime(180, t)
    const g2 = ctx.createGain()
    g2.gain.setValueAtTime(0.15, t)
    g2.gain.exponentialRampToValueAtTime(0.001, t + 0.06)
    osc.connect(g2); g2.connect(ctx.destination)
    noise.start(t); osc.start(t)
    noise.stop(t + 0.1); osc.stop(t + 0.1)
    activeNodes.push(noise, osc, g1, g2)
  } else if (midi === 42 || midi === 46) { // Hat
    const bufSize = ctx.sampleRate * 0.05
    const buf = ctx.createBuffer(1, bufSize, ctx.sampleRate)
    const d = buf.getChannelData(0)
    for (let i = 0; i < bufSize; i++) d[i] = Math.random() * 2 - 1
    const noise = ctx.createBufferSource(); noise.buffer = buf
    const hp = ctx.createBiquadFilter(); hp.type = 'highpass'
    hp.frequency.setValueAtTime(5000, t)
    const gain = ctx.createGain()
    gain.gain.setValueAtTime(0.12 * event.velocity, t)
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.04)
    noise.connect(hp); hp.connect(gain); gain.connect(ctx.destination)
    noise.start(t); noise.stop(t + 0.05)
    activeNodes.push(noise, gain)
  }
}

// --- Scheduler ---

function scheduleAhead(baseTime) {
  const horizon = audioContext.currentTime + SCHEDULE_AHEAD
  while (nextEventIndex < currentEvents.length) {
    const e = currentEvents[currentEventsIndex]
    const eventTime = baseTime + e.start
    if (eventTime > horizon) break
    if (e.channel === 9) {
      playDrumNote(e, baseTime)
    } else {
      playSynthNote(e, baseTime)
    }
    nextEventIndex++
  }
}

function schedulerTick() {
  if (playbackState !== 'playing') return
  scheduleAhead(currentBaseTime)
  if (nextEventIndex >= currentEvents.length) {
    if (loopEnabled) {
      currentBaseTime += totalDuration
      nextEventIndex = 0
      scheduleAhead(currentBaseTime)
    } else {
      stopPlayback()
      return
    }
  }
  schedulerTimer = setTimeout(schedulerTick, LOOKAHEAD * 1000)
}

// --- Transport ---

function playEvents(events) {
  stopPlayback()
  const ctx = getAudioContext()
  currentEvents = events
  totalDuration = Math.max(...events.map(e => e.start + e.duration)) + 0.2
  currentBaseTime = ctx.currentTime + 0.05
  nextEventIndex = 0
  playbackState = 'playing'
  updateUI()
  schedulerTick()
}

function stopPlayback() {
  playbackState = 'idle'
  if (schedulerTimer) { clearTimeout(schedulerTimer); schedulerTimer = null }
  for (const node of activeNodes) {
    try { node.disconnect() } catch (e) {}
    try { node.stop() } catch (e) {}
  }
  activeNodes = []
  updateUI()
}

// --- Loop ---

function toggleLoop() {
  loopEnabled = !loopEnabled
  updateUI()
}

// --- UI ---

function getAudioContext() {
  if (!audioContext) {
    audioContext = new (window.AudioContext || window.webkitAudioContext)()
  }
  if (audioContext.state === 'suspended') audioContext.resume()
  return audioContext
}

function updateUI() {
  document.getElementById('play-btn').disabled = playbackState === 'playing'
  document.getElementById('stop-btn').disabled = playbackState !== 'playing'
  document.getElementById('loop-btn').textContent = loopEnabled ? 'Loop: ON' : 'Loop: OFF'
  document.getElementById('status').textContent = playbackState === 'playing' ? 'playing...' : 'idle'
}

// --- Init ---

const demoEvents = window.MOONSIC_DEMO_EVENTS || [
  { start: 0.0, duration: 0.5, midi: 60, velocity: 0.8, channel: 0 },
  { start: 0.5, duration: 0.5, midi: 62, velocity: 0.8, channel: 0 },
  { start: 1.0, duration: 0.5, midi: 64, velocity: 0.8, channel: 0 },
  { start: 1.5, duration: 0.5, midi: 67, velocity: 0.8, channel: 0 },
  { start: 2.0, duration: 1.0, midi: 72, velocity: 0.8, channel: 0 },
]

document.getElementById('play-btn').addEventListener('click', () => playEvents(demoEvents))
document.getElementById('stop-btn').addEventListener('click', () => stopPlayback())
document.getElementById('loop-btn').addEventListener('click', () => toggleLoop())
