// ============================================================
//  call.controller.js — Call Recording & Transcription
//  VETO Legal Emergency App
//
//  Endpoints:
//    POST /api/calls/:eventId/recording   → Upload recording to Cloudinary
//    POST /api/calls/:eventId/transcribe  → Transcribe with Gemini
//    GET  /api/calls/:eventId             → Get call details
// ============================================================

const axios = require('axios');
const EmergencyEvent = require('../models/EmergencyEvent');
const User = require('../models/User');
const { cloudinary } = require('../config/cloudinary');
const { getGeminiModelId } = require('../config/gemini.config');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { buildRtcTokenForUid } = require('../services/agoraToken.service');
const agoraCr = require('../services/agoraCloudRecording.service');
const { CONSULTATION_ILS, OVERTIME_ILS_PER_MIN, FREE_CALL_MINUTES } = require('../config/pricing');

const { canAccessEvent } = require('../services/call/access.service');
const { sanitizeTranscript } = require('../services/call/transcript.service');
const {
  computeChargeFromSeconds,
  isPaymentExemptUser,
} = require('../services/call/billing.service');
const { iceServersFromEnv } = require('../services/call/iceServers.service');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

/** One finalize pipeline per event (avoid duplicate work if both peers call stop). */
const cloudRecordingFinalizeLocks = new Set();

// ── WebRTC ICE (authenticated; no event id) ───────────────────
exports.getIceConfig = (_req, res) => {
  try {
    res.json({ iceServers: iceServersFromEnv() });
  } catch {
    res.status(500).json({ error: 'ICE configuration unavailable', iceServers: [] });
  }
};

/**
 * POST /api/calls/:eventId/token
 *
 * Issues a fresh Agora RTC token for the authenticated participant. Used by
 * the Flutter AgoraService when `onTokenPrivilegeWillExpire` fires and during
 * reconnect-after-drop, so an expired socket payload never stalls a call.
 *
 * Access: only the assigned lawyer OR the event owner (citizen).
 */
exports.issueAgoraToken = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const { userId, role } = req.user;

    const event = await EmergencyEvent.findById(eventId)
      .select('user_id assigned_lawyer_id room_id status')
      .lean();
    if (!event) return res.status(404).json({ error: 'Event not found' });

    const uid = String(userId);
    const isUser   = (role === 'user' || role === 'admin') &&
      event.user_id?.toString() === uid;
    const isLawyer = role === 'lawyer' &&
      event.assigned_lawyer_id?.toString() === uid;
    if (!isUser && !isLawyer) {
      return res.status(403).json({ error: 'Not authorized for this call' });
    }

    const channelName = event.room_id || String(event._id || eventId);
    const { token, agoraUid, ttlSec, expiresAt } = buildRtcTokenForUid({
      channelName,
      userMongoId: uid,
      role: 'publisher',
    });

    res.json({
      success:    true,
      channelId:  channelName,
      agoraToken: token,
      agoraUid,
      ttlSec,
      expiresAt,
    });
  } catch (err) {
    next(err);
  }
};

// ── Upload recording ──────────────────────────────────────────
exports.uploadRecording = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const { userId }  = req.user;

    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });

    // Check access: only participants of this event
    const isUser   = event.user_id?.toString()            === userId;
    const isLawyer = event.assigned_lawyer_id?.toString() === userId;
    if (!isUser && !isLawyer && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized' });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'No recording file provided' });
    }

    // Upload to Cloudinary as video/audio resource
    const uploadResult = await new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          resource_type: 'video', // covers both audio and video
          folder:        `veto/recordings/${eventId}`,
          public_id:     `call_${Date.now()}`,
          // Do not force format — client may send WebM (browser) or MP4 (Agora MediaRecorder).
        },
        (err, result) => {
          if (err) reject(err);
          else resolve(result);
        }
      );
      uploadStream.end(req.file.buffer);
    });

    // Save recording URL to event
    await EmergencyEvent.findByIdAndUpdate(eventId, {
      recording_url:               uploadResult.secure_url,
      recording_public_id:         uploadResult.public_id || null,
      recording_duration_seconds:  uploadResult.duration != null ? Number(uploadResult.duration) : null,
      recording_size_bytes:        uploadResult.bytes != null ? Number(uploadResult.bytes) : null,
      recording_saved_decision:    'pending',
      recording_transcription_status: 'idle',
    });

    res.json({
      success:      true,
      recordingUrl: uploadResult.secure_url,
      duration:     uploadResult.duration,
    });

  } catch (err) {
    next(err);
  }
};

