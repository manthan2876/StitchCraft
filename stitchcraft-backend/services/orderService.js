/* services/orderService.js */
import crypto from 'node:crypto';
import Order from '../models/Order.js';
import Customer from '../models/Customer.js';
import Payment from '../models/Payment.js';
import Delivery from '../models/Delivery.js';
import Notification from '../models/Notification.js';
import Measurement from '../models/Measurement.js';
import Inventory from '../models/Inventory.js';
import Transaction from '../models/Transaction.js';
import { isValidIdentifier } from '../utils/identifiers.js';
import { dispatchNotification } from './notificationService.js';

// Deduct inventory when order reaches production workshop stages
export const ASTAR_DEDUCT_STATUSES = ['Stitching', 'Checking', 'Ready', 'Delivered'];

export const findOrderScoped = async (id, shopId) => {
  const baseCondition = isValidIdentifier(id)
    ? { _id: id }
    : { orderId: typeof id === 'string' ? id : '' };
  const query = {
    ...baseCondition,
    $or: [{ shopId }, { delegatedToShopId: shopId }],
  };
  return await Order.findOne(query)
    .populate('assignedKarigar')
    .populate('assignedMachine')
    .populate('asterInventoryItem');
};

export const syncPaymentFromTransactions = async (orderId, shopId) => {
  const order = await Order.findById(orderId);
  if (!order) return null;

  const asterPrice = order.needsAster ? (order.asterSellingPrice * order.asterQuantity) : 0;
  const totalOrderValue = order.price + asterPrice;

  const transactions = await Transaction.find({ orderId, shopId });
  const totalPaid = transactions.reduce((sum, tx) => {
    if (tx.type === 'Payment') return sum + tx.amount;
    if (tx.type === 'Refund') return sum - tx.amount;
    return sum;
  }, 0);

  let payment = await Payment.findOne({ orderId, shopId });
  if (!payment) {
    payment = new Payment({ orderId, shopId, totalAmount: totalOrderValue });
  } else {
    payment.totalAmount = totalOrderValue;
  }

  payment.paidAmount = totalPaid;
  payment.balanceAmount = Math.max(0, payment.totalAmount - totalPaid);
  payment.status = payment.balanceAmount === 0 ? 'Paid' : (totalPaid > 0 ? 'Partial' : 'Pending');

  await payment.save();
  return payment;
};

export const resolveCustomer = async (reqBody, shopId) => {
  const { customerId, customerName, customerPhone, customerAddress } = reqBody;
  let customerObj = null;

  if (customerId) {
    const custQuery = isValidIdentifier(customerId)
      ? { _id: customerId, shopId }
      : { customerId, shopId };
    customerObj = await Customer.findOne(custQuery);
  }

  if (!customerObj) {
    const nameQuery = customerPhone
      ? { name: customerName, phone: customerPhone, shopId }
      : { name: customerName, shopId };
    customerObj = await Customer.findOne(nameQuery);
  }

  if (!customerObj) {
    customerObj = await Customer.create({
      name: customerName,
      phone: customerPhone || '0000000000',
      email: '',
      address: customerAddress || '',
      shopId,
      ordersCount: 1,
    });
  } else {
    customerObj.ordersCount = (customerObj.ordersCount || 0) + 1;
    await customerObj.save();
  }

  return customerObj;
};

export const updateCustomerMeasurements = async (customerId, measurements, shopId) => {
  let measurementRecord = await Measurement.findOne({ customerId });
  if (!measurementRecord) {
    measurementRecord = new Measurement({
      shopId,
      customerId,
    });
  }

  if (measurements.shirt) {
    measurementRecord.shirt = {
      ...(measurementRecord.shirt?.toObject?.() || measurementRecord.shirt || {}),
      ...measurements.shirt,
    };
  }
  if (measurements.pant) {
    measurementRecord.pant = {
      ...(measurementRecord.pant?.toObject?.() || measurementRecord.pant || {}),
      ...measurements.pant,
    };
  }
  if (measurements.others !== undefined) {
    measurementRecord.others = measurements.others;
  }
  await measurementRecord.save();
  return measurementRecord;
};

