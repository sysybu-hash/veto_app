// ============================================================
//  email.service.js — optional SMTP (nodemailer)
//  Env: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM
// ============================================================

const logger = require('../lib/logger');

let _transporter;

function isConfigured() {
  return Boolean(process.env.SMTP_HOST && process.env.SMTP_FROM);
}

function getTransporter() {
  if (!isConfigured()) return null;
  if (_transporter) return _transporter;
  const nodemailer = require('nodemailer');
  _transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT) || 587,
    secure: String(process.env.SMTP_SECURE) === 'true' || Number(process.env.SMTP_PORT) === 465,
    auth: process.env.SMTP_USER
      ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS || '' }
      : undefined,
  });
  return _transporter;
}

/**
 * @param {{
 *   to: string,
 *   subject: string,
 *   text: string,
 *   html?: string,
 *   icsContent?: string,
 *   icsFilename?: string,
 *   attachments?: Array<{ filename: string, content: string|Buffer, contentType?: string }>,
 * }} p
 */
async function sendEmail({
  to,
  subject,
  text,
  html,
  icsContent,
  icsFilename = 'event.ics',
  attachments = [],
}) {
  const t = getTransporter();
  if (!t) {
    return { sent: false, reason: 'SMTP not configured' };
  }
  try {
    const mail = {
      from: process.env.SMTP_FROM,
      to,
      subject,
      text,
      html: html || undefined,
      attachments: [...attachments],
    };
    if (icsContent) {
      mail.attachments.push({
        filename: icsFilename,
        content: icsContent,
        contentType: 'text/calendar; charset=utf-8',
      });
    }
    await t.sendMail(mail);
    return { sent: true };
  } catch (e) {
    logger.error({ err: e }, '[EMAIL] failed');
    return { sent: false, reason: e.message };
  }
}

module.exports = { sendEmail, isConfigured, getTransporter };
