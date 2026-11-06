import Order from '../models/Order.js';
import Payment from '../models/Payment.js';
import Transaction from '../models/Transaction.js';
import LedgerEntry from '../models/LedgerEntry.js';
import SyncMutation from '../models/SyncMutation.js';
import Delivery from '../models/Delivery.js';
import { dispatchNotification } from './notificationService.js';
import { sanitizeOrderForPartnerTailor } from './orderService.js';

/**
 * Standardize monetary amount to integer paise (or 2-decimal rounded number)
 */
export const toCents = (amount) => Math.round(Number(amount) * 100);
export const fromCents = (cents) => Math.round(cents) / 100;

/**
 * Recalculate order financial summary from immutable transactions
 * Maintains invariant: balance = total_amount - paid_amount
 */
export const syncOrderFinancialSummary = async (orderId, shopId) => {
  const order = await Order.findOne({ _id: orderId, shopId });
  if (!order) return null;

  const asterPrice = order.needsAster ? ((Number(order.asterSellingPrice) || 0) * (Number(order.asterQuantity) || 0)) : 0;
  const totalOrderAmount = fromCents(toCents(order.price) + toCents(asterPrice));

  const transactions = await Transaction.find({ orderId: order._id, shopId });

  let paidCents = 0;
  for (const tx of transactions) {
    if (tx.type === 'Payment') {
      paidCents += toCents(tx.amount);
    } else if (tx.type === 'Refund') {
      paidCents -= toCents(tx.amount);
    }
  }

  const netPaidAmount = Math.max(0, fromCents(paidCents));
  const totalAmountCents = toCents(totalOrderAmount);
  const balanceCents = Math.max(0, totalAmountCents - paidCents);
  const balanceAmount = fromCents(balanceCents);

  let payment = await Payment.findOne({ orderId: order._id, shopId });
  if (!payment) {
    payment = new Payment({
      orderId: order._id,
      shopId,
      totalAmount: totalOrderAmount,
      paidAmount: netPaidAmount,
      balanceAmount,
      status: balanceAmount === 0 ? 'Paid' : (netPaidAmount > 0 ? 'Partial' : 'Pending'),
    });
  } else {
    payment.totalAmount = totalOrderAmount;
    payment.paidAmount = netPaidAmount;
    payment.balanceAmount = balanceAmount;
    payment.status = balanceAmount === 0 ? 'Paid' : (netPaidAmount > 0 ? 'Partial' : 'Pending');
  }

  await payment.save();

  // Keep order.advance_amount synchronized with derived summary
  order.advance_amount = netPaidAmount;
  await order.save();

  return { payment, totalAmount: totalOrderAmount, paidAmount: netPaidAmount, balanceAmount };
};

/**
 * Atomic Payment Operation (Phase 3, 7.2)
 * Validates tenant, checks idempotency, inserts immutable transaction, inserts ledger entry,
 * recalculates order summary, commits all changes atomically.
 */
