const test = require('node:test');
const assert = require('node:assert/strict');

test('citizen-dashboard router mounts summary, reports, CRUD paths', () => {
  const router = require('../src/routes/citizenDashboard.routes');
  assert.ok(router && router.stack && router.stack.length > 0);

  const paths = new Set();
  for (const layer of router.stack) {
    if (layer.route && layer.route.path) {
      paths.add(layer.route.methods.get ? `GET ${layer.route.path}` : '');
      paths.add(layer.route.methods.post ? `POST ${layer.route.path}` : '');
      paths.add(layer.route.methods.patch ? `PATCH ${layer.route.path}` : '');
      paths.add(layer.route.methods.delete ? `DELETE ${layer.route.path}` : '');
    }
  }
  const flat = [...paths].filter(Boolean);
  assert.ok(flat.some((p) => p.includes('/summary')), 'GET /summary');
  assert.ok(flat.some((p) => p.includes('/reports/summary')), 'GET /reports/summary');
  assert.ok(flat.some((p) => p === 'GET /contracts'), 'GET /contracts');
  assert.ok(flat.some((p) => p === 'POST /contracts'), 'POST /contracts');
  assert.ok(flat.some((p) => p.startsWith('PATCH /contracts')), 'PATCH /contracts/:id');
  assert.ok(flat.some((p) => p.startsWith('DELETE /contracts')), 'DELETE /contracts/:id');
  assert.ok(flat.some((p) => p === 'PATCH /notifications/:id/read'), 'PATCH notifications read');
});
