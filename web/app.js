// moonsic v4 Browser Playback — ADSR voices + drum synthesis + loop

let audioContext = null
let activeNodes = []
let playbackTimer = null
let loopEnabled = false
let currentEvents = []
let currentBaseTime = 0

// --- Synth Voices ---

const VOICES = {
  sine_lead:   { type: 'sine',     attack: 0.01, decay: 0.05, sustain: 0.7, release: 0.05, gain: 0.18 },
  triangle_bass:{ type: 'triangle', attack: 0.005, decay: 0.03, sustain: 0.8, release: 0.03, gain: 0.22 },
  square_lead: { type: 'square',   attack: 0.01, decay: 0.04, sustain: 0.6, release: 0.04, gain: 0.12 },
  saw_pad:     { type: 'sawtooth', attack: 0.08, decay: 0.1,  sustain: 0.5, release: 0.15, gain: 0.08 },
  soft_bell:   { type: 'sine',     attack: 0.002, decay: 0.3, sustain: 0.0, release: 0.01, gain: 0.15 },
}

function voiceForChannel(ch, midi) {
  if (ch === 9) return null
  return 'sine_lead'
}

// --- ADSR ---

function applyADSR(gainNode, voice, startTime, duration, baseTime) {
  const g = gainNode.gain, t = baseTime + startTime
  const a = voice.attack, d = voice.decay, s = voice.sustain, r = voice.release, v = voice.gain
  g.setValueAtTime(0, t)
  g.linearRampToValueAtTime(v, t + a)
  g.linearRampToValueAtTime(v * s, t + a + d)
  g.setValueAtTime(v * s, t + duration - r)
  g.linearRampToValueAtTime(0, t + duration)
}

// --- Melodic ---

function playSynthNote(event, baseTime) {
  const ctx = audioContext
  const freq = 440 * Math.pow(2, (event.midi - 69) / 12)
  const voiceName = voiceForChannel(event.channel, event.midi)
  if (!voiceName) return
  const voice = VOICES[voiceName]
  const osc = ctx.createOscillator()
  osc.type = voice.type
  osc.frequency.setValueAtTime(freq, baseTime + event.start)
  const gain = ctx.createGain()
  applyADSR(gain, voice, event.start, event.duration, baseTime)
  osc.connect(gain); gain.connect(ctx.destination)
  osc.start(baseTime + event.start)
  osc.stop(baseTime + event.start + event.duration + voice.release)
  activeNodes.push(osc, gain)
}

// --- Drums ---

function playDrumNote(event, baseTime) {
  const ctx = audioContext, t = baseTime + event.start, midi = event.midi
  if (midi === 36) { // Kick
    const osc = ctx.createOscillator(); osc.type = 'sine'
    osc.frequency.setValueAtTime(150, t)
    osc.frequency.exponentialRampToValueAtTime(30, t + 0.12)
    const g = ctx.createGain()
    g.gain.setValueAtTime(0.6 * event.velocity, t)
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.15)
    osc.connect(g); g.connect(ctx.destination)
    osc.start(t); osc.stop(t + 0.15)
    activeNodes.push(osc, g)
  } else if (midi === 38) { // Snare
    const bs = ctx.sampleRate * 0.1, buf = ctx.createBuffer(1, bs, ctx.sampleRate)
    const d = buf.getChannelData(0)
    for (let i = 0; i < bs; i++) d[i] = Math.random() * 2 - 1
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
    const bs = ctx.sampleRate * 0.05, buf = ctx.createBuffer(1, bs, ctx.sampleRate)
    const d = buf.getChannelData(0)
    for (let i = 0; i < bs; i++) d[i] = Math.random() * 2 - 1
    const noise = ctx.createBufferSource(); noise.buffer = buf
    const hp = ctx.createBiquadFilter(); hp.type = 'highpass'
    hp.frequency.setValueAtTime(5000, t)
    const g = ctx.createGain()
    g.gain.setValueAtTime(0.12 * event.velocity, t)
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.04)
    noise.connect(hp); hp.connect(g); g.connect(ctx.destination)
    noise.start(t); noise.stop(t + 0.05)
    activeNodes.push(noise, g)
  }
}

// --- Play / Stop / Loop ---

function playEvents(events) {
  stopPlayback()
  const ctx = getAudioContext()
  currentEvents = events
  const totalDuration = Math.max(...events.map(e => e.start + e.duration)) + 0.2
  currentBaseTime = ctx.currentTime + 0.05

  for (const e of events) {
    if (e.channel === 9) playDrumNote(e, currentBaseTime)
    else playSynthNote(e, currentBaseTime)
  }

  playbackTimer = setTimeout(() => {
    if (loopEnabled) {
      // Loop: 重新播放
      playEvents(events)
    } else {
      cleanupNodes()
      updateUI()
    }
  }, totalDuration * 1000)

  updateUI()
}

function stopPlayback() {
  if (playbackTimer) { clearTimeout(playbackTimer); playbackTimer = null }
  cleanupNodes()
  updateUI()
}

function toggleLoop() {
  loopEnabled = !loopEnabled
  updateUI()
}

function cleanupNodes() {
  for (const node of activeNodes) {
    try { node.disconnect() } catch (e) {}
    try { node.stop() } catch (e) {}
  }
  activeNodes = []
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
  const playing = playbackTimer !== null
  document.getElementById('play-btn').disabled = playing
  document.getElementById('stop-btn').disabled = !playing
  document.getElementById('loop-btn').textContent = loopEnabled ? 'Loop: ON' : 'Loop: OFF'
  document.getElementById('status').textContent = playing ? 'playing...' : 'idle'
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