// ── Transcribe recording with Gemini ─────────────────────────
exports.transcribeRecording = async (req, res, next) => {
  try {
    if (!process.env.GEMINI_API_KEY) {
      return res.status(503).json({ error: 'Transcription not configured' });
    }

    const { eventId } = req.params;
    const { userId }  = req.user;
    const { audioBase64, language, mimeType } = req.body;

    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });

    // Access check
    const isUser   = event.user_id?.toString()            === userId;
    const isLawyer = event.assigned_lawyer_id?.toString() === userId;
    if (!isUser && !isLawyer && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized' });
    }

    // Use recording_url from event if no inline audio provided
    const hasInlineAudio = audioBase64 && audioBase64.length > 0;

    const langMap = {
      he: 'עברית',
      ar: 'Arabic',
      ru: 'Russian',
      en: 'English',
    };
    const lang = langMap[language || event.language] || 'the call language';

    const model = genAI.getGenerativeModel({ model: getGeminiModelId() });

    let transcript;

    if (hasInlineAudio) {
      // Inline audio transcription (base64)
      const prompt = `
You are a verbatim speech-to-text transcription engine.
Transcribe the audio recording in ${lang} as plain text only.

Rules:
- Output ONLY the transcript text. No JSON, no markdown, no headings.
- Do NOT add emojis and do NOT describe emojis (no "smiley", no "emoji", no "(laughs)", no "[applause]").
- Do NOT add speaker labels ("Client:", "Lawyer:") and do NOT add timestamps.
- If something is unclear, leave it out rather than describing non-speech sounds.
      `.trim();

      const result = await model.generateContent([
        { text: prompt },
        {
          inlineData: {
            mimeType: mimeType || 'audio/webm',
            data:     audioBase64,
          },
        },
      ]);

      transcript = sanitizeTranscript(result.response.text());
    } else if (event.recording_url) {
      // Fetch stored recording (e.g. Cloudinary) and transcribe like inline audio.
      const audioResp = await axios.get(event.recording_url, {
        responseType: 'arraybuffer',
        maxContentLength: 40 * 1024 * 1024,
        timeout: 120000,
      });
      const buf = Buffer.from(audioResp.data);
      const audioBase64FromUrl = buf.toString('base64');
      const ct = (audioResp.headers['content-type'] || '').split(';')[0].trim();
      const urlLower = String(event.recording_url).toLowerCase();
      const mimeFromUrl = urlLower.endsWith('.mp3')
        ? 'audio/mpeg'
        : urlLower.endsWith('.m4a')
          ? 'audio/mp4'
          : urlLower.endsWith('.wav')
            ? 'audio/wav'
            : urlLower.endsWith('.mp4')
              ? 'video/mp4'
              : 'audio/webm';
      const mimeType =
        ct && (ct.startsWith('audio/') || ct.startsWith('video/')) ? ct : mimeFromUrl;

      const prompt = `
You are a verbatim speech-to-text transcription engine.
Transcribe the audio recording in ${lang} as plain text only.

Rules:
- Output ONLY the transcript text. No JSON, no markdown, no headings.
- Do NOT add emojis and do NOT describe emojis (no "smiley", no "emoji", no "(laughs)", no "[applause]").
- Do NOT add speaker labels ("Client:", "Lawyer:") and do NOT add timestamps.
- If something is unclear, leave it out rather than describing non-speech sounds.
      `.trim();

      const result = await model.generateContent([
        { text: prompt },
        {
          inlineData: {
            mimeType,
            data: audioBase64FromUrl,
          },
        },
      ]);

      transcript = sanitizeTranscript(result.response.text());
    } else {
      return res.status(400).json({ error: 'No audio data or recording URL available' });
    }

    // Save transcript to event
    await EmergencyEvent.findByIdAndUpdate(eventId, {
      call_transcript: transcript,
      transcript_language: language || event.language,
      recording_transcription_status: 'ready',
    });

    res.json({
      success:    true,
      transcript,
      language:   language || event.language,
    });

  } catch (err) {
    // Gemini rate limit
    if (err.status === 429) {
      return res.status(429).json({
        error: 'Transcription service busy. Please try again in a moment.',
      });
    }
    next(err);
  }
};

