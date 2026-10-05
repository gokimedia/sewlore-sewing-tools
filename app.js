import { calculateStretch, calculatePrintScale, convertLength, csvCell } from './calculations.js';

const $ = id => document.getElementById(id);
const pageParams = new URLSearchParams(location.search);
const isEmbedded = pageParams.get('embed') === '1';
if (isEmbedded) {
  document.body.classList.add('is-embedded');
  const privacyNote = document.createElement('p');
  privacyNote.className = 'privacy-note embed-privacy-note';
  privacyNote.textContent = 'Free to use. Calculations run on your device; your measurements stay in this browser.';
  document.querySelector('.tool-tabs').before(privacyNote);
}
const state = {
  stretch: { unit: 'cm', example: true, record: null },
  print: { unit: 'cm', example: true, record: null },
};
const stretchFields = [
  { id: 'original-length', key: 'original', label: 'Original, relaxed length' },
  { id: 'stretched-length', key: 'stretched', label: 'Stretched length' },
  { id: 'released-length', key: 'released', label: 'Released length' },
];
const printFields = [
  { id: 'target-side', key: 'target', label: 'Intended square side' },
  { id: 'measured-x', key: 'measuredX', label: 'Measured width (X)' },
  { id: 'measured-y', key: 'measuredY', label: 'Measured height (Y)' },
];
const decimal = (value, digits = 2) => new Intl.NumberFormat('en', { maximumFractionDigits: digits }).format(Object.is(value, -0) ? 0 : value);
const signed = value => `${value > 0 ? '+' : value < 0 ? '−' : ''}${decimal(Math.abs(value))}%`;
const percentage = value => `${decimal(value)}%`;

function clearErrors(kind, fields) {
  const error = $(`${kind}-error`);
  error.replaceChildren();
  error.hidden = true;
  for (const field of fields) $(field.id).removeAttribute('aria-invalid');
}

function showErrors(kind, fields, errors, focus) {
  const error = $(`${kind}-error`);
  const list = document.createElement('ul');
  for (const entry of errors) {
    const item = document.createElement('li');
    item.textContent = entry.message;
    list.append(item);
    $(entry.id).setAttribute('aria-invalid', 'true');
  }
  error.replaceChildren(list);
  error.hidden = false;
  invalidate(kind, 'Please correct the highlighted measurements, then calculate again.');
  if (focus) $(errors[0].id).focus();
}

function readMeasurements(kind, fields, focus) {
  clearErrors(kind, fields);
  const errors = [];
  const values = {};
  for (const field of fields) {
    const input = $(field.id);
    const value = Number(input.value);
    if (input.value.trim() === '' || input.validity.badInput || !Number.isFinite(value) || value <= 0) {
      errors.push({ id: field.id, message: `${field.label}: enter a number greater than zero.` });
    } else values[field.key] = value;
  }
  if (kind === 'stretch' && values.stretched < values.original) {
    errors.push({ id: 'stretched-length', message: 'Stretched length must be at least the original length.' });
  }
  if (errors.length) {
    showErrors(kind, fields, errors, focus);
    return null;
  }
  return values;
}

function invalidate(kind, message = 'Measurements changed. Calculate again to update your result.') {
  state[kind].record = null;
  $(`${kind}-results`).hidden = true;
  const pending = $(`${kind}-pending`);
  pending.textContent = message;
  pending.hidden = false;
}

function markEdited(kind) {
  state[kind].example = false;
  $(`${kind}-example-note`).hidden = true;
  $(`${kind}-clear`).textContent = 'Clear inputs';
  $(`${kind}-example`).hidden = false;
}

function showResult(kind) {
  $(`${kind}-pending`).hidden = true;
  $(`${kind}-results`).hidden = false;
  $(`${kind}-result-label`).textContent = state[kind].example ? 'Example calculation' : 'Your measurements';
}