export const handleAstarStockAdjustment = async (order, newStatus, shopId) => {
  const willDeduct = ASTAR_DEDUCT_STATUSES.includes(newStatus);
  const wasDeducted = order.asterDeducted;

  // 1. Top-level Aster inventory item
  if (order.needsAster && order.asterQuantity > 0 && order.asterInventoryItem) {
    if (willDeduct && !wasDeducted) {
      const invItem = await Inventory.findOne({ _id: order.asterInventoryItem, shopId });
      if (invItem) {
        invItem.quantity = Math.max(0, invItem.quantity - order.asterQuantity);
        await invItem.save();
        order.asterDeducted = true;
        order.inventoryDeductedAt = new Date().toISOString();
        await dispatchNotification({
          shopId,
          orderId: order._id,
          title: 'Stock Updated',
          message: `Astar stock reduced by ${order.asterQuantity} ${invItem.unit} for order ${order.orderId} (${invItem.itemName}).`,
          type: 'inventory',
        });

        // Trigger device push if stock reaches or drops below minimum threshold
        const threshold = invItem.minQuantity !== undefined ? invItem.minQuantity : 5;
        if (invItem.quantity <= threshold) {
          await dispatchNotification({
            shopId,
            orderId: order._id,
            title: '⚠️ Low Stock Alert',
            message: `${invItem.itemName} is running low! Remaining: ${invItem.quantity} ${invItem.unit} (Minimum: ${threshold} ${invItem.unit}).`,
            type: 'low_stock',
            sendPush: true,
          });
        }
      }
    } else if (!willDeduct && wasDeducted) {
      const invItem = await Inventory.findOne({ _id: order.asterInventoryItem, shopId });
      if (invItem) {
        invItem.quantity = invItem.quantity + order.asterQuantity;
        await invItem.save();
        order.asterDeducted = false;
        order.inventoryDeductedAt = null;
      }
    }
  }

  // 2. Multi-item aster inventories if present
  if (Array.isArray(order.items)) {
    for (const item of order.items) {
      if (item.needsAster && item.asterQuantity > 0 && item.asterInventoryItem) {
        const itemQty = (item.quantity || 1) * item.asterQuantity;
        if (willDeduct && !item.asterDeducted) {
          const invItem = await Inventory.findOne({ _id: item.asterInventoryItem, shopId });
          if (invItem) {
            invItem.quantity = Math.max(0, invItem.quantity - itemQty);
            await invItem.save();
            item.asterDeducted = true;
            item.inventoryDeductedAt = new Date().toISOString();
          }
        } else if (!willDeduct && item.asterDeducted) {
          const invItem = await Inventory.findOne({ _id: item.asterInventoryItem, shopId });
          if (invItem) {
            invItem.quantity = invItem.quantity + itemQty;
            await invItem.save();
            item.asterDeducted = false;
            item.inventoryDeductedAt = null;
          }
        }
      }
    }
  }
};