async function transcribeEventRecording({ eventId, language }) {
  if (!process.env.GEMINI_API_KEY) {
    await EmergencyEvent.findByIdAndUpdate(eventId, { recording_transcription_status: 'failed' });
    return;
  }
  const event = await EmergencyEvent.findById(eventId);
  if (!event?.recording_url) {
    await EmergencyEvent.findByIdAndUpdate(eventId, { recording_transcription_status: 'failed' });
    return;
  }
  await EmergencyEvent.findByIdAndUpdate(eventId, { recording_transcription_status: 'pending' });
  try {
    const audioResp = await axios.get(event.recording_url, {
      responseType: 'arraybuffer',
      maxContentLength: 40 * 1024 * 1024,
      timeout: 120000,
    });
    const buf = Buffer.from(audioResp.data);
    const ct = (audioResp.headers['content-type'] || '').split(';')[0].trim();
    const mimeType = ct && (ct.startsWith('audio/') || ct.startsWith('video/')) ? ct : 'video/mp4';
    const langMap = { he: 'עברית', ar: 'Arabic', ru: 'Russian', en: 'English' };
    const lang = langMap[language || event.language] || 'the call language';
    const model = genAI.getGenerativeModel({ model: getGeminiModelId() });
    const prompt = `
You are a verbatim speech-to-text transcription engine.
Transcribe the call recording in ${lang} as plain text only.

Rules:
- Output ONLY the transcript text. No JSON, no markdown, no headings.
- Do NOT add emojis, sound descriptions, speaker labels, or timestamps.
- If something is unclear, leave it out rather than inventing speech.
    `.trim();
    const result = await model.generateContent([
      { text: prompt },
      { inlineData: { mimeType, data: buf.toString('base64') } },
    ]);
    await EmergencyEvent.findByIdAndUpdate(eventId, {
      call_transcript: sanitizeTranscript(result.response.text()),
      transcript_language: language || event.language,
      recording_transcription_status: 'ready',
    });
  } catch (err) {
    console.error('[call] transcription finalize failed', eventId, err);
    await EmergencyEvent.findByIdAndUpdate(eventId, { recording_transcription_status: 'failed' });
  }
}

// ── Get call details ──────────────────────────────────────────
exports.finishCallBilling = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const reportedSeconds = Math.max(0, Math.ceil(Number(req.body?.durationSeconds) || 0));
    const derivedSeconds = event.call_started_at
      ? Math.max(0, Math.ceil((Date.now() - new Date(event.call_started_at).getTime()) / 1000))
      : 0;
    const durationSeconds = Math.max(
      Number(event.call_duration_seconds) || 0,
      reportedSeconds,
      derivedSeconds,
    );
    const charge = computeChargeFromSeconds(durationSeconds);
    const paymentExempt = await isPaymentExemptUser(req.user);

    event.call_duration_seconds = charge.durationSeconds;
    event.completed_at = event.completed_at || new Date();
    if (['accepted', 'in_progress', 'dispatching'].includes(event.status)) {
      event.status = 'completed';
    }
    event.charge_minutes = charge.minutes;
    event.charge_overtime_minutes = paymentExempt ? 0 : charge.overtimeMinutes;
    event.charge_amount_ils = paymentExempt ? 0 : charge.overtimeIls;
    event.charge_calculated_at = new Date();
    if (paymentExempt) {
      event.charge_status = 'waived';
    } else if (charge.overtimeIls <= 0) {
      event.charge_status = 'none';
    } else if (event.charge_status !== 'paid' && event.charge_status !== 'waived') {
      event.charge_status = 'pending';
    }
    await event.save();

    res.json({
      success: true,
      charge: {
        minutes: charge.minutes,
        baseIls: paymentExempt ? 0 : charge.baseIls,
        overtimeMinutes: paymentExempt ? 0 : charge.overtimeMinutes,
        overtimeIls: paymentExempt ? 0 : charge.overtimeIls,
        totalIls: paymentExempt ? 0 : charge.totalIls,
        status: event.charge_status,
        paymentExempt,
      },
    });
  } catch (err) {
    next(err);
  }
};

