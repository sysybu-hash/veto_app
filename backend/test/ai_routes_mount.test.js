const test = require('node:test');
const assert = require('node:assert/strict');

test('AI routes expose POST /chat with middleware chain', () => {
  const router = require('../src/routes/ai.routes');
  assert.ok(router && router.stack && router.stack.length > 0);
  const chatPost = router.stack.find(
    (layer) =>
      layer.route &&
      layer.route.path === '/chat' &&
      layer.route.methods &&
      layer.route.methods.post,
  );
  assert.ok(chatPost, 'POST /chat route missing');
});