// Core Business Logic: Create Order
export const createOrderService = async (reqBody, shopId, userId) => {
  const {
    customerName,
    apparelType: rawApparelType,
    deliveryDate,
    price: rawPrice,
    advancePaid,
    fabric: rawFabric,
    paymentType,
    measurements,
    needsAster: rawNeedsAster,
    asterQuantity: rawAsterQuantity,
    asterInventoryItem: rawAsterInventoryItem,
    asterSellingPrice: rawAsterSellingPrice,
    assignedKarigar,
    assignedMachine,
    measurementType,
    maapImageUrl,
    fabricImageUrl,
    items: rawItems,
    idempotencyKey: rawIdempotencyKey,
  } = reqBody;

  const idempotencyKey = rawIdempotencyKey || reqBody.clientMutationId || reqBody.localOrderId;
  if (idempotencyKey) {
    const existingOrder = await Order.findOne({ shopId, idempotencyKey });
    if (existingOrder) {
      const payment = await Payment.findOne({ orderId: existingOrder._id, shopId });
      const delivery = await Delivery.findOne({ orderId: existingOrder._id, shopId });
      const resObj = typeof existingOrder.toJSON === 'function' ? existingOrder.toJSON() : { ...existingOrder };
      resObj.payment = payment;
      resObj.delivery = delivery;
      return resObj;
    }
  }

  const customerObj = await resolveCustomer(reqBody, shopId);

  if (measurementType !== 'Maap' && measurements) {
    await updateCustomerMeasurements(customerObj._id, measurements, shopId);
  }

  let measurementsSnapshot = null;
  if (measurements) {
    measurementsSnapshot = {
      shirt: measurements.shirt || null,
      pant: measurements.pant || null,
      others: measurements.others || '',
    };
  } else {
    const template = await Measurement.findOne({ customerId: customerObj._id });
    if (template) {
      measurementsSnapshot = {
        shirt: template.shirt ? (typeof template.shirt.toObject === 'function' ? template.shirt.toObject() : template.shirt) : null,
        pant: template.pant ? (typeof template.pant.toObject === 'function' ? template.pant.toObject() : template.pant) : null,
        others: template.others || '',
      };
    }
  }

  // Multi-item garment normalization:
  let items = [];
  if (Array.isArray(rawItems) && rawItems.length > 0) {
    items = rawItems.map((it, idx) => ({
      id: it.id || crypto.randomUUID(),
      name: it.name || it.apparelType || `Garment #${idx + 1}`,
      apparelType: it.apparelType || it.name || 'Custom Garment',
      quantity: Number(it.quantity) > 0 ? Number(it.quantity) : 1,
      price: Number(it.price) >= 0 ? Number(it.price) : 0,
      fabric: it.fabric || rawFabric || '',
      measurements: it.measurements || null,
      needsAster: Boolean(it.needsAster),
      asterQuantity: it.needsAster ? (Number(it.asterQuantity) || 0) : 0,
      asterInventoryItem: (it.needsAster && it.asterInventoryItem) ? it.asterInventoryItem : null,
      asterSellingPrice: it.needsAster ? (Number(it.asterSellingPrice) || 0) : 0,
      notes: it.notes || '',
    }));
  } else {
    // Single garment fallback for backward compatibility
    items = [{
      id: crypto.randomUUID(),
      name: rawApparelType || 'Custom Garment',
      apparelType: rawApparelType || 'Custom Garment',
      quantity: 1,
      price: Number(rawPrice) >= 0 ? Number(rawPrice) : 0,
      fabric: rawFabric || '',
      measurements: measurementsSnapshot,
      needsAster: Boolean(rawNeedsAster),
      asterQuantity: rawNeedsAster ? (Number(rawAsterQuantity) || 0) : 0,
      asterInventoryItem: (rawNeedsAster && rawAsterInventoryItem) ? rawAsterInventoryItem : null,
      asterSellingPrice: rawNeedsAster ? (Number(rawAsterSellingPrice) || 0) : 0,
      notes: '',
    }];
  }

  // Calculate aggregated price
  const itemsTotalPrice = items.reduce((sum, it) => sum + (it.price * it.quantity), 0);
  const effectivePrice = (rawPrice !== undefined && rawPrice !== null && rawPrice !== '')
    ? Number(rawPrice)
    : itemsTotalPrice;

  // Synthesize top-level apparel string
  const synthesizedApparelType = rawApparelType || items.map((it) => `${it.apparelType}${it.quantity > 1 ? ` (${it.quantity})` : ''}`).join(', ');

  // Synthesize Aster totals across items + top-level
  const hasItemAster = items.some((it) => it.needsAster);
  const effectiveNeedsAster = Boolean(rawNeedsAster || hasItemAster);
  const totalItemAsterQty = items.reduce((s, it) => s + (it.needsAster ? (it.asterQuantity * it.quantity) : 0), 0);
  const totalItemAsterPrice = items.reduce((s, it) => s + (it.needsAster ? (it.asterQuantity * it.quantity * it.asterSellingPrice) : 0), 0);

  const effectiveAsterQty = (rawAsterQuantity !== undefined && rawAsterQuantity !== null && rawAsterQuantity !== '')
    ? Number(rawAsterQuantity)
    : totalItemAsterQty;

  const effectiveAsterSellingPrice = (rawAsterSellingPrice !== undefined && rawAsterSellingPrice !== null && rawAsterSellingPrice !== '')
    ? Number(rawAsterSellingPrice)
    : (effectiveAsterQty > 0 ? (totalItemAsterPrice / effectiveAsterQty) : 0);

  const asterTotalCharge = (rawNeedsAster
    ? (effectiveAsterQty * effectiveAsterSellingPrice)
    : totalItemAsterPrice);

  const rawShareToken = crypto.randomBytes(24).toString('hex');
  const shareTokenHash = crypto.createHash('sha256').update(rawShareToken).digest('hex');

  const order = await Order.create({
    customerName: customerObj.name,
    customer: customerObj._id,
    apparelType: synthesizedApparelType,
    deliveryDate,
    price: effectivePrice,
    fabric: rawFabric || items[0]?.fabric || '',
    shopId,
    status: 'Incoming',
    needsAster: effectiveNeedsAster,
    asterQuantity: effectiveNeedsAster ? effectiveAsterQty : 0,
    asterInventoryItem: (effectiveNeedsAster && rawAsterInventoryItem) ? rawAsterInventoryItem : null,
    asterSellingPrice: effectiveNeedsAster ? effectiveAsterSellingPrice : 0,
    measurementType: measurementType || 'Maap',
    maapImageUrl: maapImageUrl || '',
    fabricImageUrl: fabricImageUrl || '',
    assignedKarigar: assignedKarigar || null,
    assignedMachine: assignedMachine || null,
    measurementsSnapshot,
    items,
    idempotencyKey: idempotencyKey || null,
    shareToken: rawShareToken,
    shareTokenHash,
    shareTokenExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    shareTokenRevokedAt: null,
  });

  let effectivePaymentType = paymentType || 'Cash';
  if (typeof effectivePaymentType === 'string') {
    const pt = effectivePaymentType.trim().toLowerCase();
    if (pt === 'cash') effectivePaymentType = 'Cash';
    else if (pt === 'upi' || pt === 'online') effectivePaymentType = 'UPI';
    else if (pt === 'card') effectivePaymentType = 'Card';
    else if (pt === 'credit') effectivePaymentType = 'Credit';
    else if (pt === 'bank') effectivePaymentType = 'Bank';
  }

  const payment = await Payment.create({
    shopId,
    orderId: order._id,
    totalAmount: effectivePrice + asterTotalCharge,
    paidAmount: advancePaid || 0,
    paymentType: effectivePaymentType,
  });

  if (advancePaid && Number(advancePaid) > 0) {
    await Transaction.create({
      shopId,
      orderId: order._id,
      amount: Number(advancePaid),
      paymentType: effectivePaymentType,
      type: 'Payment',
    });
    await syncPaymentFromTransactions(order._id, shopId);
  }

  const delivery = await Delivery.create({
    shopId,
    orderId: order._id,
    deliveryDate,
    status: 'Pending',
  });

  await dispatchNotification({
    shopId,
    customerId: customerObj._id,
    orderId: order._id,
    title: 'New Order Created',
    message: `New order ${order.orderId} created for ${customerObj.name}. Delivery due on ${new Date(deliveryDate).toLocaleDateString()}.`,
    type: 'order_status',
  });

  const result = order.toJSON();
  result.payment = payment;
  result.delivery = delivery;
  return result;
};