exports.createActionPlan = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const event = await EmergencyEvent.findById(eventId)
      .select('user_id assigned_lawyer_id status call_type call_duration_seconds recording_url screen_recording_url call_transcript charge_status charge_amount_ils charge_overtime_minutes recording_saved_decision')
      .lean();
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const seconds = Number(event.call_duration_seconds) || 0;
    const minutes = seconds ? Math.max(1, Math.ceil(seconds / 60)) : null;
    const hasRecording = !!event.recording_url || !!event.screen_recording_url;
    const hasTranscript = !!event.call_transcript;
    const overtimeDue = event.charge_status === 'pending' && Number(event.charge_amount_ils || 0) > 0;
    const aiConfigured = !!process.env.GEMINI_API_KEY;

    const steps = [
      overtimeDue
        ? { key: 'pay_overtime', title: 'אישור תשלום דקות נוספות', action: 'payment' }
        : null,
      hasRecording || hasTranscript
        ? { key: 'save_evidence', title: 'שמירת ההקלטה והתמלול בכספת', action: 'vault' }
        : { key: 'add_notes', title: 'הוספת הערות ותיעוד ידני לכספת', action: 'vault' },
      { key: 'create_document', title: 'יצירת מסמך המשך מתאים', action: 'document_generator' },
      { key: 'follow_up', title: 'קביעת תזכורת או המשך טיפול', action: 'calendar' },
    ].filter(Boolean);

    res.json({
      plan: {
        eventId,
        minutes,
        callType: event.call_type,
        status: event.status,
        charge: {
          status: event.charge_status,
          amountIls: event.charge_amount_ils || 0,
          overtimeMinutes: event.charge_overtime_minutes || 0,
        },
        evidence: {
          hasRecording,
          hasTranscript,
          savedDecision: event.recording_saved_decision,
        },
        ai: {
          configured: aiConfigured,
          disclosure: aiConfigured
            ? 'AI can draft a non-binding summary. A lawyer should review it before use.'
            : 'AI is not configured. Showing a structured manual plan.',
        },
        steps,
        suggestedDocuments: ['סיכום ייעוץ', 'מכתב התראה', 'בקשה לשמירת ראיות'],
      },
    });
  } catch (err) {
    next(err);
  }
};

