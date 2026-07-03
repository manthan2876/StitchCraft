/* controllers/orderController.js */
import Order from '../models/Order.js';
import Payment from '../models/Payment.js';
import Delivery from '../models/Delivery.js';
import Notification from '../models/Notification.js';
import Measurement from '../models/Measurement.js';
import Transaction from '../models/Transaction.js';
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
    const { customerName, apparelType, deliveryDate, price } = req.body;
    if (!customerName || !apparelType || !deliveryDate || price === undefined) {
      return res.status(400).json({ message: 'Please provide customerName, apparelType, deliveryDate, and price' });
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
    const filter = { shopId: req.user.shopId };

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

// @desc    Get specific order details for public guest invoice
// @route   GET /api/orders/public/:id
// @access  Public
export const getOrderByIdPublic = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('assignedKarigar')
      .populate('assignedMachine')
      .populate('asterInventoryItem')
      .populate('customer');

    if (!order) return res.status(404).json({ message: 'Order not found' });

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
    console.error('Get public order by ID error:', error);
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

    await Notification.create({
      shopId: req.user.shopId,
      customerId: order.customer,
      orderId: order._id,
      message: `Payment of ₹${amount} received for order ${order.orderId}. New balance: ₹${payment.balanceAmount}.`,
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
