/**
 * StitchCraft Month-End Financial & Production Reporting Service
 * ---------------------------------------------------------------------------
 * Computes period financial summaries, production breakdowns, and generates
 * RFC 4180 compliant CSV exports with integer-safe paise arithmetic.
 */

import Order from '../models/Order.js';
import Transaction from '../models/Transaction.js';
import LedgerEntry from '../models/LedgerEntry.js';
import Payment from '../models/Payment.js';
import { toCents, fromCents } from './financialService.js';

export const escapeCSV = (value) => {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (/[",\n\r]/.test(str)) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
};

export const serializeReportToCSV = (report) => {
  const lines = [];

  // UTF-8 BOM for Excel and spreadsheet viewers
  const BOM = '\uFEFF';

  // Header Title
  lines.push(['STITCHCRAFT MONTH-END REPORT', report.period.label].map(escapeCSV).join(','));
  lines.push(['Generated At', report.generatedAt].map(escapeCSV).join(','));
  lines.push([]);

  // Section 1: Financial Summary
  lines.push(['--- FINANCIAL OVERVIEW ---'].map(escapeCSV).join(','));
  lines.push(['Metric', 'Amount (INR)'].map(escapeCSV).join(','));
  lines.push(['Total Revenue Collected', `₹${report.financial.totalRevenue.toFixed(2)}`].map(escapeCSV).join(','));
  lines.push(['Total Expenses Incurred', `₹${report.financial.totalExpenses.toFixed(2)}`].map(escapeCSV).join(','));
  lines.push(['Net Shop Profit / Loss', `₹${report.financial.netProfit.toFixed(2)}`].map(escapeCSV).join(','));
  lines.push(['Total Outstanding Udhar (Pending Balance)', `₹${report.financial.totalOutstandingUdhar.toFixed(2)}`].map(escapeCSV).join(','));
  lines.push([]);

  // Section 2: Payment Collection by Mode
  lines.push(['--- COLLECTIONS BY PAYMENT MODE ---'].map(escapeCSV).join(','));
  lines.push(['Payment Mode', 'Collected Amount (INR)'].map(escapeCSV).join(','));
  for (const [mode, amount] of Object.entries(report.financial.byMode)) {
    lines.push([mode.toUpperCase(), `₹${amount.toFixed(2)}`].map(escapeCSV).join(','));
  }
  lines.push([]);

  // Section 3: Production & Order Metrics
  lines.push(['--- PRODUCTION & ORDER METRICS ---'].map(escapeCSV).join(','));
  lines.push(['Metric', 'Count'].map(escapeCSV).join(','));
  lines.push(['Total Orders Booked', report.production.totalBooked].map(escapeCSV).join(','));
  lines.push(['Completed / Delivered', report.production.completed].map(escapeCSV).join(','));
  lines.push(['Active In-Progress', report.production.inProgress].map(escapeCSV).join(','));
  lines.push(['Cancelled Orders', report.production.cancelled].map(escapeCSV).join(','));
  lines.push([]);

  // Section 4: Garment Breakdown
  lines.push(['--- GARMENT CATEGORY BREAKDOWN ---'].map(escapeCSV).join(','));
  lines.push(['Garment Category', 'Quantity', 'Total Value (INR)', 'Avg Value (INR)'].map(escapeCSV).join(','));
  for (const [garment, stats] of Object.entries(report.garmentBreakdown)) {
    lines.push([
      garment,
      stats.count,
      `₹${stats.totalValue.toFixed(2)}`,
      `₹${stats.avgValue.toFixed(2)}`,
    ].map(escapeCSV).join(','));
  }

  return BOM + lines.join('\n');
};

export const generateMonthEndReport = async ({ shopId, year, month, startDate, endDate }) => {
  let periodStart;
  let periodEnd;
  let periodLabel;

  if (startDate && endDate) {
    periodStart = new Date(startDate);
    periodEnd = new Date(endDate);
    periodLabel = `${startDate} to ${endDate}`;
  } else {
    const y = Number(year) || new Date().getFullYear();
    const m = Number(month) !== undefined ? Number(month) : (new Date().getMonth() + 1);
    periodStart = new Date(Date.UTC(y, m - 1, 1, 0, 0, 0));
    // Last day of month
    periodEnd = new Date(Date.UTC(y, m, 0, 23, 59, 59, 999));
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    periodLabel = `${monthNames[m - 1] || m} ${y}`;
  }

  const startIso = periodStart.toISOString();
  const endIso = periodEnd.toISOString();
  const startDateStr = startIso.slice(0, 10);
  const endDateStr = endIso.slice(0, 10);

  // Fetch orders, transactions, ledger entries in parallel
  const [orders, transactions, expenses, allShopPayments] = await Promise.all([
    Order.find({ shopId, createdAt: { $gte: periodStart, $lte: periodEnd } }),
    Transaction.find({ shopId, createdAt: { $gte: periodStart, $lte: periodEnd } }),
    LedgerEntry.find({ shopId, date: { $gte: startDateStr, $lte: endDateStr } }),
    Payment.find({ shopId }),
  ]);

  // 1. Financial calculations in integer paise/cents
  let revenueCents = 0;
  const modeCents = { cash: 0, upi: 0, card: 0, bankTransfer: 0, other: 0 };

  for (const tx of transactions) {
    if (tx.type === 'Payment') {
      const amountCents = toCents(tx.amount || 0);
      revenueCents += amountCents;

      const mode = (tx.paymentType || tx.payment_method || 'cash').toLowerCase();
      if (mode.includes('upi') || mode.includes('gpay') || mode.includes('phonepe')) {
        modeCents.upi += amountCents;
      } else if (mode.includes('card')) {
        modeCents.card += amountCents;
      } else if (mode.includes('bank') || mode.includes('transfer')) {
        modeCents.bankTransfer += amountCents;
      } else if (mode.includes('cash')) {
        modeCents.cash += amountCents;
      } else {
        modeCents.other += amountCents;
      }
    } else if (tx.type === 'Refund') {
      revenueCents -= toCents(tx.amount || 0);
    }
  }

  // 2. Expenses calculation
  let expenseCents = 0;
  for (const exp of expenses) {
    if (exp.type === 'debit' || exp.category === 'expense' || exp.category === 'wage') {
      expenseCents += toCents(exp.amount || 0);
    }
  }

  // 3. Outstanding Udhar (Shop-wide pending payment balances)
  let outstandingUdharCents = 0;
  for (const p of allShopPayments) {
    const bal = Number(p.balanceAmount || 0);
    if (bal > 0) {
      outstandingUdharCents += toCents(bal);
    }
  }

  // 4. Production & Garment Metrics
  let completed = 0;
  let inProgress = 0;
  let cancelled = 0;
  const garmentStats = {};

  for (const o of orders) {
    const st = (o.status || '').toLowerCase();
    if (st === 'cancelled') {
      cancelled++;
      continue;
    } else if (['ready', 'delivered'].includes(st)) {
      completed++;
    } else {
      inProgress++;
    }

    const gName = (o.apparelType || o.garmentType || 'Custom Garment').trim();
    if (!garmentStats[gName]) {
      garmentStats[gName] = { count: 0, totalCents: 0 };
    }
    garmentStats[gName].count++;
    garmentStats[gName].totalCents += toCents(o.price || 0);
  }

  const garmentBreakdown = {};
  for (const [g, stat] of Object.entries(garmentStats)) {
    const totalVal = fromCents(stat.totalCents);
    garmentBreakdown[g] = {
      count: stat.count,
      totalValue: totalVal,
      avgValue: stat.count > 0 ? Number((totalVal / stat.count).toFixed(2)) : 0,
    };
  }

  return {
    period: {
      label: periodLabel,
      start: startIso,
      end: endIso,
    },
    generatedAt: new Date().toISOString(),
    financial: {
      totalRevenue: fromCents(revenueCents),
      totalExpenses: fromCents(expenseCents),
      netProfit: fromCents(revenueCents - expenseCents),
      totalOutstandingUdhar: fromCents(outstandingUdharCents),
      byMode: {
        cash: fromCents(modeCents.cash),
        upi: fromCents(modeCents.upi),
        card: fromCents(modeCents.card),
        bankTransfer: fromCents(modeCents.bankTransfer),
        other: fromCents(modeCents.other),
      },
    },
    production: {
      totalBooked: orders.length,
      completed,
      inProgress,
      cancelled,
    },
    garmentBreakdown,
  };
};
