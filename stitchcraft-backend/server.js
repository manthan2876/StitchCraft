import dns from 'node:dns';
dns.setServers(['8.8.8.8', '1.1.1.1']);

import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import connectDB from './config/db.js';

// Load environment variables
dotenv.config();

// Connect to Database
connectDB();

const app = express();

// Middleware
const allowedOrigins = [
  'http://localhost:5173',
  'http://127.0.0.1:5173',
  'http://192.168.1.13:5173',
  'https://stitchcraft-swart.vercel.app',
  'https://stitchcraft-frontend.vercel.app',
  'https://stitchcraft-manthan152876.vercel.app',
];
app.use(cors({
  origin: allowedOrigins,
  credentials: true
}));
app.use(express.json());

// Basic status check route
app.get('/api/status', (req, res) => {
  res.json({ status: "Tailor's App API is running smoothly" });
});

// Import route modules
import authRoutes from './routes/authRoutes.js';
import dashboardRoutes from './routes/dashboardRoutes.js';
import shopRoutes from './routes/shopRoutes.js';
import customerRoutes from './routes/customerRoutes.js';
import orderRoutes from './routes/orderRoutes.js';
import ledgerRoutes from './routes/ledgerRoutes.js';
import deliveryRoutes from './routes/deliveryRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import karigarRoutes from './routes/karigarRoutes.js';
import machineRoutes from './routes/machineRoutes.js';
import inventoryRoutes from './routes/inventoryRoutes.js';
import uploadRoutes from './routes/uploadRoutes.js';

// Mount routes
app.use('/api/auth', authRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/shops', shopRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/ledger', ledgerRoutes);
app.use('/api/deliveries', deliveryRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/karigars', karigarRoutes);
app.use('/api/machines', machineRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/upload', uploadRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err.stack);
  res.status(err.status || 500).json({
    message: err.message || 'Internal Server Error',
    stack: process.env.NODE_ENV === 'production' ? null : err.stack,
  });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
});

export default app;
