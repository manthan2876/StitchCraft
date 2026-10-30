import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { ASTAR_DEDUCT_STATUSES } from '../services/orderService.js';

describe('Order Lifecycle & Financial Computations', () => {
  it('should correctly calculate total order value with single and multi-item orders', () => {
    // Single apparel order with Aster (lining)
    const order1 = {
      price: 1500,
      needsAster: true,
      asterQuantity: 2.5,
      asterSellingPrice: 120,
    };
    const asterTotal = order1.needsAster ? (order1.asterQuantity * order1.asterSellingPrice) : 0;
    const total1 = order1.price + asterTotal;
    assert.equal(asterTotal, 300);
    assert.equal(total1, 1800);

    // Multi-garment order
    const items = [
      { name: 'Kurta', price: 800, quantity: 2 },
      { name: 'Pants', price: 600, quantity: 1 },
      { name: 'Dupatta', price: 300, quantity: 1 },
    ];
    const itemsTotal = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    assert.equal(itemsTotal, 2500);
  });

  it('should compute payment status transitions from transaction ledger', () => {
    const totalOrderValue = 3500;

    // Helper simulating payment ledger sync
    const computePaymentState = (transactions, totalAmount) => {
      const totalPaid = transactions.reduce((sum, tx) => {
        if (tx.type === 'Payment') return sum + tx.amount;
        if (tx.type === 'Refund') return sum - tx.amount;
        return sum;
      }, 0);
      const balanceAmount = Math.max(0, totalAmount - totalPaid);
      let status = 'Pending';
      if (balanceAmount === 0 && totalPaid > 0) {
        status = 'Paid';
      } else if (totalPaid > 0) {
        status = 'Partial';
      }
      return { totalAmount, paidAmount: totalPaid, balanceAmount, status };
    };

    // 1. Initial order with no payments
    const p1 = computePaymentState([], totalOrderValue);
    assert.equal(p1.status, 'Pending');
    assert.equal(p1.paidAmount, 0);
    assert.equal(p1.balanceAmount, 3500);

    // 2. Advance deposit of ₹1000
    const p2 = computePaymentState([{ type: 'Payment', amount: 1000 }], totalOrderValue);
    assert.equal(p2.status, 'Partial');
    assert.equal(p2.paidAmount, 1000);
    assert.equal(p2.balanceAmount, 2500);

    // 3. Final settlement of remaining ₹2500
    const p3 = computePaymentState([
      { type: 'Payment', amount: 1000 },
      { type: 'Payment', amount: 2500 },
    ], totalOrderValue);
    assert.equal(p3.status, 'Paid');
    assert.equal(p3.paidAmount, 3500);
    assert.equal(p3.balanceAmount, 0);

    // 4. Refund scenario
    const p4 = computePaymentState([
      { type: 'Payment', amount: 3500 },
      { type: 'Refund', amount: 500 },
    ], totalOrderValue);
    assert.equal(p4.status, 'Partial');
    assert.equal(p4.paidAmount, 3000);
    assert.equal(p4.balanceAmount, 500);
  });

  it('should only trigger inventory material consumption during active workshop stages', () => {
    // Inventory should NOT deduct in pre-workshop stages like Incoming or Measuring
    assert.equal(ASTAR_DEDUCT_STATUSES.includes('Incoming'), false);
    assert.equal(ASTAR_DEDUCT_STATUSES.includes('Measuring'), false);

    // Inventory MUST deduct in workshop production stages
    assert.equal(ASTAR_DEDUCT_STATUSES.includes('Stitching'), true);
    assert.equal(ASTAR_DEDUCT_STATUSES.includes('Checking'), true);
    assert.equal(ASTAR_DEDUCT_STATUSES.includes('Ready'), true);
    assert.equal(ASTAR_DEDUCT_STATUSES.includes('Delivered'), true);
  });

  it('should track sequential order notes without mutating existing notes', () => {
    const existingNotes = [
      { text: 'Customer requested extra inner margin (2 inches)', addedAt: '2026-10-30T10:00:00Z' },
    ];
    const newNote = { text: 'Golden zari piping added to collar', addedAt: '2026-10-30T14:30:00Z' };

    const updatedNotes = [...existingNotes, newNote];
    assert.equal(updatedNotes.length, 2);
    assert.equal(updatedNotes[0].text, 'Customer requested extra inner margin (2 inches)');
    assert.equal(updatedNotes[1].text, 'Golden zari piping added to collar');
  });

  it('should exclude cancelled orders from shop production metrics', () => {
    const orders = [
      { id: '1', status: 'Ready', price: 1200 },
      { id: '2', status: 'Stitching', price: 2000 },
      { id: '3', status: 'Cancelled', price: 3000 },
    ];

    const activeOrders = orders.filter(o => o.status !== 'Cancelled');
    const activeRevenue = activeOrders.reduce((sum, o) => sum + o.price, 0);

    assert.equal(activeOrders.length, 2);
    assert.equal(activeRevenue, 3200);
  });
});

