/**
 * VETO — Gemini Multimodal Live (native AUDIO) in the browser.
 * Ephemeral token from POST /api/ai/live-token (v1alpha). No API key in the page.
 *
 * Input: 16 kHz mono s16le via AudioWorklet (gemini_live_capture.worklet.js); ScriptProcessor fallback only if worklet fails.
 * Output: 24 kHz model PCM from inlineData → Web Audio API scheduling.
 * Flutter: receives LIVE:{ u, m, nativeAudio } — m from outputAudioTranscription; skip vetoTTS when nativeAudio.
 */
import { GoogleGenAI } from "https://esm.sh/@google/genai@1.50.1?target=es2022";

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
  if (!st._masterGain) {
    st._masterGain = ctx.createGain();
    st._masterGain.gain.value =
      typeof st._gainVal === "number" && !isNaN(st._gainVal) ? Math.max(0, Math.min(1, st._gainVal)) : 0.85;
    st._masterGain.connect(ctx.destination);
  }
  const n = int16.length;
  const buf = ctx.createBuffer(1, n, sampleRate);
  const ch = buf.getChannelData(0);
  for (let i = 0; i < n; i++) ch[i] = Math.max(-1, Math.min(1, int16[i] / 32768));
  const src = ctx.createBufferSource();
  src.buffer = buf;
  try {
    src.connect(st._masterGain);
  } catch (_) {
    src.connect(ctx.destination);
  }
  const now = ctx.currentTime;
  const startAt = st._nextPlay != null ? Math.max(now, st._nextPlay) : now;
  src.start(startAt);
  st._nextPlay = startAt + buf.duration;
  if (!st._sources) st._sources = [];
  st._sources.push(src);
  // Drop finished nodes so long Gemini replies do not grow _sources without bound (Flutter Web memory).
  src.onended = function () {
    try {
      const ix = st._sources.indexOf(src);
      if (ix >= 0) st._sources.splice(ix, 1);
    } catch (_) {
      // ignore
    }
  };
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
    if (st.workletNode) {
      st.workletNode.port.onmessage = null;
      st.workletNode.disconnect();
    }
  } catch (_) {
    // ignore
  }
  st.workletNode = null;
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
  st._masterGain = null;

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
        const errStr = String(err);
        // Recoverable disconnect: keep user transcript for Flutter (veto_screen live_socket_closed).
        if (errStr === "live_socket_closed") {
          emit(
            "LIVE:" +
              JSON.stringify({
                u: payload.u,
                m: payload.m,
                err: errStr,
                nativeAudio: !!st.usedNativeAudio,
              }),
          );
        } else {
          emit("LIVE:" + JSON.stringify({ u: payload.u, m: "", err: errStr, nativeAudio: false }));
        }
      } else {
        emit("LIVE:" + JSON.stringify(payload));
      }
      window[NS + "st"] = null;
    }, 200);
  } else {
    const payload = { u: st.accUser || "", m: st.accModel || "", nativeAudio: !!st.usedNativeAudio };
    if (err) {
      const errStr = String(err);
      if (errStr === "live_socket_closed") {
        emit(
          "LIVE:" +
            JSON.stringify({
              u: payload.u,
              m: payload.m,
              err: errStr,
              nativeAudio: !!st.usedNativeAudio,
            }),
        );
      } else {
        emit("LIVE:" + JSON.stringify({ u: payload.u, m: "", err: errStr, nativeAudio: false }));
      }
    } else emit("LIVE:" + JSON.stringify(payload));
    window[NS + "st"] = null;
  }
}

/**
 * The @google/genai web Live stack uses a BrowserWebSocket wrapper: real socket is conn.ws.
 * conn.readyState is undefined on the wrapper, so an earlier guard never skipped sends — mic loop
 * kept calling send on a CLOSING/CLOSED ws (console: __browser_websocket.ts).
 * Use conn.ws.readyState + close on conn.ws.
 */
function liveUnderlyingWs(conn) {
  if (!conn) return null;
  if (conn.ws && typeof conn.ws.readyState === "number") return conn.ws;
  if (typeof conn.readyState === "number") return conn;
  return null;
}

