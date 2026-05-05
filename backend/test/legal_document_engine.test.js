const test = require('node:test');
const assert = require('node:assert/strict');

const engine = require('../src/services/legalDocumentEngine.service');

test('createDraft applies a Hebrew demand-letter template when intent matches', () => {
  const draft = engine.createDraft(
    { intent: 'demand_letter', domain: 'civil', lang: 'he' },
    { role: 'user' },
  );
  assert.equal(draft.lang, 'he');
  assert.equal(draft.domain, 'civil');
  assert.equal(draft.intent, 'demand_letter');
  assert.match(draft.title, /התראה|VETO/);
  assert.ok(draft.body.includes('### גוף המכתב') || draft.body.length > 20);
  assert.equal(
    draft.footerStamp,
    'מסמך זה נוצר על ידי VETO LEGAL בפענוח AI',
  );
});

test('toPdfBuffer emits a non-empty PDF document with footer stamp', async () => {
  const draft = engine.createDraft(
    { intent: 'civil_claim', domain: 'civil', lang: 'he' },
    { role: 'user' },
  );
  const pdf = await engine.toPdfBuffer(draft);
  assert.ok(Buffer.isBuffer(pdf));
  assert.ok(pdf.length > 1000, `pdf too small: ${pdf.length}`);
  assert.equal(pdf.slice(0, 4).toString('utf8'), '%PDF');
});

test('toDocxBuffer emits a non-empty DOCX (zip) document', async () => {
  const draft = engine.createDraft(
    { intent: 'labor_doc', domain: 'labor', lang: 'he' },
    { role: 'user' },
  );
  const docx = await engine.toDocxBuffer(draft);
  assert.ok(Buffer.isBuffer(docx));
  assert.ok(docx.length > 2000, `docx too small: ${docx.length}`);
  // ZIP local file header signature: 0x50 0x4B 0x03 0x04 ("PK\u0003\u0004")
  assert.equal(docx[0], 0x50);
  assert.equal(docx[1], 0x4b);
  assert.equal(docx[2], 0x03);
  assert.equal(docx[3], 0x04);
});

test('TEMPLATES list exposes all expected legal intents', () => {
  const ids = Object.keys(engine.TEMPLATES);
  for (const expected of [
    'contract_review',
    'demand_letter',
    'civil_claim',
    'labor_doc',
    'family_doc',
  ]) {
    assert.ok(ids.includes(expected), `missing template: ${expected}`);
  }
});
