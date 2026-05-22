// moonsic v6 — live notation editor + playback

let audioContext = null, activeNodes = [], playbackTimer = null, loopEnabled = false
let currentBaseTime = 0, analyser = null

const VOICES = {
  sine_lead:   { type:'sine',     a:0.01,d:0.05,s:0.7,r:0.05,g:0.18 },
  triangle_bass:{ type:'triangle',a:0.005,d:0.03,s:0.8,r:0.03,g:0.22 },
  saw_pad:     { type:'sawtooth',a:0.08,d:0.1, s:0.5,r:0.15,g:0.08 },
}

// --- v6 Notation Parser (JS) ---

function parseScore(text) {
  const lines = text.split('\n')
  let bpm = 120, tsNum = 4, tsDen = 4
  let allEvents = [], allDurations = [], allVelocities = []
  let allChannels = []

  for (let line of lines) {
    line = line.trim()
    if (!line || line.startsWith('#')) continue
    if (line.startsWith('tempo ')) { bpm = parseInt(line.slice(6)) || 120; continue }
    if (line.startsWith('time ')) {
      const m = line.match(/time\s+(\d+)\s*\/\s*(\d+)/)
      if (m) { tsNum = parseInt(m[1]); tsDen = parseInt(m[2]) }
      continue
    }
    // parse events with repeats
    let repeat = 1
    const rx = line.match(/x(\d+)\s*$/)
    if (rx) { repeat = parseInt(rx[1]); line = line.replace(/x\d+\s*$/, '').trim() }
    const events = parseLine(line)
    for (let r = 0; r < repeat; r++) {
      for (const e of events) {
        if (e.midi !== undefined) {
          allEvents.push(e.midi); allDurations.push(e.dur); allVelocities.push(e.vel||100); allChannels.push(0)
        } else if (e.rest) {
          allEvents.push(-1); allDurations.push(e.dur); allVelocities.push(0); allChannels.push(0)
        }
      }
    }
  }

  // build timed events
  let cursor = 0
  const noteEvents = []
  for (let i = 0; i < allEvents.length; i++) {
    if (allEvents[i] >= 0) {
      noteEvents.push({ start:cursor, duration:allDurations[i], midi:allEvents[i], velocity:allVelocities[i]/127, channel:allChannels[i] })
    }
    cursor += allDurations[i]
  }
  return { events: noteEvents, bpm, tsNum, tsDen }
}

