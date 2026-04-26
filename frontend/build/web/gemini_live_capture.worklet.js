/**
 * AudioWorklet capture for Gemini Live — 16 kHz mono s16le chunks (no ScriptProcessorNode).
 * Loaded from same directory as gemini_live.mjs.
 */
class VetoGeminiCaptureProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this._totalIn = 0;
    this._outRate = 16000;
  }

  process(inputs) {
    const input = inputs[0];
    if (!input || input.length === 0) return true;
    const inCh = input[0];
    if (!inCh || inCh.length === 0) return true;

    const inRate = sampleRate;
    const inLen = inCh.length;
    const inStart = this._totalIn;
    const inEnd = inStart + inLen;

    let k = Math.ceil((inStart * this._outRate) / inRate - 1e-10);
    const kLimit = Math.floor((inEnd * this._outRate) / inRate - 1e-10);
    const out = [];

    while (k < kLimit) {
      const inIdx = (k * inRate) / this._outRate;
      const li = inIdx - inStart;
      const i0 = Math.floor(li);
      const i1 = Math.min(i0 + 1, inLen - 1);
      const f = li - i0;
      const s0 = inCh[i0];
      const s1 = inCh[i1];
      let s = s0 * (1 - f) + s1 * f;
      s = Math.max(-1, Math.min(1, s));
      out.push(s < 0 ? s * 32768 : s * 32767);
      k++;
    }

    this._totalIn = inEnd;

    if (out.length > 0) {
      const i16 = Int16Array.from(out);
      this.port.postMessage(i16.buffer, [i16.buffer]);
    }
    return true;
  }
}

registerProcessor("veto-gemini-capture", VetoGeminiCaptureProcessor);
