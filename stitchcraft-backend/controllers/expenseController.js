/* controllers/expenseController.js */
import LedgerEntry from '../models/LedgerEntry.js';

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

// @desc    Update an expense entry
// @route   PUT /api/ledger/expenses/:id
// @access  Private
export const updateExpense = async (req, res) => {
  try {
    const expense = await LedgerEntry.findOne({ _id: req.params.id, shopId: req.user.shopId });

    if (!expense) {
      return res.status(404).json({ message: 'Expense entry not found' });
    }

    // Optimistic concurrency check (Phase 2, 6.3)
    const clientBaseVersion = req.body.base_version !== undefined
      ? Number(req.body.base_version)
      : (req.body.baseVersion !== undefined ? Number(req.body.baseVersion) : null);

    if (clientBaseVersion !== null && !isNaN(clientBaseVersion)) {
      const currentVersion = Number(expense.version || 1);
      if (currentVersion !== clientBaseVersion) {
        return res.status(409).json({
          message: 'Conflict: concurrent modification detected',
          error: 'Conflict: concurrent modification detected',
          serverVersion: currentVersion,
          currentData: expense.toJSON ? expense.toJSON() : expense,
        });
      }
    }

    const { amount, category, description, date } = req.body;
    if (amount !== undefined) expense.amount = Number(amount);
    if (category !== undefined) expense.category = category;
    if (description !== undefined) expense.description = description;
    if (date !== undefined) expense.date = date;

    expense.version = Number(expense.version || 1) + 1;
    const updated = await expense.save();
    res.json(updated);
  } catch (error) {
    console.error('Update expense error:', error);
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
