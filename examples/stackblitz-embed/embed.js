const status = document.getElementById('copy-status');

function selectSnippet(code) {
  const range = document.createRange();
  range.selectNodeContents(code);
  const selection = window.getSelection();
  if (!selection) return false;
  selection.removeAllRanges();
  selection.addRange(range);
  code.closest('pre').focus();
  return true;
}

for (const button of document.querySelectorAll('[data-copy]')) {
  button.addEventListener('click', async () => {
    const code = document.getElementById(button.dataset.copy);
    if (!code) return;
    try {
      if (!navigator.clipboard?.writeText) throw new Error('Clipboard unavailable');
      await navigator.clipboard.writeText(code.textContent);
      status.textContent = 'Iframe HTML copied. Keep the fallback link on your resource page.';
    } catch {
      status.textContent = selectSnippet(code)
        ? 'HTML selected. Use your browser’s copy shortcut to copy it.'
        : 'Select the iframe HTML, then use your browser’s copy shortcut.';
    }
  });
}
