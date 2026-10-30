import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { formatCurrency, formatDate } from '../src/utils/formatters.js';

describe('Frontend Formatters', () => {
  describe('formatCurrency', () => {
    it('should format null and undefined as ₹0', () => {
      assert.equal(formatCurrency(null), '₹0');
      assert.equal(formatCurrency(undefined), '₹0');
    });

    it('should format positive amounts with Indian currency symbol', () => {
      assert.equal(formatCurrency(0), '₹0');
      assert.equal(formatCurrency(500), '₹500');
      assert.equal(formatCurrency(1500), '₹1,500');
      assert.equal(formatCurrency(100000), '₹1,00,000');
    });

    it('should format negative amounts correctly', () => {
      assert.equal(formatCurrency(-500), '-₹500');
      assert.equal(formatCurrency(-1250), '-₹1,250');
    });
  });

  describe('formatDate', () => {
    it('should return empty string for null, undefined, or invalid dates', () => {
      assert.equal(formatDate(null), '');
      assert.equal(formatDate(undefined), '');
      assert.equal(formatDate('invalid-date'), '');
    });

    it('should format valid ISO dates to "DD Mon YYYY"', () => {
      const formatted = formatDate('2026-10-30T00:00:00.000Z');
      assert.match(formatted, /2026/);
      assert.match(formatted, /Oct/);
    });
  });
});

