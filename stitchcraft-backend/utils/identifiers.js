export const isValidIdentifier = (value) => (
  typeof value === 'string' && value.trim().length > 0 && value.length <= 128
);
