import React from 'react';
import { MdClose, MdPayments } from 'react-icons/md';

export const PaymentModal = ({
  isOpen,
  onClose,
  balanceAmount,
  payAmount,
  setPayAmount,
  payType,
  setPayType,
  paymentError,
  setPaymentError,
  paymentLoading,
  onSubmit,
  tf,
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
      <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
        <button
          onClick={onClose}
          className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
        >
          <MdClose className="w-5 h-5" />
        </button>

        <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-1">
          <MdPayments className="text-emerald-500 w-5 h-5" />
          {tf('recordPayment', 'Record Payment')}
        </h3>
        <p className="text-xs text-text-muted mb-5 font-semibold">
          {tf('recordPaymentDesc', 'Enter partial or full amount received from the customer for this order.')}
        </p>

        <form onSubmit={onSubmit} className="flex flex-col gap-4">
          <div className="flex flex-col gap-1">
            <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('amountReceived', 'Amount (₹)')}</label>
            <input
              type="number"
              required
              min="1"
              max={balanceAmount}
              value={payAmount}
              onChange={e => { setPayAmount(e.target.value); setPaymentError(''); }}
              placeholder={`Max ₹${balanceAmount}`}
              className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all font-black placeholder:text-text-muted/50"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('paymentMode', 'Payment Mode')}</label>
            <select
              value={payType}
              onChange={e => setPayType(e.target.value)}
              className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all cursor-pointer font-bold"
            >
              <option value="Cash" className="bg-bg-card">💵 Cash</option>
              <option value="UPI" className="bg-bg-card">📱 UPI / Online</option>
              <option value="Card" className="bg-bg-card">💳 Card</option>
            </select>
          </div>

          {paymentError && (
            <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse">
              {paymentError}
            </span>
          )}

          <div className="flex gap-3 mt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2.5 bg-bg-secondary border border-border-medium text-text-main rounded-xl font-bold text-sm hover:bg-bg-card-hover transition-all cursor-pointer"
            >
              {tf('cancel', 'Cancel')}
            </button>
            <button
              type="submit"
              disabled={paymentLoading}
              className="flex-1 py-2.5 bg-emerald-500 text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-emerald-500/20 hover:bg-emerald-600 transition-all cursor-pointer disabled:opacity-50"
            >
              {paymentLoading ? tf('saving', 'Saving...') : tf('confirmPayment', 'Confirm')}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
