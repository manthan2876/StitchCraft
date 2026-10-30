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

export const validateObjectIdParam = (param = 'id') => (req, res, next) => {
  const value = req.params[param];
  if (!isValidIdentifier(value)) {
    return res.status(400).json({ message: `Invalid ${param}` });
  }
  next();
};

export const escapeRegex = (value) => (
  String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
);
