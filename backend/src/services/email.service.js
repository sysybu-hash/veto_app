// ============================================================
//  email.service.js — optional SMTP (nodemailer)
//  Env: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM
// ============================================================

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
 * @param {{ to: string, subject: string, text: string, icsContent?: string, icsFilename?: string }} p
 */
async function sendEmail({ to, subject, text, icsContent, icsFilename = 'event.ics' }) {
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
    };
    if (icsContent) {
      mail.attachments = [
        {
          filename: icsFilename,
          content: icsContent,
          contentType: 'text/calendar; charset=utf-8',
        },
      ];
    }
    await t.sendMail(mail);
    return { sent: true };
  } catch (e) {
    console.error('[EMAIL]', e.message);
    return { sent: false, reason: e.message };
  }
}

module.exports = { sendEmail, isConfigured, getTransporter };
