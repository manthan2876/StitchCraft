/* src/features/ledger/components/PendingBalancesTab.jsx */
import React, { useState, useEffect } from 'react';
import Card from '../../../components/common/Card';
import { api } from '../../../services/api';
import { formatCurrency, formatDate } from '../../../utils/formatters';
import { useLanguage } from '../../../context/LanguageContext';
import {
  MdSearch,
  MdPhone,
  MdContentCopy,
  MdCheck,
  MdOpenInNew,
  MdWarningAmber,
  MdReceiptLong,
  MdOutlineAccountBalanceWallet,
} from 'react-icons/md';
import { FaWhatsapp } from 'react-icons/fa';
import { Link } from 'react-router-dom';

export const PendingBalancesTab = () => {
  const { t } = useLanguage();
  const [data, setData] = useState({ totalOutstanding: 0, customerCount: 0, customers: [] });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [copiedId, setCopiedId] = useState(null);

  const fetchPendingBalances = async () => {
    setLoading(true);
    try {
      const res = await api.get('/customers/pending-balances');
      setData(res || { totalOutstanding: 0, customerCount: 0, customers: [] });
    } catch (err) {
      console.error('Failed to load pending balances:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPendingBalances();
  }, []);

  const handleCopyReminder = (text, id) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const filteredCustomers = (data.customers || []).filter((c) =>
    (c.name || '').toLowerCase().includes(search.toLowerCase()) ||
    (c.phone || '').toLowerCase().includes(search.toLowerCase()) ||
    (c.orders || []).some(o => (o.orderId || '').toLowerCase().includes(search.toLowerCase()))
  );

  return (
    <div className="flex flex-col gap-6 text-left">
      {/* Metrics Row */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="p-4 flex items-center gap-3.5 border border-rose-500/20 bg-rose-500/5">
          <div className="w-12 h-12 rounded-xl bg-rose-500/15 text-rose-500 flex items-center justify-center shrink-0">
            <MdWarningAmber className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-extrabold uppercase tracking-wider text-text-muted">{t('totalUdharOutstanding')}</span>
            <h3 className="text-xl font-black text-rose-500 mt-0.5">{formatCurrency(data.totalOutstanding || 0)}</h3>
          </div>
        </Card>

        <Card className="p-4 flex items-center gap-3.5 border border-border-subtle">
          <div className="w-12 h-12 rounded-xl bg-color-accent-purple/15 text-color-accent-purple flex items-center justify-center shrink-0">
            <MdOutlineAccountBalanceWallet className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-extrabold uppercase tracking-wider text-text-muted">{t('customersWithBalance')}</span>
            <h3 className="text-xl font-black text-text-main mt-0.5">{data.customerCount || 0}</h3>
          </div>
        </Card>

        <Card className="p-4 flex items-center gap-3.5 border border-border-subtle">
          <div className="w-12 h-12 rounded-xl bg-emerald-500/15 text-emerald-500 flex items-center justify-center shrink-0">
            <MdReceiptLong className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-extrabold uppercase tracking-wider text-text-muted">{t('averageOutstanding')}</span>
            <h3 className="text-xl font-black text-text-main mt-0.5">
              {formatCurrency(data.customerCount > 0 ? (data.totalOutstanding / data.customerCount) : 0)}
            </h3>
          </div>
        </Card>
      </div>

      {/* Search Input */}
      <Card className="p-4 flex justify-between items-center">
        <div className="relative w-full sm:w-80">
          <MdSearch className="absolute left-3.5 top-1/2 -translate-y-1/2 text-text-muted w-4 h-4" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t('searchUdharPlaceholder')}
            className="w-full pl-9 pr-4 py-2 bg-bg-input border border-border-subtle rounded-xl text-xs text-text-main outline-none focus:border-color-accent-purple transition-all placeholder:text-text-muted/50"
          />
        </div>
        <span className="text-xs text-text-muted font-bold hidden sm:inline">
          {(t('showingBalances') || 'Showing {filtered} of {total} owing balances')
            .replace('{filtered}', filteredCustomers.length)
            .replace('{total}', data.customerCount)}
        </span>
      </Card>

      {/* Customer Balances List */}
      <Card className="p-0 overflow-hidden border border-border-subtle">
        {loading ? (
          <div className="py-16 text-center text-xs text-text-muted font-bold flex flex-col items-center justify-center gap-3">
            <div className="w-8 h-8 rounded-full border-3 border-color-accent-purple border-t-transparent animate-spin"></div>
            <span>{t('calculatingBalances')}</span>
          </div>
        ) : filteredCustomers.length === 0 ? (
          <div className="py-16 text-center text-xs text-text-muted font-semibold">
            {search ? t('noMatchingUdhar') : t('noUdharRecords')}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-left text-xs">
              <thead>
                <tr className="bg-bg-secondary border-b border-border-subtle text-[10px] font-extrabold text-text-muted uppercase tracking-wider">
                  <th className="px-5 py-3.5">{t('customer')}</th>
                  <th className="px-5 py-3.5">{t('pendingOrders')}</th>
                  <th className="px-5 py-3.5 text-right">{t('outstandingDue')}</th>
                  <th className="px-5 py-3.5 text-right">{t('reminderActions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-subtle font-medium text-text-main">
                {filteredCustomers.map((customer) => {
                  const isCopied = copiedId === customer._id;

                  return (
                    <tr key={customer._id} className="hover:bg-bg-hover/50 transition-colors">
                      <td className="px-5 py-4">
                        <div className="flex flex-col gap-0.5">
                          <Link
                            to={`/customers/${customer._id}`}
                            className="font-bold text-sm text-text-main hover:text-color-accent-purple transition-colors flex items-center gap-1"
                          >
                            <span>{customer.name}</span>
                            <MdOpenInNew className="w-3 h-3 text-text-muted" />
                          </Link>
                          {customer.phone ? (
                            <span className="text-[11px] font-mono text-text-muted flex items-center gap-1">
                              <MdPhone className="w-3 h-3" /> {customer.phone}
                            </span>
                          ) : (
                            <span className="text-[10px] text-text-muted italic">No phone saved</span>
                          )}
                        </div>
                      </td>

                      <td className="px-5 py-4">
                        <div className="flex flex-wrap gap-1.5 max-w-sm">
                          {(customer.orders || []).map((o) => (
                            <Link
                              key={o._id}
                              to={`/orders/${o._id}`}
                              className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-mono font-bold bg-bg-secondary border border-border-subtle hover:border-color-accent-purple transition-colors text-text-main"
                              title={`${o.apparelType} - Due: ${formatDate(o.deliveryDate)}`}
                            >
                              <span>{o.orderId}</span>
                              <span className="text-rose-500 font-bold">({formatCurrency(o.balanceAmount)})</span>
                            </Link>
                          ))}
                        </div>
                        {customer.oldestDueDate && (
                          <span className="text-[10px] text-text-muted mt-1 block">
                            {t('oldestDue')}: {formatDate(customer.oldestDueDate)}
                          </span>
                        )}
                      </td>

                      <td className="px-5 py-4 text-right">
                        <span className="text-base font-black text-rose-500">
                          {formatCurrency(customer.totalBalance)}
                        </span>
                      </td>

                      <td className="px-5 py-4 text-right">
                        <div className="inline-flex items-center gap-2">
                          {customer.whatsappUrl ? (
                            <a
                              href={customer.whatsappUrl}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs transition-all shadow-sm cursor-pointer"
                              title="Send WhatsApp payment reminder"
                            >
                              <FaWhatsapp className="w-3.5 h-3.5" />
                              <span>{t('sendWhatsApp')}</span>
                            </a>
                          ) : (
                            <span className="text-[10px] text-text-muted italic">No Phone</span>
                          )}

                          <button
                            onClick={() => handleCopyReminder(customer.whatsappReminderText, customer._id)}
                            className="p-2 rounded-xl bg-bg-secondary hover:bg-bg-hover border border-border-subtle text-text-muted hover:text-text-main transition-colors cursor-pointer"
                            title={t('copyReminder')}
                          >
                            {isCopied ? <MdCheck className="w-3.5 h-3.5 text-emerald-500" /> : <MdContentCopy className="w-3.5 h-3.5" />}
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
};

export default PendingBalancesTab;

