// ============================================================
//  calendar.controller.js
// ============================================================

const mongoose = require('mongoose');
const CalendarEvent = require('../models/CalendarEvent');
const { buildIcsCalendar, singleEventIcs } = require('../utils/ics.util');
const { accountFromReq, ensureIcalFeedToken, getAccountEmail } = require('../utils/calendarAccount.util');
const { sendEmail, isConfigured: smtpOk } = require('../services/email.service');

function parseCaseId(body) {
  if (body.sourceCaseId == null || String(body.sourceCaseId) === '' || String(body.sourceCaseId) === 'null') {
    return null;
  }
  if (!mongoose.Types.ObjectId.isValid(String(body.sourceCaseId))) {
    return { error: 'Invalid sourceCaseId' };
  }
  return body.sourceCaseId;
}

exports.listEvents = async (req, res, next) => {
  try {
    const { year, month } = req.query;
    if (!year || !month) {
      return res.status(400).json({ error: 'query year and month are required (month 1-12)' });
    }
    const y = parseInt(String(year), 10);
    const m = parseInt(String(month), 10);
    if (!Number.isFinite(y) || m < 1 || m > 12) {
      return res.status(400).json({ error: 'Invalid year/month' });
    }
    const { accountId, accountRole } = accountFromReq(req);
    const from = new Date(y, m - 1, 1);
    const to = new Date(y, m, 0, 23, 59, 59, 999);
    const events = await CalendarEvent.find({
      accountId,
      accountRole,
      start: { $lte: to },
      end: { $gte: from },
    }).sort({ start: 1 });
    res.json({ events });
  } catch (err) {
    next(err);
  }
};