// Core Business Logic: Update Order
export const updateOrderService = async (orderId, reqBody, shopId, userName) => {
  const order = await findOrderScoped(orderId, shopId);
  if (!order) return null;

  const {
    status,
    deliveryDate,
    price,
    fabric,
    needsAster,
    asterQuantity,
    asterInventoryItem,
    asterSellingPrice,
    assignedKarigar,
    assignedMachine,
    measurementType,
    maapImageUrl,
    fabricImageUrl,
    items,
  } = reqBody;

  if (deliveryDate) {
    order.deliveryDate = deliveryDate;
    await Delivery.updateOne({ orderId: order._id }, { deliveryDate });
  }
  if (items && Array.isArray(items)) {
    order.items = items;
    if (price === undefined) {
      order.price = items.reduce((s, it) => s + ((it.price || 0) * (it.quantity || 1)), 0);
    }
  }
  if (price !== undefined) order.price = price;
  if (fabric !== undefined) order.fabric = fabric;
  if (needsAster !== undefined) order.needsAster = needsAster;
  if (asterQuantity !== undefined) order.asterQuantity = Number(asterQuantity) || 0;
  if (asterInventoryItem !== undefined) order.asterInventoryItem = asterInventoryItem || null;
  if (asterSellingPrice !== undefined) order.asterSellingPrice = Number(asterSellingPrice) || 0;
  if (measurementType !== undefined) order.measurementType = measurementType;
  if (maapImageUrl !== undefined) order.maapImageUrl = maapImageUrl;
  if (fabricImageUrl !== undefined) order.fabricImageUrl = fabricImageUrl;
  if (assignedKarigar !== undefined) order.assignedKarigar = assignedKarigar || null;
  if (assignedMachine !== undefined) order.assignedMachine = assignedMachine || null;

  let statusChanged = false;
  let oldStatus = order.status;
  const newStatus = status;

  if (newStatus && newStatus !== order.status) {
    // Enforce delivery credit requirements when transitioning to Delivered (5.3)
    if (newStatus === 'Delivered') {
      const payment = await Payment.findOne({ orderId: order._id, shopId });
      if (payment && Number(payment.balanceAmount) > 0) {
        if (!reqBody.allowCredit) {
          const err = new Error(
            `Order has an outstanding balance of ₹${payment.balanceAmount}. Please collect payment or confirm delivery on credit.`
          );
          err.statusCode = 400;
          err.requiresCreditApproval = true;
          err.balanceAmount = payment.balanceAmount;
          throw err;
        }

        const creditReason = (reqBody.creditReason || reqBody.reason || '').trim();
        if (!creditReason) {
          const err = new Error('A reason is required to approve delivery on credit (udhar).');
          err.statusCode = 400;
          throw err;
        }

        let delivery = await Delivery.findOne({ orderId: order._id, shopId });
        if (delivery) {
          delivery.allowCredit = true;
          delivery.creditReason = creditReason;
          delivery.creditApprovedBy = userName || 'Owner';
          delivery.creditApprovedAt = new Date().toISOString();
          delivery.status = 'Delivered';
          delivery.deliveredBy = userName || 'Owner';
          delivery.deliveredAt = new Date().toISOString();
          await delivery.save();
        }

        order.notes = order.notes || [];
        order.notes.push({
          text: `Delivered on credit (udhar ₹${payment.balanceAmount}). Reason: ${creditReason}`,
          addedAt: new Date(),
        });
      } else {
        let delivery = await Delivery.findOne({ orderId: order._id, shopId });
        if (delivery) {
          delivery.status = 'Delivered';
          delivery.deliveredBy = userName || 'Owner';
          delivery.deliveredAt = new Date().toISOString();
          await delivery.save();
        }
      }
    }

    await handleAstarStockAdjustment(order, newStatus, shopId);
    order.status = newStatus;
    statusChanged = true;
  }

  const updatedOrder = await order.save();
  await syncPaymentFromTransactions(order._id, shopId);

  if (statusChanged) {
    // If update is performed by partner tailor who received the delegated order
    if (order.delegatedToShopId && String(shopId) === String(order.delegatedToShopId)) {
      const isCompleted = newStatus === 'Ready' || newStatus === 'Delivered';
      if (isCompleted) {
        order.delegationStatus = 'completed';
        await order.save();
      }

      const partnerShop = await Shop.findById(order.delegatedToShopId);
      const partnerName = partnerShop?.shopName || 'Partner tailor';

      // Push notification to originating Main Tailor
      await dispatchNotification({
        shopId: order.shopId,
        orderId: order._id,
        title: isCompleted
            ? 'Order Completed by Partner Tailor! 🎉'
            : 'Partner Tailor Updated Order Stage',
        message: `${partnerName} has updated order #${order.orderId || order._id} (${order.apparelType || order.customerName}) to ${newStatus}.`,
        type: 'delegated_order_completed',
        sendPush: true,
      });
    }

    if (status === 'Delivered') {
      await dispatchNotification({
        shopId: order.shopId,
        customerId: order.customer,
        orderId: order._id,
        title: 'Order Delivered',
        message: `Order ${order.orderId} has been successfully delivered.`,
        type: 'order_status',
      });
    } else {
      await dispatchNotification({
        shopId: order.shopId,
        customerId: order.customer,
        orderId: order._id,
        title: 'Status Updated',
        message: `Order ${order.orderId} status changed from ${oldStatus} to ${status}.`,
        type: 'order_status',
      });
    }
  }

  const payment = await Payment.findOne({ orderId: order._id });
  const delivery = await Delivery.findOne({ orderId: order._id });

  const result = updatedOrder.toJSON();
  result.payment = payment;
  result.delivery = delivery;
  return result;
};

