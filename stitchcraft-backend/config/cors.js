/* config/cors.js */
import cors from 'cors';

/**
 * Default production-grade domains for StitchCraft web applications
 */
const defaultOrigins = [
  'https://stitchcraft-swart.vercel.app',
  'https://stitchcraft-frontend.vercel.app',
  'https://stitchcraft-manthan152876.vercel.app',
];

/**
 * Parse configured origins from environment variables (CLIENT_URL, ALLOWED_ORIGINS)
 */
export const getAllowedOrigins = (env = process.env) => {
  const configured = [];

  if (env.CLIENT_URL) {
    const urls = env.CLIENT_URL.split(',').map((u) => u.trim()).filter(Boolean);
    configured.push(...urls);
  }

  if (env.ALLOWED_ORIGINS) {
    const urls = env.ALLOWED_ORIGINS.split(',').map((u) => u.trim()).filter(Boolean);
    configured.push(...urls);
  }

  // Combine configured with defaults, removing any duplicates
  const origins = Array.from(new Set([...defaultOrigins, ...configured]));
  return origins;
};

/**
 * Check whether a requesting origin is permitted under strict security policy
 */
export const isOriginAllowed = (origin, env = process.env) => {
  // Allow requests with no origin (e.g. mobile Flutter apps, Postman, curl, server-to-server)
  if (!origin) return true;

  const allowed = getAllowedOrigins(env);
  if (allowed.includes(origin)) return true;

  // Local development origins permitted only in non-production or when explicitly enabled
  const isDev = env.NODE_ENV !== 'production' || env.ALLOW_LOCAL_ORIGINS === 'true';
  if (isDev) {
    if (
      origin.startsWith('http://localhost:') ||
      origin.startsWith('http://127.0.0.1:') ||
      origin.startsWith('http://192.168.') ||
      origin === 'http://localhost' ||
      origin === 'http://127.0.0.1'
    ) {
      return true;
    }
  }

  return false;
};

export const corsOptions = {
  origin: (origin, callback) => {
    if (isOriginAllowed(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Shop-Id', 'Idempotency-Key', 'Accept'],
};

export const corsMiddleware = cors(corsOptions);

export default corsMiddleware;
