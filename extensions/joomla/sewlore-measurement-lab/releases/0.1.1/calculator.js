/* Copyright (c) 2026 Sewlore. SPDX-License-Identifier: GPL-3.0-or-later */
(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root.document) {
    const attach = () => root.document.querySelectorAll('[data-sewlore-measurement-lab]').forEach(api.attach);
    if (root.document.readyState === 'loading') root.document.addEventListener('DOMContentLoaded', attach, {once: true});
    else attach();
  }
})(typeof globalThis === 'object' ? globalThis : this, function () {
  'use strict';
  const factors = Object.freeze({mm: 1, cm: 10, in: 25.4});
  function numeric(raw, positive = false) {
    if (typeof raw !== 'number' && typeof raw !== 'string') throw new RangeError('A number is required.');
    if (typeof raw === 'string' && raw.trim() === '') throw new RangeError('A number is required.');
    const value = Number(raw);
    if (!Number.isFinite(value) || Math.abs(value) > 1e9 || (positive && value <= 0)) throw new RangeError('Invalid measurement.');
    return value;
  }
  function convert(raw, from, to) {
    if (!Object.hasOwn(factors, from) || !Object.hasOwn(factors, to)) throw new RangeError('Unknown unit.');
    return numeric(raw) * factors[from] / factors[to];
  }
  function shrinkage(before, after) {
    const initial = numeric(before, true), final = numeric(after, true);
    return {changePercent: (initial - final) / initial * 100, retainedPercent: final / initial * 100};
  }
  function printScale(expectedWidth, expectedHeight, measuredWidth, measuredHeight) {
    const widthPercent = numeric(measuredWidth, true) / numeric(expectedWidth, true) * 100;
    const heightPercent = numeric(measuredHeight, true) / numeric(expectedHeight, true) * 100;
    return {widthPercent, heightPercent, gapPercentagePoints: Math.abs(widthPercent - heightPercent)};
  }
  function fmt(value) {
    return new Intl.NumberFormat(undefined, {maximumFractionDigits: 6}).format(Math.abs(value) < 1e-10 ? 0 : value);
  }
  function template(text, values) {
    return text.replace(/\{([a-zA-Z]+)\}/g, (_, key) => Object.hasOwn(values, key) ? String(values[key]) : '');
  }
  function attach(element) {
    if (element.dataset.sewloreAttached === '1') return;
    element.dataset.sewloreAttached = '1';
    const value = key => element.querySelector('[data-field="' + key + '"]').value;
    const result = (key, run) => {
      const output = element.querySelector('[data-result="' + key + '"]');
      try { output.textContent = run(); output.dataset.state = 'valid'; }
      catch (_) { output.textContent = element.dataset.invalid; output.dataset.state = 'invalid'; }
    };
    const render = () => {
      result('conversion', () => template(element.dataset.conversion, {value: fmt(convert(value('amount'), value('from'), value('to'))), unit: value('to')}));
      result('shrinkage', () => {
        const computed = shrinkage(value('before'), value('after'));
        return template(element.dataset.shrinkage, {change: fmt(computed.changePercent), retained: fmt(computed.retainedPercent)});
      });
      result('print', () => {
        const computed = printScale(value('expected-width'), value('expected-height'), value('measured-width'), value('measured-height'));
        return template(element.dataset.print, {width: fmt(computed.widthPercent), height: fmt(computed.heightPercent), gap: fmt(computed.gapPercentagePoints)});
      });
    };
    element.addEventListener('input', render);
    element.addEventListener('change', render);
    render();
  }
  return Object.freeze({numeric, convert, shrinkage, printScale, attach});
});
