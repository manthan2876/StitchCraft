import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams, Link } from 'react-router-dom';
import { useLanguage } from '../context/LanguageContext';
import { api } from '../services/api';
import Card from '../components/common/Card';
import { formatCurrency, formatDate } from '../utils/formatters';
import { MdSearch, MdAdd, MdFilterList, MdEdit, MdDelete, MdClose } from 'react-icons/md';

export const Orders = () => {
  const navigate = useNavigate();
  const { t } = useLanguage();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [inventories, setInventories] = useState([]);

  // Deletion modal state
  const [deleteTargetOrder, setDeleteTargetOrder] = useState(null);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [deleteError, setDeleteError] = useState('');

  // Helper with fallbacks for translations
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
      console.error('Failed to fetch orders:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchOrders(); }, []);

  useEffect(() => {
    const fetchInventories = async () => {
      setLoading(true);
      try {
        const response = await api.get('/inventory?itemType=accessories');
        const data = response.data || response;
        setInventories(data);
      } catch (err) {
        console.error('Failed to fetch Inventories:', err);
      } finally {
        setLoading(false);
      }
    }
    fetchInventories();
  }, []);


  const handleOpenDeleteModal = (order) => {
    setDeleteTargetOrder(order);
    setDeleteError('');
  };

  const handleDeleteOrderSubmit = async () => {
    if (!deleteTargetOrder) return;
    setDeleteLoading(true);
    setDeleteError('');
    try {
      await api.delete(`/orders/${deleteTargetOrder._id}`);
      setDeleteTargetOrder(null);
      fetchOrders();
    } catch (err) {
      setDeleteError(err.message || 'Failed to delete order.');
    } finally {
      setDeleteLoading(false);
    }
  };

  const updateOrderStatus = async (orderId, newStatus) => {
    try {
      await api.put(`/orders/${orderId}`, { status: newStatus });
      setOrders(prev => prev.map(o => o._id === orderId ? { ...o, status: newStatus } : o));
    } catch (err) {
      console.error('Failed to update status:', err);
    }
  };

  const [searchParams] = useSearchParams();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState(() => {
    const s = searchParams.get('status');
    const valid = ['All', 'Incoming', 'Measuring', 'Cutting', 'Stitching', 'Checking', 'Ready', 'Delivered', 'Cancelled'];
    return valid.includes(s) ? s : 'All';
  });

  const statusList = ['All', 'Incoming', 'Measuring', 'Cutting', 'Stitching', 'Checking', 'Ready', 'Delivered', 'Cancelled'];

  const getStatusBadgeClass = (status) => {
    switch (status) {
      case 'Incoming': return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
      case 'Measuring': return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      case 'Cutting': return 'bg-cyan-500/10 text-cyan-500 border-cyan-500/20';
      case 'Stitching': return 'bg-purple-500/10 text-purple-500 border-purple-500/20';
      case 'Checking': return 'bg-pink-500/10 text-pink-500 border-pink-500/20';
      case 'Ready': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20';
      case 'Delivered': return 'bg-gray-500/10 text-gray-500 border-gray-500/20';
      case 'Cancelled': return 'bg-rose-500/10 text-rose-500 border border-rose-500/20';
      default: return 'bg-bg-hover text-text-muted border border-border-subtle';
    }
  };

  const filteredOrders = orders.filter(o => {
    const matchesSearch = o.orderId.toLowerCase().includes(searchTerm.toLowerCase()) ||
      o.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      o.apparelType.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'All' || o.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="flex flex-col gap-6 select-none text-left">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-text-main tracking-wide">{tf('ordersRegistry', 'Orders Registry')}</h2>
          <p className="text-xs text-text-muted mt-0.5 font-semibold">{tf('ordersRegistrySub', 'List, update, and manage your garment orders')}</p>
        </div>
        <button
          onClick={() => navigate('/new-order')}
          className="btn-tactile flex items-center gap-1.5 self-start sm:self-auto cursor-pointer"
        >
          <MdAdd className="w-5 h-5 text-white-forced" />
          <span className="text-white-forced">{tf('newOrder', 'New Order')}</span>
        </button>
      </div>

      {/* Filters Card */}
      <Card className="flex flex-col md:flex-row md:items-center justify-between gap-4 py-4 px-6">
        {/* Search */}
        <div className="w-full md:w-[320px] relative">
          <input
            type="text"
            placeholder={tf('searchOrders', 'Search orders, customers, apparel...')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-bg-input border border-border-subtle text-xs rounded-xl px-3 py-2.5 pl-9 text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple/50 transition-all text-sm"
          />
          <MdSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-text-muted w-4.5 h-4.5" />
        </div>

        {/* Status Tab Filters */}
        <div className="flex flex-wrap items-center gap-1.5">
          <MdFilterList className="text-text-muted w-4 h-4 mr-1 hidden sm:block" />
          {statusList.map((status) => (
            <button
              key={status}
              onClick={() => setStatusFilter(status)}
              className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-all cursor-pointer
                ${statusFilter === status
                  ? 'bg-color-accent-purple border border-color-accent-purple text-white-forced shadow-md shadow-color-accent-purple/20'
                  : 'filter-tab-inactive hover:text-text-main'}`}
            >
              {tf(status.toLowerCase(), status)}
            </button>
          ))}
        </div>
      </Card>

      {/* Orders Grid/Table Card */}
      <div className="bg-bg-secondary rounded-[20px] border border-border-subtle overflow-hidden shadow-card">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-bg-primary/30 border-b border-border-subtle">
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('orderId', 'Order ID')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('customer', 'Customer')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('apparel', 'Apparel')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('maap', 'Maap/ Meas.')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('lining', 'Lining / Astar')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('karigar', 'Karigar')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('dateCreated', 'Date Created')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('deliveryDate', 'Delivery Date')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('amount', 'Amount')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('productionStatus', 'Production Status')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-center">{tf('actions', 'Actions')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-subtle">
              {loading ? (
                <tr>
                  <td colSpan="11" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('syncing', 'Syncing...')}
                  </td>
                </tr>
              ) : filteredOrders.length === 0 ? (
                <tr>
                  <td colSpan="11" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('ordersEmpty', 'No orders recorded in this shop yet.')}
                  </td>
                </tr>
              ) : (
                filteredOrders.map((order) => (
                  <tr key={order._id} className="hover:bg-bg-hover transition-colors">
                    <td className="px-6 py-4 text-sm font-black">
                      <Link to={`/orders/${order._id}`} className="text-color-accent-purple hover:underline">
                        {order.orderId}
                      </Link>
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-text-main/90">{order.customerName}</td>
                    <td className="px-6 py-4 text-sm font-bold text-text-muted">{order.apparelType ? tf(order.apparelType.toLowerCase(), order.apparelType) : '—'}</td>
                    {/* Measurement type badge */}
                    <td className="px-6 py-4 text-xs font-bold">
                      {order.measurementType === 'Maap' ? (
                        <span style={{ whiteSpace: 'nowrap' }} className="flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-extrabold bg-color-accent-purple/10 text-color-accent-purple border border-color-accent-purple/20">
                          🧵 {tf('maap', 'Maap')}
                        </span>
                      ) : (
                        <span style={{ whiteSpace: 'nowrap' }} className="flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-extrabold bg-[#007aff]/10 text-[#007aff] border border-[#007aff]/20">
                          📏 {tf('maap', 'Measurement')}
                        </span>
                      )}
                    </td>
                    {/* Astar/Lining column */}
                    <td className="px-6 py-4 text-xs font-bold">
                      {order.needsAster ? (
                        <div className="flex flex-col gap-1">
                          <span style={{ whiteSpace: 'nowrap' }} className="px-2 py-0.5 rounded-md text-[10px] font-extrabold bg-color-accent-pink/10 text-color-accent-pink border border-color-accent-pink/20 inline-flex items-center gap-1">
                            {t('yesVal')}
                            {order.asterQuantity > 0
                              ? ` · ${order.asterQuantity} ${order.asterInventoryItem?.unit || ''}`
                              : ''
                            }
                          </span>
                          {order.asterDeducted && (
                            <span style={{ whiteSpace: 'nowrap' }} className="text-[9px] text-color-accent-emerald font-extrabold flex items-center gap-0.5">✓ Stock deducted</span>
                          )}
                        </div>
                      ) : (
                        <span style={{ whiteSpace: 'nowrap' }} className="px-2 py-0.5 rounded-md text-[10px] font-extrabold bg-bg-hover text-text-muted border border-border-subtle">{tf('noVal', 'No')}</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-text-muted">
                      {order.assignedKarigar ? (
                        <Link to={`/karigars/${order.assignedKarigar._id || order.assignedKarigar}`} style={{ whiteSpace: 'nowrap' }} className="text-color-accent-purple hover:underline font-semibold">
                          {order.assignedKarigar.name || order.assignedKarigar}
                        </Link>
                      ) : (
                        <span style={{ whiteSpace: 'nowrap' }} className="opacity-40 font-medium italic">{tf('unassigned', 'Unassigned')}</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-xs font-bold text-text-muted">{formatDate(order.date)}</td>
                    <td className="px-6 py-4 text-xs font-bold text-text-main">{formatDate(order.deliveryDate)}</td>
                    <td className="px-6 py-4 text-sm font-black text-color-accent-emerald">{formatCurrency(order.price)}</td>
                    <td className="px-6 py-4 text-sm font-bold">
                      <select
                        value={order.status}
                        onChange={(e) => updateOrderStatus(order._id, e.target.value)}
                        className={`px-3 py-1 border rounded-lg text-xs font-extrabold outline-none bg-bg-secondary cursor-pointer transition-all ${getStatusBadgeClass(order.status)}`}
                      >
                        {statusList.filter(s => s !== 'All').map(s => (
                          <option key={s} value={s} className="bg-bg-card text-text-main font-bold">{tf('status' + s, s)}</option>
                        ))}
                      </select>
                    </td>
                    <td className="px-6 py-4 text-center">
                      <div className="flex items-center justify-center gap-2">
                        <button
                          onClick={() => navigate(`/orders/${order._id}/edit`)}
                          className="p-1.5 rounded-lg bg-bg-secondary hover:bg-bg-card-hover border border-border-subtle text-text-muted hover:text-text-main transition-all cursor-pointer"
                          title="Edit Details"
                        >
                          <MdEdit className="w-4 h-4 text-color-accent-purple" />
                        </button>
                        <button
                          onClick={() => handleOpenDeleteModal(order)}
                          className="p-1.5 rounded-lg bg-rose-500/10 hover:bg-rose-500/20 text-rose-500 hover:text-rose-600 transition-all cursor-pointer border border-rose-500/10"
                          title="Delete Order"
                        >
                          <MdDelete className="w-4 h-4 text-color-accent-pink" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      {deleteTargetOrder && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative">
            <button
              onClick={() => setDeleteTargetOrder(null)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-2 text-left">
              <MdDelete className="text-color-accent-pink w-5 h-5" />
              {tf('deleteOrder', 'Delete Order')}
            </h3>
            <p className="text-xs text-text-muted mb-4 font-semibold text-left">
              {tf('deleteOrderConfirm', 'Are you sure you want to permanently delete the tailoring order record')} <span className="text-text-main font-bold">{deleteTargetOrder.orderId}</span>?
            </p>

            <div className="bg-bg-secondary border border-border-subtle rounded-xl p-4 flex flex-col gap-1.5 text-left mb-4 text-xs text-text-muted font-semibold">
              <div>{tf('customer', 'Customer')}: <span className="text-text-main font-bold">{deleteTargetOrder.customerName}</span></div>
              <div>{tf('apparel', 'Apparel')}: <span className="text-text-main font-bold">{deleteTargetOrder.apparelType ? tf('apparel' + deleteTargetOrder.apparelType, deleteTargetOrder.apparelType) : '—'}</span></div>
              <div>{tf('amount', 'Amount')}: <span className="text-color-accent-emerald font-bold">{formatCurrency(deleteTargetOrder.price)}</span></div>
            </div>

            {deleteError && (
              <span className="text-xs text-color-accent-pink font-bold text-center block mb-4 animate-pulse">
                {deleteError}
              </span>
            )}

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setDeleteTargetOrder(null)}
                className="flex-1 py-2.5 bg-bg-secondary border border-border-medium text-text-main rounded-xl font-bold text-sm hover:bg-bg-card-hover transition-all cursor-pointer"
              >
                {tf('cancel', 'Cancel')}
              </button>
              <button
                onClick={handleDeleteOrderSubmit}
                disabled={deleteLoading}
                className="flex-1 py-2.5 bg-rose-600 hover:bg-rose-700 text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-rose-950/20 transition-all cursor-pointer disabled:opacity-50"
              >
                {deleteLoading ? tf('saving', 'Saving...') : tf('deleteOrder', 'Delete Order')}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default Orders;
