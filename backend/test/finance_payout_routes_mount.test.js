const test = require('node:test');
const assert = require('node:assert/strict');

test('admin finance payout routes are mounted', () => {
  const router = require('../src/routes/admin.routes');
  assert.ok(router?.stack?.length > 0);

  const paths = router.stack
    .filter((layer) => layer.route)
    .map((layer) => ({
      path: layer.route.path,
      methods: Object.keys(layer.route.methods || {}),
    }));

  const need = [
    { path: '/finance/lawyers', method: 'get' },
    { path: '/finance/lawyer-earnings/sync', method: 'post' },
    { path: '/finance/lawyers/:lawyerId/earnings', method: 'get' },
    { path: '/finance/lawyers/:lawyerId/payout-profile', method: 'patch' },
    { path: '/finance/payouts', method: 'get' },
    { path: '/finance/payouts', method: 'post' },
    { path: '/finance/payouts/:batchId/paid', method: 'patch' },
    { path: '/finance/payouts/:batchId/cancel', method: 'patch' },
    { path: '/finance/lawyer-earnings/export', method: 'get' },
  ];

  for (const n of need) {
    const hit = paths.find(
      (p) => p.path === n.path && p.methods.includes(n.method),
    );
    assert.ok(hit, `missing ${n.method.toUpperCase()} ${n.path}`);
  }
});

test('lawyerPayout service exports core API', () => {
  const svc = require('../src/services/lawyerPayout.service');
  for (const fn of [
    'upsertEarningFromEvent',
    'syncEarningsFromEvents',
    'listLawyerFinanceSummary',
    'createPayoutBatch',
    'markPayoutPaid',
    'cancelPayoutBatch',
    'listPayoutBatches',
    'updateLawyerPayoutProfile',
    'payoutSettingsPublic',
  ]) {
    assert.equal(typeof svc[fn], 'function', fn);
  }
  const settings = svc.payoutSettingsPublic();
  assert.ok(Number.isFinite(settings.callFeeIls));
  assert.ok(settings.overtimeShare > 0 && settings.overtimeShare <= 1);
});