function guardLiveConnSend(st, session) {
  const conn = session && session.conn;
  if (!conn || typeof conn.send !== "function") return;
  const WS_OPEN = typeof WebSocket !== "undefined" ? WebSocket.OPEN : 1;
  const orig = conn.send.bind(conn);
  conn.send = function (data) {
    if (st.done || st._micStopped) return;
    const ws = liveUnderlyingWs(conn);
    const rs = ws != null ? ws.readyState : undefined;
    if (rs !== undefined && rs !== WS_OPEN) {
      if (!st._micStopped) {
        st._micStopped = true;
        try {
          teardownCapture(st);
        } catch (_) {
          // ignore
        }
        // Same as ws "close": end session with whatever transcript we have — not an error string in UI.
        finalize(st, null);
      }
      return;
    }
    try {
      return orig(data);
    } catch (err) {
      if (!st._micStopped) {
        st._micStopped = true;
        try {
          teardownCapture(st);
        } catch (_) {
          // ignore
        }
        finalize(st, err && err.message ? err.message : String(err));
      }
    }
  };
  const ws = liveUnderlyingWs(conn);
  if (ws && typeof ws.addEventListener === "function") {
    ws.addEventListener("close", function () {
      if (st.done || st._micStopped) return;
      st._micStopped = true;
      try {
        teardownCapture(st);
      } catch (_) {
        // ignore
      }
      // User tapped stop: treat as normal end (full transcript). Otherwise abnormal drop.
      finalize(st, st._userRequestedStop ? null : "live_socket_closed");
    });
  }
}

function sendPcmChunk(session, st, i16) {
  if (!i16 || i16.length === 0 || st.done || st._micStopped) return;
  const u8 = new Uint8Array(i16.buffer, i16.byteOffset, i16.byteLength);
  let bin = "";
  for (let j = 0; j < u8.length; j++) bin += String.fromCharCode(u8[j]);
  const b64 = btoa(bin);
  try {
    session.sendRealtimeInput({ audio: { data: b64, mimeType: "audio/pcm;rate=16000" } });
  } catch (err) {
    if (st.done || st._micStopped) return;
    st._micStopped = true;
    try {
      teardownCapture(st);
    } catch (_) {
      // ignore
    }
    finalize(st, err && err.message ? err.message : String(err));
  }
}

/** Legacy path — only if AudioWorklet addModule / node fails. */
function startPcmMicScriptProcessor(stream, session, st, ac) {
  const src = ac.createMediaStreamSource(stream);
  st.mediaSourceNode = src;
  const bufferSize = 4096;
  const proc = ac.createScriptProcessor(bufferSize, 1, 1);
  st.scriptNode = proc;
  const mute = ac.createGain();
  mute.gain.value = 0;
  proc.onaudioprocess = function (ev) {
    if (st.done || st._micStopped) return;
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
    sendPcmChunk(session, st, i16);
  };
  src.connect(proc);
  proc.connect(mute);
  mute.connect(ac.destination);
}

async function startPcmMic(stream, session, st) {
  const AC = getAudioContextCtor();
  if (!AC) throw new Error("no_audio_context");
  const ac = new AC();
  st.captureCtx = ac;
  const canWorklet =
    ac.audioWorklet && typeof ac.audioWorklet.addModule === "function" && typeof AudioWorkletNode === "function";

  if (canWorklet) {
    try {
      const modUrl = new URL("gemini_live_capture.worklet.js", import.meta.url).href;
      await ac.audioWorklet.addModule(modUrl);
      const src = ac.createMediaStreamSource(stream);
      st.mediaSourceNode = src;
      const node = new AudioWorkletNode(ac, "veto-gemini-capture", { numberOfInputs: 1, numberOfOutputs: 1, channelCount: 1 });
      st.workletNode = node;
      node.port.onmessage = function (ev) {
        if (st.done || st._micStopped) return;
        const buf = ev.data;
        if (!buf || !(buf instanceof ArrayBuffer)) return;
        sendPcmChunk(session, st, new Int16Array(buf));
      };
      const mute = ac.createGain();
      mute.gain.value = 0;
      src.connect(node);
      node.connect(mute);
      mute.connect(ac.destination);
      await ac.resume().catch(() => {});
      return;
    } catch (e) {
      console.warn("[VETO Gemini Live] AudioWorklet unavailable, fallback:", e && e.message ? e.message : e);
      try {
        if (st.workletNode) {
          st.workletNode.port.onmessage = null;
          st.workletNode.disconnect();
        }
      } catch (_) {}
      st.workletNode = null;
      try {
        if (st.mediaSourceNode) st.mediaSourceNode.disconnect();
      } catch (_) {}
      st.mediaSourceNode = null;
    }
  }

  startPcmMicScriptProcessor(stream, session, st, ac);
  await ac.resume().catch(() => {});
}