exports.getCallDetails = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const event = await EmergencyEvent.findById(eventId)
      .select(
        // Original fields…
        'user_id assigned_lawyer_id room_id status call_type call_started_at call_duration_seconds ' +
        'recording_url recording_public_id recording_duration_seconds recording_size_bytes ' +
        'call_transcript transcript_language recording_saved_decision recording_transcription_status ' +
        'screen_recording_url screen_recording_public_id ' +
        // Phase 3 v2 fields:
        'recording_consent agora_cloud_recording_resource_id agora_rtt_task_id ' +
        'shared_files ' +
        '+e2ee_secret',
      )
      .lean();

    if (!event) return res.status(404).json({ error: 'Event not found' });

    // Access check
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const { e2ee_secret: e2eeSecretRaw, ...callRest } = event;
    const call = {
      ...callRest,
      ...(e2eeSecretRaw != null && e2eeSecretRaw !== ''
        ? { e2eeSecret: e2eeSecretRaw }
        : {}),
    };

    res.json({
      success: true,
      call,
      cloudRecordingConfigured: agoraCr.isCloudRecordingConfigured(),
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/calls/my-sos-artifacts
 * Citizen/admin: emergency events that have recording and/or transcript (for vault sync).
 */
exports.listMySosArtifacts = async (req, res, next) => {
  try {
    const { userId, role } = req.user;
    if (role !== 'user' && role !== 'admin') {
      return res.status(403).json({ error: 'Citizen accounts only.' });
    }

    const items = await EmergencyEvent.find({
      user_id: userId,
      recording_saved_decision: 'saved',
      $or: [
        { recording_url: { $exists: true, $nin: [null, ''] } },
        { call_transcript: { $exists: true, $nin: [null, ''] } },
      ],
    })
      .select(
        '_id status recording_url call_transcript transcript_language triggered_at completed_at recording_saved_decision recording_transcription_status screen_recording_url',
      )
      .sort({ triggered_at: -1 })
      .limit(50)
      .lean();

    res.json({ success: true, items });
  } catch (err) {
    next(err);
  }
};

// ── Agora Cloud Recording (full mix in browser / all clients) ─
exports.getCloudRecordingStatus = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const event = await EmergencyEvent.findById(eventId)
      .select('user_id assigned_lawyer_id')
      .lean();
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    res.json({
      success: true,
      configured: agoraCr.isCloudRecordingConfigured(),
    });
  } catch (err) {
    next(err);
  }
};

exports.startCloudRecording = async (req, res, next) => {
  try {
    if (!agoraCr.isCloudRecordingConfigured()) {
      return res.status(503).json({
        success: false,
        configured: false,
        error: 'Cloud recording not configured on server',
      });
    }
    const { eventId } = req.params;
    const wantVideo = !!req.body?.wantVideo;

    const event = await EmergencyEvent.findById(eventId)
      .select('user_id assigned_lawyer_id room_id agora_cloud_recording_sid agora_cloud_recording_resource_id agora_cloud_recording_uid')
      .lean();
    if (!event) return res.status(404).json({ error: 'Event not found' });

    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    if (String(event.user_id) !== String(req.user.userId)) {
      return res.status(403).json({ error: 'Only the citizen can start cloud recording.' });
    }

    if (event.agora_cloud_recording_sid) {
      return res.json({
        success: true,
        active: true,
        sid: event.agora_cloud_recording_sid,
        resourceId: event.agora_cloud_recording_resource_id,
        recorderUid: event.agora_cloud_recording_uid,
      });
    }

    const channelName = event.room_id || String(event._id || eventId);
    const { resourceId, sid, uidStr } = await agoraCr.acquireAndStart({
      channelName,
      eventIdHex: String(eventId),
      wantVideo,
    });

    await EmergencyEvent.findByIdAndUpdate(eventId, {
      agora_cloud_recording_resource_id: resourceId,
      agora_cloud_recording_sid: sid,
      agora_cloud_recording_uid: Number(uidStr),
      recording_saved_decision: 'pending',
      recording_transcription_status: 'idle',
    });

    res.json({
      success: true,
      active: true,
      sid,
      resourceId,
      recorderUid: Number(uidStr),
    });
  } catch (err) {
    next(err);
  }
};

