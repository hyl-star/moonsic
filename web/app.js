// moonsic v8 — multi-track arrangement + mixer

let audioContext = null, playbackTimer = null, loopEnabled = false
let currentBaseTime = 0, masterGain = null, masterAnalyser = null
let trackChannels = {}, parseResult = null
let swingAmount = 0.50, humanizeTime = 0, humanizeVel = 0, seed = 42

const INSTRUMENTS = {
  piano:{type:'sine',  a:0.003,d:0.4, s:0.15,r:0.3, g:0.20, osc2:true, detune:0},
  pluck:{type:'triangle',a:0.001,d:0.15,s:0.0, r:0.05,g:0.18},
  bass: {type:'sawtooth',a:0.005,d:0.1, s:0.6, r:0.08,g:0.24},
  pad:  {type:'sawtooth',a:0.12,d:0.2, s:0.4, r:0.3, g:0.10, osc2:true, detune:8},
  bell: {type:'sine',  a:0.001,d:0.8, s:0.0, r:0.02,g:0.14, osc2:true, detune:1200},
  lead: {type:'square',a:0.01,d:0.05,s:0.6, r:0.06,g:0.16},
}
const DYNAMICS = { ppp:16,pp:32,p:45,mp:60,mf:80,f:100,ff:115,fff:125 }
const DRUM_MAP = { K:36, S:38, H:42, O:46 }

// --- Parser ---

