/**
 * VETO — Gemini Multimodal Live (native AUDIO) in the browser.
 * Ephemeral token from POST /api/ai/live-token (v1alpha). No API key in the page.
 *
 * Input: 16 kHz mono 16-bit LE PCM (ScriptProcessor resample from mic).
 * Output: 24 kHz model PCM from inlineData → Web Audio API scheduling.
 * Flutter: receives LIVE:{ u, m, nativeAudio } — m from outputAudioTranscription; skip vetoTTS when nativeAudio.
 */
import { GoogleGenAI } from "https://esm.sh/@google/genai@1.48.0?target=es2022";

const NS = "vetoGeminiLive_";
const OUT_SR = 24000;
const IN_SR = 16000;

function emit(s) {
  const fn = window["vetoGeminiLiveResult"];
  if (typeof fn === "function") fn(s);
}

function isTunnel() {
  try {
    return typeof location !== "undefined" && (location.hostname || "").includes("loca.lt");
  } catch {
    return false;
  }
}

function headersFor(jwt) {
  const h = { "Content-Type": "application/json", Authorization: "Bearer " + jwt };
  if (isTunnel()) h["bypass-tunnel-reminder"] = "true";
  return h;
}

/** Base64 → Int16Array LE (even byte count) */
function b64ToInt16LE(b64) {
  const bin = atob(b64);
  const len = Math.floor(bin.length / 2) * 2;
  if (len < 2) return new Int16Array(0);
  const u8 = new Uint8Array(len);
  for (let i = 0; i < len; i++) u8[i] = bin.charCodeAt(i);
  return new Int16Array(u8.buffer);
}

function flushPlayback(st) {
  if (st._sources) {
    for (const s of st._sources) {
      try {
        s.stop(0);
      } catch (_) {
        // ignore
      }
    }
    st._sources = [];
  }
  st._nextPlay = null;
}

function getAudioContextCtor() {
  return window.AudioContext || window.webkitAudioContext || null;
}

function enqueuePcm(st, int16, sampleRate) {
  if (!int16 || int16.length === 0) return;
  st.usedNativeAudio = true;
  const AC = getAudioContextCtor();
  if (!AC) return;
  if (!st.playbackCtx) {
    st.playbackCtx = new AC({ sampleRate: sampleRate });
  }
  const ctx = st.playbackCtx;
  ctx.resume().catch(() => {});
  const n = int16.length;
  const buf = ctx.createBuffer(1, n, sampleRate);
  const ch = buf.getChannelData(0);
  for (let i = 0; i < n; i++) ch[i] = Math.max(-1, Math.min(1, int16[i] / 32768));
  const src = ctx.createBufferSource();
  src.buffer = buf;
  src.connect(ctx.destination);
  const now = ctx.currentTime;
  const startAt = st._nextPlay != null ? Math.max(now, st._nextPlay) : now;
  src.start(startAt);
  st._nextPlay = startAt + buf.duration;
  if (!st._sources) st._sources = [];
  st._sources.push(src);
}

function onServerMessage(st, msg) {
  if (!st || st.done) return;
  const sc = msg && msg.serverContent;
  if (!sc) return;

  if (sc.interrupted === true) {
    flushPlayback(st);
  }

  if (sc.inputTranscription && typeof sc.inputTranscription.text === "string" && sc.inputTranscription.text.length) {
    st.accUser = sc.inputTranscription.text;
  }
  if (sc.outputTranscription && typeof sc.outputTranscription.text === "string" && sc.outputTranscription.text.length) {
    st.accModel = (st.accModel || "") + sc.outputTranscription.text;
  }

  if (typeof msg.text === "string" && msg.text.length) {
    st.accModel = (st.accModel || "") + msg.text;
  }

  if (sc.modelTurn && sc.modelTurn.parts) {
    for (const p of sc.modelTurn.parts) {
      const id = p.inlineData || p.inline_data;
      if (!id || !id.data) continue;
      const mime = String(id.mimeType || id.mime_type || "").toLowerCase();
      if (mime.includes("pcm") || mime.includes("audio")) {
        let sr = OUT_SR;
        const mrate = /rate=(\d+)/.exec(mime);
        if (mrate) sr = parseInt(mrate[1], 10) || OUT_SR;
        const pcm = b64ToInt16LE(id.data);
        enqueuePcm(st, pcm, sr);
      }
    }
  }
}

