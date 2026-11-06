import Order from '../models/Order.js';
import Payment from '../models/Payment.js';
import Transaction from '../models/Transaction.js';
import LedgerEntry from '../models/LedgerEntry.js';
import Inventory from '../models/Inventory.js';
import InventoryMovement from '../models/InventoryMovement.js';
import { toCents, fromCents } from './financialService.js';

/**
 * Audit financial and inventory integrity for a shop (Phase 3, 7.4)
 * Identifies discrepancies without silently repairing history.
 */
export const generateReconciliationReport = async (shopId) => {
  if (!shopId) throw new Error('Shop ID is required for reconciliation');

  const discrepancies = {
    paymentOrderDiscrepancies: [],
    paymentLedgerDiscrepancies: [],
    refundLedgerDiscrepancies: [],
    inventoryDiscrepancies: [],
    negativeBalances: [],
    statusAnomalies: [],
  };

  // Fetch relevant tenant collections concurrently
  const [orders, payments, transactions, ledgerEntries, inventoryItems, inventoryMovements] = await Promise.all([
    Order.find({ shopId }),
    Payment.find({ shopId }),
    Transaction.find({ shopId }),
    LedgerEntry.find({ shopId }),
    Inventory.find({ shopId }),
    InventoryMovement.find({ shopId }),
  ]);

  // Index maps for efficient cross-referencing
  const paymentsByOrderId = new Map();
  for (const p of payments) {
    if (p.orderId) paymentsByOrderId.set(String(p.orderId), p);
  }

  const transactionsByOrderId = new Map();
  for (const tx of transactions) {
    if (tx.orderId) {
      const oid = String(tx.orderId);
      if (!transactionsByOrderId.has(oid)) transactionsByOrderId.set(oid, []);
      transactionsByOrderId.get(oid).push(tx);
    }
  }

  const ledgerByRefId = new Map();
  for (const le of ledgerEntries) {
    if (le.referenceId) {
      ledgerByRefId.set(String(le.referenceId), le);
    }
  }

  const movementsByItemId = new Map();
  for (const mv of inventoryMovements) {
    if (mv.inventoryItemId) {
      const iid = String(mv.inventoryItemId);
      if (!movementsByItemId.has(iid)) movementsByItemId.set(iid, []);
      movementsByItemId.get(iid).push(mv);
    }
  }

  // AUDIT 1: Payment Events vs Order Summaries
  // Formula: balance = total_amount - paid_amount
  // Invariant: total_amount = paid_amount + balance
  for (const order of orders) {
    const oid = String(order._id);
    const orderTxs = transactionsByOrderId.get(oid) || [];
    const payment = paymentsByOrderId.get(oid);

    let txPaidCents = 0;
    let txRefundCents = 0;
    for (const tx of orderTxs) {
      const cents = toCents(tx.amount);
      if (tx.type === 'Payment') {
        txPaidCents += cents;
      } else if (tx.type === 'Refund') {
        txRefundCents += cents;
      }
    }
    const netTxPaidCents = Math.max(0, txPaidCents - txRefundCents);
    const netTxPaid = fromCents(netTxPaidCents);

    const asterPrice = order.needsAster ? ((Number(order.asterSellingPrice) || 0) * (Number(order.asterQuantity) || 0)) : 0;
    const computedTotalAmount = fromCents(toCents(order.price) + toCents(asterPrice));

    if (payment) {
      const summaryPaid = Number(payment.paidAmount) || 0;
      const summaryBalance = Number(payment.balanceAmount) || 0;
      const summaryTotal = Number(payment.totalAmount) || 0;

      // Invariant check: balance = total_amount - paid_amount
      const expectedBalance = fromCents(toCents(summaryTotal) - toCents(summaryPaid));
      if (toCents(summaryBalance) !== toCents(expectedBalance)) {
        discrepancies.paymentOrderDiscrepancies.push({
          orderId: order._id,
          orderNumber: order.orderId,
          type: 'INVARIANT_VIOLATION',
          message: `Summary balance (₹${summaryBalance}) does not equal total (₹${summaryTotal}) - paid (₹${summaryPaid})`,
          summaryTotal,
          summaryPaid,
          summaryBalance,
          expectedBalance,
        });
      }

      // Transaction events sum vs summary paid
      if (toCents(netTxPaid) !== toCents(summaryPaid)) {
        discrepancies.paymentOrderDiscrepancies.push({
          orderId: order._id,
          orderNumber: order.orderId,
          type: 'TRANSACTION_SUMMARY_MISMATCH',
          message: `Transactions net paid (₹${netTxPaid}) does not match order payment summary paidAmount (₹${summaryPaid})`,
          netTxPaid,
          summaryPaid,
          difference: fromCents(toCents(summaryPaid) - toCents(netTxPaid)),
        });
      }
    } else if (orderTxs.length > 0) {
      discrepancies.paymentOrderDiscrepancies.push({
        orderId: order._id,
        orderNumber: order.orderId,
        type: 'MISSING_PAYMENT_SUMMARY',
        message: `Order has ${orderTxs.length} transaction(s) but no Payment summary record`,
        netTxPaid,
      });
    }

    // AUDIT 5a: Negative balances in order / payment
    if (payment) {
      if (Number(payment.paidAmount) < 0 || Number(payment.balanceAmount) < 0 || Number(payment.totalAmount) < 0) {
        discrepancies.negativeBalances.push({
          entity: 'Payment',
          orderId: order._id,
          orderNumber: order.orderId,
          paidAmount: payment.paidAmount,
          balanceAmount: payment.balanceAmount,
          totalAmount: payment.totalAmount,
        });
      }
    }
    if (Number(order.advance_amount) < 0 || Number(order.price) < 0) {
      discrepancies.negativeBalances.push({
        entity: 'Order',
        orderId: order._id,
        orderNumber: order.orderId,
        price: order.price,
        advance_amount: order.advance_amount,
      });
    }

    // AUDIT 6: Paid orders with outstanding balances / status anomalies
    if (payment) {
      const isStatusPaid = payment.status === 'Paid' || order.paymentStatus === 'Paid';
      if (isStatusPaid && Number(payment.balanceAmount) > 0) {
        discrepancies.statusAnomalies.push({
          orderId: order._id,
          orderNumber: order.orderId,
          issue: 'PAID_STATUS_WITH_BALANCE',
          message: `Order marked as 'Paid' but has remaining balance of ₹${payment.balanceAmount}`,
          balanceAmount: payment.balanceAmount,
        });
      }
    }
  }

  // AUDIT 2: Payments vs Ledger Entries
  for (const tx of transactions) {
    if (tx.type === 'Payment') {
      const ledgerEntry = ledgerByRefId.get(String(tx._id));
      if (!ledgerEntry) {
        discrepancies.paymentLedgerDiscrepancies.push({
          transactionId: tx._id,
          orderId: tx.orderId,
          amount: tx.amount,
          type: 'MISSING_LEDGER_ENTRY',
          message: `Payment transaction ₹${tx.amount} has no matching ledger entry`,
        });
      } else if (toCents(ledgerEntry.amount) !== toCents(tx.amount)) {
        discrepancies.paymentLedgerDiscrepancies.push({
          transactionId: tx._id,
          ledgerId: ledgerEntry._id,
          type: 'AMOUNT_MISMATCH',
          message: `Payment transaction amount ₹${tx.amount} differs from ledger entry amount ₹${ledgerEntry.amount}`,
          txAmount: tx.amount,
          ledgerAmount: ledgerEntry.amount,
        });
      }
    } else if (tx.type === 'Refund') {
      // AUDIT 3: Refunds vs Reversal Entries
      const ledgerEntry = ledgerByRefId.get(String(tx._id));
      if (!ledgerEntry) {
        discrepancies.refundLedgerDiscrepancies.push({
          transactionId: tx._id,
          orderId: tx.orderId,
          amount: tx.amount,
          type: 'MISSING_REVERSAL_ENTRY',
          message: `Refund transaction ₹${tx.amount} has no matching reversal ledger entry`,
        });
      } else if (toCents(ledgerEntry.amount) !== toCents(tx.amount)) {
        discrepancies.refundLedgerDiscrepancies.push({
          transactionId: tx._id,
          ledgerId: ledgerEntry._id,
          type: 'AMOUNT_MISMATCH',
          message: `Refund transaction amount ₹${tx.amount} differs from ledger entry amount ₹${ledgerEntry.amount}`,
          txAmount: tx.amount,
          ledgerAmount: ledgerEntry.amount,
        });
      }
    }
  }

  // AUDIT 4: Inventory Balance vs Movement History & Negative Stock
  for (const item of inventoryItems) {
    const itemMovements = movementsByItemId.get(String(item._id)) || [];
    const movementSumCents = itemMovements.reduce((sum, m) => sum + toCents(m.quantity || 0), 0);
    const movementSum = fromCents(movementSumCents);
    const currentStock = Math.round((Number(item.quantity) || 0) * 100) / 100;
    const diff = fromCents(toCents(currentStock) - toCents(movementSum));

    if (diff !== 0 && itemMovements.length > 0) {
      discrepancies.inventoryDiscrepancies.push({
        itemId: item._id,
        itemName: item.itemName,
        currentStock,
        movementSum,
        difference: diff,
        movementCount: itemMovements.length,
        message: `Inventory stock (${currentStock}) does not match sum of movements (${movementSum})`,
      });
    }

    if (currentStock < 0) {
      discrepancies.negativeBalances.push({
        entity: 'Inventory',
        itemId: item._id,
        itemName: item.itemName,
        quantity: currentStock,
        unit: item.unit,
      });
    }
  }

  const totalDiscrepancies =
    discrepancies.paymentOrderDiscrepancies.length +
    discrepancies.paymentLedgerDiscrepancies.length +
    discrepancies.refundLedgerDiscrepancies.length +
    discrepancies.inventoryDiscrepancies.length +
    discrepancies.negativeBalances.length +
    discrepancies.statusAnomalies.length;

  return {
    timestamp: new Date().toISOString(),
    shopId,
    summary: {
      totalOrdersAudited: orders.length,
      totalPaymentsAudited: payments.length,
      totalTransactionsAudited: transactions.length,
      totalLedgerEntriesAudited: ledgerEntries.length,
      totalInventoryItemsAudited: inventoryItems.length,
      totalInventoryMovementsAudited: inventoryMovements.length,
      totalDiscrepanciesFound: totalDiscrepancies,
      status: totalDiscrepancies === 0 ? 'HEALTHY' : 'DISCREPANCIES_DETECTED',
    },
    discrepancies,
  };
};

export default {
  generateReconciliationReport,
};

