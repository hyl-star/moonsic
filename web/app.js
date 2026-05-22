// moonsic Browser Playback Demo
// Uses WebAudio OscillatorNode for sine-wave playback

let audioContext = null
let activeOscillators = []
let playbackTimer = null

// 优先使用 moonsic 生成的数据，否则回退到硬编码 demo
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

function playNote(event, baseTime) {
  const ctx = getAudioContext()
  const freq = midiToFrequency(event.midi)

  const osc = ctx.createOscillator()
  osc.type = 'sine'
  osc.frequency.setValueAtTime(freq, baseTime + event.start)

  const gain = ctx.createGain()
  const maxGain = 0.2 * event.velocity
  const attack = 0.005
  const release = 0.02

  gain.gain.setValueAtTime(0, baseTime + event.start)
  gain.gain.linearRampToValueAtTime(maxGain, baseTime + event.start + attack)
  gain.gain.setValueAtTime(maxGain, baseTime + event.start + event.duration - release)
  gain.gain.linearRampToValueAtTime(0, baseTime + event.start + event.duration)

  osc.connect(gain)
  gain.connect(ctx.destination)

  osc.start(baseTime + event.start)
  osc.stop(baseTime + event.start + event.duration + release)

  activeOscillators.push(osc)
}

function playEvents(events) {
  stopPlayback()
  const ctx = getAudioContext()
  const baseTime = ctx.currentTime + 0.05

  const totalDuration = Math.max(...events.map(e => e.start + e.duration)) + 0.1

  for (const event of events) {
    playNote(event, baseTime)
  }

  playbackTimer = setTimeout(() => {
    cleanupOscillators()
    resetUI()
  }, (baseTime - ctx.currentTime + totalDuration) * 1000)

  updateUI('playing')
}

function cleanupOscillators() {
  for (const osc of activeOscillators) {
    try { osc.disconnect() } catch (e) { /* ignore */ }
  }
  activeOscillators = []
}

function stopPlayback() {
  cleanupOscillators()
  if (playbackTimer) {
    clearTimeout(playbackTimer)
    playbackTimer = null
  }
  updateUI('idle')
}

function updateUI(state) {
  const playBtn = document.getElementById('play-btn')
  const stopBtn = document.getElementById('stop-btn')
  const status = document.getElementById('status')

  if (state === 'playing') {
    playBtn.disabled = true
    stopBtn.disabled = false
    status.textContent = 'playing...'
  } else {
    playBtn.disabled = false
    stopBtn.disabled = true
    status.textContent = 'idle'
  }
}

function resetUI() {
  updateUI('idle')
}

document.getElementById('play-btn').addEventListener('click', () => {
  playEvents(demoEvents)
})

document.getElementById('stop-btn').addEventListener('click', () => {
  stopPlayback()
})
