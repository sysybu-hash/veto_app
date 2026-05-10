// ============================================================
//  access.service.js
//  Centralised authorisation helper for everything related to
//  an EmergencyEvent. Used by call.controller.js and the v2
//  endpoints (consent, transcript, chat-history, file-share).
// ============================================================

/**
 * @param {{ user_id?: any, assigned_lawyer_id?: any }} event
 * @param {{ userId: string, role: 'user'|'lawyer'|'admin' }} user
 * @returns {boolean}
 */
function canAccessEvent(event, user) {
  if (!event || !user) return false;
  const uid = String(user.userId);
  const isUser =
    (user.role === 'user' || user.role === 'admin') &&
    event.user_id?.toString() === uid;
  const isLawyer =
    user.role === 'lawyer' && event.assigned_lawyer_id?.toString() === uid;
  return isUser || isLawyer || user.role === 'admin';
}

module.exports = { canAccessEvent };
