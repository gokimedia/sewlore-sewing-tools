export function buttonSpacing(length, first, last, count) {
  if (![length, first, last].every(Number.isFinite) || length <= 0 || first < 0 || last < 0) throw new Error('Enter a positive opening length and non-negative end offsets.');
  if (!Number.isInteger(count) || count < 2 || count > 100) throw new Error('Choose 2 to 100 button centres.');
  const span = length - first - last;
  if (span <= 0) throw new Error('The two offsets must leave a positive span between the first and last centres.');
  const spacing = span / (count - 1);
  return {spacing, positions: Array.from({length:count}, (_, i) => first + i * spacing), span};
}

function grid(width, length, pieceWidth, pieceLength, gap) {
  const across = Math.floor((width + gap) / (pieceWidth + gap) + 1e-10);
  const rows = Math.floor((length + gap) / (pieceLength + gap) + 1e-10);
  const count = across * rows;
  if (!Number.isSafeInteger(count)) throw new Error('The inputs produce too many pieces to count reliably. Use realistic dimensions.');
  return {across, rows, count, pieceWidth, pieceLength};
}

export function rectangularLayout(width, length, pieceWidth, pieceLength, margin, gap, rotate) {
  if (![width,length,pieceWidth,pieceLength,margin,gap].every(Number.isFinite) || Math.min(width,length,pieceWidth,pieceLength) <= 0 || margin < 0 || gap < 0) throw new Error('Enter positive fabric and piece dimensions, with non-negative margins and gaps.');
  const usableWidth = width - 2 * margin, usableLength = length - 2 * margin;
  if (Math.min(usableWidth, usableLength) <= 0) throw new Error('The margin on both edges leaves no usable fabric.');
  const original = grid(usableWidth, usableLength, pieceWidth, pieceLength, gap);
  const turned = rotate ? grid(usableWidth, usableLength, pieceLength, pieceWidth, gap) : null;
  const best = turned && turned.count > original.count ? {...turned,rotated:true} : {...original,rotated:false};
  return {...best, originalCount:original.count, rotatedCount:turned?.count ?? null, usableWidth, usableLength};
}
