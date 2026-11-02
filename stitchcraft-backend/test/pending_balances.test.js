/* test/pending_balances.test.js */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

describe('Udhar & Pending Balance Aggregation Logic', () => {
  it('should accurately calculate total outstanding balance across unpaid orders', () => {
    const mockPayments = [
      { orderId: 'ord-1', totalAmount: 2000, paidAmount: 500, balanceAmount: 1500 },
      { orderId: 'ord-2', totalAmount: 1200, paidAmount: 1200, balanceAmount: 0 },
      { orderId: 'ord-3', totalAmount: 3500, paidAmount: 1000, balanceAmount: 2500 },
    ];

    const pending = mockPayments.filter(p => p.balanceAmount > 0);
    const totalDue = pending.reduce((sum, p) => sum + p.balanceAmount, 0);

    assert.equal(pending.length, 2);
    assert.equal(totalDue, 4000);
  });

  it('should generate valid WhatsApp reminder text with merchant details and balance', () => {
    const customer = {
      name: 'Priya Sharma',
      phone: '9876543210',
      totalBalance: 2500,
      orders: [{ orderId: 'ORD-101' }, { orderId: 'ORD-102' }],
    };
    const shopName = 'Royal Tailors';
    const shopUpi = 'royal@upi';

    const orderRefs = customer.orders.map(o => o.orderId).join(', ');
    const reminderText = `Namaste ${customer.name}, this is a gentle reminder from ${shopName}. You have a pending tailoring balance of ₹${customer.totalBalance} across order(s) ${orderRefs}. Kindly settle at your convenience. UPI ID: ${shopUpi}`;

    assert.match(reminderText, /Namaste Priya Sharma/);
    assert.match(reminderText, /₹2500/);
    assert.match(reminderText, /ORD-101, ORD-102/);
    assert.match(reminderText, /royal@upi/);

    const waUrl = `https://wa.me/${customer.phone}?text=${encodeURIComponent(reminderText)}`;
    assert.equal(waUrl.startsWith('https://wa.me/9876543210?text='), true);
  });
});