function updateStretch(focusErrors = false) {
  const values = readMeasurements('stretch', stretchFields, focusErrors);
  if (!values) return false;
  let result;
  try { result = calculateStretch(values); }
  catch (error) { showErrors('stretch', stretchFields, [{ id: 'original-length', message: error.message }], focusErrors); return false; }
  const unit = state.stretch.unit;
  const stretchOutput = $('stretch-percent');
  const percentSign = document.createElement('span');
  percentSign.textContent = '%';
  stretchOutput.replaceChildren(document.createTextNode(decimal(result.stretchPercent)), percentSign);
  $('growth-percent').textContent = percentage(result.residualGrowthPercent);
  $('recovery-percent').textContent = result.recoveredExtensionPercent === null ? 'N/A' : percentage(result.recoveredExtensionPercent);
  const maxLength = Math.max(values.original, values.stretched, values.released);
  for (const key of ['original', 'stretched', 'released']) $(`bar-${key}`).style.width = `${values[key] / maxLength * 100}%`;
  const remainder = result.residualExtension >= 0
    ? `remains ${decimal(result.residualExtension, 4)} ${unit} longer`
    : `measures ${decimal(Math.abs(result.residualExtension), 4)} ${unit} shorter`;
  $('stretch-interpretation').textContent = `This ${state.stretch.example ? 'example' : 'sample'} extends by ${decimal(result.extension, 4)} ${unit} and ${remainder} after release.${result.recoveredExtensionPercent === null ? ' Extension recovered is undefined because the measured extension is zero.' : ''}`;
  const warning = $('stretch-warning');
  warning.hidden = !result.unusualReleasedLength;
  warning.textContent = result.unusualReleasedLength ? 'The released reading is outside the original-to-stretched range. Check the marks, direction and rest conditions, then repeat the measurement. Results are shown as entered, including negative growth or recovery outside 0–100%.' : '';
  state.stretch.record = { values, result, unit, example: state.stretch.example, label: $('fabric-label').value.trim(), direction: $('fabric-direction').value, rest: $('rest-time').value.trim() };
  showResult('stretch');
  return true;
}

function updatePrint(focusErrors = false) {
  const values = readMeasurements('print', printFields, focusErrors);
  if (!values) return false;
  let result;
  try { result = calculatePrintScale(values); }
  catch (error) { showErrors('print', printFields, [{ id: 'target-side', message: error.message }], focusErrors); return false; }
  $('x-error').textContent = signed(result.xErrorPercent);
  $('y-error').textContent = signed(result.yErrorPercent);
  $('x-scale').textContent = `${percentage(result.xScalePercent)} of intended width`;
  $('y-scale').textContent = `${percentage(result.yScalePercent)} of intended height`;
  const status = $('print-status');
  const roundingSlack = 64 * Number.EPSILON * Math.max(100, result.xScalePercent, result.yScalePercent, result.tolerancePercent);
  const xOutside = Math.abs(result.xErrorPercent) > result.tolerancePercent + roundingSlack;
  const yOutside = Math.abs(result.yErrorPercent) > result.tolerancePercent + roundingSlack;
  status.className = `notice ${result.withinTolerance ? 'success' : 'warning'}`;
  status.textContent = result.withinTolerance
    ? 'Both measurements are within ±0.5% of the intended side. Check your pattern’s stated tolerance before printing the remaining pages.'
    : `${xOutside && yOutside ? 'Both measurements are' : xOutside ? 'The width is' : 'The height is'} outside ±0.5% of the intended side. Review the print instructions and print a new test page.`;
  const warning = $('print-nonuniform');
  warning.hidden = !result.nonUniform;
  warning.textContent = result.nonUniform ? 'Unequal scale: the X/Y error difference is greater than 0.5 percentage points. Repeat both measurements; one overall resizing percentage would not make both sides match.' : '';
  $('print-difference').textContent = `X/Y error difference: ${decimal(result.differencePercentagePoints)} percentage points.`;
  // Keep the explanatory diagram inside its frame; numeric results above always use the exact readings.
  const diagramMax = Math.max(values.target, values.measuredX, values.measuredY);
  const targetSquare = $('measured-square').parentElement;
  const targetFraction = values.target / diagramMax;
  targetSquare.style.width = `${168 * targetFraction}px`;
  $('measured-square').style.width = `${values.measuredX / values.target * 100}%`;
  $('measured-square').style.height = `${values.measuredY / values.target * 100}%`;
  state.print.record = { values, result, unit: state.print.unit, example: state.print.example, label: $('print-label').value.trim() };
  showResult('print');
  return true;
}

