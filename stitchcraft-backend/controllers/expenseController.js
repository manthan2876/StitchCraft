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
