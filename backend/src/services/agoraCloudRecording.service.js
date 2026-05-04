// ============================================================
//  Agora Cloud Recording (REST) — composite mix → S3 → Cloudinary
//  Full channel audio/video in browsers without client-side mix.
//
//  Env (all required when feature is used):
//    AGORA_APP_ID
//    AGORA_APP_CERTIFICATE (for recorder RTC token)
//    AGORA_RESTFUL_CUSTOMER_ID / AGORA_RESTFUL_CUSTOMER_SECRET
//    AGORA_RESTFUL_DOMAIN (optional, default https://api.sd-rtn.com)
//    AGORA_CR_S3_BUCKET, AGORA_CR_S3_ACCESS_KEY, AGORA_CR_S3_SECRET_KEY
//    AGORA_CR_S3_REGION_NUM — Agora numeric region for vendor 1 (S3), see Agora "region-vendor"
//    AGORA_CR_AWS_REGION — AWS SDK region string, e.g. us-east-1
// ============================================================

const axios = require('axios');
const { S3Client, GetObjectCommand, ListObjectsV2Command } = require('@aws-sdk/client-s3');
const { buildRtcTokenForUid, mongoIdToAgoraUid } = require('./agoraToken.service');

const APP_ID = process.env.AGORA_APP_ID || '';
const CUSTOMER_ID = process.env.AGORA_RESTFUL_CUSTOMER_ID || '';
const CUSTOMER_SECRET = process.env.AGORA_RESTFUL_CUSTOMER_SECRET || '';
const DOMAIN = (process.env.AGORA_RESTFUL_DOMAIN || 'https://api.sd-rtn.com').replace(/\/$/, '');

const S3_BUCKET = process.env.AGORA_CR_S3_BUCKET || '';
const S3_ACCESS = process.env.AGORA_CR_S3_ACCESS_KEY || '';
const S3_SECRET = process.env.AGORA_CR_S3_SECRET_KEY || '';
const S3_REGION_NUM = Number(process.env.AGORA_CR_S3_REGION_NUM);
const AWS_REGION = process.env.AGORA_CR_AWS_REGION || process.env.AWS_REGION || 'us-east-1';

function isCloudRecordingConfigured() {
  return !!(
    APP_ID &&
    process.env.AGORA_APP_CERTIFICATE &&
    CUSTOMER_ID &&
    CUSTOMER_SECRET &&
    S3_BUCKET &&
    S3_ACCESS &&
    S3_SECRET &&
    Number.isFinite(S3_REGION_NUM)
  );
}

function recorderUidString(eventIdHex) {
  const n = mongoIdToAgoraUid(`${String(eventIdHex)}:agora_cloud_recording`);
  return String(n);
}

function authHeaders() {
  const b64 = Buffer.from(`${CUSTOMER_ID}:${CUSTOMER_SECRET}`, 'utf8').toString('base64');
  return {
    Authorization: `Basic ${b64}`,
    'Content-Type': 'application/json',
  };
}

async function agoraPost(path, body) {
  const url = `${DOMAIN}${path}`;
  const res = await axios.post(url, body, {
    headers: authHeaders(),
    timeout: 60000,
    validateStatus: () => true,
  });
  return res;
}

function storageConfigForEvent(eventIdHex) {
  return {
    vendor: 1,
    region: S3_REGION_NUM,
    bucket: S3_BUCKET,
    accessKey: S3_ACCESS,
    secretKey: S3_SECRET,
    fileNamePrefix: ['veto_cr', String(eventIdHex).replace(/[^a-zA-Z0-9_-]/g, '')],
  };
}

function buildStartClientRequest({ wantVideo, token, eventIdHex }) {
  const recordingConfig = wantVideo
    ? {
      channelType: 0,
      streamTypes: 2,
      streamMode: 'default',
      subscribeAudioUids: ['#allstream#'],
      subscribeVideoUids: ['#allstream#'],
      transcodingConfig: {
        width: 640,
        height: 360,
        fps: 15,
        bitrate: 800,
        mixedVideoLayout: 0,
        backgroundColor: '#000000',
      },
    }
    : {
      channelType: 0,
      streamTypes: 0,
      streamMode: 'default',
      subscribeAudioUids: ['#allstream#'],
    };

  return {
    token,
    recordingConfig,
    recordingFileConfig: {
      avFileType: ['hls', 'mp4'],
    },
    storageConfig: storageConfigForEvent(eventIdHex),
  };
}

/**
 * @returns {{ resourceId: string, sid: string, uidStr: string }}
 */
