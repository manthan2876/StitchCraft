/* src/pages/Payments.jsx */
import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import Card from '../components/common/Card';
import { useLanguage } from '../context/LanguageContext';
import { formatCurrency } from '../utils/formatters';
import { MdSearch, MdFilterList, MdCheckCircle, MdPayment, MdClose, MdAccountBalanceWallet } from 'react-icons/md';

export const Payments = () => {
  const { t } = useLanguage();
  const [payments, setPayments] = useState([]);
  const [summary, setSummary] = useState({ totalSales: 0, totalReceived: 0, totalOutstanding: 0 });
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('All'); // 'All', 'Pending', 'Paid', 'Partial'
  const [searchTerm, setSearchTerm] = useState('');

  // Payment recording modal state
  const [selectedPayment, setSelectedPayment] = useState(null);
  const [collectAmount, setCollectAmount] = useState('');
  const [collectMethod, setCollectMethod] = useState('Cash');
  const [modalError, setModalError] = useState('');
  const [modalLoading, setModalLoading] = useState(false);

  // Helper with fallbacks for translations
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  // Tab config: keep state values as English keys for API, translate display only
  const tabs = [
    { key: 'All',     label: () => tf('all', 'All') },
    { key: 'Pending', label: () => tf('pending', 'Pending') },
    { key: 'Paid',    label: () => tf('paid', 'Paid') },
    { key: 'Partial', label: () => tf('partial', 'Partial') },
  ];

  const fetchSummary = async () => {
    try {
      const data = await api.get('/ledger/summary');
      setSummary(data);
    } catch (err) {
      console.error('Failed to fetch summary:', err);
    }
  };

  const fetchPayments = async () => {
    setLoading(true);
    try {
      const data = await api.get(`/ledger/transactions?type=${activeTab}&search=${encodeURIComponent(searchTerm)}`);
      setPayments(data);
    } catch (err) {
      console.error('Failed to fetch payments:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSummary();
  }, []);

  useEffect(() => {
    fetchPayments();
  }, [activeTab, searchTerm]);

  const handleOpenCollectModal = (payment) => {
    setSelectedPayment(payment);
    setCollectAmount(String(payment.balance));
    setCollectMethod('Cash');
    setModalError('');
  };

  const handleCloseCollectModal = () => {
    setSelectedPayment(null);
    setCollectAmount('');
    setCollectMethod('Cash');
    setModalError('');
  };

  const handleRecordPaymentSubmit = async (e) => {
    e.preventDefault();
    if (!collectAmount || Number(collectAmount) <= 0) {
      setModalError('Please enter a positive amount to collect.');
      return;
    }

    if (Number(collectAmount) > selectedPayment.balance) {
      setModalError(`Cannot collect more than the remaining balance (${formatCurrency(selectedPayment.balance)}).`);
      return;
    }

    setModalLoading(true);
    try {
      const targetOrderId = selectedPayment.orderObjId || selectedPayment.orderId;
      await api.post(`/orders/${targetOrderId}/payments`, {
        amount: Number(collectAmount),
        paymentType: collectMethod
      });

      handleCloseCollectModal();
      fetchSummary();
      fetchPayments();
    } catch (err) {
      setModalError(err.message || 'Failed to record payment.');
    } finally {
      setModalLoading(false);
    }
  };

  const getStatusBadgeClass = (status) => {
    switch (status) {
      case 'Paid':
        return 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20';
      case 'Partial':
        return 'bg-amber-500/10 text-amber-500 border border-amber-500/20';
      case 'Pending':
        return 'bg-rose-500/10 text-rose-500 border border-rose-500/20';
      default:
        return 'bg-bg-hover text-text-muted border border-border-subtle';
    }
  };

  const getStatusLabel = (status) => {
    if (status === 'Paid') return tf('paid', 'Paid');
    if (status === 'Pending') return tf('pending', 'Pending');
    if (status === 'Partial') return tf('partial', 'Partial');
    return status;
  };

  return (
    <div className="flex flex-col gap-6 select-none pb-20 relative min-h-[calc(100vh-120px)] text-left">
      {/* Page Header */}
      <div>
        <h2 className="text-xl font-bold text-text-main tracking-wide">{tf('paymentsLedger', 'Payments Ledger')}</h2>
        <p className="text-xs text-text-muted mt-0.5 font-semibold">{tf('paymentsLedgerSub', 'Real-time billing, credit cycles, and payment deposits audit')}</p>
      </div>

      {/* Financial Metric Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="flex items-center gap-4 py-4 px-6 border-l-4 border-l-emerald-500">
          <div className="w-12 h-12 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-500">
            <MdAccountBalanceWallet className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('totalSales', 'Total Sales')}</span>
            <h3 className="text-xl font-black text-text-main mt-0.5">{formatCurrency(summary.totalSales)}</h3>
          </div>
        </Card>

        <Card className="flex items-center gap-4 py-4 px-6 border-l-4 border-l-blue-500">
          <div className="w-12 h-12 rounded-xl bg-blue-500/10 flex items-center justify-center text-blue-500">
            <MdPayment className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('totalReceived', 'Total Received')}</span>
            <h3 className="text-xl font-black text-text-main mt-0.5">{formatCurrency(summary.totalReceived)}</h3>
          </div>
        </Card>

        <Card className="flex items-center gap-4 py-4 px-6 border-l-4 border-l-rose-500">
          <div className="w-12 h-12 rounded-xl bg-rose-500/10 flex items-center justify-center text-rose-500">
            <MdCheckCircle className="w-6 h-6 text-rose-500" />
          </div>
          <div>
            <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('outstandingCash', 'Outstanding Cash')}</span>
            <h3 className="text-xl font-black text-rose-500 mt-0.5">{formatCurrency(summary.totalOutstanding)}</h3>
          </div>
        </Card>
      </div>

      {/* Filters Card */}
      <Card className="flex flex-col md:flex-row md:items-center justify-between gap-4 py-4 px-6">
        {/* Search */}
        <div className="w-full md:w-[320px] relative">
          <input
            type="text"
            placeholder={tf('searchPaymentsPlaceholder', 'Search by customer, order, type...')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-bg-input border border-border-subtle text-xs rounded-xl px-3 py-2.5 pl-9 text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple/50 transition-all text-sm"
          />
          <MdSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-text-muted w-4.5 h-4.5" />
        </div>

        {/* Status Tab Filters */}
        <div className="flex flex-wrap items-center gap-1.5">
          <MdFilterList className="text-text-muted w-4 h-4 mr-1 hidden sm:block" />
          {tabs.map(({ key, label }) => (
            <button
              key={key}
              onClick={() => setActiveTab(key)}
              className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-all cursor-pointer
                ${activeTab === key
                  ? 'bg-color-accent-purple border border-color-accent-purple text-white-forced shadow-md shadow-color-accent-purple/20'
                  : 'filter-tab-inactive hover:text-text-main'}`}
            >
              {label()}
            </button>
          ))}
        </div>
      </Card>

      {/* Ledger Table */}
      <div className="bg-bg-secondary rounded-[20px] border border-border-subtle overflow-hidden shadow-card mb-12">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-bg-primary/30 border-b border-border-subtle">
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('orderId', 'Order ID')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('customer', 'Customer')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('totalValue', 'Total Value')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('received', 'Received')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('balanceDue', 'Balance Due')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('method', 'Method')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('status', 'Status')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-right">{tf('actions', 'Actions')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-subtle">
              {loading ? (
                <tr>
                  <td colSpan="8" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('syncingPayments', 'Syncing payments...')}
                  </td>
                </tr>
              ) : payments.length === 0 ? (
                <tr>
                  <td colSpan="8" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('noPaymentRecords', 'No payment transaction logs found.')}
                  </td>
                </tr>
              ) : (
                payments.map((p) => (
                  <tr key={p._id} className="hover:bg-bg-hover transition-colors">
                    <td className="px-6 py-4 text-sm font-black text-text-main">{p.orderId}</td>
                    <td className="px-6 py-4 text-sm font-bold text-text-main/90">{p.customerName}</td>
                    <td className="px-6 py-4 text-sm font-bold text-text-muted">{formatCurrency(p.amount)}</td>
                    <td className="px-6 py-4 text-sm font-bold text-color-accent-blue">{formatCurrency(p.paid)}</td>
                    <td className="px-6 py-4 text-sm font-bold text-color-accent-pink">{formatCurrency(p.balance)}</td>
                    <td className="px-6 py-4 text-xs font-bold text-text-muted">{p.paymentType}</td>
                    <td className="px-6 py-4 text-xs">
                      <span className={`px-2 py-0.5 rounded-md text-[10px] font-extrabold uppercase tracking-wider ${getStatusBadgeClass(p.status)}`}>
                        {getStatusLabel(p.status)}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-right">
                      {p.status !== 'Paid' ? (
                        <button
                          onClick={() => handleOpenCollectModal(p)}
                          className="px-3 py-1.5 bg-color-accent-purple text-white-forced rounded-lg text-xs font-extrabold flex items-center gap-1 hover:bg-color-accent-purple/90 active:scale-95 transition-all shadow-md shadow-purple-950/20 cursor-pointer ml-auto"
                        >
                          <MdPayment className="w-3.5 h-3.5 text-white-forced" />
                          <span>{tf('collect', 'Collect')}</span>
                        </button>
                      ) : (
                        <span className="text-xs text-color-accent-emerald font-extrabold flex items-center gap-1 justify-end">
                          <MdCheckCircle className="w-4 h-4" />
                          <span>{tf('settled', 'Settled')}</span>
                        </span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Collect Payment Modal */}
      {selectedPayment && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={handleCloseCollectModal}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-2">
              <MdPayment className="text-color-accent-purple w-5 h-5" />
              {tf('collectPaymentTitle', 'Collect Payment')}
            </h3>
            <p className="text-xs text-text-muted mb-4 font-semibold">
              {tf('collectPaymentDesc', 'Deposit payment amount from customer {customer} for order {orderId}')
                .replace('{customer}', selectedPayment.customerName)
                .replace('{orderId}', selectedPayment.orderId)}
            </p>

            <form onSubmit={handleRecordPaymentSubmit} className="flex flex-col gap-4">
              <div className="bg-bg-secondary border border-border-subtle rounded-xl p-4 flex flex-col gap-1.5 text-left">
                <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('remainingBalance', 'Remaining Balance')}</span>
                <span className="text-xl font-black text-color-accent-pink">{formatCurrency(selectedPayment.balance)}</span>
              </div>

              <div className="flex flex-col gap-1 text-left">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('amountToCollect', 'Amount to Collect')}</label>
                <input
                  type="number"
                  required
                  min="1"
                  max={selectedPayment.balance}
                  value={collectAmount}
                  onChange={(e) => { setCollectAmount(e.target.value); setModalError(''); }}
                  placeholder="Enter amount"
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm font-bold"
                />
              </div>

              <div className="flex flex-col gap-1 text-left">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('paymentMethod', 'Payment Method')}</label>
                <select
                  value={collectMethod}
                  onChange={(e) => setCollectMethod(e.target.value)}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm font-bold cursor-pointer"
                >
                  <option value="Cash" className="bg-bg-secondary text-text-main">{tf('cashMethod', 'Cash')}</option>
                  <option value="Online" className="bg-bg-secondary text-text-main">{tf('onlineMethod', 'Online')}</option>
                  <option value="Card" className="bg-bg-secondary text-text-main">{tf('cardMethod', 'Card')}</option>
                </select>
              </div>

              {modalError && (
                <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse">
                  {modalError}
                </span>
              )}

              <button
                type="submit"
                disabled={modalLoading}
                className="mt-2 w-full py-3 bg-color-accent-purple text-white-forced font-bold rounded-xl shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/95 active:scale-98 transition-all duration-200 cursor-pointer disabled:opacity-50 text-sm"
              >
                {modalLoading ? tf('recording', 'Recording...') : tf('recordCollectedCash', 'Record Collected Deposit')}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Sticky Bottom Ribbon Summary */}
      <div className="fixed bottom-0 left-0 lg:left-[260px] right-0 bg-bg-secondary/95 backdrop-blur-md border-t border-border-subtle py-4 px-6 flex items-center justify-between z-30 shadow-2xl">
        <div className="flex items-center gap-6">
          <div className="flex flex-col">
            <span className="text-[9px] font-bold text-text-muted uppercase tracking-wider">{tf('salesLedger', 'Sales Ledger')}</span>
            <span className="text-sm font-black text-text-main">{formatCurrency(summary.totalSales)}</span>
          </div>
          <div className="h-6 w-px bg-border-strong"></div>
          <div className="flex flex-col">
            <span className="text-[9px] font-bold text-text-muted uppercase tracking-wider">{tf('cashReceived', 'Cash Received')}</span>
            <span className="text-sm font-black text-color-accent-blue">{formatCurrency(summary.totalReceived)}</span>
          </div>
          <div className="h-6 w-px bg-border-strong"></div>
          <div className="flex flex-col">
            <span className="text-[9px] font-bold text-text-muted uppercase tracking-wider">{tf('outstandingDues', 'Outstanding Dues')}</span>
            <span className="text-sm font-black text-color-accent-pink">{formatCurrency(summary.totalOutstanding)}</span>
          </div>
        </div>
        <div>
          <span className="text-[9px] font-black text-color-accent-purple uppercase tracking-widest bg-color-accent-purple/10 px-2.5 py-1 rounded-md border border-color-accent-purple/20">
            {tf('realtimeAudit', 'Real-time Audit')}
          </span>
        </div>
      </div>
    </div>
  );
};

export default Payments;
