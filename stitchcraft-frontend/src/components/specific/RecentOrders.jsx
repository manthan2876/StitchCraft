import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { formatCurrency, formatDate } from '../../utils/formatters';
import { useLanguage } from '../../context/LanguageContext';
import { MdEdit, MdSearch, MdTune } from 'react-icons/md';

export const RecentOrders = ({ orders, onUpdateStatus, onEditOrder }) => {
  const { t } = useLanguage();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');

  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const statusList = ['Incoming', 'Measuring', 'Cutting', 'Stitching', 'Checking', 'Ready', 'Delivered', 'Cancelled'];

  const filteredOrders = orders.filter(o => {
    const matchesSearch = o.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      o.orderId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      o.apparelType.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'All' || o.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getStatusColor = (status) => {
    switch (status) {
      case 'Incoming': return { text: '#3b82f6', bg: 'rgba(59,130,246,0.1)' };
      case 'Measuring': return { text: '#f59e0b', bg: 'rgba(245,158,11,0.1)' };
      case 'Cutting': return { text: '#06b6d4', bg: 'rgba(6,182,212,0.1)' };
      case 'Stitching': return { text: '#a855f7', bg: 'rgba(168,85,247,0.1)' };
      case 'Checking': return { text: '#ec4899', bg: 'rgba(236,72,153,0.1)' };
      case 'Ready': return { text: '#10b981', bg: 'rgba(16,185,129,0.1)' };
      case 'Delivered': return { text: '#9ca3af', bg: 'rgba(156,163,175,0.1)' };
      case 'Cancelled': return { text: '#f43f5e', bg: 'rgba(244,63,94,0.1)' };
      default: return { text: '#9ca3af', bg: 'rgba(156,163,175,0.1)' };
    }
  };

  const getStatusLabel = (status) => {
    const key = 'status' + status;
    const translated = t(key);
    return translated === key ? status : translated;
  };

  return (
    <div className="bg-bg-secondary rounded-[20px] border border-border-subtle overflow-hidden shadow-card text-left">
      {/* Header Panel */}
      <div className="p-6 border-b border-border-subtle flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h3 className="text-lg font-bold text-text-main tracking-wide">{t('activeApparelProjects')}</h3>
          <p className="text-xs text-text-muted mt-0.5">{t('activeApparelProjectsSub')}</p>
        </div>

        {/* Filters */}
        <div className="flex items-center gap-3">
          {/* Mini Search */}
          <div className="relative">
            <input
              type="text"
              placeholder={t('searchOrders')}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="bg-bg-input border border-border-subtle text-xs rounded-xl px-3 py-2 pl-9 text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple/50 w-[180px] transition-all"
            />
            <MdSearch className="w-4 h-4 text-text-muted absolute left-3 top-1/2 transform -translate-y-1/2" />
          </div>

          {/* Status Dropdown */}
          <div className="flex items-center bg-bg-input border border-border-subtle rounded-xl px-2.5 py-2">
            <MdTune className="w-3.5 h-3.5 text-text-muted mr-1.5" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="bg-transparent text-xs text-text-main outline-none border-none cursor-pointer pr-1 font-bold"
            >
              <option value="All" className="bg-bg-card font-bold text-text-main">{t('allStages')}</option>
              {statusList.map(status => (
                <option key={status} value={status} className="bg-bg-card font-bold text-text-main">{getStatusLabel(status)}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Table Workspace */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-bg-primary border-b border-border-subtle">
              <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{t('orderRef')}</th>
              <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{t('customer')}</th>
              <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{t('apparel')}</th>
              <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{t('deliveryDate')}</th>
              <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-right">{t('value')}</th>
              <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-right">{t('dues')}</th>
              <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{t('statusStage')}</th>
              <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-center">{t('action')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border-subtle">
            {filteredOrders.length === 0 ? (
              <tr>
                <td colSpan="8" className="px-6 py-12 text-center text-sm text-text-muted">
                  {t('noOrdersFilter')}
                </td>
              </tr>
            ) : (
              filteredOrders.map((order) => {
                const colors = getStatusColor(order.status);
                const outstanding = order.payment?.balanceAmount || 0;

                return (
                  <tr key={order._id} className="hover:bg-bg-hover transition-colors group">
                    <td className="px-6 py-4 text-sm font-bold">
                      <Link to={`/orders/${order._id}`} className="text-color-accent-purple hover:underline">
                        {order.orderId}
                      </Link>
                    </td>
                    <td className="px-6 py-4 text-sm font-semibold text-text-main/90">
                      {order.customerName}
                    </td>
                    <td className="px-6 py-4 text-sm text-text-muted">
                      {tf(order.apparelType.toLowerCase(), order.apparelType)}
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-text-main">
                      {formatDate(order.deliveryDate)}
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-text-main text-right">
                      {formatCurrency(order.price)}
                    </td>
                    <td className={`px-6 py-4 text-sm font-black text-right ${outstanding > 0 ? 'text-color-accent-pink' : 'text-color-accent-emerald'}`}>
                      {outstanding > 0 ? formatCurrency(outstanding) : t('paid')}
                    </td>
                    <td className="px-6 py-4">
                      {onUpdateStatus ? (
                        <select
                          value={order.status}
                          onChange={(e) => onUpdateStatus(order._id, e.target.value)}
                          style={{ color: colors.text, backgroundColor: colors.bg }}
                          className="px-3 py-1.5 text-xs font-extrabold rounded-full border-none outline-none cursor-pointer focus:ring-1 focus:ring-white/10 transition-colors"
                        >
                          {statusList.map(status => (
                            <option key={status} value={status} className="bg-bg-card text-text-main font-bold">{getStatusLabel(status)}</option>
                          ))}
                        </select>
                      ) : (
                        <span
                          style={{ color: colors.text, backgroundColor: colors.bg, whiteSpace: 'nowrap' }}
                          className="inline-flex items-center gap-1.5 px-3 py-1 text-xs font-bold rounded-full"
                        >
                          <span style={{ backgroundColor: colors.text }} className="w-1.5 h-1.5 rounded-full"></span>
                          {getStatusLabel(order.status)}
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-center">
                      <button
                        onClick={() => onEditOrder && onEditOrder(order)}
                        className="p-1.5 rounded-lg bg-bg-card hover:bg-bg-card-hover text-text-muted hover:text-text-main transition-all cursor-pointer opacity-80 hover:opacity-100"
                        title={t('editDetails')}
                      >
                        <MdEdit className="w-4.5 h-4.5" />
                      </button>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default RecentOrders;