async function finalizeCloudRecordingToCloudinary({
  eventId,
  resourceId,
  sid,
  channelName,
  uidStr,
}) {
  const s3Prefix = agoraCr.storagePrefixForEvent(String(eventId));
  const mp4Key = await agoraCr.resolveMp4S3Key({
    resourceId,
    sid,
    cname: channelName,
    uidStr,
    s3Prefix,
    maxWaitMs: 120000,
  });
  const mp4Buffer = await agoraCr.downloadMp4FromS3(mp4Key);
  const uploadResult = await new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        resource_type: 'video',
        folder: `veto/recordings/${eventId}`,
        public_id: `call_cloud_${Date.now()}`,
      },
      (err, result) => {
        if (err) reject(err);
        else resolve(result);
      },
    );
    uploadStream.end(mp4Buffer);
  });
  await EmergencyEvent.findByIdAndUpdate(eventId, {
    recording_url:               uploadResult.secure_url,
    recording_public_id:         uploadResult.public_id || null,
    recording_duration_seconds:  uploadResult.duration != null ? Number(uploadResult.duration) : null,
    recording_size_bytes:        uploadResult.bytes != null ? Number(uploadResult.bytes) : null,
    recording_saved_decision:    'pending',
    recording_transcription_status: 'pending',
    agora_cloud_recording_resource_id: null,
    agora_cloud_recording_sid:         null,
    agora_cloud_recording_uid:         null,
  });
  setImmediate(() => {
    transcribeEventRecording({ eventId, language: null }).catch((err) => {
      console.error('[call] transcribe after cloud recording failed', eventId, err);
    });
  });
}

exports.stopCloudRecording = async (req, res, next) => {
  try {
    if (!agoraCr.isCloudRecordingConfigured()) {
      return res.status(503).json({
        success: false,
        configured: false,
        error: 'Cloud recording not configured on server',
      });
    }
    const { eventId } = req.params;

    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });

    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    if (String(event.user_id) !== String(req.user.userId)) {
      return res.status(403).json({ error: 'Only the citizen can stop cloud recording.' });
    }

    const rid = event.agora_cloud_recording_resource_id;
    const sid = event.agora_cloud_recording_sid;
    const rUid = event.agora_cloud_recording_uid;
    const channelName = event.room_id || String(event._id || eventId);
    const uidStr = rUid != null && rUid > 0 ? String(rUid) : agoraCr.recorderUidString(String(eventId));

    if (!rid || !sid) {
      return res.json({
        success: true,
        recordingUrl: event.recording_url || null,
        pending: false,
        alreadyStopped: true,
      });
    }

    const eid = String(eventId);
    let shouldFinalize = false;
    try {
      if (!cloudRecordingFinalizeLocks.has(eid)) {
        cloudRecordingFinalizeLocks.add(eid);
        shouldFinalize = true;
      }

      const st = await agoraCr.stopMix({
        resourceId: rid,
        sid,
        cname: channelName,
        uidStr,
      });
      if (st.status !== 200 && st.status !== 404) {
        if (shouldFinalize) cloudRecordingFinalizeLocks.delete(eid);
        const msg = st.data?.message || st.data?.reason || JSON.stringify(st.data || st.status);
        return next(new Error(`Agora stop failed (${st.status}): ${msg}`));
      }

      res.json({
        success: true,
        pending: true,
        recordingUrl: null,
      });

      if (!shouldFinalize) return;

      const ctx = {
        eventId: eid,
        resourceId: rid,
        sid,
        channelName,
        uidStr,
      };
      setImmediate(() => {
        finalizeCloudRecordingToCloudinary(ctx)
          .catch(async (err) => {
            console.error('[agora-cloud-recording] finalize failed', ctx.eventId, err);
            try {
              await EmergencyEvent.findByIdAndUpdate(ctx.eventId, {
                agora_cloud_recording_resource_id: null,
                agora_cloud_recording_sid:         null,
                agora_cloud_recording_uid:         null,
              });
            } catch (_) {
              /* ignore */
            }
          })
          .finally(() => {
            cloudRecordingFinalizeLocks.delete(eid);
          });
      });
    } catch (err) {
      if (shouldFinalize) cloudRecordingFinalizeLocks.delete(eid);
      next(err);
    }
  } catch (err) {
    next(err);
  }
};

exports.saveCallArtifacts = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    if (req.user.role !== 'user' && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Citizen accounts only' });
    }
    event.recording_saved_decision = 'saved';
    if (event.recording_url && event.recording_transcription_status === 'idle') {
      event.recording_transcription_status = 'pending';
    }
    await event.save();
    if (event.recording_url && event.recording_transcription_status !== 'ready') {
      setImmediate(() => {
        transcribeEventRecording({ eventId, language: event.language }).catch((err) => {
          console.error('[call] transcribe after save failed', eventId, err);
        });
      });
    }
    res.json({
      success: true,
      recordingUrl: event.recording_url || null,
      transcriptReady: event.recording_transcription_status === 'ready',
    });
  } catch (err) {
    next(err);
  }
};