// Delegate Order to Another Tailor
export const delegateOrderService = async (orderId, shopId, { targetShopId, targetShopName, targetPhone, notes, agreedCost }) => {
  const query = isValidIdentifier(orderId)
    ? { _id: orderId, shopId }
    : { orderId: typeof orderId === 'string' ? orderId : '', shopId };
  const order = await Order.findOne(query);
  if (!order) return null;

  const currentStatus = (order.status || '').toLowerCase();
  if (['delivered', 'completed', 'ready', 'cancelled'].includes(currentStatus)) {
    throw new Error('Cannot outsource an order that is already completed or cancelled');
  }

  const originShop = await Shop.findById(shopId);
  const costNum = agreedCost !== undefined && agreedCost !== null ? Number(agreedCost) : 0;

  order.delegatedToShopId = targetShopId;
  order.delegatedToShopName = targetShopName || '';
  order.delegatedToPhone = targetPhone || '';
  order.delegatedAt = new Date();
  order.delegationStatus = 'assigned';
  order.delegatedNotes = notes || '';
  order.delegatedCost = costNum;
  order.agreedCost = costNum;
  order.originShopId = shopId;
  order.originShopName = originShop?.shopName || 'Main Shop';
  order.originPhone = originShop?.phone || '';

  const updated = await order.save();

  // Send push notification to target partner tailor
  await dispatchNotification({
    shopId: targetShopId,
    orderId: order._id,
    title: 'New Job from Partner Tailor! 🧵',
    message: `${originShop?.shopName || 'Another tailor shop'} sent you an order for ${order.apparelType || order.garmentType || 'Garment'} with agreed rate ₹${costNum}.`,
    type: 'delegated_order_assigned',
    sendPush: true,
  });

  return updated;
};

