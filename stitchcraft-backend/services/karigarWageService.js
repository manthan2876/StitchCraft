/**
 * StitchCraft Karigar Piece-Rate Wage & Payout Ledger Service
 * ---------------------------------------------------------------------------
 * Computes piece-rate wages upon order assignment and completion, maintains
 * running payable balances for workshop tailors, and audits payouts.
 */

import LedgerEntry from '../models/LedgerEntry.js';
import Karigar from '../models/Karigar.js';
import Order from '../models/Order.js';
import { toCents, fromCents } from './financialService.js';
import { resolveGarmentTemplate } from './garmentTemplateService.js';

export const DEFAULT_PIECE_RATES = {
  shirt: 200,
  pant: 220,
  blouse: 350,
  kurti: 250,
  salwar: 200,
  suit: 1200,
  lehenga: 800,
  custom: 250,
};

export const resolvePieceRate = (garmentName = '', customRate) => {
  if (customRate !== undefined && customRate !== null && Number(customRate) >= 0) {
    return Number(customRate);
  }
  const template = resolveGarmentTemplate(garmentName);
  const key = template?.key || 'custom';
  return DEFAULT_PIECE_RATES[key] || DEFAULT_PIECE_RATES.custom;
};

/**
 * Accrues a piece-rate wage entry for a karigar upon order completion or assignment.
 */
export const accrueKarigarWage = async ({
  shopId,
  karigarId,
  orderId,
  garmentName = '',
  customRate,
  recordedBy = 'Owner',
}) => {
  const karigar = await Karigar.findOne({ _id: karigarId, shopId });
  if (!karigar) throw new Error(`Karigar '${karigarId}' not found in shop '${shopId}'`);

  const order = await Order.findOne({ _id: orderId, shopId });
  if (!order) throw new Error(`Order '${orderId}' not found in shop '${shopId}'`);

  const rate = resolvePieceRate(garmentName || order.apparelType, customRate);
  const rateCents = toCents(rate);

  // Check if wage already accrued for this order & karigar to prevent duplicate piece-rates
  const existingWage = await LedgerEntry.findOne({
    shopId,
    karigarId: String(karigarId),
    orderId: String(orderId),
    category: 'karigar_wage',
    wageType: 'accrual',
  });

  if (existingWage) {
    return {
      accrued: false,
      message: 'Wage already accrued for this order',
      entry: existingWage,
    };
  }

  const entry = await LedgerEntry.create({
    shopId,
    karigarId: String(karigarId),
    orderId: String(orderId),
    category: 'karigar_wage',
    wageType: 'accrual',
    type: 'debit', // Shop expense / liability
    amount: fromCents(rateCents),
    date: new Date().toISOString().slice(0, 10),
    description: `Piece-rate wage for ${order.apparelType || 'Garment'} (${order.orderId || order._id})`,
    notes: `Calculated piece-rate: ₹${rate}`,
    recordedBy,
  });

  return {
    accrued: true,
    rate,
    entry,
  };
};

/**
 * Records an authoritative wage payout to a karigar, reducing payable balance.
 */
export const recordKarigarPayout = async ({
  shopId,
  karigarId,
  amount,
  paymentMode = 'Cash',
  referenceNote = '',
  recordedBy = 'Owner',
}) => {
  const numericAmount = Number(amount);
  if (isNaN(numericAmount) || numericAmount <= 0) {
    throw new Error('Payout amount must be a positive number');
  }

  const karigar = await Karigar.findOne({ _id: karigarId, shopId });
  if (!karigar) throw new Error(`Karigar '${karigarId}' not found in shop '${shopId}'`);

  const entry = await LedgerEntry.create({
    shopId,
    karigarId: String(karigarId),
    category: 'karigar_wage',
    wageType: 'payout',
    type: 'credit', // Liability reduction / payment out
    amount: numericAmount,
    paymentMode,
    date: new Date().toISOString().slice(0, 10),
    description: `Wage payout to ${karigar.name} via ${paymentMode}`,
    notes: referenceNote || 'Routine piece-rate wage settlement',
    recordedBy,
  });

  return entry;
};

/**
 * Computes accrued wages, paid settlements, and net payable balance for a karigar.
 */
export const getKarigarWageSummary = async ({ shopId, karigarId }) => {
  const karigar = await Karigar.findOne({ _id: karigarId, shopId });
  if (!karigar) throw new Error(`Karigar '${karigarId}' not found in shop '${shopId}'`);

  const wageEntries = await LedgerEntry.find({
    shopId,
    karigarId: String(karigarId),
    category: 'karigar_wage',
  }).sort({ date: -1, createdAt: -1 });

  let accruedCents = 0;
  let paidCents = 0;

  for (const entry of wageEntries) {
    const amtCents = toCents(entry.amount || 0);
    if (entry.wageType === 'accrual') {
      accruedCents += amtCents;
    } else if (entry.wageType === 'payout') {
      paidCents += amtCents;
    }
  }

  const payableCents = accruedCents - paidCents;

  return {
    karigar: {
      _id: karigar._id,
      name: karigar.name,
      specialization: karigar.specialization,
      phone: karigar.phone,
    },
    totalAccruedWages: fromCents(accruedCents),
    totalPaidWages: fromCents(paidCents),
    netPayableBalance: fromCents(payableCents),
    entriesCount: wageEntries.length,
    recentEntries: wageEntries.slice(0, 20),
  };
};
