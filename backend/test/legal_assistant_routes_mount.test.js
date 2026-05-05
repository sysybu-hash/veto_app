const test = require('node:test');
const assert = require('node:assert/strict');

test('Legal assistant routes expose POST /context-chat', () => {
  const router = require('../src/routes/legalAssistant.routes');
  assert.ok(router && router.stack && router.stack.length > 0);

  const hasContextChat = router.stack.some(
    (layer) =>
      layer.route &&
      layer.route.path === '/context-chat' &&
      layer.route.methods &&
      layer.route.methods.post,
  );

  assert.ok(hasContextChat, 'POST /context-chat route missing');
});

