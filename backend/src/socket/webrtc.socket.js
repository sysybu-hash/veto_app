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

        // Authorization check
        const isUser   = role === 'user'   && event.user_id?.toString() === userId;
        const isLawyer = role === 'lawyer' && event.assigned_lawyer_id?.toString() === userId;
        const isAdmin  = role === 'admin';
        if (!isUser && !isLawyer && !isAdmin) {
          return socket.emit('call-error', { message: 'Not authorized for this call.' });
        }

        const roomKey = `call:${roomId}`;
        socket.join(roomKey);

        // Initialize room record
        if (!callRooms.has(roomId)) {
          callRooms.set(roomId, {
            participants: new Set(),
            callType: callType || 'video',
            startedAt: new Date(),
          });
          // Update event status to in-progress once a real call room is created
          await EmergencyEvent.findByIdAndUpdate(roomId, {
            status: 'in_progress',
            call_type: callType || 'video',
            call_started_at: new Date(),
          });
        }

        const room = callRooms.get(roomId);
        room.participants.add(socket.id);

        // Tell others someone joined (triggers offer creation)
        socket.to(roomKey).emit('peer-joined', {
          userId,
          role,
          socketId: socket.id,
          callType: room.callType,
        });

        // Count active sockets in room
        const roomSockets = await io.in(roomKey).allSockets();
        socket.emit('room-joined', {
          roomId,
          socketId: socket.id,
          participantCount: roomSockets.size,
          callType: room.callType,
          isCaller: roomSockets.size === 1, // first to join = caller (creates offer)
        });

        console.log(`📞 [WebRTC] ${role} ${userId} joined room:${roomId} | participants: ${roomSockets.size}`);
      } catch (err) {
        console.error('[WebRTC] join-call-room error:', err);
        socket.emit('call-error', { message: 'Failed to join call room.' });
      }
    });

    // ════════════════════════════════════════════════════════════
    //  webrtc-offer
    //  Emitted by: Caller (first peer) → to Callee
    //  Payload:    { roomId, offer: RTCSessionDescription, targetSocketId }
    // ════════════════════════════════════════════════════════════
    socket.on('webrtc-offer', ({ roomId, offer, targetSocketId }) => {
      const target = targetSocketId ? targetSocketId : `call:${roomId}`;
      const to = targetSocketId ? socket.to(targetSocketId) : socket.to(`call:${roomId}`);
      to.emit('webrtc-offer', {
        offer,
        fromSocketId: socket.id,
        fromUserId: userId,
        fromRole: role,
      });
    });

    // ════════════════════════════════════════════════════════════
    //  webrtc-answer
    //  Emitted by: Callee → to Caller
    //  Payload:    { roomId, answer: RTCSessionDescription, targetSocketId }
    // ════════════════════════════════════════════════════════════
    socket.on('webrtc-answer', ({ roomId, answer, targetSocketId }) => {
      const to = targetSocketId ? socket.to(targetSocketId) : socket.to(`call:${roomId}`);
      to.emit('webrtc-answer', {
        answer,
        fromSocketId: socket.id,
      });
    });

    // ════════════════════════════════════════════════════════════
    //  ice-candidate
    //  Emitted by: Both peers during ICE negotiation
    //  Payload:    { roomId, candidate: RTCIceCandidate, targetSocketId }
    // ════════════════════════════════════════════════════════════
    socket.on('ice-candidate', ({ roomId, candidate, targetSocketId }) => {
      const to = targetSocketId ? socket.to(targetSocketId) : socket.to(`call:${roomId}`);
      to.emit('ice-candidate', {
        candidate,
        fromSocketId: socket.id,
      });
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

        // Update event in DB
        await EmergencyEvent.findByIdAndUpdate(roomId, {
          status:                  'completed',
          completed_at:            new Date(),
          call_duration_seconds:   duration || 0,
        });

        // Make lawyer available again
        if (role === 'lawyer') {
          await Lawyer.findByIdAndUpdate(userId, { is_available: true });
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
          }
        }
      }
    });
  });
};
