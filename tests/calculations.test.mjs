import test from 'node:test';
import assert from 'node:assert/strict';
import { calculateStretch, calculatePrintScale, convertLength, csvCell } from '../calculations.js';

const close = (actual, expected) => assert.ok(Math.abs(actual - expected) < 1e-9, `${actual} ≠ ${expected}`);

test('stretch, residual growth, and recovery have different denominators', () => {
  const result = calculateStretch({ original: 10, stretched: 15, released: 10.5 });
  close(result.stretchPercent, 50);
  close(result.residualGrowthPercent, 5);
  close(result.recoveredExtensionPercent, 90);
  assert.equal(result.unusualReleasedLength, false);
});

test('zero extension has no defined recovered fraction', () => {
  const result = calculateStretch({ original: 10, stretched: 10, released: 10 });
  assert.equal(result.stretchPercent, 0);
  assert.equal(result.residualGrowthPercent, 0);
  assert.equal(result.recoveredExtensionPercent, null);
});

test('full recovery and no recovery are distinguished', () => {
  assert.equal(calculateStretch({ original: 10, stretched: 14, released: 10 }).recoveredExtensionPercent, 100);
  assert.equal(calculateStretch({ original: 10, stretched: 14, released: 14 }).recoveredExtensionPercent, 0);
});

test('unexpected released readings remain visible and are flagged, never clipped', () => {
  const shorter = calculateStretch({ original: 10, stretched: 15, released: 9.5 });
  close(shorter.residualGrowthPercent, -5);
  close(shorter.recoveredExtensionPercent, 110);
  assert.equal(shorter.unusualReleasedLength, true);
  const longer = calculateStretch({ original: 10, stretched: 15, released: 16 });
  close(longer.recoveredExtensionPercent, -20);
  assert.equal(longer.unusualReleasedLength, true);
});

test('stretch percentages are invariant under cm to inch conversion', () => {
  const cm = { original: 10, stretched: 14.2, released: 10.3 };
  const inches = Object.fromEntries(Object.entries(cm).map(([k, v]) => [k, convertLength(v, 'cm', 'in')]));
  const a = calculateStretch(cm), b = calculateStretch(inches);
  for (const key of ['stretchPercent', 'residualGrowthPercent', 'recoveredExtensionPercent']) close(a[key], b[key]);
});

test('invalid and impossible baseline values fail clearly', () => {
  for (const value of [0, -1, NaN, Infinity, '10', null]) {
    assert.throws(() => calculateStretch({ original: value, stretched: 15, released: 10 }), RangeError);
    assert.throws(() => calculatePrintScale({ target: 10, measuredX: value, measuredY: 10 }), RangeError);
  }
  assert.throws(() => calculateStretch({ original: 10, stretched: 9, released: 10 }), /Stretched length/);
  assert.throws(() => calculatePrintScale({ target: 10, measuredX: 10, measuredY: 10, tolerancePercent: -1 }), RangeError);
});

test('print errors retain direction, and unequal axes trigger a warning', () => {
  const result = calculatePrintScale({ target: 10, measuredX: 9.5, measuredY: 10.1 });
  close(result.xScalePercent, 95);
  close(result.xErrorPercent, -5);
  close(result.yErrorPercent, 1);
  close(result.differencePercentagePoints, 6);
  assert.equal(result.nonUniform, true);
  assert.equal(result.withinTolerance, false);
});

test('perfect print, uniform undersize, and exact threshold are distinct', () => {
  assert.equal(calculatePrintScale({ target: 10, measuredX: 10, measuredY: 10 }).withinTolerance, true);
  const undersize = calculatePrintScale({ target: 10, measuredX: 9.8, measuredY: 9.8 });
  assert.equal(undersize.nonUniform, false);
  assert.equal(undersize.withinTolerance, false);
  const boundary = calculatePrintScale({ target: 10, measuredX: 10.05, measuredY: 10 });
  assert.equal(boundary.withinTolerance, true);
  assert.equal(boundary.nonUniform, false);
  assert.equal(calculatePrintScale({ target: 10, measuredX: 10.051, measuredY: 10 }).nonUniform, true);
});

test('print percentages are invariant under unit conversion', () => {
  const values = { target: 10, measuredX: 9.95, measuredY: 10.01 };
  const inches = Object.fromEntries(Object.entries(values).map(([k, v]) => [k, convertLength(v, 'cm', 'in')]));
  const a = calculatePrintScale(values), b = calculatePrintScale(inches);
  for (const key of ['xErrorPercent', 'yErrorPercent', 'differencePercentagePoints']) close(a[key], b[key]);
  assert.equal(a.withinTolerance, b.withinTolerance);
  assert.equal(a.nonUniform, b.nonUniform);
});

test('length conversion round trips and rejects unknown units', () => {
  close(convertLength(convertLength(10, 'cm', 'in'), 'in', 'cm'), 10);
  assert.equal(convertLength(7.5, 'cm', 'cm'), 7.5);
  assert.throws(() => convertLength(10, 'mm', 'cm'), RangeError);
});

test('extreme finite inputs do not silently produce infinite results', () => {
  assert.throws(() => calculateStretch({ original: Number.MIN_VALUE, stretched: Number.MAX_VALUE, released: 1 }), /measurement range/);
  assert.throws(() => calculatePrintScale({ target: Number.MIN_VALUE, measuredX: 1, measuredY: 1 }), /measurement range/);
});

test('CSV preserves quotes, separators and protects user-entered formulas', () => {
  assert.equal(csvCell('Cotton, "blue"'), '"Cotton, ""blue"""');
  assert.equal(csvCell('=HYPERLINK("https://example.com")'), '"\'=HYPERLINK(""https://example.com"")"');
  assert.equal(csvCell(' @SUM(1)'), '"\' @SUM(1)"');
  assert.equal(csvCell('Regular label'), '"Regular label"');
  assert.equal(csvCell(-2), '"-2"');
});
