// ============================================================
//  call.controller.js — Call Recording & Transcription
//  VETO Legal Emergency App
//
//  Endpoints:
//    POST /api/calls/:eventId/recording   → Upload recording to Cloudinary
//    POST /api/calls/:eventId/transcribe  → Transcribe with Gemini
//    GET  /api/calls/:eventId             → Get call details
// ============================================================

const EmergencyEvent = require('../models/EmergencyEvent');
const cloudinary     = require('../config/cloudinary');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

/**
 * Build extra ICE servers from env (TURN credentials never ship in the Flutter bundle).
 * Priority:
 *   1) WEBRTC_ICE_SERVERS_JSON — JSON array, WebRTC shape, e.g.
 *      [{"urls":"turn:turn.example.com:3478","username":"u","credential":"p"}]
 *   2) TURN_URL + TURN_USERNAME + TURN_CREDENTIAL — single TURN entry
 */
function iceServersFromEnv() {
  const raw = process.env.WEBRTC_ICE_SERVERS_JSON;
  if (raw && String(raw).trim()) {
    try {
      const parsed = JSON.parse(String(raw).trim());
      if (Array.isArray(parsed)) return parsed;
    } catch (_) {
      /* fall through */
    }
  }
  const url = process.env.TURN_URL;
  const user = process.env.TURN_USERNAME;
  const pass = process.env.TURN_CREDENTIAL;
  if (url && user && pass) {
    return [{ urls: url, username: user, credential: pass }];
  }
  return [];
}

// ── WebRTC ICE (authenticated; no event id) ───────────────────
exports.getIceConfig = (_req, res) => {
  try {
    res.json({ iceServers: iceServersFromEnv() });
  } catch {
    res.status(500).json({ error: 'ICE configuration unavailable', iceServers: [] });
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
          format:        'webm',
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
      recording_url:      uploadResult.secure_url,
      recording_duration: uploadResult.duration,
      recording_size:     uploadResult.bytes,
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

    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    let transcript;

    if (hasInlineAudio) {
      // Inline audio transcription (base64)
      const prompt = `
You are a professional legal call transcription service.
Transcribe this audio recording of a legal consultation call in ${lang}.
- Format as a clean conversation transcript
- Label each speaker as "Client" or "Lawyer"
- Include timestamps if possible
- Note any important legal terms mentioned
- If audio quality is poor, note [inaudible] where needed
Return only the transcript text, no additional commentary.
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

      transcript = result.response.text();
    } else if (event.recording_url) {
      // Text-only transcription request (recording is on Cloudinary)
      const prompt = `
A legal emergency call was recorded. The recording URL is: ${event.recording_url}
Please generate a summary placeholder noting the recording is available at the URL above.
Language of the call: ${lang}.
Return a brief note that the full transcript will be available once the audio is processed.
      `.trim();

      const result = await model.generateContent(prompt);
      transcript = result.response.text();
    } else {
      return res.status(400).json({ error: 'No audio data or recording URL available' });
    }

    // Save transcript to event
    await EmergencyEvent.findByIdAndUpdate(eventId, {
      call_transcript: transcript,
      transcript_language: language || event.language,
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

// ── Get call details ──────────────────────────────────────────
exports.getCallDetails = async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const { userId }  = req.user;

    const event = await EmergencyEvent.findById(eventId)
      .select('user_id assigned_lawyer_id status call_type call_started_at call_duration_seconds recording_url call_transcript transcript_language')
      .lean();

    if (!event) return res.status(404).json({ error: 'Event not found' });

    // Access check
    const isUser   = event.user_id?.toString()            === userId;
    const isLawyer = event.assigned_lawyer_id?.toString() === userId;
    if (!isUser && !isLawyer && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized' });
    }

    res.json({ success: true, call: event });
  } catch (err) {
    next(err);
  }
};
