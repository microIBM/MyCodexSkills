// ===================== DOM =====================
const chatEl = document.getElementById('chat');
const statusEl = document.getElementById('status');
const statusTextEl = statusEl.querySelector('span');
const quoteEl = document.getElementById('quote');
const micBtn = document.getElementById('micBtn');
const callHint = document.getElementById('callHint');
const textInput = document.getElementById('textInput');
const sendBtn = document.getElementById('sendBtn');
const stopBtn = document.getElementById('stopBtn');
const bargeIn = document.getElementById('bargeIn');
const asrHint = document.getElementById('asrHint');

const DEFAULT_PLACEHOLDER = textInput.placeholder;
const STATUS_LABEL = {
  idle: 'STANDBY', connecting: 'CONNECTING', reconnecting: 'RECONNECT',
  listening: 'LISTENING', thinking: 'THINKING', speaking: 'SPEAKING',
};
const CALL_HINT = {
  idle: '按下开始语音对话',
  listening: '聆听中 · 再按结束',
  thinking: '群总琢磨中',
  speaking: '群总开麦',
  reconnecting: '连接断开，重连中',
};

let ws = null;
let currentGenId = null;
let genActive = false;
let aiBubble = null;
let mode = 'idle'; // 驱动粒子行为
let chatMode = 'base'; // base=蒸馏人设 / full=完整 SKILL.md

// ---- 模式切换 ----
const modeSwitch = document.getElementById('modeSwitch');
function renderModeSwitch() {
  modeSwitch.querySelectorAll('button').forEach(b =>
    b.classList.toggle('on', b.dataset.mode === chatMode));
}
modeSwitch.querySelectorAll('button').forEach(b => {
  b.onclick = () => { if (b.dataset.mode !== chatMode) wsSend({ type: 'set_mode', mode: b.dataset.mode }); };
});

function setStatus(state) {
  const cls = STATUS_LABEL[state] ? state : 'idle';
  mode = cls;
  statusEl.className = 'status ' + cls;
  statusTextEl.textContent = STATUS_LABEL[cls];
  if (CALL_HINT[cls]) callHint.textContent = CALL_HINT[cls];
}
function scrollChat() { chatEl.scrollTop = chatEl.scrollHeight; }
function addBubble(cls, text) {
  const div = document.createElement('div');
  div.className = 'bubble ' + cls;
  div.textContent = text;
  chatEl.appendChild(div);
  scrollChat();
  return div;
}
function onSpeechFinished() {
  setStatus(asr.on ? 'listening' : 'idle');
  asr.resumeAfterSpeech();
}

// ===================== 音频上下文（粒子律动用）=====================
let audioCtx = null, analyser = null, freqData = null;
function ensureAudioCtx() {
  if (!audioCtx) {
    try {
      const AC = window.AudioContext || window.webkitAudioContext;
      audioCtx = new AC();
      analyser = audioCtx.createAnalyser();
      analyser.fftSize = 256;
      analyser.smoothingTimeConstant = 0.7;
      freqData = new Uint8Array(analyser.frequencyBinCount);
      analyser.connect(audioCtx.destination);
    } catch (_) { audioCtx = null; }
  }
  if (audioCtx && audioCtx.state === 'suspended') audioCtx.resume().catch(() => {});
}
function audioLevel() {
  if (!analyser) return 0;
  analyser.getByteFrequencyData(freqData);
  let s = 0;
  for (let i = 0; i < freqData.length; i++) s += freqData[i];
  return s / freqData.length / 255;
}

// ===================== 音频队列 =====================
const audioQueue = {
  queue: [], playing: false, current: null,
  push(genId, base64) {
    if (genId !== currentGenId) return;
    const bytes = Uint8Array.from(atob(base64), c => c.charCodeAt(0));
    const url = URL.createObjectURL(new Blob([bytes], { type: 'audio/mpeg' }));
    this.queue.push(url);
    if (!this.playing) this.playNext();
  },
  playNext() {
    const url = this.queue.shift();
    if (!url) {
      this.playing = false;
      this.current = null;
      // 生成还没结束时保持等待（句间空档不恢复麦克风，防自听）
      if (!genActive) onSpeechFinished();
      return;
    }
    this.playing = true;
    setStatus('speaking');
    asr.pauseForSpeech();
    const audio = new Audio(url);
    this.current = audio;
    if (audioCtx && audioCtx.state === 'running') {
      try { audioCtx.createMediaElementSource(audio).connect(analyser); } catch (_) {}
    }
    const next = () => { URL.revokeObjectURL(url); this.playNext(); };
    audio.onended = next;
    audio.onerror = next;
    audio.play().catch(next);
  },
  clear() {
    this.queue.forEach(u => URL.revokeObjectURL(u));
    this.queue = [];
    if (this.current) { this.current.pause(); URL.revokeObjectURL(this.current.src); this.current = null; }
    this.playing = false;
  },
};

