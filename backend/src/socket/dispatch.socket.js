// ============================================================
//  dispatch.socket.js — Smart Dispatch Engine
//  VETO Legal Emergency App
//  "Uber for Lawyers" — real-time race-to-accept logic
// ============================================================

const crypto = require('crypto');
const Sentry = require('../../instrument');
const logger = require('../lib/logger');
const Lawyer         = require('../models/Lawyer');
const User           = require('../models/User');
const EmergencyEvent = require('../models/EmergencyEvent');
const push           = require('../services/push.service');
const { PLANS }      = require('../config/pricing');
const { buildRtcTokenForUid } = require('../services/agoraToken.service');
const {
  findSpecialization,
  getMatchTerms,
} = require('../config/specializations');

// ── Build WebRTC room link (replaces WhatsApp/Telegram) ───────
// The room ID is the eventId. Both parties join /call?roomId=eventId
function buildRoomId(eventId) {
  return eventId.toString();
}

// ── Sorted lawyer list ─────────────────────────────────────
// Preferred-language lawyers come first; rest follow
function sortByLanguage(lawyers, preferredLang) {
  return [...lawyers].sort((a, b) => {
    const aMatch = a.preferred_language === preferredLang ? 0 : 1;
    const bMatch = b.preferred_language === preferredLang ? 0 : 1;
    return aMatch - bMatch;
  });
}

