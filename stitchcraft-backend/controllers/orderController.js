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
  delegateOrderService,
  revokeDelegationService,
  sanitizeOrderForPartnerTailor,
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

    const idempotencyKey = req.headers['idempotency-key'] || req.body.idempotencyKey || req.body.clientMutationId;
    const result = await createOrderService({ ...req.body, idempotencyKey }, req.user.shopId, req.user._id);
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
    const { status, urgency, type } = req.query;
    let filter;

    // Support fetching jobs delegated from other tailor shops to this shop
    if (type === 'partner_jobs' || type === 'external_jobs') {
      filter = { delegatedToShopId: req.user.shopId, isDeleted: { $ne: true } };
    } else if (type === 'my_delegated') {
      filter = { shopId: req.user.shopId, delegationStatus: 'assigned', isDeleted: { $ne: true } };
    } else if (type === 'own' || type === 'in_house') {
      filter = { shopId: req.user.shopId, isDeleted: { $ne: true } };
    } else {
      // By default, include orders originating in this shop OR outsourced to this shop
      filter = {
        $or: [
          { shopId: req.user.shopId },
          { delegatedToShopId: req.user.shopId },
        ],
        isDeleted: { $ne: true },
      };
    }

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

      // Authoritative privacy & sanitization for partner tailors
      const sanitized = sanitizeOrderForPartnerTailor(item, req.user.shopId);
      populatedOrders.push(sanitized);
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
    try {
      await order.populate('asterInventoryItem');
    } catch (_) {}

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

    const sanitized = sanitizeOrderForPartnerTailor(result, req.user.shopId);
    res.json(sanitized);
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
    let order = await Order.findOne({ shareToken: token }).populate('customer').populate('asterInventoryItem');
    if (!order) {
      order = await Order.findOne({ $or: [{ _id: token }, { orderId: token }] }).populate('customer').populate('asterInventoryItem');
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

    let customerPhone = order.customerPhone || order.customer?.phone || '';
    let customerAddress = order.customer?.address || '';
    if (!customerPhone && order.customer) {
      try {
        const custId = order.customer._id || order.customer;
        const custDoc = await Customer.findById(custId);
        if (custDoc) {
          customerPhone = custDoc.phone || '';
          customerAddress = custDoc.address || '';
        }
      } catch (_) {}
    }

    // Build SANITIZED public invoice payload - STRICTLY stripping internal cost, profit, notes, karigar & machine assignments
    const publicInvoice = {
      _id: order._id,
      orderId: order.orderId,
      customerName: order.customerName,
      customerPhone: customerPhone,
      customer: {
        name: order.customerName,
        phone: customerPhone,
        address: customerAddress,
      },
      apparelType: order.apparelType,
      fabric: order.fabric || '',
      status: order.status,
      deliveryDate: order.deliveryDate,
      price: order.price,
      needsAster: Boolean(order.needsAster),
      asterQuantity: order.needsAster ? (order.asterQuantity || 0) : 0,
      asterSellingPrice: order.needsAster ? (order.asterSellingPrice || 0) : 0,
      asterItemName: order.asterInventoryItem?.itemName || order.asterInventoryItem?.name || 'Lining Material',
      asterInventoryItem: order.asterInventoryItem ? {
        itemName: order.asterInventoryItem.itemName || order.asterInventoryItem.name || 'Lining Material',
        unit: order.asterInventoryItem.unit || 'm',
      } : null,
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
        upiId: shop.upiId || '',
        gstin: shop.gstin || '',
        logoUrl: shop.logoUrl || '',
        invoicePrefix: shop.invoicePrefix || 'INV',
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
    const sanitized = sanitizeOrderForPartnerTailor(result, req.user.shopId);
    res.json(sanitized);
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

    let { amount, paymentType } = req.body;
    if (!amount || Number(amount) <= 0) {
      return res.status(400).json({ message: 'Please provide a positive payment amount' });
    }

    if (paymentType && typeof paymentType === 'string') {
      const pt = paymentType.trim().toLowerCase();
      if (pt === 'cash') paymentType = 'Cash';
      else if (pt === 'upi' || pt === 'online') paymentType = 'UPI';
      else if (pt === 'card') paymentType = 'Card';
      else if (pt === 'credit') paymentType = 'Credit';
      else if (pt === 'bank') paymentType = 'Bank';
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

    const sanitized = sanitizeOrderForPartnerTailor(result, req.user.shopId);
    res.json(sanitized);
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

// @desc    Delegate/outsource an order to another tailor shop
// @route   POST /api/orders/:id/delegate
// @access  Private
export const delegateOrder = async (req, res) => {
  try {
    const { targetShopId, targetShopName, targetPhone, notes, agreedCost } = req.body;
    if (!targetShopId) {
      return res.status(400).json({ message: 'Target partner tailor/shop ID is required' });
    }
    if (String(targetShopId) === String(req.user.shopId)) {
      return res.status(400).json({ message: 'Cannot delegate an order to your own shop' });
    }

    const updated = await delegateOrderService(req.params.id, req.user.shopId, {
      targetShopId,
      targetShopName,
      targetPhone,
      notes,
      agreedCost,
    });

    if (!updated) {
      return res.status(404).json({ message: 'Order not found in your shop' });
    }

    res.json(updated);
  } catch (error) {
    console.error('Delegate order error:', error);
    res.status(error.message?.includes('Cannot') ? 400 : 500).json({ message: error.message });
  }
};

// @desc    Revoke delegation and recall order to main tailor
// @route   POST /api/orders/:id/revoke-delegation
// @access  Private
export const revokeDelegation = async (req, res) => {
  try {
    const updated = await revokeDelegationService(req.params.id, req.user.shopId);
    if (!updated) {
      return res.status(404).json({ message: 'Order not found in your shop' });
    }
    res.json(updated);
  } catch (error) {
    console.error('Revoke delegation error:', error);
    res.status(error.message?.includes('Cannot') ? 400 : 500).json({ message: error.message });
  }
};
