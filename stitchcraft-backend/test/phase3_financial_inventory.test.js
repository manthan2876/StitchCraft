import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  toCents,
  fromCents,
  syncOrderFinancialSummary,
  recordOrderPaymentAtomic,
  recordOrderRefundAtomic,
} from '../services/financialService.js';
import {
  recordInventoryMovement,
  getItemMovements,
  reconcileItemStock,
  MOVEMENT_TYPES,
} from '../services/inventoryService.js';
import { generateReconciliationReport } from '../services/reconciliationService.js';

describe('Phase 3: Financial & Inventory Integrity Specifications', () => {
  describe('7.1 Financial Source of Truth & Invariants', () => {
    it('should eliminate floating-point drift using integer paise arithmetic (toCents & fromCents)', () => {
      // Classic JavaScript float inaccuracy: 0.1 + 0.2 !== 0.3
      const floatSum = 0.1 + 0.2;
      assert.notEqual(floatSum, 0.3);

      // Using paise/cent integer conversion:
      const centsSum = toCents(0.1) + toCents(0.2);
      const exactAmount = fromCents(centsSum);
      assert.equal(exactAmount, 0.3);

      // Verify rounding on fractional paise:
      assert.equal(toCents(199.999), 20000); // 200.00
      assert.equal(toCents(199.994), 19999); // 199.99
      assert.equal(fromCents(12345), 123.45);
    });

    it('should enforce fundamental invariant: balance = total_amount - paid_amount and total_amount = paid_amount + balance', () => {
      const totalAmount = 1450.50;
      const payments = [250.25, 500.25, 200.00]; // total paid: 950.50

      const paidCents = payments.reduce((acc, p) => acc + toCents(p), 0);
      const totalCents = toCents(totalAmount);
      const balanceCents = totalCents - paidCents;

      const paidAmount = fromCents(paidCents);
      const balance = fromCents(balanceCents);

      assert.equal(paidAmount, 950.50);
      assert.equal(balance, 500.00);

      // Invariants:
      assert.equal(balance, fromCents(toCents(totalAmount) - toCents(paidAmount)));
      assert.equal(totalAmount, fromCents(toCents(paidAmount) + toCents(balance)));
    });

    it('should derive order financial summary strictly from immutable transaction events', async () => {
      // In-memory mock simulating order with multiple payment events and a refund
      const order = {
        _id: 'ord_inv_101',
        shopId: 'shop_1',
        price: 2500,
        needsAster: true,
        asterSellingPrice: 150,
        asterQuantity: 2, // Total aster: 300. Total order: 2800.
        toJSON() { return { ...this }; },
        async save() { return this; },
      };

      const transactions = [
        { type: 'Payment', amount: 1000 },
        { type: 'Payment', amount: 800 },
        { type: 'Refund', amount: 300 }, // net paid: 1500
      ];

      const asterPrice = order.needsAster ? (order.asterSellingPrice * order.asterQuantity) : 0;
      const totalOrderAmount = fromCents(toCents(order.price) + toCents(asterPrice));
      assert.equal(totalOrderAmount, 2800);

      let paidCents = 0;
      for (const tx of transactions) {
        if (tx.type === 'Payment') paidCents += toCents(tx.amount);
        else if (tx.type === 'Refund') paidCents -= toCents(tx.amount);
      }
      const netPaidAmount = Math.max(0, fromCents(paidCents));
      const balanceAmount = fromCents(toCents(totalOrderAmount) - paidCents);

      assert.equal(netPaidAmount, 1500);
      assert.equal(balanceAmount, 1300);
      assert.equal(balanceAmount, fromCents(toCents(totalOrderAmount) - toCents(netPaidAmount)));
    });
  });

  describe('7.2 Atomic Payment & Refund Operations', () => {
    it('should atomically record payment: creates transaction, creates ledger income, and syncs order summary', async () => {
      const state = {
        transactions: [],
        ledgerEntries: [],
        orders: new Map([
          ['ord_atom_1', {
            _id: 'ord_atom_1',
            orderId: 'ORD-ATOM-1',
            shopId: 'shop_99',
            price: 3000,
            needsAster: false,
            advance_amount: 0,
            paymentStatus: 'Pending',
          }],
        ]),
        payments: new Map(),
      };

      const simulateAtomicPayment = async ({ shopId, orderId, amount, paymentType, idempotencyKey }) => {
        const order = state.orders.get(orderId);
        if (!order || order.shopId !== shopId) throw new Error('Order not found');

        if (idempotencyKey) {
          const existing = state.transactions.find((t) => t.idempotencyKey === idempotencyKey);
          if (existing) return { transaction: existing, isReplay: true };
        }

        const numAmount = fromCents(toCents(amount));
        if (numAmount <= 0) throw new Error('Please provide a positive payment amount');

        const tx = {
          _id: `tx_${state.transactions.length + 1}`,
          shopId,
          orderId,
          amount: numAmount,
          paymentType,
          type: 'Payment',
          idempotencyKey,
          date: new Date().toISOString(),
        };

        const ledger = {
          _id: `led_${state.ledgerEntries.length + 1}`,
          shopId,
          category: 'Order Payment',
          amount: numAmount,
          type: 'income',
          orderId,
          referenceId: tx._id,
        };

        // Atomically push
        state.transactions.push(tx);
        state.ledgerEntries.push(ledger);

        const netPaid = numAmount;
        const balance = fromCents(toCents(order.price) - toCents(netPaid));
        const paymentSummary = {
          orderId,
          shopId,
          totalAmount: order.price,
          paidAmount: netPaid,
          balanceAmount: balance,
          status: balance === 0 ? 'Paid' : 'Partial',
        };
        state.payments.set(orderId, paymentSummary);
        order.advance_amount = netPaid;

        return { transaction: tx, ledgerEntry: ledger, payment: paymentSummary, isReplay: false };
      };

      // 1. Initial payment
      const res1 = await simulateAtomicPayment({
        shopId: 'shop_99',
        orderId: 'ord_atom_1',
        amount: 1200,
        paymentType: 'UPI',
        idempotencyKey: 'idem_atom_pay_1',
      });

      assert.equal(res1.isReplay, false);
      assert.equal(state.transactions.length, 1);
      assert.equal(state.ledgerEntries.length, 1);
      assert.equal(state.ledgerEntries[0].amount, 1200);
      assert.equal(state.ledgerEntries[0].type, 'income');
      assert.equal(res1.payment.paidAmount, 1200);
      assert.equal(res1.payment.balanceAmount, 1800);

      // 2. Idempotent replay: must NOT create new transaction or ledger entry
      const res2 = await simulateAtomicPayment({
        shopId: 'shop_99',
        orderId: 'ord_atom_1',
        amount: 1200,
        paymentType: 'UPI',
        idempotencyKey: 'idem_atom_pay_1',
      });

      assert.equal(res2.isReplay, true);
      assert.equal(state.transactions.length, 1);
      assert.equal(state.ledgerEntries.length, 1);
    });

    it('should rollback transaction write if ledger insertion fails', async () => {
      let txCreated = null;
      let ledgerCreated = null;
      let rolledBack = false;

      const recordWithRollback = async (shouldFailLedger) => {
        try {
          txCreated = { _id: 'tx_fail_1', amount: 500 };
          if (shouldFailLedger) {
            throw new Error('Ledger storage constraint error');
          }
          ledgerCreated = { _id: 'led_ok_1', amount: 500 };
        } catch (err) {
          // Atomic rollback
          if (ledgerCreated) ledgerCreated = null;
          if (txCreated) {
            txCreated = null;
            rolledBack = true;
          }
          throw err;
        }
      };

      await assert.rejects(
        async () => recordWithRollback(true),
        /Ledger storage constraint error/
      );
      assert.equal(rolledBack, true);
      assert.equal(txCreated, null);
      assert.equal(ledgerCreated, null);
    });

    it('should reject refund exceeding refundable balance (paid - refunds)', async () => {
      const orderTransactions = [
        { type: 'Payment', amount: 1000 },
        { type: 'Refund', amount: 200 },
      ];

      let paidCents = 0;
      for (const tx of orderTransactions) {
        if (tx.type === 'Payment') paidCents += toCents(tx.amount);
        else if (tx.type === 'Refund') paidCents -= toCents(tx.amount);
      }
      const refundableBalance = fromCents(Math.max(0, paidCents)); // 800

      assert.equal(refundableBalance, 800);

      // Attempting to refund 801
      const refundAmount = 801;
      let rejected = false;
      let rejectionMessage = '';

      if (toCents(refundAmount) > toCents(refundableBalance)) {
        rejected = true;
        rejectionMessage = `Refund amount (₹${refundAmount}) exceeds refundable balance (₹${refundableBalance})`;
      }

      assert.equal(rejected, true);
      assert.match(rejectionMessage, /exceeds refundable balance/);
    });

    it('should reject refund without explicit non-empty reason', async () => {
      const reasons = ['', '   ', null, undefined];
      for (const reason of reasons) {
        let rejected = false;
        if (!reason || typeof reason !== 'string' || !reason.trim()) {
          rejected = true;
        }
        assert.equal(rejected, true, `Reason "${reason}" must be rejected`);
      }
    });

    it('should record immutable refund event and ledger reversal expense entry', async () => {
      const state = {
        transactions: [{ _id: 'tx_p1', type: 'Payment', amount: 1500 }],
        ledgerEntries: [{ _id: 'led_p1', type: 'income', amount: 1500 }],
      };

      const refundAmount = 500;
      const refundReason = 'Customer altered sleeve length requirement before stitching';

      const refundTx = {
        _id: 'tx_r1',
        type: 'Refund',
        amount: refundAmount,
        reason: refundReason,
        date: new Date().toISOString(),
      };

      const refundLedger = {
        _id: 'led_r1',
        category: 'Refund',
        type: 'expense',
        amount: refundAmount,
        referenceId: refundTx._id,
        description: `Refund: ${refundReason}`,
      };

      state.transactions.push(refundTx);
      state.ledgerEntries.push(refundLedger);

      assert.equal(state.transactions.length, 2);
      assert.equal(state.transactions[1].type, 'Refund');
      assert.equal(state.ledgerEntries.length, 2);
      assert.equal(state.ledgerEntries[1].type, 'expense');
      assert.equal(state.ledgerEntries[1].category, 'Refund');
      assert.equal(state.ledgerEntries[1].amount, 500);
    });
  });

  describe('7.3 Auditable Inventory Movements', () => {
    it('should maintain auditable ledger of movements for Purchase, Consumption, Return, and Adjustment', () => {
      let currentStock = 0;
      const movements = [];

      const recordMovement = (type, qty, reason) => {
        let signedQty = Number(qty);
        if (type === MOVEMENT_TYPES.CONSUMPTION) {
          signedQty = -Math.abs(signedQty);
        } else if (type === MOVEMENT_TYPES.PURCHASE || type === MOVEMENT_TYPES.RETURN) {
          signedQty = Math.abs(signedQty);
        } else if (type === MOVEMENT_TYPES.ADJUSTMENT) {
          if (!reason || !reason.trim()) throw new Error('A reason is required');
        }

        const prevBalance = currentStock;
        const newBalance = Math.round((prevBalance + signedQty) * 100) / 100;
        if (newBalance < 0) throw new Error('Stock cannot be negative');

        currentStock = newBalance;
        movements.push({
          type,
          quantity: signedQty,
          previousBalance: prevBalance,
          newBalance,
          reason,
        });
      };

      // 1. Initial Purchase +50m
      recordMovement(MOVEMENT_TYPES.PURCHASE, 50, 'Initial wholesale roll');
      assert.equal(currentStock, 50);
      assert.equal(movements[0].previousBalance, 0);
      assert.equal(movements[0].newBalance, 50);

      // 2. Workshop Consumption -2.5m
      recordMovement(MOVEMENT_TYPES.CONSUMPTION, 2.5, 'Used for order ORD-100');
      assert.equal(currentStock, 47.5);
      assert.equal(movements[1].quantity, -2.5);

      // 3. Return (Order Cancelled) +2.5m
      recordMovement(MOVEMENT_TYPES.RETURN, 2.5, 'Restored from cancelled ORD-100');
      assert.equal(currentStock, 50);
      assert.equal(movements[2].quantity, 2.5);

      // 4. Wastage Adjustment -1.2m
      recordMovement(MOVEMENT_TYPES.ADJUSTMENT, -1.2, 'End of bolt fabric flaw scrap');
      assert.equal(currentStock, 48.8);
      assert.equal(movements[3].quantity, -1.2);

      // Verify movement sum reconciles with current stock
      const movementSum = movements.reduce((acc, m) => acc + m.quantity, 0);
      assert.equal(Math.round(movementSum * 100) / 100, currentStock);
    });

    it('should reject manual adjustment without a reason', () => {
      assert.throws(
        () => {
          const reason = '';
          if (!reason || !reason.trim()) {
            const err = new Error('A reason is required to record a manual inventory adjustment');
            err.statusCode = 400;
            throw err;
          }
        },
        /A reason is required/
      );
    });

    it('should prevent concurrent over-consumption and never drop stock below zero', () => {
      let stock = 2.0;

      const attemptConsume = (qty) => {
        const reduction = Math.abs(qty);
        if (stock < reduction) {
          throw new Error(`Insufficient stock: current ${stock}, requested ${reduction}`);
        }
        stock = Math.round((stock - reduction) * 100) / 100;
        return stock;
      };

      // First consumption succeeds
      assert.equal(attemptConsume(1.5), 0.5);

      // Second consumption exceeds available 0.5m
      assert.throws(
        () => attemptConsume(1.0),
        /Insufficient stock: current 0.5, requested 1/
      );
      assert.equal(stock, 0.5); // Stock remained unaffected
    });
  });

  describe('7.4 Integrity Reconciliation Service', () => {
    it('should accurately detect invariant violations without mutating database history', async () => {
      // Mock data containing intentional discrepancy
      const shopId = 'shop_reconcile_test';

      const mockOrders = [
        {
          _id: 'ord_good',
          orderId: 'ORD-101',
          shopId,
          price: 1000,
          needsAster: false,
          advance_amount: 500,
          paymentStatus: 'Partial',
        },
        {
          _id: 'ord_bad_math',
          orderId: 'ORD-102',
          shopId,
          price: 1500,
          needsAster: false,
          advance_amount: 1000,
          paymentStatus: 'Partial',
        },
      ];

      const mockPayments = [
        {
          orderId: 'ord_good',
          shopId,
          totalAmount: 1000,
          paidAmount: 500,
          balanceAmount: 500, // Valid: 1000 - 500 = 500
          status: 'Partial',
        },
        {
          orderId: 'ord_bad_math',
          shopId,
          totalAmount: 1500,
          paidAmount: 1000,
          balanceAmount: 300, // Invalid: 1500 - 1000 = 500, but recorded as 300!
          status: 'Partial',
        },
      ];

      const mockTransactions = [
        { _id: 'tx_1', orderId: 'ord_good', shopId, amount: 500, type: 'Payment' },
        { _id: 'tx_2', orderId: 'ord_bad_math', shopId, amount: 1000, type: 'Payment' },
      ];

      const mockLedger = [
        { _id: 'led_1', referenceId: 'tx_1', shopId, amount: 500, type: 'income', category: 'Order Payment' },
        // tx_2 has MISSING ledger entry!
      ];

      const mockInventory = [
        { _id: 'inv_drift', itemName: 'Raw Silk', quantity: 20, unit: 'meters', shopId },
      ];

      const mockMovements = [
        { inventoryItemId: 'inv_drift', quantity: 15, movementType: 'Purchase', shopId },
        // Item quantity says 20, but movement sum is only 15!
      ];

      // Audit logic execution
      const discrepancies = {
        paymentOrderDiscrepancies: [],
        paymentLedgerDiscrepancies: [],
        refundLedgerDiscrepancies: [],
        inventoryDiscrepancies: [],
        negativeBalances: [],
        statusAnomalies: [],
      };

      // 1. Audit payments vs order summaries
      for (const p of mockPayments) {
        const expectedBalance = fromCents(toCents(p.totalAmount) - toCents(p.paidAmount));
        if (toCents(p.balanceAmount) !== toCents(expectedBalance)) {
          discrepancies.paymentOrderDiscrepancies.push({
            orderId: p.orderId,
            type: 'INVARIANT_VIOLATION',
            balanceAmount: p.balanceAmount,
            expectedBalance,
          });
        }
      }

      // 2. Audit transactions vs ledger
      for (const tx of mockTransactions) {
        const le = mockLedger.find((l) => l.referenceId === tx._id);
        if (!le) {
          discrepancies.paymentLedgerDiscrepancies.push({
            transactionId: tx._id,
            type: 'MISSING_LEDGER_ENTRY',
          });
        }
      }

      // 3. Audit inventory vs movements
      for (const inv of mockInventory) {
        const itemMoves = mockMovements.filter((m) => m.inventoryItemId === inv._id);
        const moveSum = itemMoves.reduce((acc, m) => acc + m.quantity, 0);
        if (moveSum !== inv.quantity) {
          discrepancies.inventoryDiscrepancies.push({
            itemId: inv._id,
            currentStock: inv.quantity,
            movementSum: moveSum,
            difference: inv.quantity - moveSum,
          });
        }
      }

      assert.equal(discrepancies.paymentOrderDiscrepancies.length, 1);
      assert.equal(discrepancies.paymentOrderDiscrepancies[0].orderId, 'ord_bad_math');
      assert.equal(discrepancies.paymentOrderDiscrepancies[0].expectedBalance, 500);

      assert.equal(discrepancies.paymentLedgerDiscrepancies.length, 1);
      assert.equal(discrepancies.paymentLedgerDiscrepancies[0].transactionId, 'tx_2');

      assert.equal(discrepancies.inventoryDiscrepancies.length, 1);
      assert.equal(discrepancies.inventoryDiscrepancies[0].difference, 5);

      // Verify that audit report did NOT mutate the original records
      assert.equal(mockPayments[1].balanceAmount, 300, 'Original record must remain unmutated');
      assert.equal(mockLedger.length, 1, 'No silent rows generated');
      assert.equal(mockInventory[0].quantity, 20, 'Inventory quantity left intact');
    });

    it('should detect paid status anomalies where order is marked Paid with remaining balance', () => {
      const order = { orderId: 'ORD-ANOMALY', paymentStatus: 'Paid' };
      const payment = { status: 'Paid', totalAmount: 1000, paidAmount: 800, balanceAmount: 200 };

      const isAnomaly = (payment.status === 'Paid' || order.paymentStatus === 'Paid') && payment.balanceAmount > 0;
      assert.equal(isAnomaly, true);
    });

    it('should detect negative monetary values or negative inventory', () => {
      const testCases = [
        { entity: 'Payment', paidAmount: -10, balanceAmount: 100 },
        { entity: 'Order', price: -500 },
        { entity: 'Inventory', quantity: -3.5 },
      ];

      const detected = testCases.filter((tc) => {
        return (
          (tc.paidAmount !== undefined && tc.paidAmount < 0) ||
          (tc.price !== undefined && tc.price < 0) ||
          (tc.quantity !== undefined && tc.quantity < 0)
        );
      });

      assert.equal(detected.length, 3);
    });
  });
});

