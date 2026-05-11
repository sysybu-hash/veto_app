// ============================================================
//  transcript.service.js
//  Sanitisation helpers for transcripts produced by Gemini /
//  Agora RTT. Removes emoji, model stage directions, and the
//  occasional code fence that slips into the output.
// ============================================================

/**
 * Cleans a transcript string in-place.
 * - Strips markdown code fences.
 * - Removes Unicode emoji (extended pictographic) with a safe fallback.
 * - Drops common "stage directions" like [inaudible] or (laughter).
 * - Collapses runs of whitespace.
 *
 * @param {string} raw
 * @returns {string}
 */
function sanitizeTranscript(raw) {
  if (!raw || typeof raw !== 'string') return '';
  let t = raw.trim();

  t = t.replace(/```[\s\S]*?```/g, (m) => m.replace(/```/g, '')).trim();

  try {
    t = t.replace(/\p{Extended_Pictographic}/gu, '');
  } catch {
    t = t.replace(/[\uD83C-\uDBFF][\uDC00-\uDFFF]/g, '');
  }

  t = t
    .replace(/\b(emoji|emojis|smiley|smileys|emoticon|emoticons)\b/gi, '')
    // Hebrew word boundaries don't match `\b` so we anchor on whitespace /
    // string edges manually instead.
    .replace(
      /(^|\s)(סמיילי|סמיילים|אימוג'?י|אימוג'ים)(?=\s|$|[.,;:!?"'()])/g,
      '$1',
    )
    .replace(
      /\[(?:inaudible|applause|music|laughter|laughs|crying|sighs|coughs|background noise|noise)[^\]]*\]/gi,
      '',
    )
    .replace(
      /\((?:inaudible|applause|music|laughter|laughs|crying|sighs|coughs|background noise|noise)[^)]*\)/gi,
      '',
    );

  t = t
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/[ \t]{2,}/g, ' ')
    .trim();
  return t;
}

module.exports = { sanitizeTranscript };