function teardownCapture(st) {
  try {
    if (st.scriptNode) {
      st.scriptNode.disconnect();
      st.scriptNode.onaudioprocess = null;
    }
  } catch (_) {
    // ignore
  }
  st.scriptNode = null;
  try {
    if (st.mediaSourceNode) st.mediaSourceNode.disconnect();
  } catch (_) {
    // ignore
  }
  st.mediaSourceNode = null;
  try {
    if (st.captureCtx && st.captureCtx.state !== "closed") st.captureCtx.close();
  } catch (_) {
    // ignore
  }
  st.captureCtx = null;
}

function finalize(st, err) {
  if (!st || st.done) return;
  st.done = true;
  if (st._timer) {
    try {
      clearTimeout(st._timer);
    } catch (_) {
      // ignore
    }
  }
  teardownCapture(st);
  if (st.stream) {
    try {
      st.stream.getTracks().forEach((t) => t.stop());
    } catch (_) {
      // ignore
    }
  }
  st.stream = null;
  flushPlayback(st);
  try {
    if (st.playbackCtx && st.playbackCtx.state !== "closed") st.playbackCtx.close();
  } catch (_) {
    // ignore
  }
  st.playbackCtx = null;

  if (st.session) {
    setTimeout(function () {
      if (st.session) {
        try {
          st.session.close();
        } catch (_) {
          // ignore
        }
      }
      st.session = null;
      const payload = {
        u: st.accUser || "",
        m: st.accModel || "",
        nativeAudio: !!st.usedNativeAudio,
      };
      if (err) {
        emit("LIVE:" + JSON.stringify({ u: payload.u, m: "", err: String(err), nativeAudio: false }));
      } else {
        emit("LIVE:" + JSON.stringify(payload));
      }
      window[NS + "st"] = null;
    }, 200);
  } else {
    const payload = { u: st.accUser || "", m: st.accModel || "", nativeAudio: !!st.usedNativeAudio };
    if (err) emit("LIVE:" + JSON.stringify({ u: payload.u, m: "", err: String(err), nativeAudio: false }));
    else emit("LIVE:" + JSON.stringify(payload));
    window[NS + "st"] = null;
  }
}

function startPcmMic(stream, session, st) {
  const AC = getAudioContextCtor();
  if (!AC) throw new Error("no_audio_context");
  const ac = new AC();
  st.captureCtx = ac;
  const src = ac.createMediaStreamSource(stream);
  st.mediaSourceNode = src;
  const bufferSize = 4096;
  const proc = ac.createScriptProcessor(bufferSize, 1, 1);
  st.scriptNode = proc;
  const mute = ac.createGain();
  mute.gain.value = 0;
  proc.onaudioprocess = function (ev) {
    if (st.done) return;
    const input = ev.inputBuffer.getChannelData(0);
    const inRate = ac.sampleRate;
    const outRate = IN_SR;
    const outLen = Math.max(1, Math.floor((input.length * outRate) / inRate));
    const i16 = new Int16Array(outLen);
    for (let i = 0; i < outLen; i++) {
      const inIdx = (i * inRate) / outRate;
      const i0 = Math.floor(inIdx);
      const i1 = Math.min(i0 + 1, input.length - 1);
      const f = inIdx - i0;
      let s = input[i0] * (1 - f) + input[i1] * f;
      s = Math.max(-1, Math.min(1, s));
      i16[i] = s < 0 ? s * 32768 : s * 32767;
    }
    const u8 = new Uint8Array(i16.buffer);
    let bin = "";
    for (let j = 0; j < u8.length; j++) bin += String.fromCharCode(u8[j]);
    const b64 = btoa(bin);
    try {
      session.sendRealtimeInput({ audio: { data: b64, mimeType: "audio/pcm;rate=16000" } });
    } catch (_) {
      // ignore
    }
  };
  src.connect(proc);
  proc.connect(mute);
  mute.connect(ac.destination);
}

