// ============================================================
//  dispatch.socket.js — Smart Dispatch Engine
//  VETO Legal Emergency App
//  "Uber for Lawyers" — real-time race-to-accept logic
// ============================================================

const Lawyer         = require('../models/Lawyer');
const User           = require('../models/User');
const EmergencyEvent = require('../models/EmergencyEvent');
const push           = require('../services/push.service');

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

    console.log(`🔌 Connected [${role}] id=${userId} socket=${socket.id}`);

    // ── Lawyer comes online ────────────────────────────────
    if (role === 'lawyer') {
      Lawyer.findByIdAndUpdate(userId, {
        is_online:  true,
        socket_id:  socket.id,
      }).catch(console.error);

      socket.join(`lawyer:${userId}`);

      // Listen for explicit availability toggles from the dashboard
      socket.on('lawyer_availability', async ({ available }) => {
        try {
          await Lawyer.findByIdAndUpdate(userId, { is_available: !!available });
          console.log(`Lawyer ${userId} availability set to ${!!available}`);
        } catch (err) {
          console.error(`Error updating availability for ${userId}:`, err);
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

      const { location, preferredLanguage, specialization } = payload;

      // Specialization → English DB terms map (mirrors ai.controller.js)
      const SPEC_MAP = {
        'פלילי':  ['criminal', 'Criminal', 'פלילי'],
        'משפחה':  ['family', 'Family', 'משפחה'],
        'נדל"ן':  ['real estate', 'Real Estate', 'realestate', 'RealEstate', 'נדל"ן', 'נדלן'],
        'עבודה':  ['labor', 'Labor', 'employment', 'Employment', 'עבודה'],
        'מסחרי':  ['commercial', 'Commercial', 'civil', 'Civil', 'מסחרי'],
        'תעבורה': ['traffic', 'Traffic', 'transportation', 'Transportation', 'תעבורה'],
      };

      try {
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
        });

        const eventId = event._id.toString();

        // 1.5. Notify the user immediately that the event was created
        socket.emit('emergency_created', { eventId });

        // 2. Find available lawyers (online via socket OR have push subscription) ─
        const lawyerQuery = {
          is_available: true,
          is_active:    true,
          $or: [
            { is_online: true },
            { push_subscription: { $ne: null, $exists: true } },
          ],
        };

        // Filter by specialization if AI provided one
        if (specialization && SPEC_MAP[specialization]) {
          const terms = SPEC_MAP[specialization];
          lawyerQuery.specializations = { $in: terms.map((t) => new RegExp(`^${t}$`, 'i')) };
        }

        let availableLawyers = await Lawyer.find(lawyerQuery).select(
          'full_name phone whatsapp_number telegram_username preferred_language socket_id push_subscription'
        );

        // Fallback: if specialization filter yielded no lawyers, try all available
        if (specialization && availableLawyers.length === 0) {
          delete lawyerQuery.specializations;
          availableLawyers = await Lawyer.find(lawyerQuery).select(
            'full_name phone whatsapp_number telegram_username preferred_language socket_id push_subscription'
          );
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

        // 3. Sort: preferred language first ──────────────────
        const sorted = sortByLanguage(availableLawyers, preferredLanguage || 'en');

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
          // Always try push if lawyer has a subscription (catches offline lawyers)
          if (lawyer.push_subscription) {
            pushLawyers.push(lawyer);
          }
        }

        // Fire-and-forget push notifications (don't await — non-blocking)
        if (pushLawyers.length > 0) {
          const pushTitle = '🚨 VETO Emergency!';
          const pushBody  = `A client needs legal help urgently. Tap to respond.`;
          push.sendToMany(pushLawyers, { title: pushTitle, body: pushBody, data: alertPayload })
            .catch(e => console.error('[PUSH] sendToMany error:', e));
        }

        console.log(
          `🚨 VETO dispatched | event=${eventId} | lawyers notified=${emittedCount}`
        );

        // 6. Acknowledge dispatch to user ─────────────────────
        socket.emit('veto_dispatched', {
          eventId,
          lawyersNotified: emittedCount,
        });

      } catch (err) {
        console.error('start_veto error:', err);
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
        ).catch(console.error);

        const event = updatedEvent;

        // 2. Mark lawyer as busy + add event to their case history ─
        await Lawyer.findByIdAndUpdate(userId, {
          is_available: false,
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
        socket.broadcast.emit('case_taken', {
          eventId,
          message: 'This case has been taken by another lawyer.',
        });

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

        console.log(
          `✅ Case accepted | event=${eventId} | lawyer=${lawyer.full_name} | t=${timeToAccept}s`
        );

      } catch (err) {
        console.error('accept_case error:', err);
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
        const ev = await EmergencyEvent.findById(eventId);
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

        io.to(`user:${ev.user_id}`).emit('session_ready', {
          ...basePayload,
          lawyerName: lawyer?.full_name || 'Lawyer',
          peerName:   lawyer?.full_name || 'Lawyer',
        });

        if (ev.assigned_lawyer_id) {
          io.to(`lawyer:${ev.assigned_lawyer_id}`).emit('session_ready', {
            ...basePayload,
            peerName:   clientLabel,
            lawyerName: lawyer?.full_name,
          });
        }
      } catch (err) {
        console.error('citizen_chose_session error:', err);
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
      ).catch(console.error);

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
      }).catch(console.error);

      // Tell all lawyers to dismiss the alert
      io.emit('case_taken', {
        eventId,
        message: 'The user has cancelled the request.',
      });

      console.log(`❌ VETO cancelled | event=${eventId}`);
    });

    // ════════════════════════════════════════════════════════
    //  EVENT: disconnect
    // ════════════════════════════════════════════════════════
    socket.on('disconnect', async () => {
      console.log(`🔌 Disconnected [${role}] id=${userId}`);

      if (role === 'lawyer') {
        await Lawyer.findByIdAndUpdate(userId, {
          is_online:  false,
          socket_id:  null,
        }).catch(console.error);
      }
    });
  });
};
