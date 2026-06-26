/* src/pages/Invoices.jsx */
import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { api } from '../services/api';
import Card from '../components/common/Card';
import { useLanguage } from '../context/LanguageContext';
import { formatCurrency, formatDate } from '../utils/formatters';
import { MdSearch, MdFilterList, MdReceipt, MdVisibility, MdPrint } from 'react-icons/md';

export const Invoices = () => {
  const navigate = useNavigate();
  const { t } = useLanguage();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('All'); // 'All', 'Paid', 'Unpaid', 'Partial'

  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const data = await api.get('/orders');
      setOrders(data);
    } catch (err) {
      console.error('Failed to fetch orders for invoices:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  // Compute invoice totals dynamically
  const invoices = orders.map(order => {
    const liningTotal = order.needsAster ? (order.asterQuantity * order.asterSellingPrice) : 0;
    const billTotal = order.price + liningTotal;
    const paidAmount = order.payment?.paidAmount || 0;
    const balanceAmount = Math.max(0, billTotal - paidAmount);

    let billingStatus = 'Unpaid';
    if (paidAmount > 0) {
      billingStatus = balanceAmount === 0 ? 'Paid' : 'Partial';
    }

    return {
      _id: order._id,
      invoiceId: `INV-${order.orderId}`,
      orderId: order.orderId,
      customerName: order.customerName,
      date: order.date,
      dueDate: order.deliveryDate,
      apparelType: order.apparelType,
      total: billTotal,
      paid: paidAmount,
      balance: balanceAmount,
      status: billingStatus
    };
  });

  // Filters
  const filteredInvoices = invoices.filter(inv => {
    const matchesSearch = inv.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      inv.invoiceId.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'All' || inv.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getStatusBadgeClass = (status) => {
    switch (status) {
      case 'Paid':
        return 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20';
      case 'Partial':
        return 'bg-amber-500/10 text-amber-500 border border-amber-500/20';
      case 'Unpaid':
        return 'bg-rose-500/10 text-rose-500 border border-rose-500/20';
      default:
        return 'bg-bg-hover text-text-muted border border-border-subtle';
    }
  };

  return (
    <div className="flex flex-col gap-6 select-none text-left pb-24">
      <div>
        <h2 className="text-xl font-bold text-text-main tracking-wide">{tf('invoiceManagement', 'Invoice Management')}</h2>
        <p className="text-xs text-text-muted mt-0.5 font-semibold">
          {tf('invoiceRegistrySub', 'Track order billings, customer balance cycles, and generate dynamic receipts')}
        </p>
      </div>

      {/* Filters */}
      <Card className="flex flex-col md:flex-row md:items-center justify-between gap-4 py-4 px-6">
        <div className="w-full md:w-[320px] relative">
          <input
            type="text"
            placeholder={tf('searchInvoicesPlaceholder', 'Search by customer, invoice no...')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-bg-input border border-border-subtle text-xs rounded-xl px-3 py-2.5 pl-9 text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple/50 transition-all text-sm"
          />
          <MdSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-text-muted w-4.5 h-4.5" />
        </div>

        <div className="flex flex-wrap items-center gap-1.5">
          <MdFilterList className="text-text-muted w-4 h-4 mr-1 hidden sm:block" />
          {[
            { key: 'All', label: 'All' },
            { key: 'Paid', label: 'Paid' },
            { key: 'Partial', label: 'Partial' },
            { key: 'Unpaid', label: 'Unpaid' }
          ].map(({ key, label }) => (
            <button
              key={key}
              onClick={() => setStatusFilter(key)}
              className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-all cursor-pointer
                ${statusFilter === key
                  ? 'bg-color-accent-purple border border-color-accent-purple text-white-forced shadow-md shadow-color-accent-purple/20'
                  : 'filter-tab-inactive hover:text-text-main'}`}
            >
              {tf(key.toLowerCase(), label)}
            </button>
          ))}
        </div>
      </Card>

      {/* Table */}
      <div className="bg-bg-secondary rounded-[20px] border border-border-subtle overflow-hidden shadow-card">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-bg-primary/30 border-b border-border-subtle">
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('invoiceNo', 'Invoice No')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('customer', 'Customer')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('billingDate', 'Bill Date')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('dueDate', 'Due Date')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('totalBill', 'Total Bill')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('balanceDue', 'Balance')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('status', 'Status')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-right">{tf('actions', 'Actions')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-subtle">
              {loading ? (
                <tr>
                  <td colSpan="8" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('syncingInvoices', 'Syncing customer invoices...')}
                  </td>
                </tr>
              ) : filteredInvoices.length === 0 ? (
                <tr>
                  <td colSpan="8" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('noInvoicesFound', 'No customer invoice logs found.')}
                  </td>
                </tr>
              ) : (
                filteredInvoices.map((inv) => (
                  <tr key={inv._id} className="hover:bg-bg-hover transition-colors">
                    <td className="px-6 py-4 text-sm font-black text-text-main">{inv.invoiceId}</td>
                    <td className="px-6 py-4 text-sm font-bold text-text-main/90">{inv.customerName}</td>
                    <td className="px-6 py-4 text-xs font-semibold text-text-muted">{formatDate(inv.date)}</td>
                    <td className="px-6 py-4 text-xs font-semibold text-text-muted">{formatDate(inv.dueDate)}</td>
                    <td className="px-6 py-4 text-sm font-bold text-text-main">{formatCurrency(inv.total)}</td>
                    <td className="px-6 py-4 text-sm font-bold text-color-accent-pink">{formatCurrency(inv.balance)}</td>
                    <td className="px-6 py-4 text-xs">
                      <span style={{ whiteSpace: 'nowrap' }} className={`px-2 py-0.5 rounded-md text-[10px] font-extrabold uppercase tracking-wider ${getStatusBadgeClass(inv.status)}`}>
                        {tf(inv.status.toLowerCase(), inv.status)}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-right">
                      <div className="flex gap-2 justify-end">
                        <Link
                          to={`/invoices/${inv._id}`}
                          className="px-2.5 py-1.5 bg-bg-secondary hover:bg-bg-card-hover border border-border-medium rounded-lg text-xs font-bold flex items-center gap-1 hover:text-color-accent-purple active:scale-95 transition-all text-text-main cursor-pointer"
                        >
                          <MdVisibility className="w-3.5 h-3.5 text-color-accent-purple" />
                          <span>{tf('view', 'View')}</span>
                        </Link>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Invoices;
