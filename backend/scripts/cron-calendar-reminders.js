/**
 * Calendar reminder worker — run every few minutes via cron/Render.
 *   cd backend && node scripts/cron-calendar-reminders.js
 *
 * Catches events where (start - beforeMin) is in the next [WINDOW_MIN] minutes.
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
require('dotenv').config({ path: path.join(__dirname, '../.env.local'), override: true });

const mongoose = require('mongoose');
const CalendarEvent = require('../src/models/CalendarEvent');
const { sendEmail, isConfigured: smtpOk } = require('../src/services/email.service');
const { notifyAccount } = require('../src/services/notificationDispatcher');
const { getAccountEmail } = require('../src/utils/calendarAccount.util');

const WINDOW_MIN = Math.max(1, parseInt(process.env.CALENDAR_REMINDER_WINDOW_MIN || '8', 10) || 8);

function wasSent(ev, beforeMin, ch) {
  return (ev.remindersFired || []).some(
    (r) => r.beforeMinutes === beforeMin && r.channel === ch,
  );
}

async function run() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    console.error('MONGO_URI missing');
    process.exit(1);
  }
  await mongoose.connect(uri);
  const now = new Date();
  const winEnd = new Date(now.getTime() + WINDOW_MIN * 60 * 1000);
  const evs = await CalendarEvent.find({
    start: { $gt: now, $lt: new Date(now.getTime() + 2 * 86400 * 1000) },
    'reminderBeforeMinutes.0': { $exists: true },
  }).limit(2000);
  let sent = 0;
  for (const ev of evs) {
    let changed = false;
    for (const beforeMin of ev.reminderBeforeMinutes || []) {
      const fireAt = new Date(ev.start.getTime() - beforeMin * 60 * 1000);
      if (fireAt < now || fireAt > winEnd) continue;

      if (smtpOk()) {
        const { email, fullName } = await getAccountEmail(ev.accountId, ev.accountRole);
        if (email && !wasSent(ev, beforeMin, 'email')) {
          const r = await sendEmail({
            to: email,
            subject: `[VETO] Reminder: ${ev.title} (${beforeMin} min)`,
            text: `שלום${fullName ? ' ' + fullName : ''}\n\nהאירוע מתחיל ב: ${ev.start.toISOString()}\n${ev.locationAddress || ''}\n\n${ev.notes || ''}`,
          });
          if (r.sent) {
            ev.remindersFired.push({ at: new Date(), beforeMinutes: beforeMin, channel: 'email' });
            changed = true;
            sent += 1;
          }
        }
      }
      if (!wasSent(ev, beforeMin, 'push')) {
        await notifyAccount({
          accountId: ev.accountId,
          accountRole: ev.accountRole,
          title: 'VETO — אירוע בקרוב',
          body: `${ev.title} — עוד ${beforeMin} דק׳`,
          data: { type: 'calendar', eventId: String(ev._id) },
        });
        ev.remindersFired.push({ at: new Date(), beforeMinutes: beforeMin, channel: 'push' });
        changed = true;
        sent += 1;
      }
    }
    if (changed) await ev.save();
  }
  await mongoose.disconnect();
  console.log(`[cron-calendar] events scanned: ${evs.length}, channel sends: ${sent} (window ${WINDOW_MIN}m)`);
  process.exit(0);
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
