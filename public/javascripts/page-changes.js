/* Warns while editing when someone else saves the page, like the Rails-era
   check_for_changes poll. Saving would be rejected anyway, this just says so
   before more work goes into the draft. */
function watchPageChanges(url, sha1, onChange, interval = 30000) {
  const timer = setInterval(async () => {
    const response = await fetch(url, { cache: 'no-store' });
    if (!response.ok || (await response.text()) === sha1) return;
    clearInterval(timer);
    onChange();
  }, interval);
  return timer;
}

if (typeof module !== 'undefined') module.exports = { watchPageChanges };

if (typeof document !== 'undefined') {
  const form = document.getElementById('page-content').form;
  const notice = document.getElementById('page-changed');
  watchPageChanges(`${form.getAttribute('action')}/sha1`, form.elements.sha1.value, () => {
    notice.hidden = false;
  });
}
