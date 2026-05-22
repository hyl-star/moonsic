// moonsic v7 — expression + instruments + swing + humanize

let audioContext = null, activeNodes = [], playbackTimer = null, loopEnabled = false
let currentBaseTime = 0, analyser = null
let swingAmount = 0.50, humanizeTime = 0, humanizeVel = 0, currentInstrument = 'piano'
let seed = 42

// --- Instrument Presets ---

const INSTRUMENTS = {
  piano: { type:'sine',  a:0.003,d:0.4, s:0.15,r:0.3, g:0.20, osc2:true, detune:0 },
  pluck: { type:'triangle', a:0.001,d:0.15,s:0.0, r:0.05,g:0.18, osc2:false },
  bass:  { type:'sawtooth',a:0.005,d:0.1, s:0.6, r:0.08,g:0.24, osc2:false },
  pad:   { type:'sawtooth',a:0.12,d:0.2, s:0.4, r:0.3, g:0.10, osc2:true, detune:8 },
  bell:  { type:'sine',  a:0.001,d:0.8, s:0.0, r:0.02,g:0.14, osc2:true, detune:1200 },
  lead:  { type:'square',a:0.01,d:0.05,s:0.6, r:0.06,g:0.16, osc2:false },
}
const INST_NAMES = Object.keys(INSTRUMENTS)

// --- Dynamics ---

const DYNAMICS = { ppp:16, pp:32, p:45, mp:60, mf:80, f:100, ff:115, fff:125 }

// --- Notation Parser ---

function parseScore(text) {
  const lines = text.split('\n')
  let bpm = 120, instrument = 'piano'
  let allEvents = [], allDurations = [], allVelocities = [], allChannels = []
  let allArtic = [], allDyn = []

  let prevEvents = null
  for (let line of lines) {
    line = line.trim()
    if (!line || line.startsWith('#')) continue
    if (line.startsWith('tempo ')) { bpm = parseInt(line.slice(6)) || 120; continue }
    if (line.startsWith('time ')) continue
    if (line.startsWith('instrument ')) { instrument = line.slice(11).trim(); continue }
    if (line.startsWith('swing ')) { swingAmount = parseFloat(line.slice(6)) || 0.5; continue }
    if (line.startsWith('humanize ')) {
      const tm = line.match(/time\s+([\d.]+)/); if(tm) humanizeTime = parseFloat(tm[1])
      const vm = line.match(/velocity\s+(\d+)/); if(vm) humanizeVel = parseInt(vm[1])
      continue
    }
    // standalone repeat
    const soloRx = line.match(/^x(\d+)$/)
    if (soloRx && prevEvents) {
      for (let r=0; r<parseInt(soloRx[1]); r++) pushEvents(prevEvents,allEvents,allDurations,allVelocities,allChannels,allArtic,allDyn)
      continue
    }
    let repeat = 1
    const rx = line.match(/x(\d+)\s*$/)
    if (rx) { repeat = parseInt(rx[1]); line = line.replace(/x\d+\s*$/,'').trim() }
    const result = parseLine(line)
    if (result.events.length > 0) prevEvents = result.events
    for (let r=0; r<repeat; r++) pushEvents(result.events,allEvents,allDurations,allVelocities,allChannels,allArtic,allDyn)
  }

  currentInstrument = instrument
  const quarterSeconds = 60 / bpm
  let cursor = 0, noteEvents = [], i = 0

  // collect chord groups
  const groups = []; let group = []
  while (i < allEvents.length) {
    if (allEvents[i] < 0) { // rest
      if (group.length) { groups.push(group); group = [] }
      groups.push([i]); i++
    } else if (allDurations[i] === 0) { // chord continuation
      group.push(i); i++
    } else {
      if (group.length) { groups.push(group); group = [] }
      group.push(i); i++
    }
  }
  if (group.length) groups.push(group)

  for (const g of groups) {
    const idx = g[0]
    if (allEvents[idx] < 0) { // rest
      if (allDurations[idx] > 0) cursor += allDurations[idx]
      continue
    }
    const dur = allDurations[idx]
    const startBeat = cursor; cursor += dur
    for (const j of g) {
      const art = allArtic[j] || 'normal'
      let playDur = dur, gainMul = 1
      if (art === 'staccato') playDur = dur * 0.55
      else if (art === 'accent') gainMul = 1.3
      else if (art === 'tenuto') playDur = dur * 0.95
      // swing
      let start = startBeat
      if (swingAmount !== 0.5 && dur === 0.5) {
        const beatInBar = startBeat % 1
        if (Math.abs(beatInBar - 0.5) < 0.01) start = Math.floor(startBeat) + swingAmount
      }
      // humanize
      let hTime = 0, hVel = 0
      if (humanizeTime > 0) { seed = (seed * 1103515245 + 12345) & 0x7fffffff; hTime = (seed / 0x7fffffff - 0.5) * humanizeTime * 2 }
      if (humanizeVel > 0) { seed = (seed * 1103515245 + 12345) & 0x7fffffff; hVel = Math.round((seed / 0x7fffffff - 0.5) * humanizeVel * 2) }
      const vel = Math.max(0, Math.min(127, (allVelocities[j]||100) + hVel))
      noteEvents.push({
        start: Math.max(0, (start + hTime) * quarterSeconds),
        duration: playDur * quarterSeconds,
        midi: allEvents[j], velocity: vel / 127 * gainMul, channel: allChannels[j],
        instrument: currentInstrument
      })
    }
  }
  return { events: noteEvents, bpm, instrument }
}

