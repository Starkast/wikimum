/* Line-based comparison of the original form values and the unsaved draft. */
function diffLines(original, draft) {
  const lines = text => text === '' ? [] : text.replace(/\r\n/g, '\n').split('\n');
  const before = lines(original);
  const after = lines(draft);
  const result = [];
  let start = 0;
  while (start < before.length && start < after.length && before[start] === after[start]) {
    result.push({ type: 'context', text: before[start++] });
  }
  let oldEnd = before.length;
  let newEnd = after.length;
  while (oldEnd > start && newEnd > start && before[oldEnd - 1] === after[newEnd - 1]) {
    oldEnd--;
    newEnd--;
  }

  const oldCount = oldEnd - start;
  const newCount = newEnd - start;
  // Bound memory and work for very large replacements. The fallback still
  // represents every changed line, without trying to align the replaced block.
  if (oldCount * newCount > 1000000) {
    before.slice(start, oldEnd).forEach(text => result.push({ type: 'removed', text }));
    after.slice(start, newEnd).forEach(text => result.push({ type: 'added', text }));
  } else {
    const lengths = Array.from({ length: oldCount + 1 }, () => new Uint32Array(newCount + 1));
    for (let i = oldCount - 1; i >= 0; i--) {
      for (let j = newCount - 1; j >= 0; j--) {
        lengths[i][j] = before[start + i] === after[start + j]
          ? lengths[i + 1][j + 1] + 1
          : Math.max(lengths[i + 1][j], lengths[i][j + 1]);
      }
    }
    let i = 0;
    let j = 0;
    while (i < oldCount || j < newCount) {
      if (i < oldCount && j < newCount && before[start + i] === after[start + j]) {
        result.push({ type: 'context', text: before[start + i++] });
        j++;
      } else if (i < oldCount && (j === newCount || lengths[i + 1][j] >= lengths[i][j + 1])) {
        result.push({ type: 'removed', text: before[start + i++] });
      } else {
        result.push({ type: 'added', text: after[start + j++] });
      }
    }
  }
  before.slice(oldEnd).forEach(text => result.push({ type: 'context', text }));
  return result;
}

if (typeof module !== 'undefined') module.exports = { diffLines };

if (typeof document !== 'undefined') {
  const textarea = document.getElementById('page-content');
  const form = textarea.form;
  const tabs = Array.from(document.querySelectorAll('.review-tabs [role="tab"]'));
  const diff = document.getElementById('diff');
  const fields = [
    { name: 'title', label: 'Titel' },
    { name: 'content', label: 'Innehåll' },
    { name: 'description', label: 'Sidbeskrivning' },
    { name: 'visibility', label: 'Synlighet' },
  ];
  const visibility = { concealed: 'Privat', public: 'Publik', crawlable: 'Publik, tillåt sökmotorer' };
  const value = field => field.name === 'visibility'
    ? visibility[form.elements[field.name].value]
    : form.elements[field.name].value;
  fields.forEach(field => { field.original = value(field); });

  function renderDiff() {
    const fragment = document.createDocumentFragment();
    let added = 0;
    let removed = 0;
    fields.forEach(field => {
      const current = value(field);
      if (current === field.original) return;
      const heading = document.createElement('h2');
      heading.textContent = field.label;
      fragment.append(heading);
      const block = document.createElement('div');
      block.className = 'diff-lines';
      let oldLine = 0;
      let newLine = 0;
      diffLines(field.original, current).forEach(line => {
        const row = document.createElement('div');
        row.className = `diff-line diff-${line.type}`;
        const oldNumber = document.createElement('span');
        const newNumber = document.createElement('span');
        oldNumber.className = newNumber.className = 'diff-number';
        oldNumber.textContent = line.type === 'added' ? '' : ++oldLine;
        newNumber.textContent = line.type === 'removed' ? '' : ++newLine;
        oldNumber.setAttribute('aria-hidden', 'true');
        newNumber.setAttribute('aria-hidden', 'true');
        const text = document.createElement('span');
        text.className = 'diff-text';
        const marker = line.type === 'added' ? '+' : line.type === 'removed' ? '−' : ' ';
        text.textContent = `${marker} ${line.text}`;
        row.append(oldNumber, newNumber, text);
        block.append(row);
        if (line.type === 'added') added++;
        if (line.type === 'removed') removed++;
      });
      fragment.append(block);
    });
    document.getElementById('diff-content').replaceChildren(fragment);
    document.getElementById('diff-summary').textContent = added || removed
      ? `+ ${added} tillagda / − ${removed} borttagna rader`
      : 'Inga ändringar ännu.';
  }

  function selectTab(tab) {
    tabs.forEach(item => {
      const selected = item === tab;
      item.setAttribute('aria-selected', String(selected));
      item.tabIndex = selected ? 0 : -1;
      document.getElementById(item.getAttribute('aria-controls')).hidden = !selected;
    });
    if (!diff.hidden) renderDiff();
  }

  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => selectTab(tab));
    tab.addEventListener('keydown', event => {
      let target;
      if (event.key === 'ArrowRight' || event.key === 'ArrowLeft') target = tabs[1 - index];
      if (event.key === 'Home') target = tabs[0];
      if (event.key === 'End') target = tabs[tabs.length - 1];
      if (!target) return;
      event.preventDefault();
      selectTab(target);
      target.focus();
    });
  });

  let timer;
  function updateDiff() {
    clearTimeout(timer);
    if (!diff.hidden) timer = setTimeout(renderDiff, 150);
  }
  ['input', 'change', 'keyup'].forEach(event => form.addEventListener(event, updateDiff));
  // The title also belongs to the live preview. Programmatic content edits
  // (uploads and fetched link titles) already trigger the textarea's keyup.
  form.elements.title.addEventListener('input', () => htmx.trigger(textarea, 'change'));
}