async function startSession(lang, jwt, apiBase, voiceName, playbackLinearGain) {
  if (!apiBase) throw new Error("apiBase missing");
  if (!jwt) throw new Error("JWT missing");
  const url = String(apiBase).replace(/\/$/, "") + "/ai/live-token";
  const tokenBody = { lang: lang || "he" };
  if (typeof voiceName === "string" && voiceName.length) {
    tokenBody.voiceName = voiceName;
  }
  const ctrl = new AbortController();
  const to = setTimeout(function () {
    try {
      ctrl.abort();
    } catch (_) {
      // ignore
    }
  }, 25000);
  let res;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: headersFor(jwt),
      body: JSON.stringify(tokenBody),
      signal: ctrl.signal,
    });
  } catch (e) {
    clearTimeout(to);
    if (e && e.name === "AbortError") throw new Error("live_token_timeout");
    throw e;
  }
  clearTimeout(to);
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

  const g =
    typeof playbackLinearGain === "number" && !isNaN(playbackLinearGain)
      ? Math.max(0, Math.min(1, playbackLinearGain))
      : 0.85;
  const st = {
    session: null,
    stream: null,
    captureCtx: null,
    mediaSourceNode: null,
    workletNode: null,
    scriptNode: null,
    playbackCtx: null,
    _nextPlay: null,
    _sources: [],
    _masterGain: null,
    _gainVal: g,
    accUser: "",
    accModel: "",
    usedNativeAudio: false,
    done: false,
    _timer: null,
    /** Mic loop stopped after send failure (avoids spamming a closed Live WebSocket). */
    _micStopped: false,
    /** True when [userStop] ran — WebSocket `close` is then a normal teardown, not a drop. */
    _userRequestedStop: false,
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
        if (st.done) return;
        st._micStopped = true;
        try {
          teardownCapture(st);
        } catch (_) {
          // ignore
        }
        finalize(st, e && e.error ? e.error : "live error");
      },
    },
  });
  st.session = session;
  guardLiveConnSend(st, session);
  await startPcmMic(media, session, st);
}

function userStop() {
  const st = window[NS + "st"];
  if (!st || st.done) return;
  st._userRequestedStop = true;
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

// Do not read AudioContext.prototype.audioWorklet — some browsers invoke a getter that
// requires a real instance as |this|, which throws TypeError: Illegal invocation.
const supported = (function () {
  try {
    if (typeof navigator === "undefined" || !navigator.mediaDevices) return false;
    if (typeof navigator.mediaDevices.getUserMedia !== "function") return false;
    const AC = typeof AudioContext !== "undefined" ? AudioContext : typeof window !== "undefined" ? window.webkitAudioContext : null;
    if (!AC) return false;
    const hasWorklet = typeof AudioWorkletNode !== "undefined";
    let hasScriptProcessor = false;
    try {
      hasScriptProcessor = typeof AC.prototype.createScriptProcessor === "function";
    } catch (_) {
      hasScriptProcessor = false;
    }
    if (!hasWorklet && !hasScriptProcessor) return false;
    if (typeof isSecureContext !== "undefined" && !isSecureContext) return false;
    return true;
  } catch (_) {
    return false;
  }
})();

if (!window["vetoGeminiLive"] || typeof window["vetoGeminiLive"] !== "object") {
  window["vetoGeminiLive"] = {};
}
Object.assign(window["vetoGeminiLive"], {
  isSupported: function () {
    return supported;
  },
  start: function (lang, jwt, apiBase, voiceName, playbackLinearGain) {
    (async function () {
      if (!supported) {
        emit("LIVE:" + JSON.stringify({ err: "not_supported" }));
        return;
      }
      if (window[NS + "st"] && !window[NS + "st"].done) {
        return;
      }
      try {
        await startSession(lang, jwt, apiBase, voiceName, playbackLinearGain);
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

window["__vetoGeminiLiveModuleApplied"] = true;
try {
  const pending = window["__vetoGeminiLivePending"];
  if (pending && pending.jwt) {
    window["__vetoGeminiLivePending"] = null;
    window["vetoGeminiLive"].start(pending.lang, pending.jwt, pending.apiBase);
  }
} catch (_) {
  // ignore
}
