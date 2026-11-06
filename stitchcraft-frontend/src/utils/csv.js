/**
 * Escape a single cell value for CSV output in accordance with RFC 4180:
 * - Wraps fields containing commas, double quotes, CR, or LF in double quotes.
 * - Double quotes inside fields are escaped by doubling them ("").
 * - Handles null and undefined cleanly as empty strings.
 * - Preserves Unicode characters without truncation.
 */
export const escapeCSV = (value) => {
  if (value === null || value === undefined) return '';
  const str = String(value);

  if (
    str.includes(',') ||
    str.includes('"') ||
    str.includes('\n') ||
    str.includes('\r')
  ) {
    return `"${str.replace(/"/g, '""')}"`;
  }

  return str;
};

/**
 * Build a complete CSV document string from a list of header strings and an array of row arrays
 */
export const buildCSV = (headers, rows) => {
  const headerLine = headers.map(escapeCSV).join(',');
  const rowLines = rows.map((row) => row.map(escapeCSV).join(','));
  return [headerLine, ...rowLines].join('\n');
};

/**
 * Filter an array of items by an ISO or date-parsable property between startDate and endDate (inclusive)
 */
export const filterByDateRange = (items, dateKey = 'date', startDate = '', endDate = '') => {
  if (!Array.isArray(items)) return [];
  if (!startDate && !endDate) return items;

  const startMs = startDate ? new Date(startDate).setHours(0, 0, 0, 0) : null;
  const endMs = endDate ? new Date(endDate).setHours(23, 59, 59, 999) : null;

  return items.filter((item) => {
    const val = item?.[dateKey];
    if (!val) return false;
    const time = new Date(val).getTime();
    if (isNaN(time)) return false;

    if (startMs !== null && time < startMs) return false;
    if (endMs !== null && time > endMs) return false;
    return true;
  });
};