async function acquireAndStart({ channelName, eventIdHex, wantVideo }) {
  const uidStr = recorderUidString(eventIdHex);
  const { token } = buildRtcTokenForUid({
    channelName,
    uid: Number(uidStr),
    role: 'publisher',
    ttlSec: 6 * 60 * 60,
  });
  if (!token) {
    throw new Error('Agora token unavailable (configure AGORA_APP_CERTIFICATE)');
  }

  const acquirePath = `/v1/apps/${APP_ID}/cloud_recording/acquire`;
  const acquireBody = {
    cname: channelName,
    uid: uidStr,
    clientRequest: {
      scene: 0,
      resourceExpiredHour: 24,
    },
  };
  const ar = await agoraPost(acquirePath, acquireBody);
  if (ar.status !== 200 || !ar.data?.resourceId) {
    const msg = ar.data?.message || ar.data?.reason || JSON.stringify(ar.data || ar.status);
    throw new Error(`Agora acquire failed (${ar.status}): ${msg}`);
  }
  const { resourceId } = ar.data;

  const startPath =
    `/v1/apps/${APP_ID}/cloud_recording/resourceid/${encodeURIComponent(resourceId)}/mode/mix/start`;
  const startBody = {
    cname: channelName,
    uid: uidStr,
    clientRequest: buildStartClientRequest({
      wantVideo: !!wantVideo,
      token,
      eventIdHex,
    }),
  };
  const sr = await agoraPost(startPath, startBody);
  if (sr.status !== 200 || !sr.data?.sid) {
    const msg = sr.data?.message || sr.data?.reason || JSON.stringify(sr.data || sr.status);
    throw new Error(`Agora start failed (${sr.status}): ${msg}`);
  }
  return { resourceId, sid: sr.data.sid, uidStr };
}

async function stopMix({ resourceId, sid, cname, uidStr }) {
  const path =
    `/v1/apps/${APP_ID}/cloud_recording/resourceid/${encodeURIComponent(resourceId)}/sid/${encodeURIComponent(sid)}/mode/mix/stop`;
  const body = {
    cname,
    uid: uidStr,
    clientRequest: {
      async_stop: true,
    },
  };
  return agoraPost(path, body);
}

async function queryMix({ resourceId, sid, cname, uidStr }) {
  const path =
    `/v1/apps/${APP_ID}/cloud_recording/resourceid/${encodeURIComponent(resourceId)}/sid/${encodeURIComponent(sid)}/mode/mix/query`;
  return agoraPost(path, {
    cname,
    uid: uidStr,
    clientRequest: {},
  });
}

function collectMp4KeysFromQueryPayload(data) {
  const keys = [];
  const walk = (node) => {
    if (!node || typeof node !== 'object') return;
    if (Array.isArray(node)) {
      node.forEach(walk);
      return;
    }
    const fl = node.fileList || node.filelist;
    if (Array.isArray(fl)) {
      for (const item of fl) {
        const name = item.fileName || item.filename;
        if (name && String(name).toLowerCase().endsWith('.mp4')) {
          keys.push(String(name));
        }
      }
    }
    for (const v of Object.values(node)) {
      if (v && typeof v === 'object') walk(v);
    }
  };
  walk(data);
  return [...new Set(keys)];
}

async function streamToBuffer(stream) {
  const chunks = [];
  for await (const chunk of stream) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

async function downloadMp4FromS3(key) {
  const client = new S3Client({
    region: AWS_REGION,
    credentials: {
      accessKeyId: S3_ACCESS,
      secretAccessKey: S3_SECRET,
    },
  });
  const out = await client.send(
    new GetObjectCommand({
      Bucket: S3_BUCKET,
      Key: key,
    }),
  );
  return streamToBuffer(out.Body);
}

async function findLatestMp4UnderPrefix(prefix) {
  const client = new S3Client({
    region: AWS_REGION,
    credentials: {
      accessKeyId: S3_ACCESS,
      secretAccessKey: S3_SECRET,
    },
  });
  let token;
  let bestKey;
  let bestTime = 0;
  do {
    const res = await client.send(
      new ListObjectsV2Command({
        Bucket: S3_BUCKET,
        Prefix: prefix,
        ContinuationToken: token,
      }),
    );
    for (const o of res.Contents || []) {
      if (!o.Key || !o.Key.toLowerCase().endsWith('.mp4')) continue;
      const t = o.LastModified ? o.LastModified.getTime() : 0;
      if (t >= bestTime) {
        bestTime = t;
        bestKey = o.Key;
      }
    }
    token = res.IsTruncated ? res.NextContinuationToken : undefined;
  } while (token);
  return bestKey;
}

/**
 * Poll Agora query + fallback S3 list until an MP4 object is available.
 */
async function resolveMp4S3Key({
  resourceId,
  sid,
  cname,
  uidStr,
  s3Prefix,
  maxWaitMs,
}) {
  const deadline = Date.now() + maxWaitMs;
  let lastKeys = [];
  while (Date.now() < deadline) {
    const qr = await queryMix({ resourceId, sid, cname, uidStr });
    if (qr.status === 404) {
      break;
    }
    if (qr.status === 200 && qr.data) {
      lastKeys = collectMp4KeysFromQueryPayload(qr.data);
      if (lastKeys.length > 0) {
        return lastKeys[lastKeys.length - 1];
      }
    }
    await new Promise((r) => setTimeout(r, 2000));
  }
  const fallback = await findLatestMp4UnderPrefix(s3Prefix);
  if (fallback) return fallback;
  if (lastKeys.length > 0) return lastKeys[lastKeys.length - 1];
  throw new Error('Cloud recording: no MP4 file found after stop (check S3 prefix / Agora console)');
}

module.exports = {
  isCloudRecordingConfigured,
  recorderUidString,
  acquireAndStart,
  stopMix,
  queryMix,
  resolveMp4S3Key,
  downloadMp4FromS3,
  storagePrefixForEvent: (eventIdHex) => `veto_cr/${String(eventIdHex)}/`,
};