function parseLine(line) {
  const events = []
  // merge chord tokens: [C4 E4 G4]h → single token
  let merged = line
  const chordRe = /\[[^\]]+\][whqes]\.?/g
  const chords = []
  let m; while ((m = chordRe.exec(line)) !== null) chords.push({ idx:m.index, raw:m[0] })
  for (let i = chords.length-1; i>=0; i--) {
    merged = merged.slice(0, chords[i].idx) + 'CHORD' + i + ' ' + merged.slice(chords[i].idx + chords[i].raw.length)
  }
  const tokens = merged.split(/\s+/).filter(t => t && t !== '|')
  for (let tok of tokens) {
    if (tok.startsWith('CHORD')) {
      const raw = chords[parseInt(tok.slice(5))].raw
      const cm = raw.match(/^\[(.+)\]([whqes]\.?)/)
      if (cm) {
        const pitches = cm[1].split(/\s+/).map(parsePitch).filter(p => p >= 0)
        const dur = parseDur(cm[2])
        for (const p of pitches) events.push({ midi:p, dur, vel:100 })
      }
      continue
    }
    if (tok === '|' || !tok) continue
    if (tok[0] === 'R') { events.push({ rest:true, dur:parseDur(tok.slice(1)) }); continue }
    if (tok[0] === '[') {
      const m = tok.match(/^\[(.+)\]([whqes]\.?)/)
      if (m) {
        const pitches = m[1].split(/\s+/).map(parsePitch).filter(p => p >= 0)
        const dur = parseDur(m[2])
        for (const p of pitches) events.push({ midi:p, dur, vel:100 })
      }
      continue
    }
    // note: C4q, C#4e:80, Bb3h.
    const m = tok.match(/^([A-G][#b]?\d)([whqes]\.?)(?::(\d+))?$/)
    if (m) {
      events.push({ midi:parsePitch(m[1]), dur:parseDur(m[2]), vel:parseInt(m[3]||'100') })
    }
  }
  return events
}

function parsePitch(s) {
  const m = s.match(/^([A-G])([#b])?(\d)$/)
  if (!m) return 60
  const names = { C:0,D:2,E:4,F:5,G:7,A:9,B:11 }
  const base = names[m[1]] || 0
  const acc = m[2] === '#' ? 1 : m[2] === 'b' ? -1 : 0
  const oct = parseInt(m[3])
  return (oct + 1) * 12 + base + acc
}

function parseDur(s) {
  const beats = { w:4, h:2, q:1, e:0.5, s:0.25 }
  let mult = 1
  if (s.endsWith('.')) { mult = 1.5; s = s.slice(0,-1) }
  return (beats[s] || 1) * mult
}

// --- Playback ---

function playSynthNote(e, baseTime) {
  const ctx = audioContext, freq = 440 * Math.pow(2, (e.midi - 69) / 12)
  const voice = VOICES.sine_lead
  const osc = ctx.createOscillator(); osc.type = voice.type
  osc.frequency.setValueAtTime(freq, baseTime + e.start)
  const gain = ctx.createGain(); const t = baseTime + e.start; const d = e.duration; const g = gain.gain
  g.setValueAtTime(0, t)
  g.linearRampToValueAtTime(voice.g, t + voice.a)
  g.linearRampToValueAtTime(voice.g * voice.s, t + voice.a + voice.d)
  g.setValueAtTime(voice.g * voice.s, t + d - voice.r)
  g.linearRampToValueAtTime(0, t + d)
  osc.connect(gain); gain.connect(ctx.destination)
  if (analyser) gain.connect(analyser)
  osc.start(t); osc.stop(t + d + voice.r); activeNodes.push(osc, gain)
}

function playEvents(events) {
  stopPlayback()
  const ctx = getAudioContext()
  if (!analyser) { analyser = ctx.createAnalyser(); analyser.fftSize = 256 }
  const totalDuration = Math.max(...events.map(e => e.start + e.duration), 0.1) + 0.2
  currentBaseTime = ctx.currentTime + 0.05
  for (const e of events) { playSynthNote(e, currentBaseTime) }
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

// --- Meter ---

function updateMeter() {
  if (!playbackTimer) { document.getElementById('meter-bar').style.width='0%'; return }
  if (analyser) {
    const data = new Uint8Array(analyser.frequencyBinCount); analyser.getByteFrequencyData(data)
    document.getElementById('meter-bar').style.width = Math.min(100, data.reduce((a,b)=>a+b,0)/data.length/2.5) + '%'
  }
  if (audioContext && currentBaseTime) {
    document.getElementById('time-display').textContent = Math.max(0, audioContext.currentTime - currentBaseTime).toFixed(1) + 's'
  }
  setTimeout(updateMeter, 50)
}

function updateUI() {
  const playing = playbackTimer !== null
  document.getElementById('play-btn').disabled = playing
  document.getElementById('stop-btn').disabled = !playing
  document.getElementById('loop-btn').textContent = loopEnabled ? 'Loop:ON' : 'Loop:OFF'
  document.getElementById('status').textContent = playing ? 'playing...' : 'idle'
}

// --- Init ---

document.getElementById('play-btn').addEventListener('click', () => {
  const text = document.getElementById('score-input').value
  try {
    const result = parseScore(text)
    document.getElementById('error-msg').textContent = ''
    playEvents(result.events)
  } catch(e) {
    document.getElementById('error-msg').textContent = 'Parse error: ' + e.message
  }
})
document.getElementById('stop-btn').addEventListener('click', () => stopPlayback())
document.getElementById('loop-btn').addEventListener('click', () => toggleLoop())