exports.deleteCallArtifacts = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    if (req.user.role !== 'user' && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Citizen accounts only' });
    }

    const deletions = [];
    if (event.recording_public_id) {
      deletions.push(cloudinary.uploader.destroy(event.recording_public_id, { resource_type: 'video' }));
    }
    if (event.screen_recording_public_id) {
      deletions.push(cloudinary.uploader.destroy(event.screen_recording_public_id, { resource_type: 'video' }));
    }
    await Promise.allSettled(deletions);

    await EmergencyEvent.findByIdAndUpdate(eventId, {
      recording_url: null,
      recording_public_id: null,
      recording_duration_seconds: null,
      recording_size_bytes: null,
      call_transcript: null,
      transcript_language: null,
      recording_saved_decision: 'deleted',
      recording_transcription_status: 'idle',
      screen_recording_url: null,
      screen_recording_public_id: null,
    });

    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};

exports.uploadScreenRecording = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'No screen recording file provided' });
    }
    const uploadResult = await new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          resource_type: 'video',
          folder: `veto/recordings/${eventId}`,
          public_id: `call_screen_${Date.now()}`,
        },
        (err, result) => {
          if (err) reject(err);
          else resolve(result);
        },
      );
      uploadStream.end(req.file.buffer);
    });
    await EmergencyEvent.findByIdAndUpdate(eventId, {
      screen_recording_url: uploadResult.secure_url,
      screen_recording_public_id: uploadResult.public_id || null,
      recording_saved_decision: 'pending',
    });
    res.json({ success: true, screenRecordingUrl: uploadResult.secure_url });
  } catch (err) {
    next(err);
  }
};

// ============================================================
//  Phase 3 — Call v2 endpoints
// ============================================================

const agoraRtt = require('../services/agoraRtt.service');

/**
 * Cache the RTT builderToken per task so we can stop the task without
 * re-acquiring. RTT tokens are one-shot; without this we can't issue
 * a stop after a process restart, but the task auto-times-out anyway.
 */
const rttBuilderTokens = new Map();

/**
 * POST /api/calls/:eventId/consent
 * Body: { granted: boolean }
 * Only the citizen (emergency event owner) may consent to cloud recording.
 * The lawyer is informed in the UI that recording is citizen-controlled.
 */
exports.recordConsent = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const granted = req.body?.granted === true;
    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    if (String(event.user_id) !== String(req.user.userId)) {
      return res.status(403).json({ error: 'Only the citizen can consent to recording.' });
    }

    await EmergencyEvent.findByIdAndUpdate(eventId, {
      $set: {
        'recording_consent.citizen_at': granted ? new Date() : null,
        // Legacy field — no longer used for gating; clear to avoid confusion.
        'recording_consent.lawyer_at': null,
      },
    });

    const fresh = await EmergencyEvent.findById(eventId)
      .select('recording_consent')
      .lean();
    const citizen = !!fresh?.recording_consent?.citizen_at;
    res.json({
      success: true,
      consent: {
        citizen,
        lawyer: false,
        bothGranted: citizen,
      },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/calls/:eventId/transcript-realtime/start
 * Spawns the Agora RTT bot for this channel. Idempotent — if a task
 * already exists for the event, returns its taskId.
 */
exports.startRealtimeTranscription = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    if (event.agora_rtt_task_id) {
      return res.json({
        success: true,
        taskId: event.agora_rtt_task_id,
        alreadyRunning: true,
      });
    }

    if (!agoraRtt.isRttConfigured()) {
      return res.status(503).json({ error: 'Real-time transcription is not configured.' });
    }

    const channelName = event.room_id || String(event._id);
    const { taskId, builderToken } = await agoraRtt.startTranscription({
      channelName,
      eventIdHex: String(event._id),
    });
    rttBuilderTokens.set(taskId, builderToken);
    await EmergencyEvent.findByIdAndUpdate(eventId, { agora_rtt_task_id: taskId });

    res.json({ success: true, taskId, alreadyRunning: false });
  } catch (err) {
    next(err);
  }
};

