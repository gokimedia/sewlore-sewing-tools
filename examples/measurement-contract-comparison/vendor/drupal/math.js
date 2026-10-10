/**
 * Sewlore Sewing Calculators: pure local measurement arithmetic.
 * MIT License. Copyright (c) 2026 Sewlore.
 * Stretch formulas adapted from @sewingselami/sewlore-sewing-math 0.1.0 (MIT).
 * No network, DOM, storage, or third-party runtime dependencies.
 */
(function (root, factory) {
	'use strict';
	if (typeof module === 'object' && module.exports) {
		module.exports = factory();
	} else {
		root.sewloreSewingCalculatorMath = factory();
	}
}(typeof globalThis !== 'undefined' ? globalThis : this, function () {
	'use strict';
	function fail(code) {
		var error = new RangeError(code);
		error.code = code;
		throw error;
	}
	function finite(value) {
		if (typeof value !== 'number' || !Number.isFinite(value)) fail('range');
		return value;
	}
	function positive(value) {
		finite(value);
		if (value <= 0) fail('positive');
		return value;
	}
	function nonnegative(value) {
		finite(value);
		if (value < 0) fail('nonnegative');
		return value;
	}
	/** One decimal separator is allowed. Grouping, exponent notation and partial parses are rejected. */
	function parseDecimal(text) {
		if (typeof text !== 'string') fail('required');
		var value = text.trim();
		if (value.length === 0 || value.length > 48 || !/^[+-]?(?:\d+(?:[.,]\d*)?|[.,]\d+)$/.test(value)) fail('required');
		return finite(Number(value.replace(',', '.')));
	}
	function stretch(original, stretched, released) {
		positive(original);
		positive(stretched);
		positive(released);
		if (stretched < original) fail('stretched');
		var extension = stretched - original;
		var residual = released - original;
		var result = {
			stretchPercent: finite((extension / original) * 100),
			residualChangePercent: finite((residual / original) * 100),
			recoveredExtensionPercent: extension === 0 ? null : finite(((stretched - released) / extension) * 100),
			unusualReleasedLength: released < original || released > stretched
		};
		return result;
	}
	function buttons(length, top, bottom, count) {
		positive(length);
		nonnegative(top);
		nonnegative(bottom);
		if (!Number.isInteger(count) || count < 2 || count > 100) fail('count');
		var span = length - top - bottom;
		if (!Number.isFinite(span)) fail('range');
		if (span <= 0) fail('span');
		var spacing = finite(span / (count - 1));
		var positions = [];
		for (var i = 0; i < count; i += 1) {
			// Explicit final endpoint avoids accumulated interval-rounding drift.
			var position = finite(i === count - 1 ? length - bottom : top + i * spacing);
			if (i > 0 && position <= positions[i - 1]) fail('range');
			positions.push(position);
		}
		return { spacing: spacing, positions: positions };
	}
	function convert(value, from, to) {
		nonnegative(value);
		var millimetres = { cm: 10, mm: 1, in: 25.4 };
		if (!Object.prototype.hasOwnProperty.call(millimetres, from) || !Object.prototype.hasOwnProperty.call(millimetres, to)) fail('unit');
		// Divide the factors first to avoid an unnecessary overflowing intermediate value.
		return finite(value * (millimetres[from] / millimetres[to]));
	}
	return Object.freeze({ parseDecimal: parseDecimal, stretch: stretch, buttons: buttons, convert: convert });
}));
