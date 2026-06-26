import Payment from '../models/Payment.js';
import Order from '../models/Order.js';
import Transaction from '../models/Transaction.js';
import LedgerEntry from '../models/LedgerEntry.js';
import mongoose from 'mongoose';

// @desc    Get payments summary (total sales, received payments, outstanding collections)
// @route   GET /api/ledger/summary
// @access  Private
export const getLedgerSummary = async (req, res) => {
  try {
    const shopId = req.user.shopId;

    // Calculate totalSales from orders (including lining selling price)
    const orders = await Order.find({ shopId }).populate('asterInventoryItem');
    const totalSales = orders.reduce((sum, o) => {
      if (o.status === 'Cancelled') return sum;
      const asterPrice = o.needsAster ? (o.asterSellingPrice * o.asterQuantity) : 0;
      return sum + (o.price || 0) + asterPrice;
    }, 0);

    // Calculate totalReceived from Transactions
    const txs = await Transaction.find({ shopId });
    const totalReceived = txs.reduce((sum, tx) => {
      if (tx.type === 'Payment') return sum + tx.amount;
      if (tx.type === 'Refund') return sum - tx.amount;
      return sum;
    }, 0);

    // Calculate outstanding balance
    const totalOutstanding = Math.max(0, totalSales - totalReceived);

    // Calculate totalExpenses from LedgerEntry
    const expenses = await LedgerEntry.find({ shopId });
    const totalExpenses = expenses.reduce((sum, e) => sum + (e.amount || 0), 0);

    // Calculate total fabric profit and wholesale fabric cost
    let totalFabricProfit = 0;
    let totalFabricCost = 0;

    const ASTAR_DEDUCT_STATUSES = ['Stitching', 'Checking', 'Ready', 'Delivered'];
    orders.forEach(o => {
      if (o.status === 'Cancelled') return;
      if (o.needsAster) {
        const cost = o.asterInventoryItem?.costPerUnit || 0;
        const profit = (o.asterSellingPrice - cost) * o.asterQuantity;
        if (profit > 0) {
          totalFabricProfit += profit;
        }
        if (ASTAR_DEDUCT_STATUSES.includes(o.status)) {
          totalFabricCost += cost * o.asterQuantity;
        }
      }
    });

    res.json({
      totalSales,
      totalReceived,
      totalOutstanding,
      totalExpenses,
      totalFabricProfit,
      totalFabricCost,
    });
  } catch (error) {
    console.error('Get ledger summary error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all journal entries (Sales, Payments, Material Cost, Expenses)
// @route   GET /api/ledger/journal
// @access  Private
export const getJournalEntries = async (req, res) => {
  try {
    const shopId = req.user.shopId;
    const { category, search } = req.query;

    // 1. Ledger Entries (Rent, Salary, Restocks)
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

    // 2. Transactions (Customer Payments / Refunds)
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

    // 3. Orders (Sales Bookings)
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

    // 4. Material Consumption Cost
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

    // Combine all
    let allEntries = [
      ...journalLedger,
      ...journalTxs,
      ...journalOrders,
      ...journalConsumption
    ];

    // Sort chronologically ascending (oldest first) for stable running balance calculation
    allEntries.sort((a, b) => {
      const diff = new Date(a.date) - new Date(b.date);
      if (diff !== 0) return diff;
      return String(a._id).localeCompare(String(b._id));
    });

    // Compute cumulative running cash balance
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

    // Filter by Category matching
    if (category && category !== 'All') {
      allEntries = allEntries.filter(entry => {
        if (category === 'Sales') return entry.type === 'Sales';
        if (category === 'Payments') return entry.type === 'Payment' || entry.type === 'Refund';
        if (category === 'Expenses') return entry.type === 'Expense';
        if (category === 'Material Cost') return entry.type === 'Material Consumption';
        return false;
      });
    }

    // Filter by Search Query
    if (search) {
      const q = search.toLowerCase();
      allEntries = allEntries.filter(entry => 
        (entry.description || '').toLowerCase().includes(q) ||
        (entry.category || '').toLowerCase().includes(q) ||
        (entry.type || '').toLowerCase().includes(q)
      );
    }

    // Sort descending chronologically (newest first) for representation
    allEntries.sort((a, b) => {
      const diff = new Date(b.date) - new Date(a.date);
      if (diff !== 0) return diff;
      return String(b._id).localeCompare(String(a._id));
    });

    res.json(allEntries);
  } catch (error) {
    console.error('Get journal entries error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all payment records (replaces transactions list)
// @route   GET /api/ledger/transactions
// @access  Private
export const getTransactions = async (req, res) => {
  try {
    const { type, search } = req.query; // 'type' holds the tab status: 'All', 'Pending', 'Paid', 'Partial'
    
    const filter = { shopId: req.user.shopId };

    if (type && type !== 'All') {
      filter.status = type;
    }

    // Retrieve payments and populate the parent order details
    const payments = await Payment.find(filter).populate({
      path: 'orderId',
      select: 'orderId customerName apparelType deliveryDate date'
    });

    // Map payments to match expected ledger columns and filter by search query
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

    // Sort by newest payment record first
    results.sort((a, b) => new Date(b.date) - new Date(a.date));

    res.json(results);
  } catch (error) {
    console.error('Get payments list error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all business expenses
// @route   GET /api/ledger/expenses
// @access  Private
export const getExpenses = async (req, res) => {
  try {
    const { category, search } = req.query;
    const filter = { shopId: req.user.shopId };

    if (category && category !== 'All') {
      filter.category = category;
    }

    let query = LedgerEntry.find(filter).sort({ date: -1 });
    const expenses = await query;

    let results = expenses;
    if (search) {
      const q = search.toLowerCase();
      results = expenses.filter(e => 
        (e.description || '').toLowerCase().includes(q) ||
        (e.category || '').toLowerCase().includes(q)
      );
    }

    res.json(results);
  } catch (error) {
    console.error('Get expenses error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Create a new expense entry
// @route   POST /api/ledger/expenses
// @access  Private
export const createExpense = async (req, res) => {
  try {
    const { amount, category, description, date } = req.body;

    if (!amount || !category) {
      return res.status(400).json({ message: 'Amount and category are required' });
    }

    const expense = await LedgerEntry.create({
      shopId: req.user.shopId,
      amount: Number(amount),
      category,
      description: description || '',
      date: date || new Date(),
    });

    res.status(201).json(expense);
  } catch (error) {
    console.error('Create expense error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete an expense entry
// @route   DELETE /api/ledger/expenses/:id
// @access  Private
export const deleteExpense = async (req, res) => {
  try {
    const expense = await LedgerEntry.findOne({ _id: req.params.id, shopId: req.user.shopId });

    if (!expense) {
      return res.status(404).json({ message: 'Expense entry not found' });
    }

    await LedgerEntry.deleteOne({ _id: expense._id });
    res.json({ message: 'Expense entry deleted successfully' });
  } catch (error) {
    console.error('Delete expense error:', error);
    res.status(500).json({ message: error.message });
  }
};