// ══════════════════════════════════════════════════════════════
//  Main export — receives the io instance from server.js
// ══════════════════════════════════════════════════════════════
module.exports = function initDispatch(io) {

  // ── Socket.io JWT Auth Middleware ────────────────────────
  // Validates handshake token before any connection is allowed.
  // Full implementation in auth.middleware.js (socket version).
  io.use(require('../middleware/auth.middleware').socketAuth);

  // ────────────────────────────────────────────────────────
  io.on('connection', (socket) => {
    const { userId, role } = socket.handshake.auth.decoded;

    logger.info({ role, userId, socketId: socket.id }, '🔌 Socket connected');

    // ── Lawyer comes online ────────────────────────────────
    if (role === 'lawyer') {
      Lawyer.findByIdAndUpdate(userId, {
        is_online:  true,
        socket_id:  socket.id,
        last_seen:  new Date(),
      }).catch((err) => logger.error({ err, userId }, 'Failed to mark lawyer online'));

      socket.join(`lawyer:${userId}`);

      // Listen for explicit availability toggles from the dashboard
      socket.on('lawyer_availability', async ({ available }) => {
        try {
          await Lawyer.findByIdAndUpdate(userId, { is_available: !!available });
          logger.info({ userId, available: !!available }, 'Lawyer availability set');
        } catch (err) {
          logger.error({ err, userId }, 'Error updating availability');
        }
      });
    }

    // ── User + admin (testing as citizen) get the client notification room ─
    if (role === 'user' || role === 'admin') {
      socket.join(`user:${userId}`);
    }

    // ════════════════════════════════════════════════════════
    //  EVENT: start_veto
    //  Emitted by: User (client)
    //  Payload:    { location: { lat, lng }, preferredLanguage }
    // ════════════════════════════════════════════════════════
    socket.on('start_veto', async (payload) => {
      // Only citizen accounts (user / admin testing on veto screen) may dispatch.
      if (role !== 'user' && role !== 'admin') {
        socket.emit('veto_error', {
          message: 'Dispatch is only available from a citizen account.',
        });
        return;
      }

      const { location, preferredLanguage, specialization } = payload || {};

      if (
        !location ||
        typeof location !== 'object' ||
        !Number.isFinite(location.lat) ||
        !Number.isFinite(location.lng)
      ) {
        socket.emit('veto_error', { message: 'Invalid location payload.' });
        return;
      }

      // `general` and falsy → no specialization filter, all available lawyers.
      // Anything truthy + unrecognised → reject so we don't silently fall back.
      const specEntry = specialization ? findSpecialization(specialization) : null;
      if (specialization && !specEntry) {
        socket.emit('veto_error', { message: 'Unsupported specialization.' });
        return;
      }
      const specMatchTerms = specEntry ? getMatchTerms(specEntry.id) : null;

      try {
        // 0. Plan / billing gate ─────────────────────────────
        // Admins and manually-added users bypass; everyone else must hold an
        // active paid plan AND either have an included consultation credit
        // remaining OR a paid pending_consultation_token.
        let billingChargeIls = 0;
        let consumeToken = false;
        let consumeCredit = false;
        if (role !== 'admin') {
          const u = await User.findById(userId).select(
            '+pending_consultation_token subscription_plan subscription_expiry consultations_included consultations_used manually_added',
          );
          if (!u) {
            socket.emit('veto_error', { message: 'User not found.' });
            return;
          }
          if (!u.manually_added) {
            const planId = u.subscription_plan;
            const plan = planId ? PLANS[planId] : null;
            const expired = u.subscription_expiry && u.subscription_expiry < new Date();
            if (!plan || expired) {
              socket.emit('veto_error', {
                code: 'NO_PLAN',
                message: 'Active subscription required to request a lawyer.',
              });
              return;
            }
            if (!plan.sosAllowed) {
              socket.emit('veto_error', {
                code: 'DEMO_BLOCKED',
                message: 'Demo plan does not include lawyer calls. Please upgrade.',
              });
              return;
            }
            const remaining = Math.max(
              0,
              (u.consultations_included || 0) - (u.consultations_used || 0),
            );
            if (remaining > 0) {
              consumeCredit = true;
            } else if (u.pending_consultation_token) {
              consumeToken = true;
            } else {
              socket.emit('veto_error', {
                code: 'PAYMENT_REQUIRED',
                message: 'Per-consultation payment required before connecting a lawyer.',
              });
              return;
            }
            billingChargeIls = consumeCredit ? 0 : 79.9;
            // Atomically consume the credit / token so concurrent requests can't double-spend.
            const update = consumeCredit
              ? { $inc: { consultations_used: 1 } }
              : { $set: { pending_consultation_token: null } };
            const filter = consumeCredit
              ? {
                  _id: u._id,
                  $expr: {
                    $lt: ['$consultations_used', '$consultations_included'],
                  },
                }
              : { _id: u._id, pending_consultation_token: u.pending_consultation_token };
            const claimed = await User.updateOne(filter, update);
            if (claimed.matchedCount === 0) {
              socket.emit('veto_error', {
                code: 'PAYMENT_REQUIRED',
                message: 'Could not reserve consultation slot — please retry.',
              });
              return;
            }
          }
        }

        // 1. Create the EmergencyEvent in MongoDB ────────────
        const event = await EmergencyEvent.create({
          user_id:        userId,
          status:         'dispatching',
          language:       preferredLanguage || 'en',
          // Session mode (audio / video / chat) is chosen by the citizen after a lawyer accepts.
          call_type:      'pending',
          event_location: {
            type:        'Point',
            coordinates: [location.lng, location.lat],
          },
          triggered_at: new Date(),
          e2ee_secret:    crypto.randomBytes(32).toString('hex'),
        });

        const eventId = event._id.toString();

        // 1.5. Notify the user immediately that the event was created
        socket.emit('emergency_created', {
          eventId,
          billing: { chargeIls: billingChargeIls, source: consumeCredit ? 'credit' : (consumeToken ? 'paid' : 'exempt') },
        });

        // 2. Find available lawyers (online via socket OR have push / FCM) ─
        const staleCutoff = new Date(Date.now() - 12 * 60 * 1000);
        const lawyerQuery = {
          is_available: true,
          is_active:    true,
          $or: [
            {
              is_online: true,
              $or: [
                { last_seen: { $gte: staleCutoff } },
                { last_seen: null },
              ],
            },
            { push_subscription: { $ne: null, $exists: true } },
            { fcm_token: { $ne: null, $exists: true } },
          ],
        };

        // Filter by specialization if AI / picker provided one (skip for `general`).
        if (specMatchTerms) {
          lawyerQuery.specializations = {
            $in: specMatchTerms.map((t) => new RegExp(`^${t}$`, 'i')),
          };
        }

        const lawyerSelect =
          '+push_subscription +fcm_token full_name phone whatsapp_number telegram_username preferred_language socket_id last_location is_approved last_seen';

        async function findLawyers(query) {
          return Lawyer.find(query).select(lawyerSelect);
        }

        // Prefer admin-approved lawyers; fall back if none match.
        let availableLawyers = await findLawyers({ ...lawyerQuery, is_approved: true });
        if (availableLawyers.length === 0) {
          availableLawyers = await findLawyers(lawyerQuery);
        }

        // Fallback: if specialization filter yielded no lawyers, try all available
        if (specMatchTerms && availableLawyers.length === 0) {
          delete lawyerQuery.specializations;
          availableLawyers = await findLawyers({ ...lawyerQuery, is_approved: true });
          if (availableLawyers.length === 0) {
            availableLawyers = await findLawyers(lawyerQuery);
          }
        }

        if (availableLawyers.length === 0) {
          // No lawyers online — notify user immediately
          socket.emit('no_lawyers_available', {
            eventId,
            message: 'No lawyers are currently available. Please try again shortly.',
          });

          await EmergencyEvent.findByIdAndUpdate(eventId, {
            status: 'failed',
            completed_at: new Date(),
          });
          return;
        }

        // 3. Sort: preferred language first, then proximity when GPS is known ──
        let sorted = sortByLanguage(availableLawyers, preferredLanguage || 'en');
        const citizenLat = Number(location?.lat);
        const citizenLng = Number(location?.lng);
        if (Number.isFinite(citizenLat) && Number.isFinite(citizenLng)) {
          const dist = (lawyer) => {
            const coords = lawyer.last_location?.coordinates;
            if (!Array.isArray(coords) || coords.length < 2) return Number.POSITIVE_INFINITY;
            const [lng, lat] = coords;
            if (!Number.isFinite(lat) || !Number.isFinite(lng) || (lat === 0 && lng === 0)) {
              return Number.POSITIVE_INFINITY;
            }
            const dLat = (lat - citizenLat) * Math.PI / 180;
            const dLng = (lng - citizenLng) * Math.PI / 180;
            const a =
              Math.sin(dLat / 2) ** 2 +
              Math.cos(citizenLat * Math.PI / 180) *
                Math.cos(lat * Math.PI / 180) *
                Math.sin(dLng / 2) ** 2;
            return 2 * 6371 * Math.asin(Math.sqrt(a));
          };
          sorted = [...sorted].sort((a, b) => dist(a) - dist(b));
        }

        // 4. Build dispatch log entries ───────────────────────
        const dispatchLog = sorted.map((l) => ({
          lawyer_id:    l._id,
          notified_at:  new Date(),
          response:     'pending',
        }));

        await EmergencyEvent.findByIdAndUpdate(eventId, {
          lawyers_notified_count: sorted.length,
          dispatch_attempts:      dispatchLog,
        });

        // 5. Broadcast alert to ALL available lawyers ─────────
        //    Use the named room `lawyer:<id>` (joined on connect) so
        //    reconnected lawyers are reached even when the stored
        //    socket_id is stale (e.g. after Render free-tier wake-up).
        //    Fall back to direct socket_id emit if room appears empty.
        const alertPayload = {
          eventId,
          userId,
          userName:  socket.handshake.auth.decoded.full_name || 'User',
          location,            // { lat, lng }
          language:  preferredLanguage || 'en',
          timestamp: new Date().toISOString(),
        };

        let emittedCount = 0;
        const pushLawyers = [];

        for (const lawyer of sorted) {
          const room = `lawyer:${lawyer._id}`;
          const roomSockets = await io.in(room).allSockets();
          if (roomSockets.size > 0) {
            io.to(room).emit('new_emergency_alert', alertPayload);
            emittedCount++;
          } else if (lawyer.socket_id) {
            // Fallback: direct socket_id (may be stale but worth trying)
            io.to(lawyer.socket_id).emit('new_emergency_alert', alertPayload);
            emittedCount++;
          }
          // Web Push and/or FCM for offline / background lawyers
          if (lawyer.push_subscription || lawyer.fcm_token) {
            pushLawyers.push(lawyer);
          }
        }

        // Fire-and-forget push notifications (don't await — non-blocking)
        if (pushLawyers.length > 0) {
          const pushTitle = '🚨 VETO Emergency!';
          const pushBody  = `A client needs legal help urgently. Tap to respond.`;
          push.sendToMany(pushLawyers, { title: pushTitle, body: pushBody, data: alertPayload })
            .catch((e) => logger.error({ err: e }, '[PUSH] sendToMany error'));

          const fcm = require('../services/fcm.service');
          const { isExpoPushToken, sendExpoPush } = require('../services/expoPush.service');
          for (const lawyer of pushLawyers) {
            if (!lawyer.fcm_token) continue;
            if (isExpoPushToken(lawyer.fcm_token)) {
              sendExpoPush(lawyer.fcm_token, {
                title: pushTitle,
                body: pushBody,
                data: alertPayload,
              }).catch((e) => logger.error({ err: e, lawyerId: lawyer._id }, '[EXPO_PUSH] send error'));
            } else if (fcm.isConfigured()) {
              fcm
                .sendToFcmToken(lawyer.fcm_token, {
                  title: pushTitle,
                  body: pushBody,
                  data: alertPayload,
                })
                .catch((e) => logger.error({ err: e, lawyerId: lawyer._id }, '[FCM] send error'));
            }
          }
        }

        logger.info({ eventId, lawyersNotified: emittedCount }, '🚨 VETO dispatched');

        // 6. Acknowledge dispatch to user ─────────────────────
        socket.emit('veto_dispatched', {
          eventId,
          lawyersNotified: emittedCount,
        });

      } catch (err) {
        logger.error({ err }, 'start_veto error');
        socket.emit('veto_error', { message: 'Dispatch failed. Please try again.' });
      }
    });

    // ════════════════════════════════════════════════════════
    //  EVENT: accept_case
    //  Emitted by: Lawyer (client)
    //  Payload:    { eventId }
    // ════════════════════════════════════════════════════════
    socket.on('accept_case', async ({ eventId }) => {
      if (role !== 'lawyer') return;

      try {
        const lawyer = await Lawyer.findById(userId).select(
          'full_name phone preferred_language'
        );
        if (!lawyer) {
          socket.emit('veto_error', { message: 'Lawyer profile not found.' });
          return;
        }

        const roomId = buildRoomId(eventId);
        const now    = new Date();

        // 1. Atomic transition: only one lawyer wins (Mongo is source of truth).
        const updatedEvent = await EmergencyEvent.findOneAndUpdate(
          { _id: eventId, status: 'dispatching' },
          {
            $set: {
              status:             'accepted',
              assigned_lawyer_id: userId,
              accepted_at:        now,
              room_id:            roomId,
            },
          },
          { new: true },
        );

        if (!updatedEvent) {
          socket.emit('case_already_taken', { eventId });
          return;
        }

        const timeToAccept = Math.round(
          (updatedEvent.accepted_at.getTime() - updatedEvent.triggered_at.getTime()) / 1000,
        );

        await EmergencyEvent.updateOne(
          { _id: eventId },
          {
            $set: {
              time_to_accept_seconds:                 timeToAccept,
              'dispatch_attempts.$[elem].response':     'accepted',
              'dispatch_attempts.$[elem].responded_at': now,
            },
          },
          { arrayFilters: [{ 'elem.lawyer_id': userId }] },
        ).catch((err) => logger.error({ err, eventId, userId }, 'accept_case dispatch_attempts update failed'));

        const event = updatedEvent;

        // 2. Add event to lawyer history. Availability is an explicit lawyer
        // choice and must not be flipped off automatically after accepting.
        await Lawyer.findByIdAndUpdate(userId, {
          $addToSet: { emergency_events: eventId },
          $inc:       { total_cases_handled: 1 },
        });

        // 2b. Add event to user's history too ─────────────────────
        await User.findByIdAndUpdate(event.user_id, {
          $addToSet: { emergency_events: eventId },
        });

        // 3. Notify the User: lawyer accepted — citizen chooses audio / video / chat next.
        io.to(`user:${event.user_id}`).emit('lawyer_found', {
          eventId,
          roomId,
          callType:               'pending',
          awaitingCitizenChoice:  true,
          lawyerName:             lawyer.full_name,
          lawyerPhone:            lawyer.phone,
          language:               lawyer.preferred_language,
          message:                'A lawyer has accepted your request!',
        });

        // 4. Confirm to the winning lawyer — wait for citizen session mode (session_ready).
        socket.emit('case_accepted_confirmed', {
          eventId,
          roomId,
          callType:               'pending',
          awaitingCitizenChoice:  true,
          peerName:               'Client',
          language:               event.language || 'he',
          userLocation:           event.event_location?.coordinates,
          userId:                 event.user_id?.toString(),
        });

        // 5. Notify ALL other lawyers: case is gone ────────────
        //    We broadcast to all sockets in the lawyers room
        //    then tell the winning lawyer to ignore it (they
        //    already received case_accepted_confirmed).
        const takenPayload = {
          eventId,
          assignedLawyerId: userId.toString(),
          message: 'This case has been taken by another lawyer.',
        };
        for (const attempt of event.dispatch_attempts || []) {
          const notifiedLawyerId = attempt.lawyer_id?.toString();
          if (!notifiedLawyerId || notifiedLawyerId === userId.toString()) {
            continue;
          }
          io.to(`lawyer:${notifiedLawyerId}`).emit('case_taken', takenPayload);
        }

        // 6. Mark remaining dispatch attempts as no_response ───
        await EmergencyEvent.updateOne(
          { _id: eventId },
          {
            $set: {
              'dispatch_attempts.$[elem].response': 'no_response',
            },
          },
          { arrayFilters: [{ 'elem.response': 'pending' }] }
        );

        logger.info(
          { eventId, lawyer: lawyer.full_name, timeToAcceptSeconds: timeToAccept },
          '✅ Case accepted',
        );

      } catch (err) {
        logger.error({ err }, 'accept_case error');
        socket.emit('veto_error', { message: 'Could not accept case. Please try again.' });
      }
    });

    // ════════════════════════════════════════════════════════
    //  EVENT: citizen_chose_session
    //  Emitted by: User / admin (testing) after lawyer accepted
    //  Payload:    { eventId, callType: 'audio' | 'video' | 'chat' }
    // ════════════════════════════════════════════════════════
    socket.on('citizen_chose_session', async ({ eventId, callType }) => {
      if (role !== 'user' && role !== 'admin') {
        socket.emit('veto_error', {
          message: 'Only citizens can choose session mode.',
        });
        return;
      }

      const allowed = ['audio', 'video', 'chat'];
      if (!eventId || !callType || !allowed.includes(callType)) {
        socket.emit('veto_error', { message: 'Invalid session type.' });
        return;
      }

      try {
        const ev = await EmergencyEvent.findById(eventId).select('+e2ee_secret');
        if (!ev) {
          socket.emit('veto_error', { message: 'Event not found.' });
          return;
        }
        if (ev.user_id.toString() !== userId) {
          socket.emit('veto_error', { message: 'Not your event.' });
          return;
        }
        if (ev.status !== 'accepted') {
          socket.emit('veto_error', { message: 'Case is not ready for session.' });
          return;
        }

        let e2eeSecret = ev.e2ee_secret;
        if (!e2eeSecret) {
          e2eeSecret = crypto.randomBytes(32).toString('hex');
          await EmergencyEvent.findByIdAndUpdate(eventId, { e2ee_secret: e2eeSecret });
        }

        await EmergencyEvent.findByIdAndUpdate(eventId, { call_type: callType });

        const roomId = buildRoomId(eventId);
        const lawyer = await Lawyer.findById(ev.assigned_lawyer_id).select(
          'full_name phone preferred_language',
        );
        const userDoc = await User.findById(ev.user_id).select('full_name phone');

        const clientLabel = userDoc?.full_name?.trim() || 'Client';

        const basePayload = {
          eventId,
          roomId,
          callType,
          language: ev.language || 'he',
        };

        const userAgora = buildRtcTokenForUid({
          channelName: roomId,
          userMongoId: ev.user_id,
          role:        'publisher',
        });
        const lawyerAgora = ev.assigned_lawyer_id
          ? buildRtcTokenForUid({
              channelName: roomId,
              userMongoId: ev.assigned_lawyer_id,
              role:        'publisher',
            })
          : { token: '', agoraUid: 0, ttlSec: 0, expiresAt: 0 };

        io.to(`user:${ev.user_id}`).emit('session_ready', {
          ...basePayload,
          lawyerName: lawyer?.full_name || 'Lawyer',
          peerName:   lawyer?.full_name || 'Lawyer',
          agoraToken: userAgora.token,
          agoraUid:   userAgora.agoraUid,
          tokenExpiresAt: userAgora.expiresAt || 0,
          e2eeSecret,
        });

        if (ev.assigned_lawyer_id) {
          io.to(`lawyer:${ev.assigned_lawyer_id}`).emit('session_ready', {
            ...basePayload,
            peerName:   clientLabel,
            lawyerName: lawyer?.full_name,
            agoraToken: lawyerAgora.token,
            agoraUid:   lawyerAgora.agoraUid,
            tokenExpiresAt: lawyerAgora.expiresAt || 0,
            e2eeSecret,
          });
        }

        // Minimal, structured log — never print the token itself.
        logger.info(
          {
            eventId,
            callType,
            userUid: userAgora.agoraUid,
            lawyerUid: lawyerAgora.agoraUid,
            hasToken: !!userAgora.token,
          },
          '📞 session_ready',
        );
      } catch (err) {
        logger.error({ err }, 'citizen_chose_session error');
        socket.emit('veto_error', { message: 'Could not start session.' });
      }
    });

    // ════════════════════════════════════════════════════════
    //  EVENT: reject_case
    //  Emitted by: Lawyer (client)
    //  Payload:    { eventId }
    // ════════════════════════════════════════════════════════
    socket.on('reject_case', async ({ eventId }) => {
      if (role !== 'lawyer') return;

      const now = new Date();
      await EmergencyEvent.updateOne(
        { _id: eventId },
        {
          $set: {
            'dispatch_attempts.$[elem].response':     'rejected',
            'dispatch_attempts.$[elem].responded_at': now,
          },
        },
        { arrayFilters: [{ 'elem.lawyer_id': userId }] }
      ).catch((err) => logger.error({ err, eventId, userId }, 'reject_case update failed'));

      // No further action — other lawyers are still seeing the alert
    });

    // ════════════════════════════════════════════════════════
    //  EVENT: cancel_veto
    //  Emitted by: User (client) — before lawyer accepts
    //  Payload:    { eventId }
    // ════════════════════════════════════════════════════════
    socket.on('cancel_veto', async ({ eventId }) => {
      if (role !== 'user' && role !== 'admin') return;

      await EmergencyEvent.findByIdAndUpdate(eventId, {
        status:       'cancelled',
        completed_at: new Date(),
      }).catch((err) => logger.error({ err, eventId }, 'cancel_veto update failed'));

      // Tell all lawyers to dismiss the alert
      io.emit('case_taken', {
        eventId,
        message: 'The user has cancelled the request.',
      });

      logger.info({ eventId }, '❌ VETO cancelled');
    });

    // ════════════════════════════════════════════════════════
    //  EVENT: disconnect
    // ════════════════════════════════════════════════════════
    socket.on('disconnect', async (reason) => {
      const uid = userId?.toString?.() ?? String(userId);
      logger.info({ role, userId: uid, reason }, '🔌 Socket disconnected');

      if (
        Sentry.__vetoInstrumented &&
        (reason === 'transport error' || reason === 'ping timeout')
      ) {
        Sentry.addBreadcrumb({
          category: 'socket',
          message: `Unexpected dispatch disconnect for user ${uid} (${role}): ${reason}`,
          level: 'warning',
        });
      }

      if (role === 'lawyer') {
        await Lawyer.findByIdAndUpdate(userId, {
          is_online:  false,
          socket_id:  null,
        }).catch((err) => logger.error({ err, userId }, 'Failed to mark lawyer offline'));
      }
    });
  });
};
