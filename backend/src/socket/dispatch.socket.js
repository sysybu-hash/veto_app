// ============================================================
//  dispatch.socket.js — Smart Dispatch Engine
//  VETO Legal Emergency App
//  "Uber for Lawyers" — real-time race-to-accept logic
// ============================================================

const Lawyer         = require('../models/Lawyer');
const EmergencyEvent = require('../models/EmergencyEvent');

// ── In-memory lock to prevent double-acceptance ────────────
// eventId → lawyerId (settled races)
const settledEvents = new Map();

// ── Deep-link builder ──────────────────────────────────────
function buildCallLink(lawyer) {
  if (lawyer.whatsapp_number) {
    const num = lawyer.whatsapp_number.replace(/\D/g, '');
    return `https://wa.me/${num}`;
  }
  if (lawyer.telegram_username) {
    return `https://t.me/${lawyer.telegram_username}`;
  }
  return `tel:${lawyer.phone}`;
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
    }

    // ── User joins their private room ──────────────────────
    if (role === 'user') {
      socket.join(`user:${userId}`);
    }

    // ════════════════════════════════════════════════════════
    //  EVENT: start_veto
    //  Emitted by: User (client)
    //  Payload:    { location: { lat, lng }, preferredLanguage }
    // ════════════════════════════════════════════════════════
    socket.on('start_veto', async (payload) => {
      if (role !== 'user') return; // lawyers can't trigger VETO

      const { location, preferredLanguage } = payload;

      try {
        // 1. Create the EmergencyEvent in MongoDB ────────────
        const event = await EmergencyEvent.create({
          user_id:        userId,
          status:         'dispatching',
          language:       preferredLanguage || 'en',
          event_location: {
            type:        'Point',
            coordinates: [location.lng, location.lat],
          },
          triggered_at: new Date(),
        });

        const eventId = event._id.toString();

        // 1.5. Notify the user immediately that the event was created
        socket.emit('emergency_created', { eventId });

        // 2. Find all available online lawyers ───────────────
        const availableLawyers = await Lawyer.find({
          is_online:   true,
          is_available: true,
          is_active:   true,
        }).select(
          'full_name phone whatsapp_number telegram_username preferred_language socket_id'
        );

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
        //    Socket rooms were joined on connection.
        //    We emit to each socket_id directly for reliability.
        const alertPayload = {
          eventId,
          userName:  socket.handshake.auth.decoded.full_name || 'User',
          location,            // { lat, lng }
          language:  preferredLanguage || 'en',
          timestamp: new Date().toISOString(),
        };

        let emittedCount = 0;
        for (const lawyer of sorted) {
          if (lawyer.socket_id) {
            io.to(lawyer.socket_id).emit('new_emergency_alert', alertPayload);
            emittedCount++;
          }
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

      // ── Atomic lock: only the FIRST lawyer wins ──────────
      if (settledEvents.has(eventId)) {
        socket.emit('case_already_taken', { eventId });
        return;
      }
      settledEvents.set(eventId, userId); // lock immediately

      // Auto-release lock after 30 min (GC)
      setTimeout(() => settledEvents.delete(eventId), 30 * 60 * 1000);

      try {
        // Check the event is still open
        const event = await EmergencyEvent.findById(eventId);
        if (!event || event.status !== 'dispatching') {
          settledEvents.delete(eventId);
          socket.emit('case_already_taken', { eventId });
          return;
        }

        const lawyer = await Lawyer.findById(userId).select(
          'full_name phone whatsapp_number telegram_username preferred_language'
        );

        const callLink = buildCallLink(lawyer);
        const now      = new Date();

        // 1. Update EmergencyEvent ────────────────────────────
        const timeToAccept = Math.round(
          (now - event.triggered_at) / 1000
        );

        await EmergencyEvent.findByIdAndUpdate(eventId, {
          status:               'accepted',
          assigned_lawyer_id:   userId,
          accepted_at:          now,
          call_link:            callLink,
          time_to_accept_seconds: timeToAccept,
          // Mark this lawyer's dispatch entry as accepted
          $set: {
            'dispatch_attempts.$[elem].response':     'accepted',
            'dispatch_attempts.$[elem].responded_at': now,
          },
        }, {
          arrayFilters: [{ 'elem.lawyer_id': userId }],
          new: true,
        });

        // 2. Mark lawyer as busy ───────────────────────────────
        await Lawyer.findByIdAndUpdate(userId, { is_available: false });

        // 3. Notify the User: lawyer found ────────────────────
        //    Send to user's private room
        io.to(`user:${event.user_id}`).emit('lawyer_found', {
          eventId,
          lawyerName:   lawyer.full_name,
          lawyerPhone:  lawyer.phone,
          callLink,
          language:     lawyer.preferred_language,
          message:      'A lawyer has accepted your request!',
        });

        // 4. Confirm to the winning lawyer ─────────────────────
        socket.emit('case_accepted_confirmed', {
          eventId,
          userLocation: event.event_location?.coordinates,
          userName:     event.user_id?.toString(),
          callLink,
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
        settledEvents.delete(eventId); // release lock on error
        console.error('accept_case error:', err);
        socket.emit('veto_error', { message: 'Could not accept case. Please try again.' });
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
      if (role !== 'user') return;

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
