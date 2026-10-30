import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  validateRequired,
  validateMinLength,
  validateEmail,
  validatePhone,
  validateNumber,
  validateDate,
  validatePassword,
} from '../src/utils/formValidators.js';

describe('Frontend Form Validators', () => {
  describe('validateRequired', () => {
    it('should return error if field is empty or undefined', () => {
      assert.equal(validateRequired('', 'Name'), 'Name is required');
      assert.equal(validateRequired(null, 'Phone'), 'Phone is required');
      assert.equal(validateRequired(undefined, 'Address'), 'Address is required');
      assert.equal(validateRequired('   ', 'Field'), 'Field is required');
    });

    it('should return empty string if field is valid', () => {
      assert.equal(validateRequired('Masterji Ramesh', 'Name'), '');
      assert.equal(validateRequired('123', 'Number'), '');
    });
  });

  describe('validateMinLength', () => {
    it('should reject inputs shorter than min length', () => {
      assert.equal(validateMinLength('a', 2, 'Shop name'), 'Shop name must be at least 2 characters');
      assert.equal(validateMinLength('', 3, 'Code'), 'Code must be at least 3 characters');
    });

    it('should accept inputs equal to or longer than min length', () => {
      assert.equal(validateMinLength('ab', 2, 'Shop name'), '');
      assert.equal(validateMinLength('StitchCraft Workshop', 2, 'Shop name'), '');
    });
  });

  describe('validateEmail', () => {
    it('should reject invalid email patterns', () => {
      assert.equal(validateEmail('not-an-email'), 'Please enter a valid email address');
      assert.equal(validateEmail('test@'), 'Please enter a valid email address');
      assert.equal(validateEmail('@domain.com'), 'Please enter a valid email address');
      assert.equal(validateEmail('test@domain'), 'Please enter a valid email address');
    });

    it('should accept valid email patterns', () => {
      assert.equal(validateEmail('masterji@stitchcraft.in'), '');
      assert.equal(validateEmail('test.tailor@boutique.co.in'), '');
      assert.equal(validateEmail('', false), '');
    });
  });

  describe('validatePhone', () => {
    it('should reject missing or non-digit phone numbers', () => {
      assert.equal(validatePhone(''), 'Phone number is required');
      assert.equal(validatePhone('abc1234567'), 'Phone number must contain between 10 and 15 digits');
      assert.equal(validatePhone('12345'), 'Phone number must contain between 10 and 15 digits');
    });

    it('should accept 10-digit Indian numbers and numbers with country code', () => {
      assert.equal(validatePhone('9876543210'), '');
      assert.equal(validatePhone('+919876543210'), '');
      assert.equal(validatePhone('98765-43210'), '');
      assert.equal(validatePhone('+91 98765 43210'), '');
      assert.equal(validatePhone('', false), '');
    });
  });

  describe('validateNumber', () => {
    it('should reject non-numeric inputs', () => {
      assert.equal(validateNumber('abc', 'Price'), 'Price must be a valid number');
      assert.equal(validateNumber('', 'Amount'), 'Amount is required');
    });

    it('should enforce min and max boundaries', () => {
      assert.equal(validateNumber(-5, 'Price', { allowZero: true }), 'Price cannot be negative');
      assert.equal(validateNumber(0, 'Quantity', { allowZero: false }), 'Quantity must be greater than zero');
      assert.equal(validateNumber(2, 'Stock', { min: 5 }), 'Stock must be at least 5');
      assert.equal(validateNumber(150, 'Percent', { max: 100 }), 'Percent cannot exceed 100');
      assert.equal(validateNumber(25, 'Percent', { min: 0, max: 100 }), '');
    });
  });

  describe('validateDate', () => {
    it('should reject empty or invalid date strings', () => {
      assert.equal(validateDate('', 'Delivery date'), 'Delivery date is required');
      assert.equal(validateDate('not-a-date', 'Delivery date'), 'Please select a valid delivery date');
    });

    it('should accept valid ISO date strings', () => {
      assert.equal(validateDate('2026-11-20', 'Delivery date'), '');
      assert.equal(validateDate('2026-11-20T00:00:00.000Z', 'Delivery date'), '');
    });
  });

  describe('validatePassword', () => {
    it('should enforce minimum password length of 6 characters', () => {
      assert.equal(validatePassword(''), 'Password is required');
      assert.equal(validatePassword('12345'), 'Password must be at least 6 characters long');
      assert.equal(validatePassword('secret123'), '');
    });
  });
});
