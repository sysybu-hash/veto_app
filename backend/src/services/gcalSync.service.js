// ============================================================
//  Google Calendar ↔ VETO sync (OAuth refresh + REST v3)
//  Conflict policy: export when local updatedAt > syncedAt or no mirror;
//  import upserts by googleEventId; cancelled remote → delete local.
// ============================================================

const { OAuth2Client } = require('google-auth-library');
const CalendarEvent = require('../models/CalendarEvent');
const User = require('../models/User');
const Lawyer = require('../models/Lawyer');
const { decryptToken } = require('../utils/gcalTokenCrypto.util');

const API_BASE = 'https://www.googleapis.com/calendar/v3';

function gcalEnv() {
  return {
    clientId: process.env.GOOGLE_CALENDAR_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CALENDAR_CLIENT_SECRET,
    redirectUri: process.env.GCAL_OAUTH_REDIRECT_URI,
  };
}

function lookaheadDays() {
  const n = parseInt(String(process.env.GCAL_SYNC_LOOKAHEAD_DAYS || '120'), 10);
  return Number.isFinite(n) && n > 1 ? n : 120;
}

function oauthClientWithRefresh(refreshToken) {
  const { clientId, clientSecret, redirectUri } = gcalEnv();
  if (!clientId || !clientSecret || !redirectUri) {
    throw new Error('Google Calendar OAuth env not configured');
  }
  const o = new OAuth2Client(clientId, clientSecret, redirectUri);
  o.setCredentials({ refresh_token: refreshToken });
  return o;
}

async function gcalRequest(oauth2, method, path, body) {
  const { token } = await oauth2.getAccessToken();
  if (!token) throw new Error('No access token from Google');
  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (res.status === 204) return {};
  const text = await res.text();
  let json = {};
  if (text) {
    try {
      json = JSON.parse(text);
    } catch {
      json = { raw: text };
    }
  }
  if (!res.ok) {
    const err = new Error(json.error?.message || res.statusText || 'Calendar API error');
    err.status = res.status;
    err.body = json;
    throw err;
  }
  return json;
}

function googleTimeToDate(t) {
  if (!t) return new Date();
  if (t.dateTime) return new Date(t.dateTime);
  if (t.date) return new Date(`${t.date}T12:00:00.000Z`);
  return new Date();
}

function vetoToGoogleEvent(ev) {
  const tz = ev.timezone || 'Asia/Jerusalem';
  return {
    summary: ev.title,
    description: ev.notes || undefined,
    location: ev.locationAddress || undefined,
    start: { dateTime: new Date(ev.start).toISOString(), timeZone: tz },
    end: { dateTime: new Date(ev.end).toISOString(), timeZone: tz },
  };
}

/**
 * @param {import('mongoose').Document} ev
 * @param {object} g
 * @param {string} calendarId
 */
async function applyGoogleEventToDoc(ev, g, calendarId) {
  ev.title = String(g.summary || 'Event').slice(0, 500);
  ev.start = googleTimeToDate(g.start);
  ev.end = googleTimeToDate(g.end);
  ev.notes = g.description ? String(g.description) : '';
  ev.locationAddress = g.location ? String(g.location) : '';
  ev.googleEventId = g.id;
  ev.googleCalendarId = calendarId;
  ev.googleEtag = g.etag || null;
  ev.syncedAt = new Date();
  ev.syncSource = 'google';
  await ev.save();
}

/**
 * Export local changes → Google.
 */
async function exportForAccount(oauth2, accountId, accountRole, calendarId) {
  const cal = encodeURIComponent(calendarId || 'primary');
  const list = await CalendarEvent.find({ accountId, accountRole });
  for (const ev of list) {
    const mustPush = !ev.googleEventId || !ev.syncedAt || ev.updatedAt > ev.syncedAt;
    if (!mustPush) continue;
    try {
      const body = vetoToGoogleEvent(ev);
      if (!ev.googleEventId) {
        const created = await gcalRequest(oauth2, 'POST', `/calendars/${cal}/events`, body);
        ev.googleEventId = created.id;
        ev.googleEtag = created.etag || null;
        ev.googleCalendarId = calendarId || 'primary';
        ev.syncedAt = new Date();
        await ev.save();
      } else {
        const eid = encodeURIComponent(ev.googleEventId);
        const updated = await gcalRequest(oauth2, 'PUT', `/calendars/${cal}/events/${eid}`, {
          ...body,
        });
        ev.googleEtag = updated.etag || ev.googleEtag;
        ev.syncedAt = new Date();
        await ev.save();
      }
    } catch (e) {
      console.error(
        `[gcal-sync] export fail account=${accountId} event=${ev._id}:`,
        e.message || e,
      );
    }
  }
}

/**
 * Import Google changes → Mongo (incremental when syncToken present).
 */