// ===================== WebSocket =====================
function wsSend(obj) { if (ws && ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(obj)); }
function connect() {
  const proto = location.protocol === 'https:' ? 'wss' : 'ws';
  ws = new WebSocket(`${proto}://${location.host}/ws`);
  ws.onopen = () => {
    setStatus(asr.on ? 'listening' : 'idle');
    if (chatMode !== 'base') wsSend({ type: 'set_mode', mode: chatMode }); // 重连后恢复模式
  };
  ws.onclose = () => { setStatus('reconnecting'); setTimeout(connect, 1000); };
  ws.onmessage = (e) => {
    const msg = JSON.parse(e.data);
    switch (msg.type) {
      case 'gen_start':
        currentGenId = msg.gen_id; genActive = true;
        aiBubble = addBubble('ai', ''); setStatus('thinking');
        break;
      case 'llm_delta':
        if (msg.gen_id === currentGenId && aiBubble) { aiBubble.textContent += msg.text; scrollChat(); }
        break;
      case 'audio':
        audioQueue.push(msg.gen_id, msg.data);
        break;
      case 'tts_error':
        break;
      case 'done':
        if (msg.gen_id === currentGenId) { genActive = false; if (!audioQueue.playing) onSpeechFinished(); }
        break;
      case 'mode_set':
        chatMode = msg.mode;
        renderModeSwitch();
        break;
      case 'error':
        if (msg.gen_id === currentGenId && aiBubble) {
          aiBubble.textContent += '\n[出错了: ' + msg.message + ']';
          genActive = false; setStatus('idle');
        }
        break;
    }
  };
}

function interruptLocal() {
  if (aiBubble && genActive) aiBubble.classList.add('interrupted');
  currentGenId = null; genActive = false;
  audioQueue.clear();
}
function sendUserText(text) {
  text = text.trim();
  if (!text || !ws || ws.readyState !== WebSocket.OPEN) return;
  ensureAudioCtx();
  interruptLocal();
  addBubble('user', text);
  wsSend({ type: 'user_text', text });
  setStatus('thinking');
}
function submitInput() { sendUserText(textInput.value); textInput.value = ''; }

sendBtn.onclick = submitInput;
textInput.onkeydown = (e) => { if (e.key === 'Enter' && !e.isComposing) submitInput(); };
textInput.onfocus = ensureAudioCtx;
stopBtn.onclick = () => { interruptLocal(); wsSend({ type: 'interrupt' }); onSpeechFinished(); };