function changeUnit(kind, fields, select) {
  const previous = state[kind].unit;
  const next = select.value;
  for (const field of fields) {
    const input = $(field.id);
    if (input.value !== '' && Number.isFinite(Number(input.value))) {
      // Retain numeric precision so switching units does not change a threshold result.
      input.value = String(convertLength(Number(input.value), previous, next));
    }
  }
  state[kind].unit = next;
  const panel = kind === 'stretch' ? $('stretch') : $('print-scale');
  for (const label of panel.querySelectorAll('.field-unit')) label.textContent = next;
  if (state[kind].record) (kind === 'stretch' ? updateStretch : updatePrint)();
  else invalidate(kind, `Lengths are now in ${next}. Enter your measurements and calculate to see the result.`);
}

function clearInputs(kind, fields) {
  clearErrors(kind, fields);
  for (const field of fields) $(field.id).value = '';
  if (kind === 'stretch') {
    $('fabric-label').value = '';
    $('rest-time').value = '';
  } else $('print-label').value = '';
  markEdited(kind);
  invalidate(kind, 'Enter your measurements, then calculate to see your result.');
  $(fields[0].id).focus();
}

function loadExample(kind) {
  state[kind].example = true;
  state[kind].unit = 'cm';
  $(`${kind}-unit`).value = 'cm';
  const panel = kind === 'stretch' ? $('stretch') : $('print-scale');
  for (const label of panel.querySelectorAll('.field-unit')) label.textContent = 'cm';
  $(`${kind}-example-note`).hidden = false;
  $(`${kind}-clear`).textContent = 'Clear example';
  $(`${kind}-example`).hidden = true;
  if (kind === 'stretch') {
    $('original-length').value = '10';
    $('stretched-length').value = '14';
    $('released-length').value = '10.2';
    $('fabric-label').value = 'Example knit';
    $('fabric-direction').value = 'Across width';
    $('rest-time').value = '60 seconds';
    updateStretch();
  } else {
    $('target-side').value = '10';
    $('measured-x').value = '9.8';
    $('measured-y').value = '9.8';
    $('print-label').value = 'Example test square';
    updatePrint();
  }
}

