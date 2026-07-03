/* services/ledgerService.js */
import Payment from '../models/Payment.js';
import Order from '../models/Order.js';
import Transaction from '../models/Transaction.js';
import LedgerEntry from '../models/LedgerEntry.js';

export const computeLedgerSummary = async (shopId) => {
  const orders = await Order.find({ shopId }).populate('asterInventoryItem');
  const totalSales = orders.reduce((sum, o) => {
    if (o.status === 'Cancelled') return sum;
    const asterPrice = o.needsAster ? (o.asterSellingPrice * o.asterQuantity) : 0;
    return sum + (o.price || 0) + asterPrice;
  }, 0);

  const txs = await Transaction.find({ shopId });
  const totalReceived = txs.reduce((sum, tx) => {
    if (tx.type === 'Payment') return sum + tx.amount;
    if (tx.type === 'Refund') return sum - tx.amount;
    return sum;
  }, 0);

  const totalOutstanding = Math.max(0, totalSales - totalReceived);

  const expenses = await LedgerEntry.find({ shopId });
  const totalExpenses = expenses.reduce((sum, e) => sum + (e.amount || 0), 0);

  let totalFabricProfit = 0;
  let totalFabricCost = 0;

  const ASTAR_DEDUCT_STATUSES = ['Stitching', 'Checking', 'Ready', 'Delivered'];
  orders.forEach(o => {
    if (o.status === 'Cancelled') return;
    if (o.needsAster) {
      const cost = o.asterInventoryItem?.costPerUnit || 0;
      const profit = (o.asterSellingPrice - cost) * o.asterQuantity;
      if (profit > 0) totalFabricProfit += profit;
      if (ASTAR_DEDUCT_STATUSES.includes(o.status)) {
        totalFabricCost += cost * o.asterQuantity;
      }
    }
  });

  return {
    totalSales,
    totalReceived,
    totalOutstanding,
    totalExpenses,
    totalFabricProfit,
    totalFabricCost,
  };
};

export const fetchJournalEntries = async (shopId, category, search) => {
  const ledgerEntries = await LedgerEntry.find({ shopId });
  const journalLedger = ledgerEntries.map(e => ({
    _id: e._id,
    date: e.date,
    type: 'Expense',
    referenceId: e.referenceId || e._id,
    description: e.description || `${e.category} Expense`,
    amount: e.amount,
    paymentMethod: 'Cash',
    flow: 'Out',
    category: e.category
  }));

  const txs = await Transaction.find({ shopId }).populate({
    path: 'orderId',
    select: 'orderId customerName'
  });
  const journalTxs = txs.map(tx => {
    const order = tx.orderId || {};
    return {
      _id: tx._id,
      date: tx.date,
      type: tx.type === 'Payment' ? 'Payment' : 'Refund',
      referenceId: order._id || tx.orderId,
      description: tx.type === 'Payment'
        ? `Payment received for ${order.orderId || 'Order'} (${order.customerName || 'Customer'})`
        : `Refund issued for ${order.orderId || 'Order'}`,
      amount: tx.amount,
      paymentMethod: tx.paymentType || 'Cash',
      flow: tx.type === 'Payment' ? 'In' : 'Out',
      category: 'Payments'
    };
  });

  const orders = await Order.find({ shopId }).populate('asterInventoryItem');
  const journalOrders = orders.map(o => {
    const asterPrice = o.needsAster ? (o.asterSellingPrice * o.asterQuantity) : 0;
    const isReverted = o.status === 'Cancelled';
    return {
      _id: o._id,
      date: o.date,
      type: 'Sales',
      referenceId: o._id,
      description: `${isReverted ? '[Reverted] ' : ''}Order Booked: ${o.orderId} - ${o.apparelType} (${o.customerName})`,
      amount: o.price + asterPrice,
      paymentMethod: 'N/A',
      flow: 'None',
      category: 'Sales',
      isReverted: isReverted
    };
  });

  const ASTAR_DEDUCT_STATUSES = ['Stitching', 'Checking', 'Ready', 'Delivered'];
  const journalConsumption = [];
  orders.forEach(o => {
    if (o.status === 'Cancelled') return;
    if (o.needsAster && o.asterQuantity > 0 && ASTAR_DEDUCT_STATUSES.includes(o.status)) {
      const costPrice = o.asterInventoryItem?.costPerUnit || 0;
      const totalCost = costPrice * o.asterQuantity;
      if (totalCost > 0) {
        journalConsumption.push({
          _id: o._id + '-cost',
          date: o.date,
          type: 'Material Consumption',
          referenceId: o._id,
          description: `Lining Consumed: ${o.asterQuantity} ${o.asterInventoryItem?.unit || 'units'} of ${o.asterInventoryItem?.itemName || 'Material'} for ${o.orderId}`,
          amount: totalCost,
          paymentMethod: 'N/A',
          flow: 'None',
          category: 'Material Cost'
        });
      }
    }
  });

  let allEntries = [
    ...journalLedger,
    ...journalTxs,
    ...journalOrders,
    ...journalConsumption
  ];

  allEntries.sort((a, b) => {
    const diff = new Date(a.date) - new Date(b.date);
    if (diff !== 0) return diff;
    return String(a._id).localeCompare(String(b._id));
  });

  let balance = 0;
  allEntries = allEntries.map(entry => {
    if (entry.flow === 'In') {
      balance += entry.amount;
    } else if (entry.flow === 'Out') {
      balance -= entry.amount;
    }
    return {
      ...entry,
      runningBalance: balance
    };
  });

  if (category && category !== 'All') {
    allEntries = allEntries.filter(entry => {
      if (category === 'Sales') return entry.type === 'Sales';
      if (category === 'Payments') return entry.type === 'Payment' || entry.type === 'Refund';
      if (category === 'Expenses') return entry.type === 'Expense';
      if (category === 'Material Cost') return entry.type === 'Material Consumption';
      return false;
    });
  }

  if (search) {
    const q = search.toLowerCase();
    allEntries = allEntries.filter(entry =>
      (entry.description || '').toLowerCase().includes(q) ||
      (entry.category || '').toLowerCase().includes(q) ||
      (entry.type || '').toLowerCase().includes(q)
    );
  }

  allEntries.sort((a, b) => {
    const diff = new Date(b.date) - new Date(a.date);
    if (diff !== 0) return diff;
    return String(b._id).localeCompare(String(b._id));
  });

  return allEntries;
};

export const fetchTransactionsList = async (shopId, type, search) => {
  const filter = { shopId };
  if (type && type !== 'All') {
    filter.status = type;
  }

  const payments = await Payment.find(filter).populate({
    path: 'orderId',
    select: 'orderId customerName apparelType deliveryDate date'
  });

  let results = payments.map(p => {
    const order = p.orderId || {};
    return {
      _id: p._id,
      id: p._id,
      transactionId: order.orderId || 'ORD-UNKNOWN',
      orderId: order.orderId || 'ORD-UNKNOWN',
      orderObjId: order._id,
      customerName: order.customerName || 'Unknown Customer',
      description: `${order.apparelType || 'Tailoring'} Order Payment`,
      amount: p.totalAmount,
      paid: p.paidAmount,
      balance: p.balanceAmount,
      status: p.status,
      paymentType: p.paymentType,
      date: p.createdAt,
    };
  });

  if (search) {
    const q = search.toLowerCase();
    results = results.filter(r =>
      r.customerName.toLowerCase().includes(q) ||
      r.orderId.toLowerCase().includes(q) ||
      r.paymentType.toLowerCase().includes(q)
    );
  }

  results.sort((a, b) => new Date(b.date) - new Date(a.date));
  return results;
};