// ===================== 语音识别 =====================
const asr = {
  rec: null, on: false, pausedBySpeech: false,
  supported: !!(window.SpeechRecognition || window.webkitSpeechRecognition),
  init() {
    if (!this.supported) {
      micBtn.disabled = true;
      callHint.textContent = '浏览器不支持语音识别';
      asrHint.textContent = '请用 Chrome/Edge 打开以启用语音，当前可用文字输入。';
      return;
    }
    const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    this.rec = new SR();
    this.rec.lang = 'zh-CN'; this.rec.continuous = true; this.rec.interimResults = true;
    this.rec.onresult = (e) => {
      let interim = '';
      for (let i = e.resultIndex; i < e.results.length; i++) {
        const r = e.results[i];
        if (r.isFinal) { const t = r[0].transcript.trim(); if (t) sendUserText(t); }
        else interim += r[0].transcript;
      }
      textInput.placeholder = interim || DEFAULT_PLACEHOLDER;
    };
    this.rec.onerror = (e) => {
      if (e.error === 'not-allowed') { this.stop(); asrHint.textContent = '麦克风权限被拒绝，请在浏览器设置中允许。'; }
    };
    this.rec.onend = () => { if (this.on && !this.pausedBySpeech) this.safeStart(); };
  },
  safeStart() { try { this.rec.start(); } catch (_) {} },
  safeStop() { try { this.rec.stop(); } catch (_) {} },
  start() { if (!this.supported) return; ensureAudioCtx(); this.on = true; micBtn.classList.add('active'); setStatus('listening'); this.safeStart(); },
  stop() { this.on = false; this.pausedBySpeech = false; micBtn.classList.remove('active'); if (this.rec) this.safeStop(); if (!audioQueue.playing) setStatus('idle'); textInput.placeholder = DEFAULT_PLACEHOLDER; },
  pauseForSpeech() { if (!this.on || bargeIn.checked) return; this.pausedBySpeech = true; this.safeStop(); },
  resumeAfterSpeech() {
    if (!this.on || !this.pausedBySpeech) return;
    setTimeout(() => {
      if (this.on && !audioQueue.playing) { this.pausedBySpeech = false; setStatus('listening'); this.safeStart(); }
    }, 300);
  },
};
micBtn.onclick = () => { asr.on ? asr.stop() : asr.start(); };

// ===================== 语录轮换 =====================
(function rotateQuotes() {
  const quotes = [
    '只做龙头不做杂毛', '会空仓的才是祖师爷', '买在分歧 · 卖在一致',
    '龙头是走出来的，不是猜出来的', '错过永远比错误好', '赚钱赚的是市场合力的钱',
    '退潮就空仓 · 冰点等信号', '亏钱也要亏在龙头身上',
  ];
  let i = 0;
  setInterval(() => {
    quoteEl.style.opacity = 0;
    setTimeout(() => {
      i = (i + 1) % quotes.length;
      quoteEl.textContent = quotes[i];
      quoteEl.style.opacity = 1;
    }, 800);
  }, 9000);
})();

// ===================== 粒子聚形「群」 =====================
const stage = document.getElementById('stage');
const ctx = stage.getContext('2d');
let W = 0, H = 0, CX = 0, CY = 0, GR = 0;
let buckets = []; // 按颜色/透明度分桶，减少 fillStyle 切换

const INK = [23, 23, 21];
const RED = [216, 56, 47];
const ALPHAS = [0.28, 0.45, 0.65, 0.88];

function sampleGlyph(w, h) {
  const cx = w / 2, cy = h * 0.27;
  const size = Math.min(w * 0.46, h * 0.34);
  const off = document.createElement('canvas');
  off.width = w; off.height = h;
  const c = off.getContext('2d', { willReadFrequently: true });
  c.fillStyle = '#000';
  c.font = `900 ${size}px "Microsoft YaHei", "PingFang SC", sans-serif`;
  c.textAlign = 'center';
  c.textBaseline = 'middle';
  c.fillText('群', cx, cy);
  const data = c.getImageData(0, 0, w, h).data;

  let step = 2, pts = [];
  do {
    pts = [];
    for (let y = 0; y < h; y += step) {
      for (let x = 0; x < w; x += step) {
        if (data[(y * w + x) * 4 + 3] > 128) {
          pts.push([x + (Math.random() - 0.5) * step, y + (Math.random() - 0.5) * step]);
        }
      }
    }
    step++;
  } while (pts.length > 6000 && step < 10);
  return { pts, cx, cy, r: size * 0.62 };
}

function buildParticles() {
  const { pts, cx, cy, r } = sampleGlyph(W, H);
  CX = cx; CY = cy; GR = r;
  const halo = Math.floor(pts.length * 0.14); // 外围散点，dither 云感
  const all = [];

  function make(hx, hy, isHalo) {
    const red = Math.random() < 0.035;
    return {
      hx, hy,
      x: Math.random() * W, y: Math.random() * H,
      s: (isHalo ? 0.7 : 0.9) + Math.random() * 1.1,
      f1: 0.0006 + Math.random() * 0.0012, f2: 0.0006 + Math.random() * 0.0012,
      p1: Math.random() * 6.283, p2: Math.random() * 6.283,
      rnd: 0.4 + Math.random() * 0.9,
      bucket: (red ? 4 : 0) + (Math.random() * 4 | 0),
      isHalo,
    };
  }

  for (const [x, y] of pts) all.push(make(x, y, false));
  for (let i = 0; i < halo; i++) {
    const ang = Math.random() * 6.283;
    const dist = r * (1.05 + Math.random() * Math.random() * 1.1);
    all.push(make(cx + Math.cos(ang) * dist, cy + Math.sin(ang) * dist * 0.9, true));
  }

  buckets = [];
  for (let b = 0; b < 8; b++) {
    const col = b < 4 ? INK : RED;
    buckets.push({
      style: `rgba(${col[0]},${col[1]},${col[2]},${ALPHAS[b % 4]})`,
      parts: all.filter(p => p.bucket === b),
    });
  }
}