function pushEvents(events, allEvents, allDurations, allVelocities, allChannels, allArtic, allDyn) {
  for (const e of events) {
    if (e.midi !== undefined) {
      allEvents.push(e.midi); allDurations.push(e.chord ? 0 : e.dur)
      allVelocities.push(e.vel||100); allChannels.push(0)
      allArtic.push(e.artic||'normal'); allDyn.push(e.dyn||'mf')
    } else if (e.rest) {
      allEvents.push(-1); allDurations.push(e.dur); allVelocities.push(0); allChannels.push(0)
      allArtic.push('normal'); allDyn.push('mf')
    }
  }
}

function parseLine(line) {
  const events = []
  // merge chord tokens
  let merged = line
  const chordRe = /\[[^\]]+\][whqes]\.?(?::\d+)?(?:@[a-z]+)?/g
  const chords = []; let m
  while ((m = chordRe.exec(line)) !== null) chords.push({ idx:m.index, raw:m[0] })
  for (let i = chords.length-1; i>=0; i--) {
    merged = merged.slice(0, chords[i].idx) + 'CHORD' + i + ' ' + merged.slice(chords[i].idx + chords[i].raw.length)
  }
  const tokens = merged.split(/\s+/).filter(t => t && t !== '|')
  let currentDyn = 'mf'
  for (let tok of tokens) {
    if (tok.startsWith('CHORD')) {
      const raw = chords[parseInt(tok.slice(5))].raw
      const cm = raw.match(/^\[(.+)\]([whqes]\.?)(?::(\d+))?(?:@([a-z]+))?/)
      if (cm) {
        const pitches = cm[1].split(/\s+/).map(parsePitch).filter(p => p >= 0)
        const dur = parseDur(cm[2])
        const vel = cm[3] ? parseInt(cm[3]) : DYNAMICS[cm[4]||currentDyn] || 80
        const artic = parseArtic(tok)
        let first = true
        for (const p of pitches) events.push({ midi:p, dur, vel, artic, dyn:cm[4]||currentDyn, chord:!first }); first=false
      }
    } else if (DYNAMICS[tok]) {
      currentDyn = tok
    } else if (tok[0] === 'R') {
      events.push({ rest:true, dur:parseDur(tok.slice(1)) })
    } else if (tok[0] >= 'A' && tok[0] <= 'G' || tok[0] === '.' || tok[0] === '>' || tok[0] === '_' || tok[0] === '!') {
      // articulation prefix
      let artic = 'normal', t = tok
      if (t[0] === '!') { artic = 'staccato'; t = t.slice(1) }
      else if (t[0] === '>') { artic = 'accent'; t = t.slice(1) }
      else if (t[0] === '_') { artic = 'tenuto'; t = t.slice(1) }
      const nm = t.match(/^([A-G][#b]?\d)([whqes]\.?)(?::(\d+))?(?:@([a-z]+))?$/)
      if (nm) {
        const vel = nm[3] ? parseInt(nm[3]) : DYNAMICS[nm[4]||currentDyn] || 80
        events.push({ midi:parsePitch(nm[1]), dur:parseDur(nm[2]), vel, artic, dyn:nm[4]||currentDyn })
      }
    }
  }
  return { events }
}

function parseArtic(tok) {
  if (tok[0]==='!') return 'staccato'
  if (tok[0]==='>') return 'accent'
  if (tok[0]==='_') return 'tenuto'
  return 'normal'
}

function parsePitch(s) {
  const m = s.match(/^([A-G])([#b])?(\d)$/); if (!m) return 60
  const names = { C:0,D:2,E:4,F:5,G:7,A:9,B:11 }
  return (parseInt(m[3])+1)*12 + (names[m[1]]||0) + (m[2]==='#'?1:m[2]==='b'?-1:0)
}
function parseDur(s) {
  const beats = { w:4, h:2, q:1, e:0.5, s:0.25 }; let m=1
  if (s.endsWith('.')) { m=1.5; s=s.slice(0,-1) }
  return (beats[s]||1)*m
}

// --- Playback ---

function playSynthNote(e, baseTime) {
  const ctx = audioContext, freq = 440 * Math.pow(2, (e.midi-69)/12)
  const inst = INSTRUMENTS[e.instrument] || INSTRUMENTS.piano
  const osc = ctx.createOscillator(); osc.type = inst.type
  osc.frequency.setValueAtTime(freq, baseTime + e.start)
  const gain = ctx.createGain(); const t = baseTime + e.start; const d = e.duration; const g = gain.gain
  const vel = Math.max(0, Math.min(1, e.velocity))
  const noteGain = inst.g * vel
  g.setValueAtTime(0, t)
  g.linearRampToValueAtTime(noteGain, t + inst.a)
  g.linearRampToValueAtTime(noteGain * inst.s, t + inst.a + inst.d)
  g.setValueAtTime(noteGain * inst.s, Math.max(t, t + d - inst.r))
  g.linearRampToValueAtTime(0, t + d)
  osc.connect(gain); gain.connect(ctx.destination)
  if (analyser) gain.connect(analyser)
  // second oscillator for body
  if (inst.osc2) {
    const osc2 = ctx.createOscillator(); osc2.type = inst.type
    osc2.frequency.setValueAtTime(freq + inst.detune, baseTime + e.start)
    const g2 = ctx.createGain(); g2.gain.setValueAtTime(noteGain*0.3, t)
    g2.gain.linearRampToValueAtTime(0, t + d)
    osc2.connect(g2); g2.connect(ctx.destination)
    osc2.start(t); osc2.stop(t + d + inst.r); activeNodes.push(osc2, g2)
  }
  osc.start(t); osc.stop(t + d + inst.r); activeNodes.push(osc, gain)
}

function playEvents(events) {
  stopPlayback()
  const ctx = getAudioContext()
  if (!analyser) { analyser = ctx.createAnalyser(); analyser.fftSize = 256 }
  const totalDuration = Math.max(...events.map(e => e.start + e.duration), 0.1) + 0.2
  currentBaseTime = ctx.currentTime + 0.05
  for (const e of events) playSynthNote(e, currentBaseTime)
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

// --- UI ---

function updateMeter() {
  if (!playbackTimer) { document.getElementById('meter-bar').style.width='0%'; return }
  if (analyser) {
    const data = new Uint8Array(analyser.frequencyBinCount); analyser.getByteFrequencyData(data)
    document.getElementById('meter-bar').style.width = Math.min(100, data.reduce((a,b)=>a+b,0)/data.length/2.5)+'%'
  }
  if (audioContext && currentBaseTime)
    document.getElementById('time-display').textContent = Math.max(0, audioContext.currentTime - currentBaseTime).toFixed(1)+'s'
  setTimeout(updateMeter, 50)
}

function updateUI() {
  const playing = playbackTimer !== null
  document.getElementById('play-btn').disabled = playing
  document.getElementById('stop-btn').disabled = !playing
  document.getElementById('loop-btn').textContent = loopEnabled ? 'Loop:ON' : 'Loop:OFF'
  document.getElementById('status').textContent = playing ? 'playing ('+(currentInstrument||'piano')+')' : 'idle'
}

function loadExample(id) {
  const examples = {
    melody: 'tempo 120\ntime 4/4\n| C4q D4q E4q G4q | [C4 E4 G4]h Rq G4q:90 | x2',
    dynamics: 'tempo 100\ninstrument piano\n| C4q@p D4q@mp E4q@mf G4q@f | C5e@ff B4e A4q@mf Rq |',
    staccato: 'tempo 120\ninstrument pluck\n| !C4e !D4e !E4e !F4e !G4e !F4e !E4e !D4e | C4w@f',
    accent: 'tempo 110\ninstrument lead\n| C4q >E4q G4q >C5q | >A4h Rq G4q@mp |',
    swing: 'tempo 100\nswing 0.60\ninstrument piano\n| C4e D4e E4e G4e C4e D4e E4e G4e | C4q D4q |',
    piano: 'tempo 110\ninstrument piano\n| C4q@mp D4q E4q@mf G4q@f | [C4 E4 G4]h@p Rq >G4q@f | C5e@f B4e A4q@mf G4q_ Rq |'
  }
  if (examples[id]) {
    document.getElementById('score-input').value = examples[id]
    document.getElementById('error-msg').textContent = ''
  }
}

document.getElementById('play-btn').addEventListener('click', () => {
  const text = document.getElementById('score-input').value
  try {
    const result = parseScore(text)
    document.getElementById('error-msg').textContent = ''
    document.getElementById('info').textContent = `instrument: ${result.instrument || 'piano'} | swing: ${swingAmount.toFixed(2)}`
    playEvents(result.events)
  } catch(e) {
    document.getElementById('error-msg').textContent = 'Parse error: ' + e.message
  }
})
document.getElementById('stop-btn').addEventListener('click', stopPlayback)
document.getElementById('loop-btn').addEventListener('click', toggleLoop)
