// ============================================================
//  ics.util.js — minimal iCalendar VEVENT (single event or feed)
// ============================================================

const crypto = require('crypto');

function esc(s) {
  if (s == null) return '';
  return String(s)
    .replace(/\\/g, '\\\\')
    .replace(/;/g, '\\;')
    .replace(/,/g, '\\,')
    .replace(/\r?\n/g, '\\n');
}

/**
 * @param {Array<{uid:string, title:string, start:Date, end:Date, location?:string, notes?:string, dtStamp?:Date}>} events
 */
function buildIcsCalendar({ events, calName = 'VETO Legal' }) {
  const lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//VETO//Legal Calendar//EN',
    `X-WR-CALNAME:${esc(calName)}`,
    'CALSCALE:GREGORIAN',
  ];
  for (const e of events) {
    const uid = e.uid || `veto-${crypto.randomBytes(8).toString('hex')}@veto-legal`;
    const dtStamp = toUtcIcs(e.dtStamp || new Date());
    const s = toUtcIcs(e.start);
    const end = toUtcIcs(e.end);
    lines.push('BEGIN:VEVENT');
    lines.push(`UID:${esc(uid)}`);
    lines.push(`DTSTAMP:${dtStamp}`);
    lines.push(`DTSTART:${s}`);
    lines.push(`DTEND:${end}`);
    lines.push(`SUMMARY:${esc(e.title)}`);
    if (e.location) lines.push(`LOCATION:${esc(e.location)}`);
    if (e.notes) lines.push(`DESCRIPTION:${esc(e.notes)}`);
    lines.push('END:VEVENT');
  }
  lines.push('END:VCALENDAR');
  return lines.join('\r\n') + '\r\n';
}

function toUtcIcs(d) {
  const x = d instanceof Date ? d : new Date(d);
  const p = (n) => String(n).padStart(2, '0');
  const y = x.getUTCFullYear();
  const m = p(x.getUTCMonth() + 1);
  const day = p(x.getUTCDate());
  const h = p(x.getUTCHours());
  const min = p(x.getUTCMinutes());
  const s = p(x.getUTCSeconds());
  return `${y}${m}${day}T${h}${min}${s}Z`;
}

function singleEventIcs({ title, start, end, location, notes, uid }) {
  return buildIcsCalendar({
    calName: 'VETO',
    events: [
      { uid, title, start, end, location, notes, dtStamp: new Date() },
    ],
  });
}

module.exports = { buildIcsCalendar, singleEventIcs, esc, toUtcIcs };