async function importForAccount(oauth2, doc, accountId, accountRole, calendarId) {
  const cal = encodeURIComponent(calendarId || 'primary');
  let syncToken = doc.gcalEventsSyncToken || null;
  const now = new Date();
  const min = new Date(now);
  min.setDate(min.getDate() - 7);
  const max = new Date(now);
  max.setDate(max.getDate() + lookaheadDays());

  const Model = accountRole === 'lawyer' ? Lawyer : User;

  function buildInitialPath() {
    let p = `/calendars/${cal}/events?singleEvents=true&maxResults=250`;
    if (syncToken) {
      p += `&syncToken=${encodeURIComponent(syncToken)}`;
    } else {
      p += `&timeMin=${encodeURIComponent(min.toISOString())}&timeMax=${encodeURIComponent(max.toISOString())}`;
    }
    return p;
  }

  let pageToken;
  let nextSyncToken;
  let tokenRetries = 0;

  for (;;) {
    let url;
    if (pageToken) {
      url = `/calendars/${cal}/events?pageToken=${encodeURIComponent(pageToken)}`;
    } else {
      url = buildInitialPath();
    }
    let data;
    try {
      data = await gcalRequest(oauth2, 'GET', url, null);
    } catch (e) {
      if (e.status === 410 && syncToken != null && tokenRetries < 2) {
        tokenRetries += 1;
        await Model.findByIdAndUpdate(accountId, { gcalEventsSyncToken: null });
        syncToken = null;
        pageToken = undefined;
        continue;
      }
      throw e;
    }
    const items = data.items || [];
    for (const g of items) {
      if (g.status === 'cancelled') {
        await CalendarEvent.findOneAndDelete({
          accountId,
          accountRole,
          googleEventId: g.id,
        });
        continue;
      }
      let ev = await CalendarEvent.findOne({ accountId, accountRole, googleEventId: g.id });
      if (!ev) {
        ev = new CalendarEvent({
          accountId,
          accountRole,
          title: String(g.summary || 'Event').slice(0, 500),
          type: 'other',
          start: googleTimeToDate(g.start),
          end: googleTimeToDate(g.end),
          timezone: 'Asia/Jerusalem',
          notes: g.description ? String(g.description) : '',
          locationAddress: g.location ? String(g.location) : '',
        });
      } else if (ev.syncSource === 'veto') {
        const gUpdated = g.updated ? new Date(g.updated) : new Date(0);
        if (ev.updatedAt > gUpdated) continue;
      }
      await applyGoogleEventToDoc(ev, g, calendarId || 'primary');
    }
    pageToken = data.nextPageToken;
    if (data.nextSyncToken) nextSyncToken = data.nextSyncToken;
    if (!pageToken) break;
  }

  if (nextSyncToken) {
    await Model.findByIdAndUpdate(accountId, {
      gcalEventsSyncToken: nextSyncToken,
      gcalLastSyncAt: new Date(),
    });
  } else {
    await Model.findByIdAndUpdate(accountId, { gcalLastSyncAt: new Date() });
  }
}

/**
 * @param {string} accountId
 * @param {'user'|'lawyer'|'admin'} accountRole
 */
async function syncOneAccount(accountId, accountRole) {
  const Model = accountRole === 'lawyer' ? Lawyer : User;
  const doc = await Model.findById(accountId).select('+gcalRefreshTokenEnc');
  if (!doc?.gcalRefreshTokenEnc) return { skipped: true };
  const refresh = decryptToken(doc.gcalRefreshTokenEnc);
  if (!refresh) {
    console.error(`[gcal-sync] decrypt failed account=${accountId}`);
    return { error: 'decrypt_failed' };
  }
  const oauth2 = oauthClientWithRefresh(refresh);
  const calendarId = doc.gcalCalendarId || 'primary';
  await importForAccount(oauth2, doc, accountId, accountRole, calendarId);
  await exportForAccount(oauth2, accountId, accountRole, calendarId);
  await Model.findByIdAndUpdate(accountId, { gcalLastSyncAt: new Date() });
  return { ok: true };
}

async function syncAllAccounts() {
  if (!gcalEnv().clientId) {
    console.warn('[gcal-sync] GOOGLE_CALENDAR_CLIENT_ID not set — skipping');
    return;
  }
  const users = await User.find({
    gcalRefreshTokenEnc: { $exists: true, $nin: [null, ''] },
  }).select('+gcalRefreshTokenEnc _id role');
  const lawyers = await Lawyer.find({
    gcalRefreshTokenEnc: { $exists: true, $nin: [null, ''] },
  }).select('+gcalRefreshTokenEnc _id');

  for (const u of users) {
    const role = u.role === 'admin' ? 'admin' : 'user';
    try {
      await syncOneAccount(String(u._id), role);
    } catch (e) {
      console.error(`[gcal-sync] user ${u._id}:`, e.message || e);
    }
  }
  for (const l of lawyers) {
    try {
      await syncOneAccount(String(l._id), 'lawyer');
    } catch (e) {
      console.error(`[gcal-sync] lawyer ${l._id}:`, e.message || e);
    }
  }
}

/**
 * Best-effort delete on Google when user deletes a VETO event (optional hook).
 */
async function deleteRemoteIfMirrored(accountId, accountRole, googleEventId, calendarId) {
  if (!googleEventId) return;
  try {
    const Model = accountRole === 'lawyer' ? Lawyer : User;
    const doc = await Model.findById(accountId).select('+gcalRefreshTokenEnc');
    if (!doc?.gcalRefreshTokenEnc) return;
    const refresh = decryptToken(doc.gcalRefreshTokenEnc);
    if (!refresh) return;
    const oauth2 = oauthClientWithRefresh(refresh);
    const cal = encodeURIComponent(calendarId || 'primary');
    const eid = encodeURIComponent(googleEventId);
    await gcalRequest(oauth2, 'DELETE', `/calendars/${cal}/events/${eid}`, null);
  } catch (e) {
    console.warn('[gcal-sync] deleteRemoteIfMirrored:', e.message || e);
  }
}

module.exports = {
  syncAllAccounts,
  syncOneAccount,
  deleteRemoteIfMirrored,
};
