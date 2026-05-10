// ============================================================
//  specializations.js — single source of truth for legal areas
//  VETO Legal Emergency App
//
//  Owns:
//    1. The canonical id (`criminal`, `traffic`, ...)
//    2. The Hebrew/English/Russian/Arabic display names
//    3. The matching rule used to filter Lawyer.specializations[]
//
//  Consumers (DO NOT redeclare any of this in their own files):
//    - dispatch.socket.js (lawyer matching for SOS)
//    - ai.controller.js   (LLM intent → matching lawyers)
//    - config.routes.js   → GET /api/config/specializations (web client)
// ============================================================

/**
 * Order matters — this is the order rendered in the SpecializationDialog.
 * `general` must stay last so the picker shows it as the catch-all.
 */
const SPECIALIZATIONS = [
  {
    id: 'criminal',
    label: { he: 'פלילי',  en: 'Criminal',     ru: 'Уголовное',     ar: 'جنائي' },
    matchTerms: ['criminal', 'Criminal', 'פלילי'],
  },
  {
    id: 'traffic',
    label: { he: 'תעבורה', en: 'Traffic',      ru: 'Транспорт',     ar: 'مرور' },
    matchTerms: ['traffic', 'Traffic', 'transportation', 'Transportation', 'תעבורה'],
  },
  {
    id: 'civil',
    label: { he: 'מסחרי',  en: 'Civil',        ru: 'Гражданское',   ar: 'مدني' },
    matchTerms: ['commercial', 'Commercial', 'civil', 'Civil', 'מסחרי'],
  },
  {
    id: 'family',
    label: { he: 'משפחה',  en: 'Family',       ru: 'Семейное',      ar: 'الأسرة' },
    matchTerms: ['family', 'Family', 'משפחה'],
  },
  {
    id: 'labor',
    label: { he: 'עבודה',  en: 'Labor',        ru: 'Трудовое',      ar: 'العمل' },
    matchTerms: ['labor', 'Labor', 'employment', 'Employment', 'עבודה'],
  },
  {
    id: 'realestate',
    label: { he: 'נדל״ן',  en: 'Real Estate',  ru: 'Недвижимость',  ar: 'عقارات' },
    matchTerms: ['real estate', 'Real Estate', 'realestate', 'RealEstate', 'נדל״ן', 'נדל"ן', 'נדלן'],
  },
  {
    id: 'general',
    label: { he: 'כללי',   en: 'General',      ru: 'Общее',         ar: 'عام' },
    /** General accepts any lawyer — no specialization filter. */
    matchTerms: [],
  },
];

const SPECIALIZATION_IDS = SPECIALIZATIONS.map((s) => s.id);

/**
 * Map of every accepted alias (id, Hebrew label, English label, every match term)
 * → canonical entry. Used by SOS dispatch & AI controller to normalize whatever
 * the caller sent (legacy clients still send Hebrew labels, AI returns English).
 */
function buildAliasMap() {
  const map = new Map();
  const lower = (s) => String(s).trim().toLowerCase();
  for (const spec of SPECIALIZATIONS) {
    map.set(lower(spec.id), spec);
    for (const lang of Object.keys(spec.label)) {
      map.set(lower(spec.label[lang]), spec);
    }
    for (const term of spec.matchTerms) {
      map.set(lower(term), spec);
    }
  }
  return map;
}

const ALIAS_MAP = buildAliasMap();

function findSpecialization(input) {
  if (!input) return null;
  const key = String(input).trim().toLowerCase();
  return ALIAS_MAP.get(key) || null;
}

/**
 * Returns an array of regex strings suitable for `{ $in: terms }` against
 * `Lawyer.specializations`. Returns null when the input is `general` or
 * unrecognised — caller should NOT add a specialization filter in that case.
 */
function getMatchTerms(input) {
  const spec = findSpecialization(input);
  if (!spec || spec.matchTerms.length === 0) return null;
  return spec.matchTerms;
}

module.exports = {
  SPECIALIZATIONS,
  SPECIALIZATION_IDS,
  findSpecialization,
  getMatchTerms,
};