function parseScore(text) {
  const lines = text.split('\n')
  let bpm = 120, globalSwing = 0.50, hTime = 0, hVel = 0
  let tracks = [], currentTrack = null

  function ensureTrack(name) {
    let t = tracks.find(tr => tr.id === name)
    if (!t) { t = { id:name, name, instrument:'piano', volume:1.0, pan:0, mute:false, solo:false, rawEvents:[], events:[] }; tracks.push(t) }
    return t
  }

  let prevRaw = null
  for (let line of lines) {
    line = line.trim(); if (!line || line.startsWith('#')) continue
    if (line.startsWith('tempo ')) { bpm = parseInt(line.slice(6))||120; continue }
    if (line.startsWith('time ')) continue
    if (line.startsWith('key ')) {
      const km = line.match(/key\s+([A-G][#b]?)\s*(major|minor)?/i)
      if (km) { v9Key = { tonic: km[1], accidental: km[1].length>1?km[1][1]:'', octave:4, kind: (km[2]||'major').toLowerCase() } }
      continue
    }
    if (line.startsWith('style ')) { continue }
    if (line.startsWith('progression ')) {
      // auto-generate chords from progression text
      const progText = line.slice(12).trim()
      const numerals = parseRomanText(progText)
      const chordEvents = generateChordsFromRoman(numerals)
      if (chordEvents.length > 0) {
        const chordsTrack = ensureTrack('chords'); chordsTrack.instrument = 'pad'
        chordsTrack.rawEvents.push(...chordEvents); prevRaw = chordEvents
      }
      continue
    }
    if (line.startsWith('generate ')) {
      const cmd = line.slice(9).trim()
      if (cmd === 'chords') continue // already handled by progression
      if (cmd.startsWith('bass ')) {
        const style = cmd.slice(5); const bassEvents = generateBass(style)
        if (bassEvents.length > 0) { const t = ensureTrack('bass'); t.instrument = 'bass'; t.rawEvents.push(...bassEvents) }
      }
      if (cmd.startsWith('arpeggio ')) {
        const style = cmd.slice(9); const arpEvents = generateArpeggio(style)
        if (arpEvents.length > 0) { const t = ensureTrack('arpeggio'); t.instrument = 'bell'; t.rawEvents.push(...arpEvents) }
      }
      continue
    }
    if (line.startsWith('swing ')) { globalSwing = parseFloat(line.slice(6))||0.5; continue }
    if (line.startsWith('humanize ')) {
      const tm = line.match(/time\s+([\d.]+)/); if(tm) hTime = parseFloat(tm[1])
      const vm = line.match(/velocity\s+(\d+)/); if(vm) hVel = parseInt(vm[1])
      continue
    }
    const th = line.match(/^track\s+(\S+)(.*)/)
    if (th) {
      currentTrack = ensureTrack(th[1]); prevRaw = null
      const attrs = th[2]
      const im = attrs.match(/instrument\s+(\S+)/); if(im) currentTrack.instrument = im[1]
      const vm = attrs.match(/volume\s+([\d.]+)/); if(vm) currentTrack.volume = parseFloat(vm[1])
      const pm = attrs.match(/pan\s+([-\d.]+)/); if(pm) currentTrack.pan = parseFloat(pm[1])
      const mm = attrs.match(/mute\s+(\S+)/); if(mm) currentTrack.mute = mm[1]==='true'
      const sm = attrs.match(/solo\s+(\S+)/); if(sm) currentTrack.solo = sm[1]==='true'
      continue
    }
    if (!currentTrack) { currentTrack = ensureTrack('main') }
    const soloRx = line.match(/^x(\d+)$/)
    if (soloRx && prevRaw) {
      for (let r=0; r<parseInt(soloRx[1]); r++) currentTrack.rawEvents.push(...prevRaw)
      continue
    }
    let repeat = 1
    const rx = line.match(/x(\d+)\s*$/)
    if (rx) { repeat = parseInt(rx[1]); line = line.replace(/x\d+\s*$/,'').trim() }
    const evts = parseLine(line, currentTrack.instrument === 'drums')
    if (evts.length > 0) prevRaw = evts
    for (let r=0; r<repeat; r++) currentTrack.rawEvents.push(...evts)
  }

  swingAmount = globalSwing; humanizeTime = hTime; humanizeVel = hVel; seed = 42
  parseResult = { tracks, bpm }

  const quarterSeconds = 60 / bpm; let allFlat = []
  for (const track of tracks) {
    let cursor = 0; const events = []; let i = 0; const raw = track.rawEvents
    const groups = []; let g = []
    while (i < raw.length) {
      if (raw[i].rest) { if(g.length){groups.push(g);g=[]}; groups.push([i]); i++ }
      else if (raw[i].chord) { g.push(i); i++ }
      else { if(g.length){groups.push(g);g=[]}; g.push(i); i++ }
    }
    if (g.length) groups.push(g)
    for (const grp of groups) {
      const idx = grp[0]
      if (raw[idx].rest) { if (raw[idx].dur > 0) cursor += raw[idx].dur; continue }
      const dur = raw[idx].dur; const startBeat = cursor; cursor += dur
      let jit = 0
      if (humanizeTime > 0) { seed = (seed*1103515245+12345)&0x7fffffff; jit = (seed/0x7fffffff-0.5)*humanizeTime*2 }
      for (const j of grp) {
        const art = raw[j].artic||'normal'; let playDur = dur, gainMul = 1
        if (art==='staccato') playDur = dur*0.55
        else if (art==='accent') gainMul = 1.3
        else if (art==='tenuto') playDur = dur*0.95
        let start = startBeat
        if (swingAmount !== 0.5 && dur === 0.5) {
          if (Math.abs((startBeat%1)-0.5)<0.01) start = Math.floor(startBeat)+swingAmount
        }
        let hV = 0
        if (humanizeVel>0){seed=(seed*1103515245+12345)&0x7fffffff;hV=Math.round((seed/0x7fffffff-0.5)*humanizeVel*2)}
        const vel = Math.max(0,Math.min(127,(raw[j].vel||100)+hV))
        const evt = {
          start:Math.max(0,(start+jit)*quarterSeconds), duration:playDur*quarterSeconds,
          midi:raw[j].midi, velocity:vel/127*gainMul,
          trackId:track.id, isDrum:raw[j].isDrum||false
        }
        events.push(evt); allFlat.push(evt)
      }
    }
    track.events = events
  }
  return { tracks, bpm, allEvents: allFlat }
}

// --- v9 Theory Generators ---

let v9Key = { tonic: 'C', accidental: '', octave: 4, kind: 'major' }
let v9ProgEvents = null

function parseRomanText(text) {
  const map = { I:0, II:1, III:2, IV:3, V:4, VI:5, VII:6 }
  const result = []; let i = 0
  while (i < text.length) {
    if (text[i] === ' ') { i++; continue }
    let tok = ''; while (i < text.length && text[i] !== ' ') { tok += text[i]; i++ }
    const upper = tok.toUpperCase()
    if (map[upper] !== undefined) result.push(upper)
  }
  return result
}

function generateChordsFromRoman(numerals, instrument) {
  const tonicMidi = typeof v9Key.tonic === 'string' ? (parsePitch(v9Key.tonic + (v9Key.accidental||'') + v9Key.octave)) : 60
  const intervals = { I:[0,4,7], II:[2,5,9], III:[4,7,11], IV:[0,5,9], V:[2,7,11], VI:[0,4,9], VII:[2,5,11] }
  const events = []
  for (const rn of numerals) {
    const intv = intervals[rn] || [0,4,7]
    let first = true
    for (const semitone of intv) {
      events.push({ midi: tonicMidi + semitone - (tonicMidi%12) + (tonicMidi>=0?0:0), dur:2, vel:80, chord:!first, isDrum:false })
      first = false
    }
  }
  // fix: compute midi relative to tonic
  const rootMidi = typeof v9Key.tonic === 'string' ? parsePitch(v9Key.tonic + (v9Key.accidental||'') + v9Key.octave) : 60
  const degBase = { I:0,II:1,III:2,IV:3,V:4,VI:5,VII:6 }
  const majorIntv = [0,2,4,5,7,9,11]
  const chordIntv = { I:[0,4,7], II:[0,3,7], III:[0,3,7], IV:[0,4,7], V:[0,4,7], VI:[0,3,7], VII:[0,3,6] }
  const result = []
  for (const rn of numerals) {
    const deg = degBase[rn]; const root = rootMidi + majorIntv[deg]
    const intv = chordIntv[rn] || [0,4,7]; let first = true
    for (const s of intv) { result.push({ midi: root + s, dur:2, vel:80, chord:!first, isDrum:false }); first = false }
  }
  v9ProgEvents = result
  return result
}

function generateBass(style) {
  if (!v9ProgEvents) return []
  const events = []; const chordGroups = []; let g = []
  for (const e of v9ProgEvents) { if (e.chord) g.push(e); else { if(g.length){chordGroups.push(g);g=[]}; g.push(e) } }
  if (g.length) chordGroups.push(g)
  for (const grp of chordGroups) {
    const root = grp[0].midi; const dur = 2
    if (style === 'root_fifth' || style === 'RootFifth') { events.push({midi:root,dur:1,vel:90,isDrum:false}); events.push({midi:root+7,dur:1,vel:90,isDrum:false}) }
    else if (style === 'octave' || style === 'Octave') { events.push({midi:root,dur:1,vel:90,isDrum:false}); events.push({midi:root+12,dur:1,vel:90,isDrum:false}) }
    else { events.push({midi:root,dur,vel:90,isDrum:false}) } // Root
  }
  return events
}

function generateArpeggio(style) {
  if (!v9ProgEvents) return []
  const events = []; const chordGroups = []; let g = []
  for (const e of v9ProgEvents) { if (e.chord) g.push(e); else { if(g.length){chordGroups.push(g);g=[]}; g.push(e) } }
  if (g.length) chordGroups.push(g)
  for (const grp of chordGroups) {
    const pitches = grp.map(e => e.midi)
    if (style === 'up' || style === 'Up') { for (const p of pitches) events.push({midi:p,dur:0.5,vel:80,isDrum:false}) }
    else if (style === 'down' || style === 'Down') { for (let i=pitches.length-1;i>=0;i--) events.push({midi:pitches[i],dur:0.5,vel:80,isDrum:false}) }
    else if (style === 'updown' || style === 'UpDown') {
      for (const p of pitches) events.push({midi:p,dur:0.5,vel:80,isDrum:false})
      for (let i=pitches.length-2;i>=1;i--) events.push({midi:pitches[i],dur:0.5,vel:80,isDrum:false})
    } else { for (const p of pitches) events.push({midi:p,dur:0.5,vel:80,isDrum:false}) }
  }
  return events
}

function parseLine(line, isDrumTrack) {
  const events = []; let merged = line
  const chordRe = /[!>_]?\[[^\]]+\][whqes]\.?(?::\d+)?(?:@[a-z]+)?/g
  const chords = []; let m
  while ((m=chordRe.exec(line))!==null) chords.push({idx:m.index,raw:m[0]})
  for (let i=chords.length-1;i>=0;i--) merged = merged.slice(0,chords[i].idx)+'CHORD'+i+' '+merged.slice(chords[i].idx+chords[i].raw.length)
  const tokens = merged.split(/\s+/).filter(t=>t&&t!=='|'); let curDyn = 'mf'
  for (let tok of tokens) {
    if (tok.startsWith('CHORD')) {
      const raw = chords[parseInt(tok.slice(5))].raw
      const cm = raw.replace(/^[!>_]/,'').match(/^\[(.+)\]([whqes]\.?)(?::(\d+))?(?:@([a-z]+))?/)
      if (cm) {
        const pitches = cm[1].split(/\s+/).map(parsePitch).filter(p=>p>=0); const dur = parseDur(cm[2])
        const vel = cm[3]?parseInt(cm[3]):DYNAMICS[cm[4]||curDyn]||80
        const artic = (raw[0]==='!'?'staccato':raw[0]==='>'?'accent':raw[0]==='_'?'tenuto':'normal')
        let first = true
        for (const p of pitches) { events.push({midi:p,dur,vel,artic,dyn:cm[4]||curDyn,chord:!first,isDrum:isDrumTrack}); first=false }
      }
    } else if (DYNAMICS[tok]) { curDyn = tok }
    else if (isDrumTrack && DRUM_MAP[tok[0]] !== undefined) {
      let t = tok; const artic = (t[0]==='!'?'staccato':t[0]==='>'?'accent':t[0]==='_'?'tenuto':'normal')
      if (artic!=='normal') t = t.slice(1)
      const dm = t.match(/^([KHSO])([whqes]\.?)(?::(\d+))?(?:@([a-z]+))?$/)
      if (dm) { const midi = DRUM_MAP[dm[1]]; const dur = parseDur(dm[2]); const vel = dm[3]?parseInt(dm[3]):DYNAMICS[dm[4]||curDyn]||80; events.push({midi,dur,vel,artic,dyn:dm[4]||curDyn,isDrum:true}) }
    } else if (tok[0]==='R') { events.push({rest:true,dur:parseDur(tok.slice(1)),isDrum:isDrumTrack}) }
    else {
      let t = tok; const artic = (t[0]==='!'?'staccato':t[0]==='>'?'accent':t[0]==='_'?'tenuto':'normal')
      if (artic!=='normal') t = t.slice(1)
      const nm = t.match(/^([A-G][#b]?\d)([whqes]\.?)(?::(\d+))?(?:@([a-z]+))?$/)
      if (nm) { const vel = nm[3]?parseInt(nm[3]):DYNAMICS[nm[4]||curDyn]||80; events.push({midi:parsePitch(nm[1]),dur:parseDur(nm[2]),vel,artic,dyn:nm[4]||curDyn,isDrum:isDrumTrack}) }
    }
  }
  return events
}

function parsePitch(s) { const m=s.match(/^([A-G])([#b])?(\d)$/); if(!m)return 60; const n={C:0,D:2,E:4,F:5,G:7,A:9,B:11}; return (parseInt(m[3])+1)*12+(n[m[1]]||0)+(m[2]==='#'?1:m[2]==='b'?-1:0) }
function parseDur(s) { const b={w:4,h:2,q:1,e:0.5,s:0.25}; let m=1; if(s.endsWith('.')){m=1.5;s=s.slice(0,-1)}; return (b[s]||1)*m }

// --- Playback ---

function setupAudioGraph() {
  if (!audioContext) return
  if (masterGain) { try{masterGain.disconnect()}catch(e){} }
  masterGain = audioContext.createGain(); masterGain.gain.setValueAtTime(0.85, audioContext.currentTime)
  masterGain.connect(audioContext.destination)
  if (!masterAnalyser) { masterAnalyser = audioContext.createAnalyser(); masterAnalyser.fftSize = 256 }
  masterGain.connect(masterAnalyser)
  for (const id of Object.keys(trackChannels)) { const ch = trackChannels[id]; for (const n of ch.nodes) { try{n.disconnect()}catch(e){} try{n.stop()}catch(e){} } try{ch.gain.disconnect()}catch(e){}; try{ch.panner.disconnect()}catch(e){}; try{ch.analyser.disconnect()}catch(e){} }
  trackChannels = {}
  if (!parseResult) return
  const anySolo = parseResult.tracks.some(t => t.solo)
  for (const track of parseResult.tracks) {
    const ch = { gain:null, panner:null, analyser:null, nodes:[] }
    const audible = anySolo ? track.solo : !track.mute
    ch.gain = audioContext.createGain(); ch.gain.gain.setValueAtTime(audible ? track.volume : 0, audioContext.currentTime)
    ch.panner = audioContext.createStereoPanner(); ch.panner.pan.setValueAtTime(track.pan, audioContext.currentTime)
    ch.analyser = audioContext.createAnalyser(); ch.analyser.fftSize = 128
    ch.gain.connect(ch.panner); ch.panner.connect(masterGain); ch.panner.connect(ch.analyser)
    trackChannels[track.id] = ch
  }
}

function playSynthNote(e, baseTime) {
  const ctx = audioContext; const freq = 440*Math.pow(2,(e.midi-69)/12)
  const track = parseResult ? parseResult.tracks.find(t => t.id === e.trackId) : null
  const instName = (track && track.instrument && INSTRUMENTS[track.instrument]) ? track.instrument : 'piano'
  const inst = INSTRUMENTS[instName] || INSTRUMENTS.piano
  const ch = trackChannels[e.trackId]; if (!ch) return
  if (e.isDrum) { playDrum(e, baseTime, ch); return }
  const osc = ctx.createOscillator(); osc.type = inst.type
  osc.frequency.setValueAtTime(freq, baseTime+e.start)
  const gain = ctx.createGain(); const t = baseTime+e.start, d = e.duration
  const ng = inst.g * Math.max(0,Math.min(1,e.velocity))
  const g = gain.gain; g.setValueAtTime(0,t)
  g.linearRampToValueAtTime(ng, t+inst.a); g.linearRampToValueAtTime(ng*inst.s, t+inst.a+inst.d)
  g.setValueAtTime(ng*inst.s, Math.max(t, t+d-inst.r)); g.linearRampToValueAtTime(0, t+d)
  osc.connect(gain); gain.connect(ch.gain)
  if (inst.osc2) {
    const osc2 = ctx.createOscillator(); osc2.type = inst.type; osc2.frequency.setValueAtTime(freq+inst.detune, t)
    const g2 = ctx.createGain(); g2.gain.setValueAtTime(ng*0.3, t); g2.gain.linearRampToValueAtTime(0, t+d)
    osc2.connect(g2); g2.connect(ch.gain); osc2.start(t); osc2.stop(t+d+inst.r); ch.nodes.push(osc2,g2)
  }
  osc.start(t); osc.stop(t+d+inst.r); ch.nodes.push(osc,gain)
}

function playDrum(e, baseTime, ch) {
  const ctx = audioContext, t = baseTime+e.start, midi = e.midi, vel = Math.max(0,Math.min(1,e.velocity))
  if (midi === 36) { const osc = ctx.createOscillator(); osc.type='sine'; osc.frequency.setValueAtTime(150,t); osc.frequency.exponentialRampToValueAtTime(30,t+0.12); const g = ctx.createGain(); g.gain.setValueAtTime(0.6*vel,t); g.gain.exponentialRampToValueAtTime(0.001,t+0.15); osc.connect(g); g.connect(ch.gain); osc.start(t); osc.stop(t+0.15); ch.nodes.push(osc,g) }
  else if (midi === 38) { const bs = ctx.sampleRate*0.1, buf = ctx.createBuffer(1,bs,ctx.sampleRate); const d = buf.getChannelData(0); for(let i=0;i<bs;i++)d[i]=Math.random()*2-1; const noise = ctx.createBufferSource(); noise.buffer=buf; const g1 = ctx.createGain(); g1.gain.setValueAtTime(0.3*vel,t); g1.gain.exponentialRampToValueAtTime(0.001,t+0.08); noise.connect(g1); g1.connect(ch.gain); const osc = ctx.createOscillator(); osc.type='triangle'; osc.frequency.setValueAtTime(180,t); const g2 = ctx.createGain(); g2.gain.setValueAtTime(0.15,t); g2.gain.exponentialRampToValueAtTime(0.001,t+0.06); osc.connect(g2); g2.connect(ch.gain); noise.start(t); osc.start(t); noise.stop(t+0.1); osc.stop(t+0.1); ch.nodes.push(noise,osc,g1,g2) }
  else if (midi === 42) { const bs = ctx.sampleRate*0.05, buf = ctx.createBuffer(1,bs,ctx.sampleRate); const d = buf.getChannelData(0); for(let i=0;i<bs;i++)d[i]=Math.random()*2-1; const noise = ctx.createBufferSource(); noise.buffer=buf; const hp = ctx.createBiquadFilter(); hp.type='highpass'; hp.frequency.setValueAtTime(5000,t); const g = ctx.createGain(); g.gain.setValueAtTime(0.12*vel,t); g.gain.exponentialRampToValueAtTime(0.001,t+0.04); noise.connect(hp); hp.connect(g); g.connect(ch.gain); noise.start(t); noise.stop(t+0.05); ch.nodes.push(noise,g) }
  else if (midi === 46) { const bs = ctx.sampleRate*0.1, buf = ctx.createBuffer(1,bs,ctx.sampleRate); const d = buf.getChannelData(0); for(let i=0;i<bs;i++)d[i]=Math.random()*2-1; const noise = ctx.createBufferSource(); noise.buffer=buf; const hp = ctx.createBiquadFilter(); hp.type='highpass'; hp.frequency.setValueAtTime(5000,t); const g = ctx.createGain(); g.gain.setValueAtTime(0.1*vel,t); g.gain.exponentialRampToValueAtTime(0.001,t+0.12); noise.connect(hp); hp.connect(g); g.connect(ch.gain); noise.start(t); noise.stop(t+0.12); ch.nodes.push(noise,g) }
}

function playEvents(events) { stopPlayback(); const ctx = getAudioContext(); setupAudioGraph(); const td = Math.max(...events.map(e=>e.start+e.duration),0.1)+0.2; currentBaseTime = ctx.currentTime+0.05; for (const e of events) playSynthNote(e, currentBaseTime); playbackTimer = setTimeout(()=>{ if(loopEnabled)playEvents(events);else stopPlayback() }, td*1000); updateUI(); updateMeters() }
function stopPlayback() { if(playbackTimer){clearTimeout(playbackTimer);playbackTimer=null}; for(const id of Object.keys(trackChannels)){const ch=trackChannels[id];for(const n of ch.nodes){try{n.disconnect()}catch(e){}try{n.stop()}catch(e){}};try{ch.gain.disconnect()}catch(e){};try{ch.panner.disconnect()}catch(e){};try{ch.analyser.disconnect()}catch(e){}};trackChannels={}; updateUI(); updateMixerUI() }
function toggleLoop() { loopEnabled=!loopEnabled; updateUI() }
function getAudioContext() { if(!audioContext)audioContext=new(window.AudioContext||window.webkitAudioContext)(); if(audioContext.state==='suspended')audioContext.resume(); return audioContext }

// --- Mixer UI ---
function buildMixerUI() { const el=document.getElementById('mixer-rows');if(!el||!parseResult)return; el.innerHTML=''; for(const track of parseResult.tracks){ const row=document.createElement('div');row.className='mixer-row'; row.innerHTML=`<span class="mix-name">${track.id}</span><span class="mix-inst">${track.instrument||'piano'}</span><input type="range" class="mix-vol" min="0" max="200" value="${Math.round(track.volume*100)}" data-track="${track.id}"><input type="range" class="mix-pan" min="-100" max="100" value="${Math.round(track.pan*100)}" data-track="${track.id}"><button class="mix-mute${track.mute?' active':''}" data-track="${track.id}" data-action="mute">M</button><button class="mix-solo${track.solo?' active':''}" data-track="${track.id}" data-action="solo">S</button><div class="mix-meter"><div class="mix-meter-bar" id="meter-${track.id}"></div></div>`; el.appendChild(row) } el.querySelectorAll('.mix-vol').forEach(s=>s.addEventListener('input',e=>{const ch=trackChannels[e.target.dataset.track];if(ch)ch.gain.gain.setValueAtTime(parseInt(e.target.value)/100,audioContext.currentTime)})); el.querySelectorAll('.mix-pan').forEach(s=>s.addEventListener('input',e=>{const ch=trackChannels[e.target.dataset.track];if(ch)ch.panner.pan.setValueAtTime(parseInt(e.target.value)/100,audioContext.currentTime)})); el.querySelectorAll('[data-action="mute"]').forEach(b=>b.addEventListener('click',e=>{const tr=parseResult.tracks.find(t=>t.id===e.target.dataset.track);if(!tr)return;tr.mute=!tr.mute;e.target.classList.toggle('active',tr.mute);const ch=trackChannels[tr.id];if(ch)ch.gain.gain.setValueAtTime(tr.mute?0:tr.volume,audioContext.currentTime)})); el.querySelectorAll('[data-action="solo"]').forEach(b=>b.addEventListener('click',e=>{const tr=parseResult.tracks.find(t=>t.id===e.target.dataset.track);if(!tr)return;tr.solo=!tr.solo;e.target.classList.toggle('active',tr.solo);const anySolo=parseResult.tracks.some(t=>t.solo);for(const t of parseResult.tracks){const ch=trackChannels[t.id];if(!ch)continue;ch.gain.gain.setValueAtTime((anySolo?t.solo:!t.mute)?t.volume:0,audioContext.currentTime)}; updateMixerUI()})) }
function updateMixerUI() { if(!parseResult)return; for(const track of parseResult.tracks){const b=document.getElementById('meter-'+track.id);if(!b)continue;const ch=trackChannels[track.id];if(!ch||!ch.analyser)continue;const data=new Uint8Array(ch.analyser.frequencyBinCount);ch.analyser.getByteFrequencyData(data);b.style.width=Math.min(100,data.reduce((a,b)=>a+b,0)/data.length/2.5)+'%'} }
function updateMeters() { if(!playbackTimer)return; updateMixerUI(); if(masterAnalyser){const data=new Uint8Array(masterAnalyser.frequencyBinCount);masterAnalyser.getByteFrequencyData(data);document.getElementById('meter-bar').style.width=Math.min(100,data.reduce((a,b)=>a+b,0)/data.length/2.5)+'%'}; const el=document.getElementById('time-display');if(el&&audioContext&&currentBaseTime)el.textContent=Math.max(0,audioContext.currentTime-currentBaseTime).toFixed(1)+'s'; setTimeout(updateMeters,50) }
function updateUI() { const p=playbackTimer!==null; document.getElementById('play-btn').disabled=p; document.getElementById('stop-btn').disabled=!p; document.getElementById('loop-btn').textContent=loopEnabled?'Loop:ON':'Loop:OFF'; document.getElementById('status').textContent=p?'playing...':'idle' }

function loadExample(id) { const ex={ full:'tempo 108\ntime 4/4\nswing 0.56\n\ntrack lead instrument piano volume 0.85 pan 0.05\n| C4q@mp D4q E4q@mf G4q@f |\n| C5e@f B4e A4q@mf G4q_ Rq |\n\ntrack chords instrument pad volume 0.40 pan -0.35\n| [C3 E3 G3]w@p | [F3 A3 C4]h@mp [G3 B3 D4]h@mp |\n\ntrack bass instrument bass volume 0.75 pan 0.10\n| C2q Rq G2q Rq | F2q Rq G2q Rq |\n\ntrack drums instrument drums volume 0.80 pan 0\n| Kq Hq Sq Hq | Kq He He Sq Hq |', drums:'tempo 100\ntrack drums instrument drums volume 0.85\n| Kq Hq Sq Hq | Kq He He Sq Hq | Kq Hq Sq Oq | Kq He Sq He |', bassdrums:'tempo 100\ntrack bass instrument bass volume 0.8\n| C2q Rq G2q Rq | F2q Rq G2q Rq |\n\ntrack drums instrument drums volume 0.7\n| Kq Hq Sq Hq | Kq He He Sq Hq |', progression:'tempo 100\ntime 4/4\nkey C major\nstyle pop_ballad\nprogression I vi IV V\ngenerate chords\ngenerate bass root_fifth\ngenerate arpeggio updown\n\ntrack drums instrument drums volume 0.7\n| Kq Hq Sq Hq | Kq He He Sq Hq | x2', voicelead:'tempo 100\ntime 4/4\nkey C major\nprogression I V vi IV\ngenerate chords\n# chords use voice leading for smooth transitions' }; if(ex[id])document.getElementById('score-input').value=ex[id] }

document.getElementById('play-btn').addEventListener('click',()=>{ try{const r=parseScore(document.getElementById('score-input').value);document.getElementById('error-msg').textContent='';buildMixerUI();playEvents(r.allEvents)}catch(e){document.getElementById('error-msg').textContent='Parse error: '+e.message} })
document.getElementById('stop-btn').addEventListener('click',stopPlayback)
document.getElementById('loop-btn').addEventListener('click',toggleLoop)
