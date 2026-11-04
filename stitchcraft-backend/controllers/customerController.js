/* controllers/customerController.js */
import Customer from '../models/Customer.js';
import Order from '../models/Order.js';
import Payment from '../models/Payment.js';
import Shop from '../models/Shop.js';
import {
  createCustomerService,
  getCustomerProfileService,
  updateCustomerService,
  deleteCustomerService,
} from '../services/customerService.js';
import { escapeRegex } from '../middleware/securityMiddleware.js';

// @desc    Create a new customer
// @route   POST /api/customers
// @access  Private
export const createCustomer = async (req, res) => {
  try {
    const { name, phone } = req.body;
    if (!name || !phone) {
      return res.status(400).json({ message: 'Please provide customer name and phone number' });
    }

    const idempotencyKey = req.headers['idempotency-key'] || req.body.idempotencyKey || req.body.clientMutationId;
    const result = await createCustomerService({ ...req.body, idempotencyKey }, req.user.shopId);
    res.status(201).json(result);
  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all customers linked to the shop (with optional search)
// @route   GET /api/customers
// @access  Private
export const getCustomers = async (req, res) => {
  try {
    const search = typeof req.query.search === 'string' ? req.query.search.slice(0, 100) : '';
    const escapedSearch = escapeRegex(search);
    const filter = { shopId: req.user.shopId };

    if (search) {
      filter.$or = [
        { name: { $regex: escapedSearch, $options: 'i' } },
        { phone: { $regex: escapedSearch, $options: 'i' } },
        { email: { $regex: escapedSearch, $options: 'i' } },
        { customerId: { $regex: escapedSearch, $options: 'i' } },
      ];
    }

    const customers = await Customer.find(filter).sort({ createdAt: -1 });

    // Deduplicate customers by sanitized 10-digit phone number
    const seenPhones = new Set();
    const uniqueCustomers = [];
    for (const c of customers) {
      const clean = (c.phone || '').replace(/\D/g, '').slice(-10);
      if (clean) {
        if (!seenPhones.has(clean)) {
          seenPhones.add(clean);
          uniqueCustomers.push(c);
        }
      } else {
        uniqueCustomers.push(c);
      }
    }

    res.json(uniqueCustomers);
  } catch (error) {
    console.error('Get customers error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get a single customer's full profile, measurements, and histories
// @route   GET /api/customers/:id
// @access  Private
export const getCustomerById = async (req, res) => {
  try {
    const result = await getCustomerProfileService(req.params.id, req.user.shopId);
    if (!result) return res.status(404).json({ message: 'Customer not found' });
    res.json(result);
  } catch (error) {
    console.error('Get customer by ID error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update customer contact info or measurements
// @route   PUT /api/customers/:id
// @access  Private
export const updateCustomer = async (req, res) => {
  try {
    const result = await updateCustomerService(req.params.id, req.body, req.user.shopId);
    if (!result) return res.status(404).json({ message: 'Customer not found' });
    res.json(result);
  } catch (error) {
    console.error('Update customer error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Permanently delete a customer profile and associated measurements
// @route   DELETE /api/customers/:id
// @access  Private
export const deleteCustomer = async (req, res) => {
  try {
    const success = await deleteCustomerService(req.params.id, req.user.shopId);
    if (!success) return res.status(404).json({ message: 'Customer not found' });
    res.json({ message: 'Customer profile and measurements deleted successfully' });
  } catch (error) {
    console.error('Delete customer error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all customers with pending balance (Udhar)
// @route   GET /api/customers/pending-balances
// @access  Private
export const getPendingBalances = async (req, res) => {
  try {
    const shopId = req.user.shopId;
    if (!shopId) {
      return res.status(400).json({ message: 'No active shop associated with session' });
    }

    const shop = await Shop.findById(shopId);
    const shopName = shop?.shopName || 'StitchCraft';
    const shopUpi = shop?.upiId || '';

    // Find all payments with positive balance
    const payments = await Payment.find({ shopId });
    const pendingPayments = (payments || []).filter(p => Number(p.balanceAmount) > 0);

    if (pendingPayments.length === 0) {
      return res.json({
        totalOutstanding: 0,
        customerCount: 0,
        customers: [],
      });
    }

    const orderIds = pendingPayments.map(p => p.orderId);
    const orders = await Order.find({ _id: { $in: orderIds }, shopId, status: { $ne: 'Cancelled' } }).populate('customer');

    // Map orderId -> payment
    const paymentMap = new Map();
    for (const p of pendingPayments) {
      paymentMap.set(String(p.orderId), p);
    }

    // Group orders and balances by customer
    const customerMap = new Map();

    for (const order of orders) {
      const payment = paymentMap.get(String(order._id));
      if (!payment || Number(payment.balanceAmount) <= 0) continue;

      const customerId = order.customer ? String(order.customer._id) : (order.customerName || 'Unknown');
      const customerName = order.customer?.name || order.customerName || 'Valued Customer';
      const phone = order.customer?.phone || '';
      const email = order.customer?.email || '';

      if (!customerMap.has(customerId)) {
        customerMap.set(customerId, {
          customerId: order.customer?.customerId || customerId,
          _id: order.customer?._id || customerId,
          name: customerName,
          phone,
          email,
          totalBalance: 0,
          orders: [],
          oldestDueDate: order.deliveryDate || order.createdAt,
        });
      }

      const custEntry = customerMap.get(customerId);
      const balance = Number(payment.balanceAmount);
      custEntry.totalBalance += balance;

      custEntry.orders.push({
        _id: order._id,
        orderId: order.orderId,
        apparelType: order.apparelType,
        deliveryDate: order.deliveryDate,
        totalAmount: Number(payment.totalAmount),
        paidAmount: Number(payment.paidAmount),
        balanceAmount: balance,
        status: order.status,
        shareToken: order.shareToken,
      });

      if (order.deliveryDate && new Date(order.deliveryDate) < new Date(custEntry.oldestDueDate)) {
        custEntry.oldestDueDate = order.deliveryDate;
      }
    }

    // Calculate total summary and format WhatsApp reminder messages
    let totalOutstanding = 0;
    const customers = Array.from(customerMap.values())
      .filter(c => c.totalBalance > 0)
      .sort((a, b) => b.totalBalance - a.totalBalance)
      .map(c => {
        totalOutstanding += c.totalBalance;

        const orderRefs = c.orders.map(o => o.orderId).join(', ');
        let reminderText = `Namaste ${c.name}, this is a gentle reminder from ${shopName}. You have a pending tailoring balance of ₹${c.totalBalance} across order(s) ${orderRefs}. Kindly settle at your convenience.`;
        if (shopUpi) {
          reminderText += ` UPI ID: ${shopUpi}`;
        }

        return {
          ...c,
          whatsappReminderText: reminderText,
          whatsappUrl: c.phone
            ? `https://wa.me/${c.phone.replace(/[^0-9]/g, '')}?text=${encodeURIComponent(reminderText)}`
            : null,
        };
      });

    res.json({
      totalOutstanding,
      customerCount: customers.length,
      customers,
    });
  } catch (error) {
    console.error('Get pending balances error:', error);
    res.status(500).json({ message: error.message });
  }
};
