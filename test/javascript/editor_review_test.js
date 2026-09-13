const { test } = require('node:test');
const assert = require('node:assert/strict');
const { diffLines } = require('../../public/javascripts/editor-review');

test('line comparison preserves both documents across edits and large replacements', () => {
  const examples = [
    ['', ''], ['', 'new'], ['old', ''],
    ['a\nb\nc', 'a\nx\nc'], ['a\na\nb', 'a\nb\na'],
    ['a\n', 'a'], ['<script>\n&', '<b>\n&'],
    ['a\nb\nc\nd', 'a\nx\nc\ny'],
    ['old\n'.repeat(1100), 'new\n'.repeat(1100)],
  ];
  for (const [original, draft] of examples) {
    const diff = diffLines(original, draft);
    assert.equal(diff.filter(line => line.type !== 'added').map(line => line.text).join('\n'), original);
    assert.equal(diff.filter(line => line.type !== 'removed').map(line => line.text).join('\n'), draft);
  }
  assert.deepEqual(diffLines('a\nb\nc', 'a\nx\nc'), [
    { type: 'context', text: 'a' },
    { type: 'removed', text: 'b' },
    { type: 'added', text: 'x' },
    { type: 'context', text: 'c' },
  ]);
});
