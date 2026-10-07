import assert from 'node:assert/strict';
import { calculateStretch, calculatePrintScale, convertLength, csvCell } from '@sewingselami/sewlore-sewing-math';

// Hypothetical arithmetic only; no fabric or printout was measured for this example.
const stretch = calculateStretch({ original: 10, stretched: 14, released: 10.5 });
assert.equal(stretch.stretchPercent, 40);
assert.equal(stretch.residualGrowthPercent, 5);
assert.equal(stretch.recoveredExtensionPercent, 87.5);

const print = calculatePrintScale({ target: 10, measuredX: 9.8, measuredY: 10.1 });
assert.ok(Math.abs(print.xErrorPercent + 2) < 1e-9);
assert.ok(Math.abs(print.yErrorPercent - 1) < 1e-9);
assert.ok(Math.abs(print.differencePercentagePoints - 3) < 1e-9);
assert.equal(print.nonUniform, true);
assert.equal(convertLength(2.54, 'cm', 'in'), 1);
assert.equal(csvCell('Cotton, "blue"'), '"Cotton, ""blue"""');

console.log(JSON.stringify({ hypothetical: true, stretch, print }, null, 2));
