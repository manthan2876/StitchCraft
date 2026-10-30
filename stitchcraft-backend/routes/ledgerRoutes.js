import express from 'express';
const router = express.Router();
import {
  getLedgerSummary,
  getTransactions,
  getJournalEntries,
} from '../controllers/ledgerController.js';
import {
  getExpenses,
  createExpense,
  deleteExpense,
} from '../controllers/expenseController.js';
import { protect, authorize } from '../middleware/authMiddleware.js';
import { validateExpenseRequest } from '../middleware/validationMiddleware.js';

router.use(protect); // Secure all routes in this module

router.get('/summary', getLedgerSummary);
router.get('/journal', getJournalEntries);
router.get('/transactions', getTransactions);
router.get('/expenses', getExpenses);
router.post('/expenses', validateExpenseRequest, createExpense);
router.delete('/expenses/:id', authorize('owner'), deleteExpense);

export default router;
