// moonsic v5 — mixer + level meter + time

let audioContext = null, activeNodes = [], playbackTimer = null, loopEnabled = false
let currentBaseTime = 0, analyser = null, meterTimer = null

const VOICES = {
  sine_lead:   { type:'sine',     a:0.01,d:0.05,s:0.7,r:0.05,g:0.18 },
  triangle_bass:{ type:'triangle',a:0.005,d:0.03,s:0.8,r:0.03,g:0.22 },
  square_lead: { type:'square',  a:0.01,d:0.04,s:0.6,r:0.04,g:0.12 },
  saw_pad:     { type:'sawtooth',a:0.08,d:0.1, s:0.5,r:0.15,g:0.08 },
  soft_bell:   { type:'sine',    a:0.002,d:0.3, s:0.0,r:0.01,g:0.15 },
}

function playSynthNote(e, baseTime) {
  const ctx = audioContext
  const freq = 440 * Math.pow(2, (e.midi - 69) / 12)
  const voice = VOICES.sine_lead
  const osc = ctx.createOscillator(); osc.type = voice.type
  osc.frequency.setValueAtTime(freq, baseTime + e.start)
  const gain = ctx.createGain(); const t = baseTime + e.start; const d = e.duration
  const g = gain.gain
  g.setValueAtTime(0, t)
  g.linearRampToValueAtTime(voice.g, t + voice.a)
  g.linearRampToValueAtTime(voice.g * voice.s, t + voice.a + voice.d)
  g.setValueAtTime(voice.g * voice.s, t + d - voice.r)
  g.linearRampToValueAtTime(0, t + d)
  osc.connect(gain)
  // pan
  const pan = e.pan || 0
  if (pan !== 0) {
    const panner = ctx.createStereoPanner(); panner.pan.setValueAtTime(pan, t)
    gain.connect(panner); panner.connect(ctx.destination)
    if (analyser) panner.connect(analyser)
    activeNodes.push(panner)
  } else {
    gain.connect(ctx.destination)
    if (analyser) gain.connect(analyser)
  }
  osc.start(t); osc.stop(t + d + voice.r)
  activeNodes.push(osc, gain)
}

function playDrumNote(e, baseTime) {
  const ctx = audioContext, t = baseTime + e.start, midi = e.midi
  if (midi === 36) {
    const osc = ctx.createOscillator(); osc.type = 'sine'
    osc.frequency.setValueAtTime(150, t); osc.frequency.exponentialRampToValueAtTime(30, t + 0.12)
    const g = ctx.createGain(); g.gain.setValueAtTime(0.6 * (e.velocity||0.8), t)
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.15)
    osc.connect(g); g.connect(ctx.destination); if(analyser) g.connect(analyser)
    osc.start(t); osc.stop(t + 0.15); activeNodes.push(osc, g)
  } else if (midi === 38) {
    const bs = ctx.sampleRate * 0.1, buf = ctx.createBuffer(1, bs, ctx.sampleRate)
    const d = buf.getChannelData(0); for (let i = 0; i < bs; i++) d[i] = Math.random() * 2 - 1
    const noise = ctx.createBufferSource(); noise.buffer = buf
    const g1 = ctx.createGain(); g1.gain.setValueAtTime(0.3 * (e.velocity||0.8), t)
    g1.gain.exponentialRampToValueAtTime(0.001, t + 0.08)
    noise.connect(g1); g1.connect(ctx.destination); if(analyser) g1.connect(analyser)
    const osc = ctx.createOscillator(); osc.type = 'triangle'; osc.frequency.setValueAtTime(180, t)
    const g2 = ctx.createGain(); g2.gain.setValueAtTime(0.15, t)
    g2.gain.exponentialRampToValueAtTime(0.001, t + 0.06)
    osc.connect(g2); g2.connect(ctx.destination)
    noise.start(t); osc.start(t); noise.stop(t + 0.1); osc.stop(t + 0.1)
    activeNodes.push(noise, osc, g1, g2)
  } else if (midi === 42 || midi === 46) {
    const bs = ctx.sampleRate * 0.05, buf = ctx.createBuffer(1, bs, ctx.sampleRate)
    const d = buf.getChannelData(0); for (let i = 0; i < bs; i++) d[i] = Math.random() * 2 - 1
    const noise = ctx.createBufferSource(); noise.buffer = buf
    const hp = ctx.createBiquadFilter(); hp.type = 'highpass'; hp.frequency.setValueAtTime(5000, t)
    const g = ctx.createGain(); g.gain.setValueAtTime(0.12 * (e.velocity||0.8), t)
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.04)
    noise.connect(hp); hp.connect(g); g.connect(ctx.destination)
    noise.start(t); noise.stop(t + 0.05); activeNodes.push(noise, g)
  }
}

function playEvents(events) {
  stopPlayback()
  const ctx = getAudioContext()
  if (!analyser) { analyser = ctx.createAnalyser(); analyser.fftSize = 256 }
  const totalDuration = Math.max(...events.map(e => e.start + e.duration)) + 0.2
  currentBaseTime = ctx.currentTime + 0.05
  for (const e of events) {
    if (e.channel === 9) playDrumNote(e, currentBaseTime)
    else playSynthNote(e, currentBaseTime)
  }
  playbackTimer = setTimeout(() => {
    if (loopEnabled) playEvents(events); else { cleanupNodes(); updateUI() }
  }, totalDuration * 1000)
  updateUI(); updateMeter()
}

function stopPlayback() { if(playbackTimer){clearTimeout(playbackTimer);playbackTimer=null} cleanupNodes(); updateUI() }
function toggleLoop() { loopEnabled = !loopEnabled; updateUI() }

function cleanupNodes() { for (const n of activeNodes) { try{n.disconnect()}catch(e){} try{n.stop()}catch(e){} } activeNodes=[] }

function getAudioContext() {
  if (!audioContext) audioContext = new (window.AudioContext || window.webkitAudioContext)()
  if (audioContext.state === 'suspended') audioContext.resume()
  return audioContext
}

function updateMeter() {
  if (!playbackTimer) { document.getElementById('meter-bar').style.width = '0%'; meterTimer=null; return }
  if (analyser) {
    const data = new Uint8Array(analyser.frequencyBinCount)
    analyser.getByteFrequencyData(data)
    const avg = data.reduce((a, b) => a + b, 0) / data.length
    document.getElementById('meter-bar').style.width = Math.min(100, avg / 2.5) + '%'
  }
  if (audioContext && currentBaseTime) {
    const elapsed = audioContext.currentTime - currentBaseTime
    document.getElementById('time-display').textContent = elapsed > 0 ? elapsed.toFixed(1) + 's' : '0.0s'
  }
  meterTimer = setTimeout(updateMeter, 50)
}

function updateUI() {
  const playing = playbackTimer !== null
  document.getElementById('play-btn').disabled = playing
  document.getElementById('stop-btn').disabled = !playing
  document.getElementById('loop-btn').textContent = loopEnabled ? 'Loop:ON' : 'Loop:OFF'
  document.getElementById('status').textContent = playing ? 'playing...' : 'idle'
}

const demoEvents = window.MOONSIC_DEMO_EVENTS || [{ start:0,duration:0.5,midi:60,velocity:0.8,channel:0 }]
document.getElementById('play-btn').addEventListener('click', () => playEvents(demoEvents))
document.getElementById('stop-btn').addEventListener('click', () => stopPlayback())
document.getElementById('loop-btn').addEventListener('click', () => toggleLoop())
