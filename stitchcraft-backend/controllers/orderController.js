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
import {
  recordOrderPaymentAtomic,
  recordOrderRefundAtomic,
} from '../services/financialService.js';
import { serializeOrderForRole } from '../services/serializerService.js';

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
    const userRole = (req.user.role || 'staff').toLowerCase();
    const isKarigar = userRole === 'karigar' || userRole === 'tailor';
    const { status, urgency, type } = req.query;

    const additionalCriteria = { isDeleted: { $ne: true } };
    if (status) additionalCriteria.status = status;
    if (urgency === 'high') {
      const threeDaysLater = new Date();
      threeDaysLater.setDate(threeDaysLater.getDate() + 3);
      additionalCriteria.deliveryDate = { $lte: threeDaysLater };
      additionalCriteria.status = { $ne: 'Delivered' };
    }

    let orders = [];

    if (isKarigar) {
      // Karigars strictly see only jobs assigned to them within the shop
      const karigarIdentifier = req.user.karigarId || req.user._id;
      orders = await Order.find({
        shopId: req.user.shopId,
        assignedKarigar: karigarIdentifier,
        ...additionalCriteria,
      })
        .populate('assignedKarigar')
        .populate('assignedMachine')
        .populate('asterInventoryItem')
        .sort({ deliveryDate: 1 });
    } else if (type === 'partner_jobs' || type === 'external_jobs') {
      orders = await Order.find({
        delegatedToShopId: req.user.shopId,
        ...additionalCriteria,
      })
        .populate('assignedKarigar')
        .populate('assignedMachine')
        .populate('asterInventoryItem')
        .sort({ deliveryDate: 1 });
    } else if (type === 'my_delegated') {
      orders = await Order.find({
        shopId: req.user.shopId,
        delegationStatus: 'assigned',
        ...additionalCriteria,
      })
        .populate('assignedKarigar')
        .populate('assignedMachine')
        .populate('asterInventoryItem')
        .sort({ deliveryDate: 1 });
    } else if (type === 'own' || type === 'in_house') {
      orders = await Order.find({
        shopId: req.user.shopId,
        ...additionalCriteria,
      })
        .populate('assignedKarigar')
        .populate('assignedMachine')
        .populate('asterInventoryItem')
        .sort({ deliveryDate: 1 });
    } else {
      // By default, fetch orders originating in this shop AND outsourced to this shop
      // using direct indexed tenant predicates (eliminating unfiltered $or query shapes)
      const [ownOrders, delegatedOrders] = await Promise.all([
        Order.find({
          shopId: req.user.shopId,
          ...additionalCriteria,
        })
          .populate('assignedKarigar')
          .populate('assignedMachine')
          .populate('asterInventoryItem'),
        Order.find({
          delegatedToShopId: req.user.shopId,
          ...additionalCriteria,
        })
          .populate('assignedKarigar')
          .populate('assignedMachine')
          .populate('asterInventoryItem'),
      ]);

      const orderMap = new Map();
      for (const o of ownOrders) orderMap.set(String(o._id), o);
      for (const o of delegatedOrders) orderMap.set(String(o._id), o);
      orders = Array.from(orderMap.values());
      orders.sort((a, b) => new Date(a.deliveryDate || 0) - new Date(b.deliveryDate || 0));
    }

    // Eliminate N+1 queries: Batch-fetch payment and delivery records in O(1) database trips
    const orderIds = orders.map((o) => o._id);
    let payments = [];
    let deliveries = [];

    if (orderIds.length > 0) {
      [payments, deliveries] = await Promise.all([
        Payment.find({ orderId: { $in: orderIds } }),
        Delivery.find({ orderId: { $in: orderIds } }),
      ]);
    }

    const paymentMap = new Map();
    for (const p of payments) {
      paymentMap.set(String(p.orderId), p);
    }

    const deliveryMap = new Map();
    for (const d of deliveries) {
      deliveryMap.set(String(d.orderId), d);
    }

    const populatedOrders = orders.map((o) => {
      const payment = paymentMap.get(String(o._id)) || null;
      const delivery = deliveryMap.get(String(o._id)) || null;
      const item = typeof o.toJSON === 'function' ? o.toJSON() : { ...o };
      item.payment = payment;
      item.delivery = delivery;

      // Authoritative privacy & sanitization for partner tailors and roles
      const sanitizedPartner = sanitizeOrderForPartnerTailor(item, req.user.shopId);
      return serializeOrderForRole(sanitizedPartner, userRole);
    });

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

    const userRole = (req.user.role || 'staff').toLowerCase();
    const isKarigar = userRole === 'karigar' || userRole === 'tailor';

    if (isKarigar) {
      const karigarIdentifier = String(req.user.karigarId || req.user._id);
      const orderKarigar = order.assignedKarigar?._id || order.assignedKarigar;
      if (!orderKarigar || String(orderKarigar) !== karigarIdentifier) {
        return res.status(403).json({
          message: 'Forbidden: Karigars can only access orders assigned to them.',
        });
      }
    }

    if (!order.shareToken) {
      const rawToken = crypto.randomBytes(24).toString('hex');
      order.shareToken = rawToken;
      order.shareTokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
      order.shareTokenExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
      order.shareTokenRevokedAt = null;
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
    const finalResult = serializeOrderForRole(sanitized, userRole);
    res.json(finalResult);
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
    const rawParam = req.params.token || req.params.id;
    if (!rawParam || typeof rawParam !== 'string') {
      return res.status(400).json({ message: 'Invalid or missing share token' });
    }
    const token = rawParam.trim();

    // STRICT: Look up ONLY by shareTokenHash or shareToken.
    // ABSOLUTELY NO fallback to _id or orderId (P0-01).
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const order = await Order.findOne({
      $or: [
        { shareTokenHash: tokenHash },
        { shareToken: token },
      ],
    }).populate('customer').populate('asterInventoryItem');

    if (!order) {
      return res.status(404).json({ message: 'Invoice not found or link is invalid' });
    }

    // Check revocation (P0-01)
    if (order.shareTokenRevokedAt) {
      return res.status(410).json({
        message: 'This shared invoice link has been revoked. Please contact the tailor shop for an updated link.',
      });
    }

    // Check expiration (P0-01: 30-day default window)
    if (order.shareTokenExpiresAt && new Date() > new Date(order.shareTokenExpiresAt)) {
      return res.status(410).json({
        message: 'This shared invoice link has expired. Please contact the tailor shop for an updated link.',
      });
    }

    const payment = await Payment.findOne({ orderId: order._id });
    const delivery = await Delivery.findOne({ orderId: order._id });
    const transactions = await Transaction.find({ orderId: order._id }).sort({ date: 1 });
    const shop = await Shop.findById(order.shopId);

    // Build MINIMAL SANITIZED public invoice payload (INV-06, 07; SEC-02)
    // Strictly zero leakage: NO phone, NO address, NO measurements, NO internal costs/margins/notes/karigar/machine, NO token echo.
    const publicInvoice = {
      orderId: order.orderId,
      customerName: order.customerName || (order.customer ? order.customer.name : 'Valued Customer'),
      apparelType: order.apparelType,
      fabric: order.fabric || '',
      status: order.status,
      date: order.createdAt || order.date,
      deliveryDate: order.deliveryDate,
      price: order.price,
      needsAster: Boolean(order.needsAster),
      asterQuantity: order.needsAster ? (order.asterQuantity || 0) : 0,
      asterSellingPrice: order.needsAster ? (order.asterSellingPrice || 0) : 0,
      asterItemName: order.asterInventoryItem?.itemName || order.asterInventoryItem?.name || 'Lining Material',
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
    console.error('Get public order by token error:', error);
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

    const rawToken = crypto.randomBytes(24).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');

    order.shareToken = rawToken;
    order.shareTokenHash = tokenHash;
    order.shareTokenExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
    order.shareTokenRevokedAt = null;
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

// @desc    Revoke public invoice share token
// @route   POST /api/orders/:id/revoke-share-token
// @access  Private
export const revokeShareToken = async (req, res) => {
  try {
    const order = await findOrderScoped(req.params.id, req.user.shopId);
    if (!order) return res.status(404).json({ message: 'Order not found' });

    order.shareTokenRevokedAt = new Date().toISOString();
    await order.save();

    res.json({
      message: 'Share token has been revoked successfully',
      revokedAt: order.shareTokenRevokedAt,
    });
  } catch (error) {
    console.error('Revoke share token error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update order active stage or details
// @route   PUT /api/orders/:id
// @access  Private
export const updateOrder = async (req, res) => {
  try {
    const userRole = (req.user?.role || 'staff').toLowerCase();
    const isKarigar = userRole === 'karigar' || userRole === 'tailor';

    if (isKarigar) {
      // Verify karigar is assigned to this order
      const existingOrder = await findOrderScoped(req.params.id, req.user.shopId);
      if (!existingOrder) return res.status(404).json({ message: 'Order not found' });

      const karigarIdentifier = String(req.user.karigarId || req.user._id);
      const orderKarigar = existingOrder.assignedKarigar?._id || existingOrder.assignedKarigar;
      if (!orderKarigar || String(orderKarigar) !== karigarIdentifier) {
        return res.status(403).json({
          message: 'Forbidden: Karigars can only update orders assigned to them.',
        });
      }

      // Karigars cannot alter financial, pricing, or assignment fields
      const restrictedFields = ['price', 'items', 'customer', 'customerName', 'assignedKarigar', 'assignedMachine', 'delegatedToShopId', 'advance_amount'];
      for (const field of restrictedFields) {
        delete req.body[field];
      }
    }

    const result = await updateOrderService(req.params.id, req.body, req.user.shopId, req.user.name);
    if (!result) return res.status(404).json({ message: 'Order not found' });
    const sanitized = sanitizeOrderForPartnerTailor(result, req.user.shopId);
    const finalResult = serializeOrderForRole(sanitized, userRole);
    res.json(finalResult);
  } catch (error) {
    console.error('Update order error:', error);
    res.status(error.statusCode || 500).json({
      message: error.message,
      error: error.message,
      serverVersion: error.serverVersion,
      currentData: error.currentData,
      requiresCreditApproval: error.requiresCreditApproval || false,
      balanceAmount: error.balanceAmount,
    });
  }
};

// @desc    Receive payment against an order (atomic - Phase 3, 7.2)
// @route   POST /api/orders/:id/payments
// @access  Private
export const recordOrderPayment = async (req, res) => {
  try {
    const idempotencyKey = req.headers['idempotency-key'] || req.body.idempotencyKey || req.body.clientMutationId;
    const sanitized = await recordOrderPaymentAtomic({
      shopId: req.user.shopId,
      orderId: req.params.id,
      amount: req.body.amount,
      paymentType: req.body.paymentType,
      idempotencyKey,
      recordedBy: req.user.name || 'Owner',
    });
    res.json(sanitized);
  } catch (error) {
    console.error('Record payment error:', error);
    res.status(error.statusCode || 500).json({ message: error.message });
  }
};

// @desc    Record an immutable refund/reversal against an order (atomic - Phase 3, 7.2)
// @route   POST /api/orders/:id/refunds
// @access  Private
export const recordOrderRefund = async (req, res) => {
  try {
    const idempotencyKey = req.headers['idempotency-key'] || req.body.idempotencyKey || req.body.clientMutationId;
    const sanitized = await recordOrderRefundAtomic({
      shopId: req.user.shopId,
      orderId: req.params.id,
      amount: req.body.amount,
      reason: req.body.reason,
      paymentType: req.body.paymentType,
      idempotencyKey,
      processedBy: req.user.name || 'Owner',
    });
    res.json(sanitized);
  } catch (error) {
    console.error('Record refund error:', error);
    res.status(error.statusCode || 500).json({ message: error.message });
  }
};

// @desc    Delete a specific order and clean up associated records
// @route   DELETE /api/orders/:id
// @access  Private
export const deleteOrder = async (req, res) => {
  try {
    if (req.user?.role !== 'owner') {
      return res.status(403).json({ message: 'Forbidden: only shop owners can delete orders' });
    }
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