exports.getFeedInfo = async (req, res, next) => {
  try {
    const { accountId, accountRole } = accountFromReq(req);
    const token = await ensureIcalFeedToken(accountId, accountRole);
    if (!token) return res.status(404).json({ error: 'Account not found' });
    const base = (process.env.PUBLIC_API_BASE || process.env.VETO_PUBLIC_BASE || '').replace(/\/$/, '');
    const origin = base || '';
    res.json({
      token,
      webcalUrl: `${origin ? `${origin}` : ''}/api/calendar/export.ics?token=${encodeURIComponent(token)}`,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Public — GET /api/calendar/export.ics?token=
 */
exports.exportIcs = async (req, res, next) => {
  try {
    const { token } = req.query;
    if (!token || String(token).length < 8) {
      return res.status(400).type('text/plain').send('Bad token');
    }
    const User = require('../models/User');
    const Lawyer = require('../models/Lawyer');
    const u = await User.findOne({ icalFeedToken: token });
    const l = u ? null : await Lawyer.findOne({ icalFeedToken: token });
    if (!u && !l) {
      return res.status(404).type('text/plain').send('Not found');
    }
    const accountId = u?._id || l._id;
    const accountRole = u
      ? u.role === 'admin'
        ? 'admin'
        : 'user'
      : 'lawyer';
    const now = new Date();
    const later = new Date();
    later.setFullYear(later.getFullYear() + 1);
    const list = await CalendarEvent.find({
      accountId,
      accountRole,
      end: { $gte: now },
    })
      .where('start')
      .lte(later)
      .sort({ start: 1 })
      .limit(500);
    const events = list.map((e) => ({
      uid: `veto-${e._id}@veto-legal`,
      title: e.title,
      start: e.start,
      end: e.end,
      location: e.locationAddress || undefined,
      notes: e.notes || undefined,
    }));
    const body = buildIcsCalendar({ calName: 'VETO', events });
    res.set('Content-Type', 'text/calendar; charset=utf-8');
    res.set('Content-Disposition', 'inline; filename="veto.ics"');
    res.send(body);
  } catch (err) {
    next(err);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(String(req.params.id))) {
      return res.status(400).json({ error: 'Invalid id' });
    }
    const { accountId, accountRole } = accountFromReq(req);
    const ev = await CalendarEvent.findOne({ _id: req.params.id, accountId, accountRole });
    if (!ev) return res.status(404).json({ error: 'Event not found' });
    res.json(ev);
  } catch (err) {
    next(err);
  }
};

exports.createEvent = async (req, res, next) => {
  try {
    const { title, type, start, end, timezone, locationAddress, locationLatLng, reminderBeforeMinutes, notes, sourceCaseId: rawCase } = req.body;
    if (!title || !start || !end) {
      return res.status(400).json({ error: 'title, start, and end are required' });
    }
    let c = null;
    if (rawCase != null && String(rawCase) !== '' && String(rawCase) !== 'null') {
      const p = parseCaseId(req.body);
      if (p && p.error) return res.status(400).json({ error: p.error });
      c = p;
    }
    const { accountId, accountRole } = accountFromReq(req);
    const ev = await CalendarEvent.create({
      accountId,
      accountRole,
      title: String(title).trim(),
      type: type && ['hearing', 'meeting', 'other'].includes(type) ? type : 'other',
      start: new Date(start),
      end: new Date(end),
      timezone: timezone || 'Asia/Jerusalem',
      locationAddress: locationAddress == null ? '' : String(locationAddress),
      locationLatLng:
        locationLatLng && typeof locationLatLng === 'object'
          ? { lat: Number(locationLatLng.lat) || null, lng: Number(locationLatLng.lng) || null }
          : { lat: null, lng: null },
      reminderBeforeMinutes: Array.isArray(reminderBeforeMinutes)
        ? reminderBeforeMinutes.map((x) => parseInt(x, 10)).filter((n) => !Number.isNaN(n) && n >= 0)
        : [],
      notes: notes == null ? '' : String(notes),
      sourceCaseId: c,
    });
    if (smtpOk()) {
      const { email, fullName } = await getAccountEmail(accountId, accountRole);
      if (email) {
        const ics = singleEventIcs({
          title: ev.title,
          start: ev.start,
          end: ev.end,
          location: ev.locationAddress,
          notes: ev.notes,
          uid: `veto-${ev._id}@veto-legal`,
        });
        const subj = `[VETO] ${ev.title} — event added`;
        await sendEmail({
          to: email,
          subject: subj,
          text: `Hello${fullName ? ' ' + fullName : ''},\n\nA calendar event was created in VETO.\n`,
          icsContent: ics,
        });
      }
    }
    res.status(201).json(ev);
  } catch (err) {
    next(err);
  }
};

exports.updateEvent = async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(String(req.params.id))) {
      return res.status(400).json({ error: 'Invalid id' });
    }
    const { accountId, accountRole } = accountFromReq(req);
    const ev = await CalendarEvent.findOne({ _id: req.params.id, accountId, accountRole });
    if (!ev) return res.status(404).json({ error: 'Event not found' });

    const f = [
      'title',
      'type',
      'start',
      'end',
      'timezone',
      'locationAddress',
      'reminderBeforeMinutes',
      'notes',
    ];
    for (const k of f) {
      if (req.body[k] !== undefined) {
        if (k === 'start' || k === 'end') {
          ev[k] = new Date(req.body[k]);
        } else if (k === 'reminderBeforeMinutes' && Array.isArray(req.body[k])) {
          ev[k] = req.body[k]
            .map((x) => parseInt(x, 10))
            .filter((n) => !Number.isNaN(n) && n >= 0);
        } else {
          ev[k] = req.body[k];
        }
      }
    }
    if (req.body.locationLatLng && typeof req.body.locationLatLng === 'object') {
      ev.locationLatLng = {
        lat: Number(req.body.locationLatLng.lat) || null,
        lng: Number(req.body.locationLatLng.lng) || null,
      };
    }
    if (req.body.sourceCaseId !== undefined) {
      const c = parseCaseId(req.body);
      if (c && c.error) return res.status(400).json({ error: c.error });
      ev.sourceCaseId = c;
    }
    await ev.save();

    if (smtpOk()) {
      const { email, fullName } = await getAccountEmail(accountId, accountRole);
      if (email) {
        const ics = singleEventIcs({
          title: ev.title,
          start: ev.start,
          end: ev.end,
          location: ev.locationAddress,
          notes: ev.notes,
          uid: `veto-${ev._id}@veto-legal`,
        });
        await sendEmail({
          to: email,
          subject: `[VETO] Updated: ${ev.title}`,
          text: `Hello${fullName ? ' ' + fullName : ''},\n\nA calendar event was updated in VETO.\n`,
          icsContent: ics,
        });
      }
    }
    res.json(ev);
  } catch (err) {
    next(err);
  }
};

exports.deleteEvent = async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(String(req.params.id))) {
      return res.status(400).json({ error: 'Invalid id' });
    }
    const { accountId, accountRole } = accountFromReq(req);
    const ev = await CalendarEvent.findOneAndDelete({ _id: req.params.id, accountId, accountRole });
    if (!ev) return res.status(404).json({ error: 'Event not found' });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};

module.exports = exports;
