/**
 * Browser test for selection-based URL title fetching.
 *
 * Usage:
 *   Start the server (SESSION_SECRET must be >=64 chars):
 *     DATABASE_URL=postgres://localhost/wikimum_test RACK_ENV=test \
 *       SESSION_SECRET=$(head -c 64 /dev/urandom | base64 | head -c 64) \
 *       bundle exec puma -p 9393 config.ru
 *   Run this test:
 *     TEST_URL=http://localhost:9393 node test/browser/link_titles_selection_test.js
 */

const { test, describe, before, after } = require('node:test');
const assert = require('node:assert');
const puppeteer = require('puppeteer-core');

const TEST_URL = process.env.TEST_URL || 'http://localhost:9393';

describe('Link titles selection feature', { timeout: 30000 }, () => {
  let browser;
  let page;

  before(async () => {
    browser = await puppeteer.launch({
      executablePath: '/usr/bin/chromium',
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    page = await browser.newPage();

    // Login via dev endpoint
    await page.goto(`${TEST_URL}/authorize/dev`);
    // Wait for redirect to complete
    await page.waitForNavigation({ waitUntil: 'networkidle0' }).catch(() => {});
  });

  after(async () => {
    if (browser) {
      await browser.close();
    }
  });

  test('shows "Inga URL:er" when no URLs in textarea', async () => {
    // Navigate to new page form
    await page.goto(`${TEST_URL}/_new`);
    await page.waitForSelector('#page-content');

    // Set content without URLs
    await page.evaluate(() => {
      document.getElementById('page-content').value = 'Just some text without URLs';
    });

    // Click fetch titles
    await page.click('#link-titles-btn');

    // Wait for status message
    await page.waitForFunction(
      () => document.getElementById('link-titles-status').textContent === 'Inga URL:er',
      { timeout: 5000 }
    );

    const status = await page.$eval('#link-titles-status', el => el.textContent);
    assert.strictEqual(status, 'Inga URL:er');
  });

  test('shows "Inga URL:er i markering" when no URLs in selected text', async () => {
    await page.goto(`${TEST_URL}/_new`);
    await page.waitForSelector('#page-content');

    // Set content with URL outside of selection
    await page.evaluate(() => {
      const textarea = document.getElementById('page-content');
      textarea.value = 'No URL here\nhttps://example.com\nMore text';
      // Select only the first line (no URL)
      textarea.selectionStart = 0;
      textarea.selectionEnd = 11; // "No URL here"
    });

    // Click fetch titles
    await page.click('#link-titles-btn');

    // Wait for status message
    await page.waitForFunction(
      () => document.getElementById('link-titles-status').textContent === 'Inga URL:er i markering',
      { timeout: 5000 }
    );

    const status = await page.$eval('#link-titles-status', el => el.textContent);
    assert.strictEqual(status, 'Inga URL:er i markering');
  });

  test('extracts URLs only from selected text when selection exists', async () => {
    await page.goto(`${TEST_URL}/_new`);
    await page.waitForSelector('#page-content');

    // Set content with multiple URLs
    await page.evaluate(() => {
      const textarea = document.getElementById('page-content');
      const line1 = 'https://first-url.example.com';
      const line2 = 'https://selected-url.example.com';
      const line3 = 'https://third-url.example.com';
      textarea.value = line1 + '\n' + line2 + '\n' + line3;
      // Select only the middle line (line2)
      const selStart = line1.length + 1; // +1 for newline
      const selEnd = selStart + line2.length;
      textarea.selectionStart = selStart;
      textarea.selectionEnd = selEnd;
    });

    // Mock the fetch to track which URL gets requested
    await page.evaluate(() => {
      window.fetchedUrls = [];
      const originalFetch = window.fetch;
      window.fetch = async function(url, options) {
        if (url === '/link-title') {
          const formData = options.body;
          const urlValue = formData.get('url');
          window.fetchedUrls.push(urlValue);
          // Return mock response
          return {
            ok: true,
            headers: { get: () => 'application/json' },
            json: async () => ({ url: urlValue, title: 'Fetched Title' })
          };
        }
        return originalFetch.call(this, url, options);
      };
    });

    // Click fetch titles
    await page.click('#link-titles-btn');

    // Wait for processing to complete
    await page.waitForFunction(
      () => !window.linkTitlesProcessing && document.getElementById('link-titles-status').textContent === '',
      { timeout: 5000 }
    );

    // Check which URLs were fetched
    const fetchedUrls = await page.evaluate(() => window.fetchedUrls);
    assert.deepStrictEqual(fetchedUrls, ['https://selected-url.example.com']);
  });

  test('extracts all URLs when no selection exists', async () => {
    await page.goto(`${TEST_URL}/_new`);
    await page.waitForSelector('#page-content');

    // Set content with multiple URLs, no selection
    await page.evaluate(() => {
      const textarea = document.getElementById('page-content');
      textarea.value = 'https://first.example.com and https://second.example.com';
      // No selection (cursor at end)
      textarea.selectionStart = textarea.value.length;
      textarea.selectionEnd = textarea.value.length;
    });

    // Mock fetch
    await page.evaluate(() => {
      window.fetchedUrls = [];
      const originalFetch = window.fetch;
      window.fetch = async function(url, options) {
        if (url === '/link-title') {
          const formData = options.body;
          const urlValue = formData.get('url');
          window.fetchedUrls.push(urlValue);
          return {
            ok: true,
            headers: { get: () => 'application/json' },
            json: async () => ({ url: urlValue, title: 'Title' })
          };
        }
        return originalFetch.call(this, url, options);
      };
    });

    // Click fetch titles
    await page.click('#link-titles-btn');

    // Wait for processing to complete
    await page.waitForFunction(
      () => !window.linkTitlesProcessing && document.getElementById('link-titles-status').textContent === '',
      { timeout: 5000 }
    );

    // Check both URLs were fetched
    const fetchedUrls = await page.evaluate(() => window.fetchedUrls);
    assert.deepStrictEqual(fetchedUrls, ['https://first.example.com', 'https://second.example.com']);
  });

  test('replaces URL everywhere in document when fetching from selection', async () => {
    await page.goto(`${TEST_URL}/_new`);
    await page.waitForSelector('#page-content');

    // Set content with same URL appearing multiple times
    await page.evaluate(() => {
      const textarea = document.getElementById('page-content');
      textarea.value = 'https://repeated.example.com first\nhttps://repeated.example.com second';
      // Select only the first occurrence
      textarea.selectionStart = 0;
      textarea.selectionEnd = 30;
    });

    // Mock fetch
    await page.evaluate(() => {
      window.fetch = async function(url, options) {
        if (url === '/link-title') {
          const formData = options.body;
          const urlValue = formData.get('url');
          return {
            ok: true,
            headers: { get: () => 'application/json' },
            json: async () => ({ url: urlValue, title: 'Repeated Title' })
          };
        }
      };
    });

    // Click fetch titles
    await page.click('#link-titles-btn');

    // Wait for processing to complete
    await page.waitForFunction(
      () => !window.linkTitlesProcessing && document.getElementById('link-titles-status').textContent === '',
      { timeout: 5000 }
    );

    // Both occurrences should be replaced
    const content = await page.$eval('#page-content', el => el.value);
    assert.strictEqual(
      content,
      '[Repeated Title](https://repeated.example.com) first\n[Repeated Title](https://repeated.example.com) second'
    );
  });
});
