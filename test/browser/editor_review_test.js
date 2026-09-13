const { test } = require('node:test');
const assert = require('node:assert/strict');
const puppeteer = require('puppeteer-core');

const url = process.env.TEST_URL || 'http://localhost:9393';

test('editor switches between a live preview and safe, accurate draft changes', { timeout: 30000 }, async () => {
  const browser = await puppeteer.launch({
    executablePath: '/usr/bin/chromium',
    headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu'],
  });
  try {
    const page = await browser.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.setViewport({ width: 1440, height: 1000 });
    await page.goto(`${url}/authorize/dev`);
    await page.goto(`${url}/new`);
    const title = `Editor review ${Date.now()}`;
    await page.type('#title', title);
    await page.type('#page-content', 'First line\n\nOriginal paragraph.\n\nLast line');
    await Promise.all([page.waitForNavigation(), page.click('form button')]);
    const savedUrl = page.url();
    await page.goto(`${savedUrl}/edit`);
    assert.equal(await page.$eval('#preview', el => el.hidden), false);
    assert.equal(await page.$eval('#diff', el => el.hidden), true);
    await page.click('#diff-tab');
    assert.equal(await page.$eval('#diff-summary', el => el.textContent), 'Inga ändringar ännu.');

    await page.$eval('#page-content', el => {
      el.value = 'First line\n\nUpdated **paragraph**.\n<script>window.diffInjected = true</script>\n\nLast line';
      el.dispatchEvent(new Event('input', { bubbles: true }));
    });
    await page.waitForFunction(() => document.querySelector('.diff-added'));
    assert.match(await page.$eval('#diff-content', el => el.textContent), /− Original paragraph\./);
    assert.match(await page.$eval('#diff-content', el => el.textContent), /\+ Updated \*\*paragraph\*\*\./);
    assert.equal(await page.evaluate(() => window.diffInjected), undefined);
    assert.equal(await page.$eval('#diff', el => el.hidden), false);

    await page.click('#preview-tab');
    await page.waitForFunction(() => document.querySelector('#preview strong')?.textContent === 'paragraph');
    await page.$eval('#title', el => {
      el.value += ' updated';
      el.dispatchEvent(new Event('input', { bubbles: true }));
    });
    await page.waitForFunction(() => document.querySelector('#preview h1').textContent.endsWith('updated'));
    await page.focus('#preview-tab');
    await page.keyboard.press('ArrowRight');
    assert.equal(await page.$eval('#diff-tab', el => el.getAttribute('aria-selected')), 'true');
    assert.match(await page.$eval('#diff-content', el => el.textContent), /Titel/);
    await page.$eval('#description', el => {
      el.value = 'A new description';
      el.dispatchEvent(new Event('input', { bubbles: true }));
    });
    await page.click('input[value="crawlable"]');
    await page.waitForFunction(() => document.getElementById('diff-content').textContent.includes('Synlighet'));
    assert.match(await page.$eval('#diff-content', el => el.textContent), /Sidbeskrivning/);

    await page.setViewport({ width: 390, height: 844 });
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
    await page.emulateMediaFeatures([{ name: 'prefers-color-scheme', value: 'dark' }]);
    assert.notEqual(await page.$eval('.diff-added', el => getComputedStyle(el).backgroundColor), 'rgb(226, 244, 231)');
    await page.setViewport({ width: 1440, height: 1000 });

    // Reverting all draft fields restores the empty state without reloading.
    await page.evaluate(() => {
      const form = document.getElementById('page-content').form;
      form.reset();
      form.dispatchEvent(new Event('input', { bubbles: true }));
    });
    await page.waitForFunction(() => document.getElementById('diff-summary').textContent === 'Inga ändringar ännu.');
    await page.type('#page-content', '\nSaved addition.');
    await Promise.all([page.waitForNavigation(), page.click('form button')]);
    assert.match(await page.$eval('#content', el => el.textContent), /Saved addition/);
    await page.goto(`${savedUrl}/edit`);
    assert.equal(await page.$eval('#preview', el => el.hidden), false);
    await page.click('#diff-tab');
    assert.equal(await page.$eval('#diff-summary', el => el.textContent), 'Inga ändringar ännu.');
    assert.deepEqual(errors, []);
  } finally {
    await browser.close();
  }
});
