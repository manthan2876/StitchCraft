/* config/cors.js */
import cors from 'cors';

const allowedOrigins = [
  'http://localhost:5173',
  'http://127.0.0.1:5173',
  'http://192.168.1.13:5173',
  'https://stitchcraft-swart.vercel.app',
  'https://stitchcraft-frontend.vercel.app',
  'https://stitchcraft-manthan152876.vercel.app',
];

export const corsMiddleware = cors({
  origin: allowedOrigins,
  credentials: true
});

export default corsMiddleware;
