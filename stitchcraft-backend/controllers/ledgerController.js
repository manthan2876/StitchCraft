/* controllers/ledgerController.js */
import {
  computeLedgerSummary,
  fetchJournalEntries,
  fetchTransactionsList,
} from '../services/ledgerService.js';
import { generateReconciliationReport } from '../services/reconciliationService.js';

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

// @desc    Generate financial and inventory reconciliation audit report (Phase 3, 7.4)
// @route   GET /api/ledger/reconciliation
// @access  Private (Owner/Manager)
export const getReconciliationReport = async (req, res) => {
  try {
    const report = await generateReconciliationReport(req.user.shopId);
    res.json(report);
  } catch (error) {
    console.error('Get reconciliation report error:', error);
    res.status(500).json({ message: error.message });
  }
};
