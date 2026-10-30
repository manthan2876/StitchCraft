/**
 * Client-Side Form Validation Utilities for StitchCraft
 * ---------------------------------------------------------------------------
 * Provides real-time field validation for text, phone, email, numbers, and dates.
 */

export const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
export const PHONE_REGEX = /^[0-9+]{10,15}$/;

/**
 * Validate required field
 */
export const validateRequired = (value, fieldLabel = 'This field') => {
  if (value === undefined || value === null || String(value).trim().length === 0) {
    return `${fieldLabel} is required`;
  }
  return '';
};

/**
 * Validate string minimum length
 */
export const validateMinLength = (value, minLen = 2, fieldLabel = 'This field') => {
  if (!value || String(value).trim().length < minLen) {
    return `${fieldLabel} must be at least ${minLen} characters`;
  }
  return '';
};

/**
 * Validate email address
 */
export const validateEmail = (email, required = true) => {
  if (!email || !String(email).trim()) {
    return required ? 'Email address is required' : '';
  }
  if (!EMAIL_REGEX.test(String(email).trim())) {
    return 'Please enter a valid email address';
  }
  return '';
};

/**
 * Validate phone number (10 to 15 digits)
 */
export const validatePhone = (phone, required = true) => {
  if (!phone || !String(phone).trim()) {
    return required ? 'Phone number is required' : '';
  }
  const cleanPhone = String(phone).replace(/[\s-]/g, '');
  if (!PHONE_REGEX.test(cleanPhone)) {
    return 'Phone number must contain between 10 and 15 digits';
  }
  return '';
};

/**
 * Validate positive number
 */
export const validateNumber = (value, fieldLabel = 'Amount', { allowZero = true, min, max } = {}) => {
  if (value === undefined || value === null || value === '') {
    return `${fieldLabel} is required`;
  }
  const num = Number(value);
  if (isNaN(num)) {
    return `${fieldLabel} must be a valid number`;
  }
  if (!allowZero && num <= 0) {
    return `${fieldLabel} must be greater than zero`;
  }
  if (allowZero && num < 0) {
    return `${fieldLabel} cannot be negative`;
  }
  if (min !== undefined && num < min) {
    return `${fieldLabel} must be at least ${min}`;
  }
  if (max !== undefined && num > max) {
    return `${fieldLabel} cannot exceed ${max}`;
  }
  return '';
};

/**
 * Validate date
 */
export const validateDate = (dateStr, fieldLabel = 'Date', { notPast = false } = {}) => {
  if (!dateStr) return `${fieldLabel} is required`;
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return `Please select a valid ${fieldLabel.toLowerCase()}`;
  if (notPast) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (d < today) {
      return `${fieldLabel} cannot be in the past`;
    }
  }
  return '';
};

/**
 * Validate password
 */
export const validatePassword = (password, minLen = 6) => {
  if (!password) return 'Password is required';
  if (password.length < minLen) {
    return `Password must be at least ${minLen} characters long`;
  }
  return '';
};

export default {
  validateRequired,
  validateMinLength,
  validateEmail,
  validatePhone,
  validateNumber,
  validateDate,
  validatePassword,
};