export const recordOrderPaymentAtomic = async ({
  shopId,
  orderId,
  amount,
  paymentType = 'Cash',
  idempotencyKey = null,
  recordedBy = 'Owner',
}) => {
  if (!shopId) throw new Error('Shop ID is required');
  if (!orderId) throw new Error('Order ID is required');

  const order = await Order.findOne({ _id: orderId, shopId });
  if (!order) {
    const err = new Error('Order not found');
    err.statusCode = 404;
    throw err;
  }

  const numAmount = fromCents(toCents(amount));
  if (numAmount <= 0) {
    const err = new Error('Please provide a positive payment amount');
    err.statusCode = 400;
    throw err;
  }

  // Normalize payment method
  let normalizedType = 'Cash';
  if (paymentType && typeof paymentType === 'string') {
    const pt = paymentType.trim().toLowerCase();
    if (pt === 'upi' || pt === 'online') normalizedType = 'UPI';
    else if (pt === 'card') normalizedType = 'Card';
    else if (pt === 'credit') normalizedType = 'Credit';
    else if (pt === 'bank') normalizedType = 'Bank';
    else normalizedType = 'Cash';
  }

  // Check idempotency (Phase 2, 6.3 & Phase 3, 7.2)
  if (idempotencyKey) {
    const existingTx = await Transaction.findOne({ shopId, idempotencyKey });
    if (existingTx) {
      const summary = await syncOrderFinancialSummary(order._id, shopId);
      const delivery = await Delivery.findOne({ orderId: order._id, shopId });
      const result = order.toJSON();
      result.payment = summary.payment;
      result.delivery = delivery;
      result.transaction = existingTx;
      result.isReplay = true;
      return sanitizeOrderForPartnerTailor(result, shopId);
    }
  }

  // Atomic execution pipeline
  let createdTx = null;
  let createdLedger = null;

  try {
    // 1. Insert immutable payment event
    createdTx = await Transaction.create({
      shopId,
      orderId: order._id,
      amount: numAmount,
      paymentType: normalizedType,
      type: 'Payment',
      idempotencyKey: idempotencyKey || null,
      date: new Date().toISOString(),
    });

    // 2. Insert corresponding accounting ledger entry
    createdLedger = await LedgerEntry.create({
      shopId,
      category: 'Order Payment',
      amount: numAmount,
      type: 'income',
      orderId: order._id,
      referenceId: createdTx._id,
      description: `Payment for order ${order.orderId || order._id} (${normalizedType})`,
      date: new Date().toISOString(),
    });

    // 3. Recalculate derived order financial summary
    const summary = await syncOrderFinancialSummary(order._id, shopId);

    // 4. Record server mutation idempotency
    if (idempotencyKey) {
      await SyncMutation.create({
        shopId,
        mutationId: idempotencyKey,
        entityType: 'payments',
        entityId: createdTx._id,
        operation: 'payment',
        statusCode: 200,
        response: { transactionId: createdTx._id, amount: numAmount },
        createdAt: new Date().toISOString(),
      }).catch((mErr) => console.warn('SyncMutation write warning:', mErr.message));
    }

    // 5. Dispatch notification
    await dispatchNotification({
      shopId,
      customerId: order.customer,
      orderId: order._id,
      title: 'Payment Received',
      message: `Payment of ₹${numAmount} received for order ${order.orderId}. New balance: ₹${summary.balanceAmount}.`,
      type: 'payment',
    }).catch(() => {});

    const delivery = await Delivery.findOne({ orderId: order._id, shopId });
    const result = order.toJSON();
    result.payment = summary.payment;
    result.delivery = delivery;
    result.transaction = createdTx;
    result.ledgerEntry = createdLedger;

    return sanitizeOrderForPartnerTailor(result, shopId);
  } catch (error) {
    // Atomic rollback on failure
    if (createdLedger && createdLedger._id) {
      await LedgerEntry.deleteOne({ _id: createdLedger._id }).catch(() => {});
    }
    if (createdTx && createdTx._id) {
      await Transaction.deleteOne({ _id: createdTx._id }).catch(() => {});
    }
    throw error;
  }
};

/**
 * Atomic Refund Operation (Phase 3, 7.2)
 * Validates refundable balance, checks idempotency, inserts immutable refund event,
 * inserts reversal ledger entry, recalculates summary, commits atomically.
 */