function resizeStage() {
  const dpr = Math.min(window.devicePixelRatio || 1, 1.5);
  W = window.innerWidth; H = window.innerHeight;
  stage.width = W * dpr; stage.height = H * dpr;
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  buildParticles();
}
resizeStage();
let resizeTimer;
window.addEventListener('resize', () => { clearTimeout(resizeTimer); resizeTimer = setTimeout(resizeStage, 150); });

// 鼠标斥力：靠近的粒子被冲散，移走后回聚
const mouse = { x: -9999, y: -9999 };
const MOUSE_R = 160, MOUSE_R2 = MOUSE_R * MOUSE_R, MOUSE_F = 220;
window.addEventListener('mousemove', (e) => { mouse.x = e.clientX; mouse.y = e.clientY; });
window.addEventListener('mouseout', () => { mouse.x = -9999; mouse.y = -9999; });
window.addEventListener('touchmove', (e) => {
  const t0 = e.touches[0];
  if (t0) { mouse.x = t0.clientX; mouse.y = t0.clientY; }
}, { passive: true });
window.addEventListener('touchend', () => { mouse.x = -9999; mouse.y = -9999; });

let smoothLevel = 0;
function drawStage(t) {
  ctx.clearRect(0, 0, W, H);

  const level = mode === 'speaking' ? audioLevel() : 0;
  smoothLevel += (level - smoothLevel) * 0.25;

  const breathe = 1.1 + Math.sin(t * 0.0011) * 0.7;                  // idle 呼吸
  const jitter = breathe + (mode === 'listening' ? 1.2 : 0) + smoothLevel * 26;
  const swirl = mode === 'thinking' ? Math.sin(t * 0.0016) * 5 : 0;  // thinking 涡旋
  const burst = smoothLevel * 30;                                    // speaking 径向外推

  for (const bucket of buckets) {
    ctx.fillStyle = bucket.style;
    for (const p of bucket.parts) {
      let tx = p.hx + Math.sin(t * p.f1 + p.p1) * jitter * p.rnd;
      let ty = p.hy + Math.cos(t * p.f2 + p.p2) * jitter * p.rnd;
      if (swirl || burst) {
        const dx = p.hx - CX, dy = p.hy - CY;
        const d = Math.sqrt(dx * dx + dy * dy) + 0.001;
        if (swirl) { tx += (-dy / d) * swirl * p.rnd * 2; ty += (dx / d) * swirl * p.rnd * 2; }
        if (burst) { tx += (dx / d) * burst * p.rnd; ty += (dy / d) * burst * p.rnd; }
      }
      const mdx = p.x - mouse.x, mdy = p.y - mouse.y;
      const md2 = mdx * mdx + mdy * mdy;
      if (md2 < MOUSE_R2) {
        const md = Math.sqrt(md2) + 0.001;
        const f = 1 - md / MOUSE_R;
        const push = f * f * MOUSE_F * p.rnd; // 平方衰减：越近冲得越猛
        tx += (mdx / md) * push;
        ty += (mdy / md) * push;
        p.x += (mdx / md) * push * 0.35;      // 即时冲开分量，增强“炸开”手感
        p.y += (mdy / md) * push * 0.35;
      }
      p.x += (tx - p.x) * 0.07;
      p.y += (ty - p.y) * 0.07;
      ctx.fillRect(p.x, p.y, p.s, p.s);
    }
  }
  requestAnimationFrame(drawStage);
}
requestAnimationFrame(drawStage);

// ===================== 启动 =====================
asr.init();
connect();