/** POST /api/calls/:eventId/transcript-realtime/stop */
exports.stopRealtimeTranscription = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    const taskId = event.agora_rtt_task_id;
    if (!taskId) {
      return res.json({ success: true, stopped: false, reason: 'no_task' });
    }
    const builderToken = rttBuilderTokens.get(taskId) || null;
    try {
      await agoraRtt.stopTranscription({ taskId, builderToken });
    } catch (err) {
      console.warn('[call] rtt stop best-effort:', err.message);
    }
    rttBuilderTokens.delete(taskId);
    await EmergencyEvent.findByIdAndUpdate(eventId, { agora_rtt_task_id: null });
    res.json({ success: true, stopped: true });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/calls/:eventId/chat-history
 *  → { messages: [{ author_role, author_id, text, ts }, ...] }
 */
exports.getChatHistory = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const event = await EmergencyEvent.findById(eventId)
      .select('user_id assigned_lawyer_id call_chat_messages')
      .lean();
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    res.json({ success: true, messages: event.call_chat_messages || [] });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/calls/:eventId/chat-message
 * Body: { text: string }
 * Persists the message and pushes it to the other side via Socket.io
 * (replaces socket-only `call-chat-message`).
 */
exports.postChatMessage = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const text = typeof req.body?.text === 'string' ? req.body.text.trim() : '';
    if (!text) return res.status(400).json({ error: 'text is required' });
    if (text.length > 4000) return res.status(400).json({ error: 'text too long' });

    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const authorRole = req.user.role === 'lawyer' ? 'lawyer' : 'user';
    const message = {
      author_role: authorRole,
      author_id: req.user.userId,
      text,
      ts: new Date(),
    };
    await EmergencyEvent.findByIdAndUpdate(eventId, {
      $push: { call_chat_messages: message },
    });

    // Push to the other side via the call room.
    try {
      const io = req.app?.get('io');
      if (io) {
        io.to(`call:${eventId}`).emit('call-chat-message', {
          text,
          fromRole: authorRole,
          userId: req.user.userId,
          ts: message.ts.toISOString(),
        });
      }
    } catch (err) {
      console.warn('[call] chat-message push failed:', err.message);
    }

    res.json({ success: true, message });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/calls/:eventId/file-share (multipart `file`)
 * Uploads a file dropped during the call to Cloudinary as `auto`
 * resource_type so PDFs, images, video, and audio all work.
 */
exports.shareFileInCall = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (!canAccessEvent(event, req.user)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'No file provided' });
    }

    const uploadResult = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          resource_type: 'auto',
          folder: `veto/call_files/${eventId}`,
          public_id: `share_${Date.now()}_${(req.file.originalname || 'file').replace(/[^a-zA-Z0-9._-]/g, '')}`,
        },
        (err, result) => {
          if (err) reject(err);
          else resolve(result);
        },
      );
      stream.end(req.file.buffer);
    });

    const byRole = req.user.role === 'lawyer' ? 'lawyer' : 'user';
    const entry = {
      cloud_url: uploadResult.secure_url,
      mime: req.file.mimetype || null,
      size: req.file.size || 0,
      by_role: byRole,
      by_id: req.user.userId,
      original_name: req.file.originalname || null,
      ts: new Date(),
    };
    await EmergencyEvent.findByIdAndUpdate(eventId, {
      $push: { shared_files: entry },
    });

    try {
      const io = req.app?.get('io');
      if (io) {
        io.to(`call:${eventId}`).emit('call-file-shared', {
          ...entry,
          ts: entry.ts.toISOString(),
        });
      }
    } catch (err) {
      console.warn('[call] file-share push failed:', err.message);
    }

    res.json({ success: true, file: entry });
  } catch (err) {
    next(err);
  }
};
