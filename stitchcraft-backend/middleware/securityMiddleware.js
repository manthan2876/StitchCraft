import rateLimit from 'express-rate-limit';
import { isValidIdentifier } from '../utils/identifiers.js';

const limiter = (windowMs, limit, message) => rateLimit({
  windowMs,
  limit,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { message },
});

export const apiLimiter = limiter(
  15 * 60 * 1000,
  300,
  'Too many requests, please try again later',
);

export const authLimiter = limiter(
  15 * 60 * 1000,
  10,
  'Too many authentication attempts, please try again later',
);

export const uploadLimiter = limiter(
  15 * 60 * 1000,
  30,
  'Too many upload requests, please try again later',
);

export const destructiveLimiter = limiter(
  15 * 60 * 1000,
  10,
  'Too many sensitive-operation requests, please try again later',
);

export const publicInvoiceLimiter = limiter(
  15 * 60 * 1000,
  60,
  'Too many invoice requests, please try again later',
);

export const validateObjectIdParam = (param = 'id') => (req, res, next) => {
  const value = req.params[param];
  if (!isValidIdentifier(value)) {
    return res.status(400).json({ message: `Invalid ${param}` });
  }
  next();
};

export const validateShareTokenParam = (param = 'token') => (req, res, next) => {
  const value = req.params[param];
  if (!value || typeof value !== 'string') {
    return res.status(400).json({ message: `Invalid or missing ${param}` });
  }
  const trimmed = value.trim();
  // Must be an opaque token between 16 and 128 characters (hex or base64url)
  if (!/^[a-zA-Z0-9_-]{16,128}$/.test(trimmed)) {
    return res.status(400).json({ message: `Invalid ${param} format` });
  }
  req.params[param] = trimmed;
  next();
};

export const escapeRegex = (value) => (
  String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
);
