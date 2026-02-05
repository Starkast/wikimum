const { test } = require('node:test');
const assert = require('node:assert');
const { extractBareUrls } = require('../../public/javascripts/link_titles.js');

test('extracts simple URL', () => {
  const content = 'Check out https://example.com for more info';
  const urls = extractBareUrls(content);
  assert.deepStrictEqual(urls, ['https://example.com']);
});

test('extracts multiple URLs', () => {
  const content = 'See https://example.com and http://test.org';
  const urls = extractBareUrls(content);
  assert.deepStrictEqual(urls, ['https://example.com', 'http://test.org']);
});

test('ignores URLs in markdown links', () => {
  const content = 'Check [Example](https://example.com) for info';
  const urls = extractBareUrls(content);
  assert.deepStrictEqual(urls, []);
});

test('extracts bare URL but ignores same URL in markdown link', () => {
  const content = 'Visit https://bare.com and [Linked](https://linked.com)';
  const urls = extractBareUrls(content);
  assert.deepStrictEqual(urls, ['https://bare.com']);
});

test('deduplicates URLs', () => {
  const content = 'https://example.com and again https://example.com';
  const urls = extractBareUrls(content);
  assert.deepStrictEqual(urls, ['https://example.com']);
});

test('extracts URL with path and query', () => {
  const content = 'See https://example.com/path/to/page?query=1';
  const urls = extractBareUrls(content);
  assert.deepStrictEqual(urls, ['https://example.com/path/to/page?query=1']);
});

test('handles URL appearing both bare and in markdown link', () => {
  const content = 'https://example.com and [Example](https://example.com)';
  const urls = extractBareUrls(content);
  assert.deepStrictEqual(urls, ['https://example.com']);
});

test('returns empty array for content with no URLs', () => {
  const content = 'Just some text without any links';
  const urls = extractBareUrls(content);
  assert.deepStrictEqual(urls, []);
});

test('handles URLs at end of sentence', () => {
  const content = 'Check this: https://example.com.';
  const urls = extractBareUrls(content);
  assert.deepStrictEqual(urls, ['https://example.com.']);
});

test('handles URLs in parentheses', () => {
  const content = 'Info (see https://example.com) here';
  const urls = extractBareUrls(content);
  assert.deepStrictEqual(urls, ['https://example.com']);
});

test('extracts URL with fragment', () => {
  const content = 'See https://example.com/page#section for details';
  const urls = extractBareUrls(content);
  assert.deepStrictEqual(urls, ['https://example.com/page#section']);
});
