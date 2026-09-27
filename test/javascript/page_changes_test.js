const { test, mock } = require('node:test');
const assert = require('node:assert/strict');
const { watchPageChanges } = require('../../public/javascripts/page-changes');

test('reports a change once and then stops polling', async (t) => {
  t.mock.timers.enable({ apis: ['setInterval'] });
  const answers = ['abc', 'def'];
  const fetch = mock.fn(async () => ({ ok: true, text: async () => answers.shift() }));
  t.mock.method(globalThis, 'fetch', fetch);
  let changes = 0;

  watchPageChanges('/page/sha1', 'abc', () => changes++, 1000);
  for (let i = 0; i < 3; i++) {
    t.mock.timers.tick(1000);
    await new Promise(setImmediate);
  }

  assert.equal(changes, 1);
  assert.equal(fetch.mock.callCount(), 2);
  assert.equal(fetch.mock.calls[0].arguments[0], '/page/sha1');
});

test('ignores failed requests', async (t) => {
  t.mock.timers.enable({ apis: ['setInterval'] });
  t.mock.method(globalThis, 'fetch', async () => ({ ok: false, text: async () => 'Not authorized' }));
  let changes = 0;

  const timer = watchPageChanges('/page/sha1', 'abc', () => changes++, 1000);
  t.mock.timers.tick(1000);
  await new Promise(setImmediate);
  clearInterval(timer);

  assert.equal(changes, 0);
});