async function startSession(lang, jwt, apiBase) {
  if (!apiBase) throw new Error("apiBase missing");
  if (!jwt) throw new Error("JWT missing");
  const url = String(apiBase).replace(/\/$/, "") + "/ai/live-token";
  const res = await fetch(url, {
    method: "POST",
    headers: headersFor(jwt),
    body: JSON.stringify({ lang: lang || "he" }),
  });
  if (!res.ok) {
    let d = "HTTP " + res.status;
    try {
      const j = await res.json();
      if (j && j.error) d = j.error;
    } catch (_) {
      // ignore
    }
    throw new Error(d);
  }
  const body = await res.json();
  const name = body.name;
  const model = body.model;
  if (!name || !model) throw new Error("Invalid token response");

  const st = {
    session: null,
    stream: null,
    captureCtx: null,
    mediaSourceNode: null,
    scriptNode: null,
    playbackCtx: null,
    _nextPlay: null,
    _sources: [],
    accUser: "",
    accModel: "",
    usedNativeAudio: false,
    done: false,
    _timer: null,
  };
  window[NS + "st"] = st;

  const media = await navigator.mediaDevices.getUserMedia({
    audio: { echoCancellation: true, noiseSuppression: true, channelCount: 1 },
  });
  st.stream = media;

  const genai = new GoogleGenAI({ apiKey: name, httpOptions: { apiVersion: "v1alpha" } });
  const session = await genai.live.connect({
    model: model,
    callbacks: {
      onmessage: (e) => onServerMessage(st, e),
      onerror: (e) => {
        if (!st.done) finalize(st, (e && e.error) ? e.error : "live error");
      },
    },
  });
  st.session = session;
  startPcmMic(media, session, st);
}

function userStop() {
  const st = window[NS + "st"];
  if (!st || st.done) return;
  teardownCapture(st);
  try {
    if (st.session) st.session.sendRealtimeInput({ audioStreamEnd: true });
  } catch (_) {
    // ignore
  }
  st._timer = setTimeout(function () {
    if (st && !st.done) finalize(st, null);
  }, 2800);
}

const _AC = typeof AudioContext !== "undefined" ? AudioContext : typeof window !== "undefined" ? window.webkitAudioContext : null;
const supported =
  typeof navigator !== "undefined" &&
  !!navigator.mediaDevices &&
  typeof navigator.mediaDevices.getUserMedia === "function" &&
  !!_AC &&
  typeof _AC.prototype.createScriptProcessor === "function" &&
  (typeof isSecureContext === "undefined" || isSecureContext);

if (!window["vetoGeminiLive"] || typeof window["vetoGeminiLive"] !== "object") {
  window["vetoGeminiLive"] = {};
}
Object.assign(window["vetoGeminiLive"], {
  isSupported: function () {
    return supported;
  },
  start: function (lang, jwt, apiBase) {
    (async function () {
      if (!supported) {
        emit("LIVE:" + JSON.stringify({ err: "not_supported" }));
        return;
      }
      if (window[NS + "st"] && !window[NS + "st"].done) {
        return;
      }
      try {
        await startSession(lang, jwt, apiBase);
      } catch (e) {
        const st = window[NS + "st"];
        if (st) {
          teardownCapture(st);
          if (st.stream) {
            try {
              st.stream.getTracks().forEach((t) => t.stop());
            } catch (_) {
              // ignore
            }
          }
          st.stream = null;
        }
        window[NS + "st"] = null;
        const msg = e && e.message ? e.message : String(e);
        emit("LIVE:" + JSON.stringify({ u: "", m: "", err: msg, nativeAudio: false }));
      }
    })();
  },
  stop: function () {
    userStop();
  },
});