function downloadRecord(kind) {
  const record = state[kind].record;
  if (!record) return;
  const timestamp = new Date().toISOString();
  const rows = [['Sewlore measurement record', kind === 'stretch' ? 'Fabric Stretch Lab' : 'PDF Print Scale Checker'], ['Recorded at (UTC)', timestamp], ['Record type', record.example ? 'Illustrative example — not measured data' : 'User-entered measurements'], ['Sample / pattern label', record.label], ['Length unit', record.unit]];
  if (kind === 'stretch') {
    rows.push(['Direction', record.direction], ['Rest time', record.rest], ['Original length', record.values.original], ['Stretched length', record.values.stretched], ['Released length', record.values.released], ['Stretch (%)', record.result.stretchPercent], ['Residual growth (%)', record.result.residualGrowthPercent], ['Extension recovered (%)', record.result.recoveredExtensionPercent === null ? 'Undefined: zero extension' : record.result.recoveredExtensionPercent], ['Unusual released measurement', record.result.unusualReleasedLength ? 'Yes — repeat measurement' : 'No']);
  } else {
    rows.push(['Intended side', record.values.target], ['Measured width (X)', record.values.measuredX], ['Measured height (Y)', record.values.measuredY], ['Width error (%)', record.result.xErrorPercent], ['Height error (%)', record.result.yErrorPercent], ['X/Y difference (percentage points)', record.result.differencePercentagePoints], ['Tool comparison threshold (%)', record.result.tolerancePercent], ['Within tool threshold', record.result.withinTolerance ? 'Yes' : 'No'], ['Unequal scale flagged', record.result.nonUniform ? 'Yes' : 'No']);
  }
  const content = '\uFEFF' + rows.map(row => row.map(csvCell).join(',')).join('\r\n');
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  const slug = record.label.replace(/[^a-z0-9]+/gi, '-').replace(/^-|-$/g, '').slice(0, 40).toLowerCase() || 'measurement';
  link.href = url;
  link.download = `sewlore-${kind}-${slug}-${timestamp.slice(0, 10)}.csv`;
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

const tabs = [{ button: $('tab-stretch'), panel: $('stretch'), hash: '#stretch' }, { button: $('tab-print'), panel: $('print-scale'), hash: '#print-scale' }];
function activateTab(index, updateHash = false, focus = false) {
  tabs.forEach((tab, i) => {
    tab.button.setAttribute('aria-selected', String(i === index));
    tab.button.tabIndex = i === index ? 0 : -1;
    tab.panel.hidden = i !== index;
  });
  if (updateHash) {
    if (isEmbedded) {
      const url = new URL(location.href);
      url.searchParams.set('tool', tabs[index].panel.id);
      url.hash = '';
      history.replaceState(null, '', `${url.pathname}${url.search}`);
    } else if (location.hash !== tabs[index].hash) {
      history.replaceState(null, '', `${location.pathname}${location.search}${tabs[index].hash}`);
    }
  }
  if (focus) tabs[index].button.focus();
}
function syncHash() {
  const hashIndex = tabs.findIndex(tab => tab.hash === location.hash);
  const queryTool = new URLSearchParams(location.search).get('tool');
  activateTab(hashIndex >= 0 ? hashIndex : queryTool === 'print-scale' ? 1 : 0);
}
tabs.forEach((tab, index) => {
  tab.button.addEventListener('click', () => activateTab(index, true));
  tab.button.addEventListener('keydown', event => {
    let next;
    if (event.key === 'ArrowRight') next = (index + 1) % tabs.length;
    else if (event.key === 'ArrowLeft') next = (index - 1 + tabs.length) % tabs.length;
    else if (event.key === 'Home') next = 0;
    else if (event.key === 'End') next = tabs.length - 1;
    else return;
    event.preventDefault();
    activateTab(next, true, true);
  });
});
window.addEventListener('hashchange', syncHash);
syncHash();

for (const [kind, fields, update] of [['stretch', stretchFields, updateStretch], ['print', printFields, updatePrint]]) {
  $(`${kind}-form`).addEventListener('submit', event => { event.preventDefault(); update(true); });
  $(`${kind}-form`).addEventListener('input', event => {
    if (event.target.id === `${kind}-unit`) return;
    markEdited(kind);
    clearErrors(kind, fields);
    invalidate(kind);
  });
  $(`${kind}-unit`).addEventListener('change', event => changeUnit(kind, fields, event.target));
  $(`${kind}-clear`).addEventListener('click', () => clearInputs(kind, fields));
  $(`${kind}-example`).addEventListener('click', () => loadExample(kind));
  $(`${kind}-download`).addEventListener('click', () => downloadRecord(kind));
  update();
}

// Attribution only appears in outbound Sewlore links. No visit or measurement telemetry is collected.
const requestedSource = pageParams.get('source');
const hasExplicitSource = Boolean(requestedSource && /^[a-z0-9][a-z0-9._-]{0,63}$/i.test(requestedSource));
const source = hasExplicitSource ? requestedSource : 'sewing_tools';
for (const link of document.querySelectorAll('[data-sewlore-link]')) {
  // An embed on Sewlore should not relabel navigation within the site as a referral.
  if (isEmbedded && !hasExplicitSource) continue;
  const url = new URL(link.href);
  url.searchParams.set('utm_source', source);
  url.searchParams.set('utm_medium', 'referral');
  url.searchParams.set('utm_campaign', 'free_sewing_tools');
  url.searchParams.set('utm_content', link.dataset.sewloreLink);
  link.href = url.href;
}

// On HTTPS or localhost the app caches its own files after the first load for offline use.
if ('serviceWorker' in navigator && (location.protocol === 'https:' || location.hostname === 'localhost' || location.hostname === '127.0.0.1')) {
  navigator.serviceWorker.register('./service-worker.js', { scope: './' }).then(async () => {
    await navigator.serviceWorker.ready;
    $('offline-status').textContent = 'Ready for offline use. Measurements stay on your device; source links need internet.';
  }).catch(() => { /* The tools still work with no API dependency; some iframe hosts disable workers. */ });
}
