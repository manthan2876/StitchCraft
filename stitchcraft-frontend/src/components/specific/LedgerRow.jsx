/* src/components/specific/LedgerRow.jsx */
import React from 'react';
import { formatDate, formatCurrency } from '../../utils/formatters';
import { MdEdit, MdList } from 'react-icons/md';

export const LedgerRow = ({ tx, index, onEdit, onViewDetails }) => {
  const isCredit = tx.type === 'Credit' || tx.type === undefined; // Default transaction type Credit (ledger collections)

  return (
    <tr className="border-b border-border-subtle hover:bg-bg-hover transition-colors">
      <td className="px-6 py-4 text-sm font-semibold text-text-muted">
        {index + 1}.
      </td>
      <td className="px-6 py-4 text-sm font-bold text-text-main">
        {formatDate(tx.date)}
      </td>
      <td className="px-6 py-4 text-sm font-semibold text-text-main/90">
        {tx.transactionId || tx.id}
      </td>
      <td className="px-6 py-4 text-sm font-medium text-text-muted">
        <div className="flex flex-col">
          <span className="text-text-main font-semibold">{tx.customerName}</span>
          <span className="text-xs text-text-muted/80">{tx.description}</span>
        </div>
      </td>
      <td className={`px-6 py-4 text-sm font-black ${isCredit ? 'text-color-accent-emerald' : 'text-color-accent-pink'}`}>
        {isCredit ? '+' : '-'}{formatCurrency(tx.amount || 0)}
      </td>
      <td className="px-6 py-4">
        <span style={{ whiteSpace: 'nowrap' }} className="inline-flex items-center gap-1.5 px-3 py-1 text-xs font-semibold rounded-full bg-color-accent-blue/15 text-color-accent-blue">
          <span className="w-1.5 h-1.5 rounded-full bg-color-accent-blue"></span>
          {tx.status}
        </span>
      </td>
      <td className="px-6 py-4 text-right">
        <div className="flex justify-end gap-2">
          {onViewDetails && (
            <button
              onClick={() => onViewDetails(tx)}
              className="p-1.5 rounded-lg bg-bg-card hover:bg-bg-card-hover text-text-muted hover:text-text-main transition-all cursor-pointer"
              title="View Order Details"
            >
              <MdList className="w-4 h-4 text-color-accent-purple" />
            </button>
          )}
          {onEdit && (
            <button
              onClick={() => onEdit(tx)}
              className="p-1.5 rounded-lg bg-bg-card hover:bg-bg-card-hover text-text-muted hover:text-text-main transition-all cursor-pointer"
              title="Edit Transaction"
            >
              <MdEdit className="w-4 h-4" />
            </button>
          )}
        </div>
      </td>
    </tr>
  );
};

export default LedgerRow;
