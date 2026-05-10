// ============================================================
//  Agora Real-Time Transcription (RTT) — REST API
//  VETO Legal Emergency App, Phase 3 call rewrite.
//
//  Agora RTT is a server-side ASR/translation worker that joins
//  the channel as a bot, listens to every publisher, and emits
//  text segments. We only need to:
//    1. acquire a builderToken
//    2. start a task (returns a taskId)
//    3. (optionally) query the task status
//    4. stop the task at end-of-call
//
//  Segments themselves are delivered straight into the channel
//  as Agora data-stream messages OR pushed to a configured
//  callback URL — the web client subscribes to the channel
//  data-stream so the server doesn't have to relay them. We
//  persist `agora_rtt_task_id` on EmergencyEvent so we can
//  always stop the right task.
//
//  Env (all required when feature is used):
//    AGORA_APP_ID                   (same as RTC)
//    AGORA_APP_CERTIFICATE          (same as RTC)
//    AGORA_RTT_CUSTOMER_ID          (defaults to AGORA_RESTFUL_CUSTOMER_ID)
//    AGORA_RTT_CUSTOMER_SECRET      (defaults to AGORA_RESTFUL_CUSTOMER_SECRET)
//    AGORA_RTT_REGION               default `fra` (Frankfurt) — use the region nearest your channel
//    AGORA_RTT_TARGET_LANG          default `he-IL,en-US` (multi-lang space sep with comma)
//    AGORA_RTT_TRANSLATE_TO         optional: comma-separated, e.g. `en-US`
// ============================================================

const axios = require('axios');
const { buildRtcTokenForUid, mongoIdToAgoraUid } = require('./agoraToken.service');

const APP_ID = process.env.AGORA_APP_ID || '';
const CUSTOMER_ID =
  process.env.AGORA_RTT_CUSTOMER_ID || process.env.AGORA_RESTFUL_CUSTOMER_ID || '';
const CUSTOMER_SECRET =
  process.env.AGORA_RTT_CUSTOMER_SECRET ||
  process.env.AGORA_RESTFUL_CUSTOMER_SECRET ||
  '';
