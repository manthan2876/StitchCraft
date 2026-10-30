/* controllers/orderController.js */
import crypto from 'node:crypto';
import Order from '../models/Order.js';
import Shop from '../models/Shop.js';
import Payment from '../models/Payment.js';
import Delivery from '../models/Delivery.js';
import Notification from '../models/Notification.js';
import Measurement from '../models/Measurement.js';
import Transaction from '../models/Transaction.js';
import { dispatchNotification } from '../services/notificationService.js';
import {
  findOrderScoped,
  syncPaymentFromTransactions,
  createOrderService,
  updateOrderService,
  deleteOrderService,
} from '../services/orderService.js';

// @desc    Create a new order
// @route   POST /api/orders
// @access  Private
export const createOrder = async (req, res) => {
  try {
    const { customerName, apparelType, deliveryDate, price, items } = req.body;
    if (!customerName || !deliveryDate) {
      return res.status(400).json({ message: 'Please provide customerName and deliveryDate' });
    }
    if (!apparelType && (!items || !Array.isArray(items) || items.length === 0)) {
      return res.status(400).json({ message: 'Please provide apparelType or at least one item' });
    }
    if (price === undefined && (!items || !Array.isArray(items) || items.length === 0)) {
      return res.status(400).json({ message: 'Please provide price or items with pricing' });
    }

    const result = await createOrderService(req.body, req.user.shopId, req.user._id);
    res.status(201).json(result);
  } catch (error) {
    console.error('Create order error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all orders scoped to logged-in Shop (with filters)
// @route   GET /api/orders
// @access  Private
export const getOrders = async (req, res) => {
  try {
    const { status, urgency } = req.query;
    const filter = { shopId: req.user.shopId, isDeleted: { $ne: true } };

    if (status) filter.status = status;

    if (urgency === 'high') {
      const threeDaysLater = new Date();
      threeDaysLater.setDate(threeDaysLater.getDate() + 3);
      filter.deliveryDate = { $lte: threeDaysLater };
      filter.status = { $ne: 'Delivered' };
    }

    const orders = await Order.find(filter)
      .populate('assignedKarigar')
      .populate('assignedMachine')
      .populate('asterInventoryItem')
      .sort({ deliveryDate: 1 });

    const populatedOrders = [];
    for (let o of orders) {
      const payment = await Payment.findOne({ orderId: o._id });
      const delivery = await Delivery.findOne({ orderId: o._id });
      const item = o.toJSON();
      item.payment = payment;
      item.delivery = delivery;
      populatedOrders.push(item);
    }

    res.json(populatedOrders);
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get specific order details
// @route   GET /api/orders/:id
// @access  Private
export const getOrderById = async (req, res) => {
  try {
    const order = await findOrderScoped(req.params.id, req.user.shopId);
    if (!order) return res.status(404).json({ message: 'Order not found' });

    if (!order.shareToken) {
      order.shareToken = crypto.randomBytes(16).toString('hex');
      order.shareTokenExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
      await order.save();
    }

    await order.populate('customer');

    const payment = await Payment.findOne({ orderId: order._id });
    const delivery = await Delivery.findOne({ orderId: order._id });
    const measurements = order.customer
      ? await Measurement.findOne({ customerId: order.customer._id })
      : null;
    const transactions = await Transaction.find({ orderId: order._id }).sort({ date: 1 });

    const hasSnapshot = order.measurementsSnapshot &&
      (order.measurementsSnapshot.shirt || order.measurementsSnapshot.pant || order.measurementsSnapshot.others);
    const resolvedMeasurements = hasSnapshot ? order.measurementsSnapshot : measurements;

    const costPrice = order.asterInventoryItem?.costPerUnit || 0;
    const asterProfit = order.needsAster ? (order.asterSellingPrice - costPrice) * order.asterQuantity : 0;

    const result = order.toJSON();
    result.payment = payment;
    result.delivery = delivery;
    result.measurements = resolvedMeasurements;
    result.measurementsSnapshot = order.measurementsSnapshot || null;
    result.transactions = transactions;
    result.asterProfit = asterProfit;
    result.asterCostPrice = costPrice;

    res.json(result);
  } catch (error) {
    console.error('Get order by ID error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get specific order details for public guest invoice via share token
// @route   GET /api/orders/public/:token
// @access  Public
export const getOrderByIdPublic = async (req, res) => {
  try {
    const token = req.params.token || req.params.id;
    // Find by shareToken, or fallback to _id or orderId
    let order = await Order.findOne({ shareToken: token }).populate('customer');
    if (!order) {
      order = await Order.findOne({ $or: [{ _id: token }, { orderId: token }] }).populate('customer');
    }

    if (!order) {
      return res.status(404).json({ message: 'Invoice not found or link is invalid' });
    }

    // Check expiration
    if (order.shareTokenExpiresAt && new Date() > new Date(order.shareTokenExpiresAt)) {
      return res.status(410).json({
        message: 'This shared invoice link has expired. Please contact the tailor shop for an updated link.'
      });
    }

    // Ensure token is generated if opened via old id link
    if (!order.shareToken) {
      order.shareToken = crypto.randomBytes(16).toString('hex');
      order.shareTokenExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
      await order.save();
    }

    const payment = await Payment.findOne({ orderId: order._id });
    const delivery = await Delivery.findOne({ orderId: order._id });
    const measurements = order.customer
      ? await Measurement.findOne({ customerId: order.customer._id })
      : null;
    const transactions = await Transaction.find({ orderId: order._id }).sort({ date: 1 });
    const shop = await Shop.findById(order.shopId);

    const hasSnapshot = order.measurementsSnapshot &&
      (order.measurementsSnapshot.shirt || order.measurementsSnapshot.pant || order.measurementsSnapshot.others);
    const resolvedMeasurements = hasSnapshot ? order.measurementsSnapshot : measurements;

    // Build SANITIZED public invoice payload - STRICTLY stripping internal cost, profit, notes, karigar & machine assignments
    const publicInvoice = {
      _id: order._id,
      orderId: order.orderId,
      customerName: order.customerName,
      apparelType: order.apparelType,
      fabric: order.fabric || '',
      status: order.status,
      deliveryDate: order.deliveryDate,
      price: order.price,
      needsAster: Boolean(order.needsAster),
      asterQuantity: order.needsAster ? (order.asterQuantity || 0) : 0,
      asterSellingPrice: order.needsAster ? (order.asterSellingPrice || 0) : 0,
      measurementType: order.measurementType,
      shareToken: order.shareToken,
      shareTokenExpiresAt: order.shareTokenExpiresAt,
      measurements: resolvedMeasurements,
      measurementsSnapshot: resolvedMeasurements,
      items: Array.isArray(order.items)
        ? order.items.map((it) => ({
            id: it.id,
            name: it.name || it.apparelType,
            apparelType: it.apparelType,
            quantity: it.quantity || 1,
            price: it.price,
            fabric: it.fabric || '',
            needsAster: Boolean(it.needsAster),
            asterQuantity: it.asterQuantity || 0,
            asterSellingPrice: it.asterSellingPrice || 0,
          }))
        : [],
      payment: payment ? {
        totalAmount: payment.totalAmount,
        paidAmount: payment.paidAmount,
        balanceAmount: payment.balanceAmount,
        status: payment.status,
        paymentType: payment.paymentType,
      } : null,
      delivery: delivery ? {
        deliveryDate: delivery.deliveryDate,
        status: delivery.status,
      } : null,
      transactions: (transactions || []).map((tx) => ({
        _id: tx._id,
        amount: tx.amount,
        paymentType: tx.paymentType,
        type: tx.type,
        date: tx.date,
      })),
      shop: shop ? {
        _id: shop._id,
        shopName: shop.shopName,
        phone: shop.phone,
        address: shop.address,
      } : null,
    };

    res.json(publicInvoice);
  } catch (error) {
    console.error('Get public order by ID error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Generate or renew public invoice share token
// @route   POST /api/orders/:id/share-token
// @access  Private
export const generateShareToken = async (req, res) => {
  try {
    const order = await findOrderScoped(req.params.id, req.user.shopId);
    if (!order) return res.status(404).json({ message: 'Order not found' });

    order.shareToken = crypto.randomBytes(16).toString('hex');
    order.shareTokenExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
    await order.save();

    res.json({
      shareToken: order.shareToken,
      shareTokenExpiresAt: order.shareTokenExpiresAt,
      shareUrl: `/invoice/share/${order.shareToken}`,
    });
  } catch (error) {
    console.error('Generate share token error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update order active stage or details
// @route   PUT /api/orders/:id
// @access  Private
export const updateOrder = async (req, res) => {
  try {
    const result = await updateOrderService(req.params.id, req.body, req.user.shopId, req.user.name);
    if (!result) return res.status(404).json({ message: 'Order not found' });
    res.json(result);
  } catch (error) {
    console.error('Update order error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Receive payment against an order
// @route   POST /api/orders/:id/payments
// @access  Private
export const recordOrderPayment = async (req, res) => {
  try {
    const order = await findOrderScoped(req.params.id, req.user.shopId);
    if (!order) return res.status(404).json({ message: 'Order not found' });

    const { amount, paymentType } = req.body;
    if (!amount || Number(amount) <= 0) {
      return res.status(400).json({ message: 'Please provide a positive payment amount' });
    }

    await Transaction.create({
      shopId: req.user.shopId,
      orderId: order._id,
      amount: Number(amount),
      paymentType: paymentType || 'Cash',
      type: 'Payment',
    });

    const payment = await syncPaymentFromTransactions(order._id, req.user.shopId);

    await dispatchNotification({
      shopId: req.user.shopId,
      customerId: order.customer,
      orderId: order._id,
      title: 'Payment Received',
      message: `Payment of ₹${amount} received for order ${order.orderId}. New balance: ₹${payment.balanceAmount}.`,
      type: 'payment',
    });

    const result = order.toJSON();
    result.payment = payment;
    result.delivery = await Delivery.findOne({ orderId: order._id });

    res.json(result);
  } catch (error) {
    console.error('Record payment error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete a specific order and clean up associated records
// @route   DELETE /api/orders/:id
// @access  Private
export const deleteOrder = async (req, res) => {
  try {
    const success = await deleteOrderService(req.params.id, req.user.shopId);
    if (!success) return res.status(404).json({ message: 'Order not found' });
    res.json({ message: 'Order and associated records deleted successfully' });
  } catch (error) {
    console.error('Delete order error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Add an internal note to an order
// @route   POST /api/orders/:id/notes
// @access  Private
export const addNoteToOrder = async (req, res) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ message: 'Note text is required' });
    }

    const order = await findOrderScoped(req.params.id, req.user.shopId);
    if (!order) return res.status(404).json({ message: 'Order not found' });

    if (!Array.isArray(order.notes)) {
      order.notes = [];
    }
    order.notes.push({ text: text.trim(), addedAt: new Date() });
    await order.save();

    res.status(201).json({ notes: order.notes });
  } catch (error) {
    console.error('Add note error:', error);
    res.status(500).json({ message: error.message });
  }
};
