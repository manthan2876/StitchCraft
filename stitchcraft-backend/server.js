import express from 'express';
import helmet from 'helmet';
import dotenv from 'dotenv';
import connectDB from './config/db.js';
import corsMiddleware from './config/cors.js';
import apiRouter from './routes/index.js';
import errorHandler from './middleware/errorMiddleware.js';
import { apiLimiter } from './middleware/securityMiddleware.js';

// Load environment variables
dotenv.config();
const app = express();

// Middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));
app.use(corsMiddleware);
app.use(express.json());
app.use('/api', apiLimiter);

// API Routes
app.use('/api', apiRouter);

// Error handling middleware
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
  });
};

startServer().catch((error) => {
  console.error(`Server startup failed: ${error.message}`);
  process.exitCode = 1;
});

export default app;
