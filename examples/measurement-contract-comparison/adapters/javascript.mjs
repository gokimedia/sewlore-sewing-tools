/** Adapter only: all numerical results come from unchanged vendored sources. */
import {readFileSync} from 'node:fs';
import {createRequire} from 'node:module';
import * as npm from '../vendor/npm/src/index.js';
const require = createRequire(import.meta.url);
const drupal = require('../vendor/drupal/math.js');
const engine = process.argv[2];
if (!['npm', 'drupal_js'].includes(engine)) throw new Error('Choose npm or drupal_js');
const cases = JSON.parse(readFileSync(new URL('../cases.json', import.meta.url), 'utf8'));

const unsupported = (reason) => ({status:'unsupported', reason, native_call_performed:false});
function evaluate(c) {
  const v = c.input;
  if (c.operation === 'convert' && engine === 'npm' && ![v.from, v.to].every(x => ['cm','in'].includes(x))) {
    return unsupported('npm convertLength accepts only cm or in; no adapter conversion is inserted.');
  }
  if (c.operation === 'stretch' && new Set(v.units).size !== 1) {
    return unsupported('This JavaScript API requires a common unit; no adapter normalization is inserted.');
  }
  if (c.operation === 'print_scale' && engine === 'drupal_js') {
    return unsupported('The Drupal JavaScript math export has no print-scale function.');
  }
  try {
    let raw, value;
    if (c.operation === 'convert') {
      raw = engine === 'npm' ? npm.convertLength(v.value, v.from, v.to) : drupal.convert(v.value, v.from, v.to);
      value = {converted_length:raw};
    } else if (c.operation === 'stretch') {
      raw = engine === 'npm' ? npm.calculateStretch({original:v.original, stretched:v.stretched, released:v.released}) : drupal.stretch(v.original, v.stretched, v.released);
      value = {stretch_percent:raw.stretchPercent, residual_change_percent:engine === 'npm' ? raw.residualGrowthPercent : raw.residualChangePercent, recovered_extension_percent:raw.recoveredExtensionPercent, unusual_released_length:raw.unusualReleasedLength};
    } else if (c.operation === 'print_scale') {
      raw = npm.calculatePrintScale({target:v.target, measuredX:v.measured_x, measuredY:v.measured_y, tolerancePercent:v.tolerance_percent});
      value = {x_error_percent:raw.xErrorPercent, y_error_percent:raw.yErrorPercent, difference_percentage_points:raw.differencePercentagePoints, non_uniform:raw.nonUniform, within_tolerance:raw.withinTolerance};
    } else throw new Error('Unknown fixture operation');
    return {status:'accepted', value, native_output:raw, native_call_performed:true};
  } catch (error) {
    return {status:'rejected', error_type:error.name, error_code:error.code ?? null, error:error.message, native_call_performed:true};
  }
}
process.stdout.write(JSON.stringify(cases.map(c => ({case_id:c.id, engine, ...evaluate(c)}))) + '\n');