const REGION = (process.env.AGORA_RTT_REGION || 'fra').replace(/[^a-z0-9]/gi, '');
const TARGET_LANG = (process.env.AGORA_RTT_TARGET_LANG || 'he-IL,en-US')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);
const TRANSLATE_TO = (process.env.AGORA_RTT_TRANSLATE_TO || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

function isRttConfigured() {
  return !!(APP_ID && process.env.AGORA_APP_CERTIFICATE && CUSTOMER_ID && CUSTOMER_SECRET);
}

function rttDomain() {
  // Agora RTT REST endpoints are scoped per region, e.g.
  // https://api.agora.io/<region>/v1/projects/<APP_ID>/...
  return `https://api.agora.io/${REGION}/v1/projects/${APP_ID}`;
}

function authHeaders() {
  const b64 = Buffer.from(`${CUSTOMER_ID}:${CUSTOMER_SECRET}`, 'utf8').toString('base64');
  return {
    Authorization: `Basic ${b64}`,
    'Content-Type': 'application/json',
  };
}

async function agoraJson(method, path, body) {
  const url = `${rttDomain()}${path}`;
  const res = await axios.request({
    method,
    url,
    data: body,
    headers: authHeaders(),
    timeout: 30_000,
    validateStatus: () => true,
  });
  return res;
}

/** Acquire a one-shot builder token; required as the first call. */
async function acquireBuilderToken({ instanceId }) {
  const res = await agoraJson('POST', '/rtsc/speech-to-text/builderTokens', {
    instanceId: String(instanceId).slice(0, 64),
  });
  if (res.status !== 200 || !res.data?.tokenName) {
    const msg = res.data?.message || res.data?.reason || JSON.stringify(res.data || res.status);
    throw new Error(`Agora RTT acquire failed (${res.status}): ${msg}`);
  }
  return res.data.tokenName;
}

/** Generate the RTC token the bot will use to join the channel. */
function rttBotRtcToken({ channelName, eventIdHex }) {
  const uid = mongoIdToAgoraUid(`${String(eventIdHex)}:agora_rtt_bot`);
  const { token } = buildRtcTokenForUid({
    channelName,
    uid,
    role: 'subscriber',
    ttlSec: 6 * 60 * 60,
  });
  if (!token) {
    throw new Error('Agora token unavailable (configure AGORA_APP_CERTIFICATE)');
  }
  return { token, uid };
}

/**
 * Start an RTT task. The bot joins `channelName` and emits real-time
 * transcription segments as data-stream messages. The web client should
 * already be subscribed to the channel data stream and will pick these up
 * — no server callback is required for the basic flow.
 *
 * @returns {{ taskId: string, builderToken: string }}
 */
async function startTranscription({ channelName, eventIdHex }) {
  if (!isRttConfigured()) {
    throw new Error('Agora RTT is not configured.');
  }
  const builderToken = await acquireBuilderToken({ instanceId: `veto-${eventIdHex}` });
  const { token: botToken, uid: botUid } = rttBotRtcToken({ channelName, eventIdHex });

  const body = {
    audio: {
      subscribeSource: 'AGORARTC',
      agoraRtcConfig: {
        channelName,
        uid: String(botUid),
        token: botToken,
        channelType: 'LIVE_TYPE',
        // Subscribe to every publishing client; languages are inferred per-speaker.
        subscribeConfig: { subscribeMode: 'CHANNEL_MODE' },
        // Bot leaves automatically if channel goes quiet for >30 s.
        maxIdleTime: 30,
      },
    },
    config: {
      features: ['RECOGNIZE'],
      recognizeConfig: {
        language: TARGET_LANG.join(','),
        model: 'Model',
        output: { transcription: { enable: true } },
        ...(TRANSLATE_TO.length > 0
          ? {
              translation: {
                enable: true,
                targetLanguages: TRANSLATE_TO,
              },
            }
          : {}),
      },
    },
  };

  const res = await agoraJson(
    'POST',
    `/rtsc/speech-to-text/tasks?builderToken=${encodeURIComponent(builderToken)}`,
    body,
  );
  if (res.status !== 200 && res.status !== 201) {
    const msg = res.data?.message || res.data?.reason || JSON.stringify(res.data || res.status);
    throw new Error(`Agora RTT start failed (${res.status}): ${msg}`);
  }
  const taskId = res.data?.taskId || res.data?.task_id;
  if (!taskId) {
    throw new Error('Agora RTT start succeeded but returned no taskId.');
  }
  return { taskId: String(taskId), builderToken };
}

async function stopTranscription({ taskId, builderToken }) {
  if (!taskId) return { stopped: false, reason: 'no_task_id' };
  if (!builderToken) return { stopped: false, reason: 'no_builder_token' };
  const res = await agoraJson(
    'DELETE',
    `/rtsc/speech-to-text/tasks/${encodeURIComponent(taskId)}?builderToken=${encodeURIComponent(builderToken)}`,
  );
  if (res.status === 200 || res.status === 204) {
    return { stopped: true };
  }
  // 404 = task already gone; treat as success so callers don't error on retries.
  if (res.status === 404) {
    return { stopped: true, alreadyGone: true };
  }
  const msg = res.data?.message || res.data?.reason || JSON.stringify(res.data || res.status);
  throw new Error(`Agora RTT stop failed (${res.status}): ${msg}`);
}

async function queryTranscription({ taskId, builderToken }) {
  if (!taskId || !builderToken) return null;
  const res = await agoraJson(
    'GET',
    `/rtsc/speech-to-text/tasks/${encodeURIComponent(taskId)}?builderToken=${encodeURIComponent(builderToken)}`,
  );
  if (res.status !== 200) return null;
  return res.data;
}

module.exports = {
  isRttConfigured,
  startTranscription,
  stopTranscription,
  queryTranscription,
};
