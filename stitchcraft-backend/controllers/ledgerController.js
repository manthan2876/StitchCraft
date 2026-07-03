/* controllers/ledgerController.js */
import {
  computeLedgerSummary,
  fetchJournalEntries,
  fetchTransactionsList,
} from '../services/ledgerService.js';

// @desc    Get payments summary (total sales, received payments, outstanding collections)
// @route   GET /api/ledger/summary
// @access  Private
export const getLedgerSummary = async (req, res) => {
  try {
    const summary = await computeLedgerSummary(req.user.shopId);
    res.json(summary);
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
    const { category, search } = req.query;
    const entries = await fetchJournalEntries(req.user.shopId, category, search);
    res.json(entries);
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
    const { type, search } = req.query;
    const transactions = await fetchTransactionsList(req.user.shopId, type, search);
    res.json(transactions);
  } catch (error) {
    console.error('Get payments list error:', error);
    res.status(500).json({ message: error.message });
  }
};
