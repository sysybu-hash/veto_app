const test = require('node:test');
const assert = require('node:assert/strict');

test('Legal documents routes expose POST /generate and /export', () => {
  const router = require('../src/routes/legalDocuments.routes');
  assert.ok(router && router.stack && router.stack.length > 0);

  const hasGenerate = router.stack.some(
    (layer) =>
      layer.route &&
      layer.route.path === '/generate' &&
      layer.route.methods &&
      layer.route.methods.post,
  );
  const hasExport = router.stack.some(
    (layer) =>
      layer.route &&
      layer.route.path === '/export' &&
      layer.route.methods &&
      layer.route.methods.post,
  );

  assert.ok(hasGenerate, 'POST /generate route missing');
  assert.ok(hasExport, 'POST /export route missing');
});

