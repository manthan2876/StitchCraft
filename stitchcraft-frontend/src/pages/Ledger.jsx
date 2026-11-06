/* src/pages/Ledger.jsx */
import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import Card from '../components/common/Card';
import { formatCurrency, formatDate } from '../utils/formatters';
import { useLanguage } from '../context/LanguageContext';
import { buildCSV, filterByDateRange } from '../utils/csv';
import PendingBalancesTab from '../features/ledger/components/PendingBalancesTab';
import {
  MdSearch as SearchIcon,
  MdFilterList as FilterIcon,
  MdFileDownload as DownloadIcon,
  MdPrint as PrintIcon,
  MdTrendingUp as UpIcon,
  MdInventory as InventoryIcon,
  MdAccountBalanceWallet as WalletIcon,
  MdMoneyOff as ExpenseIcon,
} from 'react-icons/md';

export const Ledger = () => {
  const { t } = useLanguage();
  const [journal, setJournal] = useState([]);
  const [summary, setSummary] = useState({
    totalSales: 0,
    totalReceived: 0,
    totalOutstanding: 0,
    totalExpenses: 0,
    totalFabricProfit: 0,
    totalFabricCost: 0,
  });
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCategory, setFilterCategory] = useState('All'); // 'All', 'Sales', 'Payments', 'Expenses', 'Material Cost'
  const [activeSubTab, setActiveSubTab] = useState('cashbook'); // 'cashbook' | 'udhar'
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  // Helper with fallbacks for translations
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const fetchSummary = async () => {
    try {
      const data = await api.get('/ledger/summary');
      setSummary(data);
    } catch (err) {
      console.error('Failed to fetch summary:', err);
    }
  };

  const fetchJournal = async () => {
    setLoading(true);
    try {
      const data = await api.get(
        `/ledger/journal?category=${filterCategory}&search=${encodeURIComponent(searchTerm)}`
      );
      setJournal(data);
    } catch (err) {
      console.error('Failed to fetch journal entries:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSummary();
  }, []);

  useEffect(() => {
    fetchJournal();
  }, [filterCategory, searchTerm]);

  // Filter journal records by selected date range
  const displayedJournal = filterByDateRange(journal, 'date', startDate, endDate);

  // Export to CSV Feature with strict RFC 4180 escaping and date range filtering
  const downloadCSV = () => {
    const headers = ['Date', 'Type', 'Description', 'Amount', 'Flow', 'Method', 'Running Balance'];
    const rows = displayedJournal.map(entry => [
      formatDate(entry.date),
      entry.type || '',
      entry.description || '',
      entry.amount !== undefined ? entry.amount : 0,
      entry.flow || 'None',
      entry.paymentMethod || 'N/A',
      entry.runningBalance !== undefined ? entry.runningBalance : '',
    ]);

    const csvContent = buildCSV(headers, rows);
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    const dateSuffix = startDate || endDate ? `_${startDate || 'start'}_to_${endDate || 'today'}` : `_${new Date().toISOString().split('T')[0]}`;
    link.download = `StitchCraft_Ultimate_Ledger${dateSuffix}.csv`;
    link.click();
  };

  // Print Feature
  const handlePrint = () => {
    window.print();
  };

  const cashInHand = summary.totalReceived - summary.totalExpenses;

  const getFlowBadgeClass = (flow) => {
    if (flow === 'In') return 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20';
    if (flow === 'Out') return 'bg-rose-500/10 text-rose-500 border border-rose-500/20';
    return 'bg-gray-500/10 text-gray-500 border border-gray-500/20';
  };

  const getTypeLabel = (type) => {
    if (type === 'Sales') return tf('sales', 'Sales Booking');
    if (type === 'Payment') return tf('payment', 'Payment Received');
    if (type === 'Refund') return tf('refund', 'Refund Issued');
    if (type === 'Expense') return tf('expense', 'Expense');
    if (type === 'Material Consumption') return tf('materialConsumption', 'Material Consumption');
    return type;
  };

  return (
    <div className="flex flex-col gap-8 select-none text-left pb-24">
      {/* Printable Heading */}
      <div className="hidden print:block mb-6 border-b border-border-strong pb-4">
        <h1 className="text-2xl font-black text-black">StitchCraft Tailoring ERP - Financial Ledger</h1>
        <p className="text-xs text-gray-500 mt-1">Generated on: {new Date().toLocaleString()}</p>
      </div>

      {/* Header controls */}
      <div className="flex items-center justify-between print:hidden">
        <div>
          <h2 className="text-xl font-bold text-text-main tracking-wide">{tf('ultimateLedger', 'Ultimate Ledger')}</h2>
          <p className="text-xs text-text-muted mt-0.5 font-semibold">
            {tf('ultimateLedgerSub', 'Unified inflows/outflows of sales, client deposits, lining usage, and shop expenses')}
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button onClick={downloadCSV} className="btn-tactile-dark flex items-center gap-1.5 cursor-pointer text-xs py-2 px-3">
            <DownloadIcon className="w-4 h-4 text-text-main" />
            <span>{tf('downloadCsv', 'Download CSV')}</span>
          </button>
          <button onClick={handlePrint} className="btn-tactile-dark flex items-center gap-1.5 cursor-pointer text-xs py-2 px-3">
            <PrintIcon className="w-4 h-4 text-text-main" />
            <span>{tf('printLedger', 'Print Ledger')}</span>
          </button>
        </div>
      </div>

      {/* Sub-tab Navigation (Cashbook vs Udhar) */}
      <div className="flex border-b border-border-subtle gap-6 print:hidden">
        <button
          onClick={() => setActiveSubTab('cashbook')}
          className={`pb-3 text-sm font-bold transition-all border-b-2 cursor-pointer ${
            activeSubTab === 'cashbook'
              ? 'border-color-accent-purple text-color-accent-purple'
              : 'border-transparent text-text-muted hover:text-text-main'
          }`}
        >
          {tf('cashbookJournal', 'Cashbook & Inflows/Outflows')}
        </button>
        <button
          onClick={() => setActiveSubTab('udhar')}
          className={`pb-3 text-sm font-bold transition-all border-b-2 cursor-pointer flex items-center gap-1.5 ${
            activeSubTab === 'udhar'
              ? 'border-color-accent-purple text-color-accent-purple'
              : 'border-transparent text-text-muted hover:text-text-main'
          }`}
        >
          <span>{tf('udharPendingBalances', 'Udhar / Pending Balances')}</span>
          {summary.totalOutstanding > 0 && (
            <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-rose-500/15 text-rose-500">
              {formatCurrency(summary.totalOutstanding)}
            </span>
          )}
        </button>
      </div>

      {activeSubTab === 'udhar' ? (
        <PendingBalancesTab />
      ) : (
        <>
          {/* Financial Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className="flex items-center gap-4 py-4 px-6 border-l-4 border-l-emerald-500 bg-bg-card">
          <div className="w-12 h-12 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-500">
            <WalletIcon className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('cashInHand', 'Cash in Hand')}</span>
            <h3 className="text-lg font-black text-text-main mt-0.5">{formatCurrency(cashInHand)}</h3>
          </div>
        </Card>

        <Card className="flex items-center gap-4 py-4 px-6 border-l-4 border-l-blue-500 bg-bg-card">
          <div className="w-12 h-12 rounded-xl bg-blue-500/10 flex items-center justify-center text-blue-500">
            <UpIcon className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('totalSalesBooked', 'Total Sales Booked')}</span>
            <h3 className="text-lg font-black text-text-main mt-0.5">{formatCurrency(summary.totalSales)}</h3>
          </div>
        </Card>

        <Card className="flex items-center gap-4 py-4 px-6 border-l-4 border-l-rose-500 bg-bg-card">
          <div className="w-12 h-12 rounded-xl bg-rose-500/10 flex items-center justify-center text-rose-500">
            <ExpenseIcon className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('generalExpenses', 'General Expenses')}</span>
            <h3 className="text-lg font-black text-rose-500 mt-0.5">{formatCurrency(summary.totalExpenses)}</h3>
          </div>
        </Card>

        <Card className="flex items-center gap-4 py-4 px-6 border-l-4 border-l-purple-500 bg-bg-card">
          <div className="w-12 h-12 rounded-xl bg-purple-500/10 flex items-center justify-center text-color-accent-purple">
            <InventoryIcon className="w-6 h-6 text-color-accent-purple" />
          </div>
          <div>
            <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('fabricLiningCost', 'Lining Material Cost')}</span>
            <h3 className="text-lg font-black text-text-main mt-0.5">{formatCurrency(summary.totalFabricCost)}</h3>
          </div>
        </Card>
      </div>

      {/* Filters Card */}
      <Card className="flex flex-col gap-4 py-4 px-6 print:hidden">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          {/* Search */}
          <div className="w-full md:w-[300px] relative">
            <input
              type="text"
              placeholder={tf('searchLedgerPlaceholder', 'Search ledger entries...')}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-bg-input border border-border-subtle text-xs rounded-xl px-3 py-2.5 pl-9 text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple/50 transition-all text-sm"
            />
            <SearchIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 text-text-muted w-4 h-4" />
          </div>

          {/* Date Range Filtering */}
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('dateRange', 'Date Range')}:</span>
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="bg-bg-input border border-border-subtle text-xs rounded-lg px-2.5 py-1.5 text-text-main outline-none focus:border-color-accent-purple"
              aria-label="Start Date"
            />
            <span className="text-xs text-text-muted">to</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="bg-bg-input border border-border-subtle text-xs rounded-lg px-2.5 py-1.5 text-text-main outline-none focus:border-color-accent-purple"
              aria-label="End Date"
            />
            {(startDate || endDate) && (
              <button
                type="button"
                onClick={() => { setStartDate(''); setEndDate(''); }}
                className="text-xs text-rose-500 hover:underline px-1 font-semibold cursor-pointer"
              >
                Clear
              </button>
            )}
          </div>
        </div>

        {/* Category Filters */}
        <div className="flex flex-wrap items-center gap-1.5 pt-2 border-t border-border-subtle">
          <FilterIcon className="text-text-muted w-4 h-4 mr-1 hidden sm:block" />
          {[
            { key: 'All', label: 'All' },
            { key: 'Sales', label: 'Sales Booked' },
            { key: 'Payments', label: 'Payments' },
            { key: 'Expenses', label: 'Shop Expenses' },
            { key: 'Material Cost', label: 'Lining Cost' },
          ].map(({ key, label }) => (
            <button
              key={key}
              onClick={() => setFilterCategory(key)}
              className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-all cursor-pointer border
                ${filterCategory === key
                  ? 'bg-color-accent-purple border-color-accent-purple text-white-forced shadow-md'
                  : 'filter-tab-inactive hover:text-text-main'}`}
            >
              {tf(key.toLowerCase().replace(' ', ''), label)}
            </button>
          ))}
        </div>
      </Card>

      {/* Ledger Journal Log Table */}
      <div className="bg-bg-secondary rounded-[20px] border border-border-subtle overflow-hidden shadow-card">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-bg-primary/30 border-b border-border-subtle">
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('date', 'Date')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('description', 'Description')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('type', 'Type')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('method', 'Method')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('flow', 'Flow')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-right">{tf('amount', 'Amount')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-right">{tf('balance', 'Balance')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-subtle">
              {loading ? (
                <tr>
                  <td colSpan="7" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('syncingLedger', 'Syncing ledger audit entries...')}
                  </td>
                </tr>
              ) : displayedJournal.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('noLedgerRecords', 'No ledger journal entries found.')}
                  </td>
                </tr>
              ) : (
                displayedJournal.map((entry) => (
                  <tr key={entry._id} className="hover:bg-bg-hover transition-colors">
                    <td style={{ whiteSpace: 'nowrap' }} className="px-6 py-4 text-sm font-semibold text-text-main">
                      {formatDate(entry.date)}
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-text-main/90 max-w-xs md:max-w-md truncate">
                      {entry.description}
                    </td>
                    <td style={{ whiteSpace: 'nowrap' }} className="px-6 py-4 text-xs font-semibold text-text-muted">
                      {getTypeLabel(entry.type)}
                    </td>
                    <td style={{ whiteSpace: 'nowrap' }} className="px-6 py-4 text-xs font-medium text-text-muted">
                      {entry.paymentMethod}
                    </td>
                    <td className="px-6 py-4 text-xs">
                      {entry.isReverted ? (
                        <span style={{ whiteSpace: 'nowrap' }} className="inline-block px-2 py-0.5 rounded-md text-[9px] font-black uppercase tracking-wider bg-rose-500/10 text-rose-500 border border-rose-500/20">
                          {tf('reverted', 'Reverted')}
                        </span>
                      ) : (
                        <span style={{ whiteSpace: 'nowrap' }} className={`inline-block px-2 py-0.5 rounded-md text-[9px] font-black uppercase tracking-wider ${getFlowBadgeClass(entry.flow)}`}>
                          {entry.flow === 'In' ? tf('inflow', 'In') : entry.flow === 'Out' ? tf('outflow', 'Out') : tf('nonCash', 'Non-Cash')}
                        </span>
                      )}
                    </td>
                    <td style={{ whiteSpace: 'nowrap' }} className={`px-6 py-4 text-sm font-black text-right ${
                      entry.isReverted
                        ? 'line-through text-text-muted opacity-50'
                        : (entry.flow === 'In' ? 'text-color-accent-emerald' : entry.flow === 'Out' ? 'text-color-accent-pink' : 'text-text-muted opacity-80')
                    }`}>
                      {entry.flow === 'In' ? '+' : entry.flow === 'Out' ? '-' : ''}{formatCurrency(entry.amount)}
                    </td>
                    <td style={{ whiteSpace: 'nowrap' }} className="px-6 py-4 text-sm font-black text-right text-text-main">
                      {entry.flow === 'None' ? '—' : formatCurrency(entry.runningBalance)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
        </>
      )}
    </div>
  );
};

export default Ledger;