// Sanitize Order details when accessed by an outsourced partner tailor
export const sanitizeOrderForPartnerTailor = (orderObj, requestingShopId) => {
  if (!orderObj) return orderObj;

  const isPlain = typeof orderObj.toJSON === 'function' ? orderObj.toJSON() : { ...orderObj };
  const originShopId = isPlain.shopId || isPlain.originShopId;
  const isDelegatedToMe = Boolean(
    requestingShopId &&
    isPlain.delegatedToShopId &&
    String(isPlain.delegatedToShopId) === String(requestingShopId) &&
    String(originShopId) !== String(requestingShopId)
  );

  if (!isDelegatedToMe) {
    return isPlain;
  }

  // 1. Show as coming from other tailor
  const originShopName = isPlain.originShopName || 'Partner Tailor Shop';
  const originPhone = isPlain.originPhone || '';

  isPlain.isPartnerJob = true;
  isPlain.isOutsourcedToMe = true;
  isPlain.delegationStatus = isPlain.delegationStatus || 'assigned';

  // 2. Hide customer details (protect privacy, no customer poaching)
  isPlain.customerName = `Partner Tailor: ${originShopName}`;
  isPlain.customerPhone = originPhone;
  isPlain.customerId = null;
  isPlain.customer = {
    name: `Partner Tailor: ${originShopName}`,
    phone: originPhone,
    isPartnerShop: true,
  };
  delete isPlain.customerAddress;

  // 3. Due date must be ONE DAY BEFORE the main order's delivery date
  if (isPlain.deliveryDate) {
    const origDelivery = new Date(isPlain.deliveryDate);
    if (!isNaN(origDelivery.getTime())) {
      const oneDayBefore = new Date(origDelivery.getTime() - 24 * 60 * 60 * 1000);
      isPlain.deliveryDate = oneDayBefore.toISOString();
      isPlain.partnerDueDate = oneDayBefore.toISOString();
    }
  }
  if (isPlain.dueDate) {
    const origDue = typeof isPlain.dueDate === 'number'
      ? new Date(isPlain.dueDate)
      : new Date(isPlain.dueDate);
    if (!isNaN(origDue.getTime())) {
      const oneDayBefore = new Date(origDue.getTime() - 24 * 60 * 60 * 1000);
      isPlain.dueDate = typeof isPlain.dueDate === 'number'
        ? oneDayBefore.getTime()
        : oneDayBefore.toISOString();
    }
  }

  // 4. Billing cost privacy: show billing cost set by main tailor at time of outsourcing
  const outsourcedCost = Number(isPlain.delegatedCost ?? isPlain.agreedCost ?? 0);
  isPlain.price = outsourcedCost;
  isPlain.totalAmount = outsourcedCost;
  isPlain.laborCost = outsourcedCost;
  delete isPlain.originalPrice;
  delete isPlain.asterProfit;
  delete isPlain.asterCostPrice;
  delete isPlain.materialCost;
  delete isPlain.overheadCost;
  isPlain.advanceAmount = 0;
  isPlain.advance_amount = 0;
  isPlain.advancePaid = 0;

  // Mask payment object to reflect agreed outsourced fee
  isPlain.payment = {
    totalAmount: outsourcedCost,
    paidAmount: 0,
    balanceAmount: outsourcedCost,
    status: 'Pending',
    isPartnerB2B: true,
  };
  isPlain.transactions = []; // Strip all customer transactions

  // 5. Fabric details (fabric, fabricImageUrl, asterQuantity, etc.) remain intact
  return isPlain;
};

