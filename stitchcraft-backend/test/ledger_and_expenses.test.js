import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

describe('Ledger & Financial Auditing Logic', () => {
  it('should calculate accurate ledger financial summaries', () => {
    const orders = [
      { status: 'Stitching', price: 1500, needsAster: true, asterQuantity: 2, asterSellingPrice: 150, asterCostPrice: 50 },
      { status: 'Delivered', price: 2000, needsAster: false },
      { status: 'Cancelled', price: 5000, needsAster: true, asterQuantity: 5, asterSellingPrice: 200, asterCostPrice: 80 },
    ];

    // Compute total sales (exclude cancelled)
    const totalSales = orders.reduce((sum, o) => {
      if (o.status === 'Cancelled') return sum;
      const asterPrice = o.needsAster ? (o.asterSellingPrice * o.asterQuantity) : 0;
      return sum + (o.price || 0) + asterPrice;
    }, 0);
    // 1500 + 300 + 2000 = 3800
    assert.equal(totalSales, 3800);

    // Compute fabric profit and cost
    let totalFabricProfit = 0;
    let totalFabricCost = 0;
    const ASTAR_DEDUCT_STATUSES = ['Stitching', 'Checking', 'Ready', 'Delivered'];

    orders.forEach(o => {
      if (o.status === 'Cancelled') return;
      if (o.needsAster) {
        const profit = (o.asterSellingPrice - o.asterCostPrice) * o.asterQuantity;
        if (profit > 0) totalFabricProfit += profit;
        if (ASTAR_DEDUCT_STATUSES.includes(o.status)) {
          totalFabricCost += o.asterCostPrice * o.asterQuantity;
        }
      }
    });

    // Profit: (150 - 50) * 2 = 200
    assert.equal(totalFabricProfit, 200);
    // Cost: 50 * 2 = 100
    assert.equal(totalFabricCost, 100);

    // Transactions
    const txs = [
      { type: 'Payment', amount: 1500 },
      { type: 'Payment', amount: 800 },
      { type: 'Refund', amount: 300 },
    ];
    const totalReceived = txs.reduce((sum, tx) => {
      if (tx.type === 'Payment') return sum + tx.amount;
      if (tx.type === 'Refund') return sum - tx.amount;
      return sum;
    }, 0);
    assert.equal(totalReceived, 2000);

    // Outstanding
    const totalOutstanding = Math.max(0, totalSales - totalReceived);
    assert.equal(totalOutstanding, 1800);

    // Expenses
    const expenses = [
      { category: 'Shop Rent', amount: 12000 },
      { category: 'Electricity', amount: 1500 },
      { category: 'Machine Oil', amount: 250 },
    ];
    const totalExpenses = expenses.reduce((sum, e) => sum + e.amount, 0);
    assert.equal(totalExpenses, 13750);

    // Cash in hand
    const cashInHand = totalReceived - totalExpenses;
    assert.equal(cashInHand, -11750);
  });

  it('should maintain running cash balance across chronological journal entries', () => {
    const rawEntries = [
      { _id: '1', date: '2026-10-01T09:00:00Z', type: 'Payment', flow: 'In', amount: 5000 },
      { _id: '2', date: '2026-10-01T10:00:00Z', type: 'Expense', flow: 'Out', amount: 1200 },
      { _id: '3', date: '2026-10-02T11:00:00Z', type: 'Sales', flow: 'None', amount: 4500 }, // non-cash booking
      { _id: '4', date: '2026-10-03T15:00:00Z', type: 'Payment', flow: 'In', amount: 2500 },
      { _id: '5', date: '2026-10-04T12:00:00Z', type: 'Expense', flow: 'Out', amount: 800 },
    ];

    // Sort chronologically ascending
    const sorted = [...rawEntries].sort((a, b) => new Date(a.date) - new Date(b.date));

    let balance = 0;
    const computed = sorted.map(entry => {
      if (entry.flow === 'In') {
        balance += entry.amount;
      } else if (entry.flow === 'Out') {
        balance -= entry.amount;
      }
      return { ...entry, runningBalance: balance };
    });

    assert.equal(computed[0].runningBalance, 5000);
    assert.equal(computed[1].runningBalance, 3800);
    assert.equal(computed[2].runningBalance, 3800); // unaffected by sales booking
    assert.equal(computed[3].runningBalance, 6300);
    assert.equal(computed[4].runningBalance, 5500);
  });

  it('should filter journal entries accurately by category', () => {
    const entries = [
      { type: 'Sales', category: 'Sales', description: 'Order Booked: Sherwani' },
      { type: 'Payment', category: 'Payments', description: 'Payment received' },
      { type: 'Expense', category: 'Expenses', description: 'Needles & Chalk' },
      { type: 'Material Consumption', category: 'Material Cost', description: 'Lining Consumed' },
    ];

    const salesOnly = entries.filter(e => e.type === 'Sales');
    assert.equal(salesOnly.length, 1);
    assert.equal(salesOnly[0].description, 'Order Booked: Sherwani');

    const expensesOnly = entries.filter(e => e.type === 'Expense');
    assert.equal(expensesOnly.length, 1);
    assert.equal(expensesOnly[0].description, 'Needles & Chalk');
  });
});

