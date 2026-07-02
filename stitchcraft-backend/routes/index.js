/* routes/index.js */
import { Router } from 'express';
import authRoutes from './authRoutes.js';
import dashboardRoutes from './dashboardRoutes.js';
import shopRoutes from './shopRoutes.js';
import customerRoutes from './customerRoutes.js';
import orderRoutes from './orderRoutes.js';
import ledgerRoutes from './ledgerRoutes.js';
import deliveryRoutes from './deliveryRoutes.js';
import notificationRoutes from './notificationRoutes.js';
import karigarRoutes from './karigarRoutes.js';
import machineRoutes from './machineRoutes.js';
import inventoryRoutes from './inventoryRoutes.js';
import uploadRoutes from './uploadRoutes.js';

const router = Router();

// Basic status check route
router.get('/status', (req, res) => {
  res.json({ status: "Tailor's App API is running smoothly" });
});

// Mount modular sub-routes
router.use('/auth', authRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/shops', shopRoutes);
router.use('/customers', customerRoutes);
router.use('/orders', orderRoutes);
router.use('/ledger', ledgerRoutes);
router.use('/deliveries', deliveryRoutes);
router.use('/notifications', notificationRoutes);
router.use('/karigars', karigarRoutes);
router.use('/machines', machineRoutes);
router.use('/inventory', inventoryRoutes);
router.use('/upload', uploadRoutes);

export default router;
