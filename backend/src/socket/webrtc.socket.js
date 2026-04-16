// ============================================================
//  webrtc.socket.js — WebRTC Signaling Server
//  VETO Legal Emergency App
//
//  Handles peer-to-peer audio/video call signaling:
//  - Room join/leave
//  - SDP offer / answer exchange
//  - ICE candidate exchange
//  - Media toggle (mute/camera)
//  - Call end + event update
// ============================================================

const EmergencyEvent = require('../models/EmergencyEvent');
const Lawyer         = require('../models/Lawyer');

// In-memory call rooms: roomId → { participants: Set<socketId>, callType, startedAt }
const callRooms = new Map();

module.exports = function initWebRTC(io) {

  io.on('connection', (socket) => {
    const decoded = socket.handshake.auth?.decoded;
    if (!decoded) return;
    const { userId, role } = decoded;

    // ════════════════════════════════════════════════════════════
    //  join-call-room
    //  Emitted by: User OR Lawyer after case is accepted
    //  Payload:    { roomId: eventId, callType: 'video'|'audio' }
    // ════════════════════════════════════════════════════════════
    socket.on('join-call-room', async ({ roomId, callType }) => {
      try {
        const event = await EmergencyEvent.findById(roomId);
        if (!event) {
          return socket.emit('call-error', { message: 'Emergency event not found.' });
        }

        // Authorization: citizen (user or admin account) or assigned lawyer only.
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

        // Initialize room record
        if (!callRooms.has(roomId)) {
          callRooms.set(roomId, {
            participants: new Set(),
            callType: normalizedType,
            startedAt: new Date(),
          });
          // Update event status to in-progress once a real session room is created
          await EmergencyEvent.findByIdAndUpdate(roomId, {
            status: 'in_progress',
            call_type: normalizedType,
            call_started_at: new Date(),
          });
        }

        const room = callRooms.get(roomId);
        room.participants.add(socket.id);

        // WebRTC signaling — text-only sessions skip offer/answer
        if (normalizedType !== 'chat') {
          socket.to(roomKey).emit('peer-joined', {
            userId,
            role,
            socketId: socket.id,
            callType: room.callType,
          });
        }

        // Count active sockets in room
        const roomSockets = await io.in(roomKey).allSockets();
        socket.emit('room-joined', {
          roomId,
          socketId: socket.id,
          participantCount: roomSockets.size,
          callType: room.callType,
          isCaller: roomSockets.size === 1, // first to join = caller (creates offer)
        });

        if (normalizedType === 'chat' && roomSockets.size === 2) {
          io.in(roomKey).emit('chat-ready', { roomId });
        }

        console.log(`📞 [WebRTC] ${role} ${userId} joined room:${roomId} | participants: ${roomSockets.size} | mode=${normalizedType}`);
      } catch (err) {
        console.error('[WebRTC] join-call-room error:', err);
        socket.emit('call-error', { message: 'Failed to join call room.' });
      }
    });

    // ════════════════════════════════════════════════════════════
    //  call-chat-message — text session in same call room
    // ════════════════════════════════════════════════════════════
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
        console.error('[WebRTC] call-chat-message error:', err);
      }
    });

    // ════════════════════════════════════════════════════════════
    //  webrtc-offer
    //  Emitted by: Caller (first peer) → to Callee
    //  Payload:    { roomId, offer: RTCSessionDescription, targetSocketId }
    // ════════════════════════════════════════════════════════════
    // Use io.to(socketId) for targeted relay — socket.to(otherId) is unreliable in some
    // Socket.io setups; delivery to a specific peer must go through the server io instance.
    socket.on('webrtc-offer', ({ roomId, offer, targetSocketId }) => {
      const payload = {
        offer,
        fromSocketId: socket.id,
        fromUserId: userId,
        fromRole: role,
      };
      if (targetSocketId) {
        io.to(String(targetSocketId)).emit('webrtc-offer', payload);
      } else {
        socket.to(`call:${roomId}`).emit('webrtc-offer', payload);
      }
    });

    // ════════════════════════════════════════════════════════════
    //  webrtc-answer
    //  Emitted by: Callee → to Caller
    //  Payload:    { roomId, answer: RTCSessionDescription, targetSocketId }
    // ════════════════════════════════════════════════════════════
    socket.on('webrtc-answer', ({ roomId, answer, targetSocketId }) => {
      const payload = {
        answer,
        fromSocketId: socket.id,
      };
      if (targetSocketId) {
        io.to(String(targetSocketId)).emit('webrtc-answer', payload);
      } else {
        socket.to(`call:${roomId}`).emit('webrtc-answer', payload);
      }
    });

    // ════════════════════════════════════════════════════════════
    //  ice-candidate
    //  Emitted by: Both peers during ICE negotiation
    //  Payload:    { roomId, candidate: RTCIceCandidate, targetSocketId }
    // ════════════════════════════════════════════════════════════
    socket.on('ice-candidate', ({ roomId, candidate, targetSocketId }) => {
      const payload = {
        candidate,
        fromSocketId: socket.id,
      };
      if (targetSocketId) {
        io.to(String(targetSocketId)).emit('ice-candidate', payload);
      } else {
        socket.to(`call:${roomId}`).emit('ice-candidate', payload);
      }
    });

    // ════════════════════════════════════════════════════════════
    //  media-toggle
    //  Emitted by: Either peer when toggling mic/camera
    //  Payload:    { roomId, video: bool, audio: bool }
    // ════════════════════════════════════════════════════════════
    socket.on('media-toggle', ({ roomId, video, audio }) => {
      socket.to(`call:${roomId}`).emit('peer-media-toggle', {
        video,
        audio,
        fromSocketId: socket.id,
        fromRole: role,
      });
    });

    // ════════════════════════════════════════════════════════════
    //  call-ended
    //  Emitted by: Either peer when ending the call
    //  Payload:    { roomId, duration: seconds }
    // ════════════════════════════════════════════════════════════
    socket.on('call-ended', async ({ roomId, duration }) => {
      try {
        // Notify the other peer
        socket.to(`call:${roomId}`).emit('call-ended', {
          endedBy: role,
          duration,
        });

        socket.leave(`call:${roomId}`);

        // Clean up room
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

        // Restore assigned lawyer availability whoever ends the call (citizen or lawyer).
        if (endedMeta?.assigned_lawyer_id) {
          await Lawyer.findByIdAndUpdate(endedMeta.assigned_lawyer_id, {
            is_available: true,
          }).catch(console.error);
        }

        console.log(`📞 [WebRTC] Call ended | room=${roomId} | by=${role} | ${duration}s`);
      } catch (err) {
        console.error('[WebRTC] call-ended error:', err);
      }
    });

    // ════════════════════════════════════════════════════════════
    //  disconnect — clean up open call rooms
    // ════════════════════════════════════════════════════════════
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
            // Both peers disconnected without a graceful `call-ended` — finalize DB state.
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
                console.error('[WebRTC] disconnect room cleanup:', e);
              }
            })();
          }
        }
      }
    });
  });
};
