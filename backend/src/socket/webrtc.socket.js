// ============================================================
//  webrtc.socket.js — Call room signaling (Agora + text chat)
//  VETO Legal Emergency App
//
//  - Room join/leave, chat messages, call end, lawyer availability
//  - 30s "peer missing" timeout → both sides get `call-timeout`
//  - `call-renew-token` → server re-issues an Agora RTC token
//  - SDP/ICE (legacy WebRTC) removed — use Agora for A/V
// ============================================================

const EmergencyEvent = require('../models/EmergencyEvent');
const Lawyer         = require('../models/Lawyer');
const { buildRtcTokenForUid } = require('../services/agoraToken.service');

/** Milliseconds to wait for the second participant before both sides are
 *  notified that the peer never showed up. */
const JOIN_TIMEOUT_MS = 30 * 1000;

/**
 * In-memory map of active call rooms.
 * @type {Map<string, {
 *   participants: Set<string>,
 *   callType: 'video'|'audio'|'chat',
 *   startedAt: Date,
 *   joinTimer: NodeJS.Timeout | null,
 * }>}
 */
const callRooms = new Map();

function clearJoinTimer(room) {
  if (room && room.joinTimer) {
    clearTimeout(room.joinTimer);
    room.joinTimer = null;
  }
}

module.exports = function initCallSignaling(io) {

  io.on('connection', (socket) => {
    const decoded = socket.handshake.auth?.decoded;
    if (!decoded) return;
    const { userId, role } = decoded;

    // ════════════════════════════════════════════════════════════
    //  join-call-room
    //  Payload:    { roomId: eventId, callType: 'video'|'audio'|'chat' }
    // ════════════════════════════════════════════════════════════
    socket.on('join-call-room', async ({ roomId, callType }) => {
      try {
        const event = await EmergencyEvent.findById(roomId);
        if (!event) {
          return socket.emit('call-error', { message: 'Emergency event not found.' });
        }

        const uid = userId?.toString();
        const isUser =
          (role === 'user' || role === 'admin') &&
          event.user_id?.toString() === uid;
        const isLawyer =
          role === 'lawyer' && event.assigned_lawyer_id?.toString() === uid;
        if (!isUser && !isLawyer) {
          return socket.emit('call-error', { message: 'Not authorized for this call.' });
        }

        const normalizedType = callType === 'chat'
          ? 'chat'
          : callType === 'audio' ? 'audio' : 'video';

        const roomKey = `call:${roomId}`;
        socket.join(roomKey);

        if (!callRooms.has(roomId)) {
          const initialRoom = {
            participants: new Set(),
            callType: normalizedType,
            startedAt: new Date(),
            joinTimer: null,
          };
          callRooms.set(roomId, initialRoom);
          await EmergencyEvent.findByIdAndUpdate(roomId, {
            status: 'in_progress',
            call_type: normalizedType,
            call_started_at: new Date(),
          });
        }

        const room = callRooms.get(roomId);
        room.participants.add(socket.id);

        const roomSockets = await io.in(roomKey).allSockets();
        socket.emit('room-joined', {
          roomId,
          socketId: socket.id,
          participantCount: roomSockets.size,
          callType: room.callType,
          isCaller: roomSockets.size === 1,
        });

        if (roomSockets.size >= 2) {
          // Second participant is in — cancel the pending "peer missing" timer.
          clearJoinTimer(room);
          if (normalizedType === 'chat') {
            io.in(roomKey).emit('chat-ready', { roomId });
          }
        } else if (roomSockets.size === 1 && !room.joinTimer) {
          // First participant: arm the 30-second timer. If the peer never
          // joins we tell both the waiting socket AND (best-effort) the
          // absent side's user / lawyer room that the call timed out.
          room.joinTimer = setTimeout(async () => {
            const live = callRooms.get(roomId);
            if (!live) return;
            clearJoinTimer(live);
            // Still only 1 socket? Emit timeout.
            const sockets = await io.in(`call:${roomId}`).allSockets();
            if (sockets.size >= 2) return;

            const reason = 'peer_no_answer';
            io.in(`call:${roomId}`).emit('call-timeout', { roomId, reason });
            // Best-effort broadcast to the absent side's user:/ lawyer: rooms
            // so push/socket clients that never made it to the call room can
            // clean up their UI too.
            try {
              const ev = await EmergencyEvent.findById(roomId)
                .select('user_id assigned_lawyer_id')
                .lean();
              if (ev?.user_id) {
                io.to(`user:${ev.user_id}`).emit('call-timeout', { roomId, reason });
              }
              if (ev?.assigned_lawyer_id) {
                io.to(`lawyer:${ev.assigned_lawyer_id}`).emit('call-timeout', { roomId, reason });
              }
            } catch (_) { /* ignore */ }

            // Mark event as timed-out so history reflects reality.
            await EmergencyEvent.findOneAndUpdate(
              { _id: roomId, status: { $in: ['accepted', 'in_progress'] } },
              {
                $set: {
                  status:       'completed',
                  completed_at: new Date(),
                  timed_out:    true,
                },
              },
            ).catch(() => {});

            callRooms.delete(roomId);
          }, JOIN_TIMEOUT_MS);
        }

        console.log(
          `📞 join-call-room | ${role} ${uid} | room=${roomId} | peers=${roomSockets.size} | mode=${normalizedType}`,
        );
      } catch (err) {
        console.error('[Call] join-call-room error:', err);
        socket.emit('call-error', { message: 'Failed to join call room.' });
      }
    });

    // ════════════════════════════════════════════════════════════
    //  call-renew-token
    //  Payload: { roomId }
    //  The engine’s onTokenPrivilegeWillExpire fires a few seconds
    //  before expiry; client asks the server for a fresh RTC token
    //  and passes it straight to engine.renewToken(...).
    // ════════════════════════════════════════════════════════════
    socket.on('call-renew-token', async ({ roomId }) => {
      try {
        const event = await EmergencyEvent.findById(roomId)
          .select('user_id assigned_lawyer_id room_id')
          .lean();
        if (!event) return socket.emit('call-error', { message: 'Event not found.' });

        const uid = userId?.toString();
        const isUser =
          (role === 'user' || role === 'admin') &&
          event.user_id?.toString() === uid;
        const isLawyer =
          role === 'lawyer' && event.assigned_lawyer_id?.toString() === uid;
        if (!isUser && !isLawyer) {
          return socket.emit('call-error', { message: 'Not authorized.' });
        }

        const channelName = event.room_id || String(roomId);
        const { token, agoraUid, expiresAt } = buildRtcTokenForUid({
          channelName,
          userMongoId: uid,
          role:        'publisher',
        });

        socket.emit('call-token-renewed', {
          roomId,
          channelId:  channelName,
          agoraToken: token,
          agoraUid,
          tokenExpiresAt: expiresAt || 0,
        });
      } catch (err) {
        console.error('[Call] call-renew-token error:', err);
        socket.emit('call-error', { message: 'Could not renew token.' });
      }
    });

    socket.on('call-chat-message', async ({ roomId, text }) => {
      try {
        const event = await EmergencyEvent.findById(roomId);
        if (!event) return;

        const uid = userId?.toString();
        const isUser =
          (role === 'user' || role === 'admin') &&
          event.user_id?.toString() === uid;
        const isLawyer =
          role === 'lawyer' && event.assigned_lawyer_id?.toString() === uid;
        if (!isUser && !isLawyer) return;

        const t = typeof text === 'string' ? text.trim() : '';
        if (!t || t.length > 4000) return;

        socket.to(`call:${roomId}`).emit('call-chat-message', {
          text: t,
          fromRole: role,
          userId: uid,
        });
      } catch (err) {
        console.error('[Call] call-chat-message error:', err);
      }
    });

    // Legacy WebRTC: offer/answer/ICE are ignored (Agora handles A/V)
    const noop = () => {};
    socket.on('webrtc-offer', noop);
    socket.on('webrtc-answer', noop);
    socket.on('ice-candidate', noop);
    socket.on('media-toggle', noop);

    socket.on('call-ended', async ({ roomId, duration }) => {
      try {
        socket.to(`call:${roomId}`).emit('call-ended', {
          endedBy: role,
          duration,
        });

        socket.leave(`call:${roomId}`);

        const room = callRooms.get(roomId);
        if (room) {
          clearJoinTimer(room);
          room.participants.delete(socket.id);
          if (room.participants.size === 0) {
            callRooms.delete(roomId);
          }
        }

        const endedMeta = await EmergencyEvent.findById(roomId)
          .select('assigned_lawyer_id')
          .lean();

        await EmergencyEvent.findByIdAndUpdate(roomId, {
          status:                  'completed',
          completed_at:            new Date(),
          call_duration_seconds:   duration || 0,
        });

        if (endedMeta?.assigned_lawyer_id) {
          await Lawyer.findByIdAndUpdate(endedMeta.assigned_lawyer_id, {
            is_available: true,
          }).catch(console.error);
        }

        console.log(`📞 call-ended | room=${roomId} | by=${role} | ${duration}s`);
      } catch (err) {
        console.error('[Call] call-ended error:', err);
      }
    });

    socket.on('disconnect', () => {
      for (const [roomId, room] of callRooms.entries()) {
        if (room.participants.has(socket.id)) {
          room.participants.delete(socket.id);
          socket.to(`call:${roomId}`).emit('peer-left', {
            socketId: socket.id,
            userId,
            role,
          });
          if (room.participants.size === 0) {
            clearJoinTimer(room);
            callRooms.delete(roomId);
            void (async () => {
              try {
                const meta = await EmergencyEvent.findById(roomId)
                  .select('assigned_lawyer_id status')
                  .lean();
                await EmergencyEvent.findOneAndUpdate(
                  { _id: roomId, status: { $in: ['accepted', 'in_progress'] } },
                  {
                    $set: {
                      status:       'completed',
                      completed_at: new Date(),
                    },
                  },
                );
                if (meta?.assigned_lawyer_id) {
                  await Lawyer.findByIdAndUpdate(meta.assigned_lawyer_id, {
                    is_available: true,
                  }).catch(console.error);
                }
              } catch (e) {
                console.error('[Call] disconnect room cleanup:', e);
              }
            })();
          }
        }
      }
    });
  });
};