// Revoke Delegated Order back to originating tailor
export const revokeDelegationService = async (orderId, shopId) => {
  const query = isValidIdentifier(orderId)
    ? { _id: orderId, shopId }
    : { orderId: typeof orderId === 'string' ? orderId : '', shopId };
  const order = await Order.findOne(query);
  if (!order) return null;

  const currentStatus = (order.status || '').toLowerCase();
  if (['delivered', 'completed', 'ready', 'cancelled'].includes(currentStatus)) {
    throw new Error('Cannot recall an order that is already completed or cancelled');
  }

  const previousPartnerShopId = order.delegatedToShopId;

  order.delegatedToShopId = null;
  order.delegatedToShopName = null;
  order.delegatedToPhone = null;
  order.delegationStatus = 'none';
  order.delegatedNotes = null;

  const updated = await order.save();

  if (previousPartnerShopId) {
    await dispatchNotification({
      shopId: previousPartnerShopId,
      orderId: order._id,
      title: 'Delegated Order Recalled',
      message: `The delegated order #${order.orderId || order._id} was cancelled by the originating shop.`,
      type: 'general',
      sendPush: false,
    });
  }

  return updated;
};

// Core Business Logic: Delete Order (Soft-delete to preserve financial audit trail)
export const deleteOrderService = async (orderId, shopId) => {
  const order = await findOrderScoped(orderId, shopId);
  if (!order) return null;

  if (order.customer) {
    await Customer.updateOne(
      { _id: order.customer, shopId },
      { $inc: { ordersCount: -1 } }
    );
  }

  // Restore any deducted astar stock if the order was in production
  if (order.needsAster && order.asterDeducted && order.asterInventoryItem) {
    const invItem = await Inventory.findOne({ _id: order.asterInventoryItem, shopId });
    if (invItem) {
      invItem.quantity = (invItem.quantity || 0) + (order.asterQuantity || 0);
      await invItem.save();
      order.asterDeducted = false;
    }
  }

  // Restore multi-item astar stock if deducted
  if (Array.isArray(order.items)) {
    for (const it of order.items) {
      if (it.needsAster && it.asterDeducted && it.asterInventoryItem) {
        const itemQty = (it.quantity || 1) * (it.asterQuantity || 0);
        const invItem = await Inventory.findOne({ _id: it.asterInventoryItem, shopId });
        if (invItem) {
          invItem.quantity = (invItem.quantity || 0) + itemQty;
          await invItem.save();
          it.asterDeducted = false;
        }
      }
    }
  }

  // Soft-delete order to preserve financial transactions in the ledger
  order.status = 'Cancelled';
  order.isDeleted = true;
  order.deletedAt = new Date().toISOString();
  await order.save();

  // Cancel associated pending delivery
  await Delivery.updateOne(
    { orderId: order._id, shopId },
    { status: 'Cancelled' }
  );

  return true;
};
