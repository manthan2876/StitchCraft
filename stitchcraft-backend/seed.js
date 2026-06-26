import dns from 'node:dns';
dns.setServers(['8.8.8.8', '1.1.1.1']);

import mongoose from 'mongoose';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

import User from './models/User.js';
import Shop from './models/Shop.js';
import Customer from './models/Customer.js';
import Order from './models/Order.js';
import Payment from './models/Payment.js';
import Delivery from './models/Delivery.js';
import Notification from './models/Notification.js';
import Counter from './models/Counter.js';

const seedDB = async () => {
  try {
    const mongoUri = process.env.MONGO_URI;
    console.log(`Connecting to database to seed: ${mongoUri}`);
    await mongoose.connect(mongoUri);
    console.log('MongoDB Connected.');

    console.log('Clearing old collections...');
    await User.deleteMany({});
    await Shop.deleteMany({});
    await Customer.deleteMany({});
    await Order.deleteMany({});
    await Payment.deleteMany({});
    await Delivery.deleteMany({});
    await Notification.deleteMany({});
    await Counter.deleteMany({});

    console.log('Seeding default accounts...');

    // 1. Create default Owner User
    const ramesh = new User({
      name: 'Masterji Ramesh',
      email: 'ramesh@stitchcraft.com',
      password: '1234',
      role: 'owner',
    });
    await ramesh.save();

    // 2. Create default Shop
    const shop = new Shop({
      shopName: 'Ramesh Tailors',
      ownerId: ramesh._id,
      phone: '9876543210',
      address: '12, Gandhi Road, Salem - 636001',
    });
    await shop.save();

    // Link User to Shop
    ramesh.shopId = shop._id;
    await ramesh.save();

    // 3. Create default Customers
    const c1 = await Customer.create({
      name: 'Aarav Mehta',
      phone: '9876543210',
      email: 'aarav@mehta.com',
      address: '10, Anna Nagar, Salem - 636002',
      ordersCount: 1,
      shopId: shop._id,
    });

    const c2 = await Customer.create({
      name: 'Priya Sharma',
      phone: '9812345678',
      email: 'priya@sharma.com',
      address: '15, Rajaji Street, Salem - 636003',
      ordersCount: 1,
      shopId: shop._id,
    });

    const c3 = await Customer.create({
      name: 'Rohan Gupta',
      phone: '9765432109',
      email: 'rohan@gupta.com',
      address: '5, Nehru Nagar, Salem - 636004',
      ordersCount: 1,
      shopId: shop._id,
    });

    // 4. Create default Orders (dates in June 2026)
    const o1 = await Order.create({
      customerName: c1.name,
      customer: c1._id,
      apparelType: 'Suit',
      deliveryDate: new Date('2026-06-14T12:00:00Z'),
      price: 12000,
      fabric: 'Premium Wool Blend',
      status: 'Stitching',
      shopId: shop._id,
    });

    const o2 = await Order.create({
      customerName: c2.name,
      customer: c2._id,
      apparelType: 'Lehenga',
      deliveryDate: new Date('2026-06-18T12:00:00Z'),
      price: 25000,
      fabric: 'Silk with Zari Embroidery',
      status: 'Cutting',
      shopId: shop._id,
    });

    const o3 = await Order.create({
      customerName: c3.name,
      customer: c3._id,
      apparelType: 'Shirt',
      deliveryDate: new Date('2026-06-25T12:00:00Z'),
      price: 2500,
      fabric: 'Egyptian Cotton White',
      status: 'Ready',
      shopId: shop._id,
    });

    // 5. Create associated Payments
    await Payment.create({
      shopId: shop._id,
      orderId: o1._id,
      totalAmount: 12000,
      paidAmount: 3000,
      paymentType: 'Card',
    });

    await Payment.create({
      shopId: shop._id,
      orderId: o2._id,
      totalAmount: 25000,
      paidAmount: 10000,
      paymentType: 'Online',
    });

    await Payment.create({
      shopId: shop._id,
      orderId: o3._id,
      totalAmount: 2500,
      paidAmount: 2500,
      paymentType: 'Cash',
    });

    // 6. Create associated Deliveries
    await Delivery.create({
      shopId: shop._id,
      orderId: o1._id,
      deliveryDate: o1.deliveryDate,
      status: 'Pending',
    });

    await Delivery.create({
      shopId: shop._id,
      orderId: o2._id,
      deliveryDate: o2.deliveryDate,
      status: 'Pending',
    });

    await Delivery.create({
      shopId: shop._id,
      orderId: o3._id,
      deliveryDate: o3.deliveryDate,
      status: 'Pending',
    });

    // 7. Create default Notifications
    await Notification.create({
      shopId: shop._id,
      customerId: c1._id,
      orderId: o1._id,
      message: `Incoming order ORD-901 (Suit) registered for Aarav Mehta.`,
    });

    await Notification.create({
      shopId: shop._id,
      customerId: c2._id,
      orderId: o2._id,
      message: `Fabric cutting is in progress for Priya Sharma's Lehenga (ORD-902).`,
    });

    await Notification.create({
      shopId: shop._id,
      customerId: c3._id,
      orderId: o3._id,
      message: `Order ORD-903 is ready for delivery. Notification sent to Rohan Gupta.`,
    });

    console.log('Seeding completed successfully.');
    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error(`Error during seeding: ${error.message}`);
    process.exit(1);
  }
};

seedDB();
