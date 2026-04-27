// ============================================================
//  webrtc.socket.js — Call room signaling (Agora + text chat)
//  VETO Legal Emergency App
//
//  - Room join/leave, chat messages, call end, lawyer availability
//  - SDP/ICE (legacy WebRTC) removed — use Agora for A/V
// ============================================================

const EmergencyEvent = require('../models/EmergencyEvent');
const Lawyer         = require('../models/Lawyer');

// In-memory call rooms: roomId → { participants: Set<socketId>, callType, startedAt }
const callRooms = new Map();

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

        const normalizedType = callType === 'chat' ? 'chat' : callType === 'audio' ? 'audio' : 'video';

        const roomKey = `call:${roomId}`;
        socket.join(roomKey);

        if (!callRooms.has(roomId)) {
          callRooms.set(roomId, {
            participants: new Set(),
            callType: normalizedType,
            startedAt: new Date(),
          });
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

        if (normalizedType === 'chat' && roomSockets.size === 2) {
          io.in(roomKey).emit('chat-ready', { roomId });
        }

        console.log(`📞 [Call] ${role} ${userId} joined room:${roomId} | participants: ${roomSockets.size} | mode=${normalizedType}`);
      } catch (err) {
        console.error('[Call] join-call-room error:', err);
        socket.emit('call-error', { message: 'Failed to join call room.' });
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

        console.log(`📞 [Call] Call ended | room=${roomId} | by=${role} | ${duration}s`);
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