export const recordOrderRefundAtomic = async ({
  shopId,
  orderId,
  amount,
  reason,
  paymentType = 'Cash',
  idempotencyKey = null,
  processedBy = 'Owner',
}) => {
  if (!shopId) throw new Error('Shop ID is required');
  if (!orderId) throw new Error('Order ID is required');

  const order = await Order.findOne({ _id: orderId, shopId });
  if (!order) {
    const err = new Error('Order not found');
    err.statusCode = 404;
    throw err;
  }

  const numAmount = fromCents(toCents(amount));
  if (numAmount <= 0) {
    const err = new Error('Please provide a positive refund amount');
    err.statusCode = 400;
    throw err;
  }

  if (!reason || typeof reason !== 'string' || !reason.trim()) {
    const err = new Error('A reason is required to record a refund or reversal');
    err.statusCode = 400;
    throw err;
  }

  // Validate refundable balance: cannot exceed net paid amount
  const transactions = await Transaction.find({ orderId: order._id, shopId });
  let paidCents = 0;
  for (const tx of transactions) {
    if (tx.type === 'Payment') paidCents += toCents(tx.amount);
    else if (tx.type === 'Refund') paidCents -= toCents(tx.amount);
  }
  const refundableCents = Math.max(0, paidCents);
  const refundAmountCents = toCents(numAmount);

  if (refundableCents <= 0) {
    const err = new Error('Cannot process refund: No payments have been recorded for this order');
    err.statusCode = 400;
    throw err;
  }

  if (refundAmountCents > refundableCents) {
    const err = new Error(
      `Refund amount (₹${numAmount}) exceeds refundable balance (₹${fromCents(refundableCents)})`
    );
    err.statusCode = 400;
    err.refundableBalance = fromCents(refundableCents);
    throw err;
  }

  // Idempotency check
  if (idempotencyKey) {
    const existingTx = await Transaction.findOne({ shopId, idempotencyKey });
    if (existingTx) {
      const summary = await syncOrderFinancialSummary(order._id, shopId);
      const delivery = await Delivery.findOne({ orderId: order._id, shopId });
      const result = order.toJSON();
      result.payment = summary.payment;
      result.delivery = delivery;
      result.refundTransaction = existingTx;
      result.isReplay = true;
      return sanitizeOrderForPartnerTailor(result, shopId);
    }
  }

  let createdTx = null;
  let createdLedger = null;

  try {
    // 1. Insert immutable refund transaction event
    createdTx = await Transaction.create({
      shopId,
      orderId: order._id,
      amount: numAmount,
      paymentType: paymentType || 'Cash',
      type: 'Refund',
      reason: reason.trim(),
      processedBy,
      idempotencyKey: idempotencyKey || null,
      date: new Date().toISOString(),
    });

    // 2. Insert accounting ledger reversal entry
    createdLedger = await LedgerEntry.create({
      shopId,
      category: 'Refund',
      amount: numAmount,
      type: 'expense',
      orderId: order._id,
      referenceId: createdTx._id,
      description: `Refund for order ${order.orderId || order._id}: ${reason.trim()}`,
      date: new Date().toISOString(),
    });

    // 3. Recalculate summary
    const summary = await syncOrderFinancialSummary(order._id, shopId);

    // 4. Record mutation idempotency
    if (idempotencyKey) {
      await SyncMutation.create({
        shopId,
        mutationId: idempotencyKey,
        entityType: 'payments',
        entityId: createdTx._id,
        operation: 'refund',
        statusCode: 200,
        response: { refundTransactionId: createdTx._id, amount: numAmount },
        createdAt: new Date().toISOString(),
      }).catch(() => {});
    }

    // 5. Dispatch notification
    await dispatchNotification({
      shopId,
      customerId: order.customer,
      orderId: order._id,
      title: 'Refund Processed',
      message: `Refund of ₹${numAmount} recorded for order ${order.orderId}. Reason: ${reason.trim()}. Balance due: ₹${summary.balanceAmount}.`,
      type: 'payment',
    }).catch(() => {});

    const delivery = await Delivery.findOne({ orderId: order._id, shopId });
    const result = order.toJSON();
    result.payment = summary.payment;
    result.delivery = delivery;
    result.refundTransaction = createdTx;
    result.ledgerEntry = createdLedger;

    return sanitizeOrderForPartnerTailor(result, shopId);
  } catch (error) {
    if (createdLedger && createdLedger._id) {
      await LedgerEntry.deleteOne({ _id: createdLedger._id }).catch(() => {});
    }
    if (createdTx && createdTx._id) {
      await Transaction.deleteOne({ _id: createdTx._id }).catch(() => {});
    }
    throw error;
  }
};

export default {
  toCents,
  fromCents,
  syncOrderFinancialSummary,
  recordOrderPaymentAtomic,
  recordOrderRefundAtomic,
};

