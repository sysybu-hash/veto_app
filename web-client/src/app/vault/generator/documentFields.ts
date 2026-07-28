// ============================================================
//  documentFields.ts — per-document-type structured field config
//  for the "מחולל מסמכים משפטיים" generator UI.
//
//  Each document type picks a small set of parties (rendered as a
//  table: name / ID number / address) and a few extra flat fields
//  from a shared vocabulary (amount / date / textarea), instead of
//  a fully bespoke schema per type.
// ============================================================

export type FieldDef = {
  key: string;
  label: string;
  type: "text" | "date" | "textarea";
  placeholder?: string;
};

export type DocumentFieldsConfig = {
  partyLabels: string[];
  fields: FieldDef[];
};

const DEFAULT_CONFIG: DocumentFieldsConfig = {
  partyLabels: ["צד א׳", "צד ב׳"],
  fields: [
    { key: "amount", label: "סכום רלוונטי", type: "text", placeholder: "לדוגמה: 5,000 ש\"ח" },
    { key: "date", label: "תאריך רלוונטי", type: "date" },
    { key: "agreed", label: "מה סוכם", type: "textarea" },
    { key: "breach", label: "מה הופר", type: "textarea" },
  ],
};

export const DOCUMENT_TYPE_FIELDS: Record<string, DocumentFieldsConfig> = {
  warning_letter: {
    partyLabels: ["שולח", "נמען"],
    fields: [
      { key: "amount", label: "סכום הדרישה", type: "text", placeholder: "לדוגמה: 12,000 ש\"ח" },
      { key: "deadlineDate", label: "מועד לתיקון ההפרה", type: "date" },
      { key: "agreed", label: "מה סוכם", type: "textarea" },
      { key: "breach", label: "מה הופר", type: "textarea" },
    ],
  },
  cease_and_desist: {
    partyLabels: ["שולח", "נמען"],
    fields: [
      { key: "breachDate", label: "תאריך ההפרה", type: "date" },
      { key: "agreed", label: "מה סוכם / מה הזכות שנפגעה", type: "textarea" },
      { key: "breach", label: "מה הופר", type: "textarea" },
    ],
  },
  lease_agreement: {
    partyLabels: ["משכיר", "שוכר"],
    fields: [
      { key: "amount", label: "דמי שכירות", type: "text", placeholder: "לדוגמה: 4,500 ש\"ח לחודש" },
      { key: "startDate", label: "תחילת תקופת השכירות", type: "date" },
      { key: "endDate", label: "סיום תקופת השכירות", type: "date" },
      { key: "agreed", label: "מה סוכם", type: "textarea" },
    ],
  },
  nda: {
    partyLabels: ["צד א׳", "צד ב׳"],
    fields: [
      { key: "startDate", label: "תאריך תחילה", type: "date" },
      { key: "agreed", label: "מה סוכם", type: "textarea" },
    ],
  },
  employment: {
    partyLabels: ["מעסיק", "עובד"],
    fields: [
      { key: "amount", label: "שכר", type: "text", placeholder: "לדוגמה: 12,000 ש\"ח לחודש" },
      { key: "startDate", label: "תאריך תחילת העסקה", type: "date" },
      { key: "agreed", label: "מה סוכם", type: "textarea" },
    ],
  },
  loan_agreement: {
    partyLabels: ["מלווה", "לווה"],
    fields: [
      { key: "amount", label: "סכום ההלוואה", type: "text", placeholder: "לדוגמה: 20,000 ש\"ח" },
      { key: "dueDate", label: "מועד החזר", type: "date" },
      { key: "agreed", label: "מה סוכם", type: "textarea" },
    ],
  },
  power_of_attorney: {
    partyLabels: ["מייפה כוח", "מיופה כוח"],
    fields: [
      { key: "date", label: "תאריך", type: "date" },
      { key: "agreed", label: "מה מוקנה בייפוי הכוח", type: "textarea" },
    ],
  },
  family_estate: {
    partyLabels: ["צד א׳", "צד ב׳"],
    fields: [
      { key: "date", label: "תאריך רלוונטי", type: "date" },
      { key: "agreed", label: "מה סוכם / רצון הצדדים", type: "textarea" },
    ],
  },
  tort_insurance: {
    partyLabels: ["נפגע/תובע", "גורם אחראי/מבטח"],
    fields: [
      { key: "amount", label: "סכום הנזק הנתבע", type: "text" },
      { key: "eventDate", label: "תאריך האירוע", type: "date" },
      { key: "breach", label: "מה קרה / מה הופר", type: "textarea" },
    ],
  },
  consumer_privacy: {
    partyLabels: ["צרכן/נושא המידע", "עסק/גוף"],
    fields: [
      { key: "amount", label: "סכום רלוונטי (אם יש)", type: "text" },
      { key: "eventDate", label: "תאריך האירוע/העסקה", type: "date" },
      { key: "breach", label: "מה הופר", type: "textarea" },
    ],
  },
  commercial: {
    partyLabels: ["צד א׳", "צד ב׳"],
    fields: [
      { key: "amount", label: "סכום/תמורה", type: "text" },
      { key: "date", label: "תאריך רלוונטי", type: "date" },
      { key: "agreed", label: "מה סוכם", type: "textarea" },
    ],
  },
  authority_request: {
    partyLabels: ["פונה", "רשות/גוף"],
    fields: [
      { key: "date", label: "תאריך", type: "date" },
      { key: "agreed", label: "נושא הבקשה", type: "textarea" },
    ],
  },
  custom: DEFAULT_CONFIG,
};

export function getDocumentFieldsConfig(documentType: string): DocumentFieldsConfig {
  return DOCUMENT_TYPE_FIELDS[documentType] || DEFAULT_CONFIG;
}

export type PartyRow = { name: string; idNumber: string; address: string };

export function emptyParties(count: number): PartyRow[] {
  return Array.from({ length: count }, () => ({ name: "", idNumber: "", address: "" }));
}
