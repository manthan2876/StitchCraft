/* src/pages/KarigarDetails.jsx */
import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { api } from '../services/api';
import Card from '../components/common/Card';
import {
  MdArrowBack, MdPhone, MdEdit, MdDelete, MdClose,
  MdAssignmentInd, MdAssignmentTurnedIn, MdTimer, MdTrendingUp, MdCheckCircle
} from 'react-icons/md';
import { useLanguage } from '../context/LanguageContext';
import { formatCurrency, formatDate } from '../utils/formatters';

export const KarigarDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { t } = useLanguage();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('Active'); // 'Active' | 'History'

  // Edit Karigar Modal states
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editForm, setEditForm] = useState({ name: '', phone: '', specialization: 'Stitching', status: 'Active' });
  const [editLoading, setEditLoading] = useState(false);
  const [editError, setEditError] = useState('');

  // Delete Karigar Modal states
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [deleteError, setDeleteError] = useState('');

  // Helper with fallbacks for translations
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const fetchKarigarDetails = async () => {
    setLoading(true);
    try {
      const resData = await api.get(`/karigars/${id}`);
      setData(resData);
    } catch (err) {
      console.error('Failed to fetch karigar details:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchKarigarDetails();
  }, [id]);

  const handleOpenEditModal = () => {
    if (!data?.karigar) return;
    setEditForm({
      name: data.karigar.name,
      phone: data.karigar.phone,
      specialization: data.karigar.specialization || 'Stitching',
      status: data.karigar.status || 'Active'
    });
    setEditError('');
    setIsEditModalOpen(true);
  };

  const handleEditSubmit = async (e) => {
    e.preventDefault();
    if (!editForm.name || !editForm.phone) {
      setEditError('Name and phone are required.');
      return;
    }
    setEditLoading(true);
    setEditError('');
    try {
      const updated = await api.put(`/karigars/${id}`, editForm);
      setData(prev => ({ ...prev, karigar: updated }));
      setIsEditModalOpen(false);
    } catch (err) {
      setEditError(err.message || 'Failed to update Karigar profile.');
    } finally {
      setEditLoading(false);
    }
  };

  const handleDeleteKarigar = async () => {
    setDeleteLoading(true);
    setDeleteError('');
    try {
      await api.delete(`/karigars/${id}`);
      navigate('/karigars');
    } catch (err) {
      setDeleteError(err.message || 'Failed to delete Karigar.');
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleOrderStatusChange = async (orderId, newStatus) => {
    try {
      await api.put(`/orders/${orderId}`, { status: newStatus });
      // Re-fetch details to sync stats and orders lists
      fetchKarigarDetails();
    } catch (err) {
      console.error('Failed to update order status:', err);
      alert('Failed to update order status.');
    }
  };

  if (loading) {
    return <div className="w-full py-12 text-center text-sm text-text-muted">{tf('syncing', 'Syncing...')}</div>;
  }

  if (!data || !data.karigar) {
    return (
      <Card className="flex flex-col items-center justify-center py-12 text-center gap-4">
        <h4 className="text-sm font-bold text-text-main">{tf('recordNotFound', 'Record Not Found')}</h4>
        <p className="text-xs text-text-muted font-semibold">{tf('karigarNotFoundDesc', 'Karigar details could not be found.')}</p>
        <button onClick={() => navigate('/karigars')} className="btn-tactile cursor-pointer">
          <span className="text-white-forced">{tf('backToRegistry', 'Back to Registry')}</span>
        </button>
      </Card>
    );
  }

  const { karigar, stats, activeOrders, completedOrders } = data;
  const avatarColors = 'from-indigo-600 to-cyan-500';
  const getInitials = (name = '') =>
    name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();

  const getStatusClass = (status) => {
    return status === 'Active'
      ? 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20'
      : 'bg-gray-500/10 text-gray-500 border border-gray-500/20';
  };

  const getOrderStatusBadgeClass = (status) => {
    switch (status) {
      case 'Incoming': return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
      case 'Measuring': return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      case 'Cutting': return 'bg-cyan-500/10 text-cyan-500 border-cyan-500/20';
      case 'Stitching': return 'bg-purple-500/10 text-purple-500 border-purple-500/20';
      case 'Checking': return 'bg-pink-500/10 text-pink-500 border-pink-500/20';
      case 'Ready': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20';
      case 'Delivered': return 'bg-gray-500/10 text-gray-500 border-gray-500/20';
      default: return 'bg-bg-hover text-text-muted border border-border-subtle';
    }
  };

  const statusList = ['Incoming', 'Measuring', 'Cutting', 'Stitching', 'Checking', 'Ready', 'Delivered'];

  return (
    <div className="flex flex-col gap-6 select-none max-w-5xl mx-auto text-left">
      {/* Header Actions */}
      <div className="flex items-center justify-between">
        <Link to="/karigars" className="flex items-center gap-1.5 text-xs text-text-muted hover:text-text-main font-bold transition-colors">
          <MdArrowBack className="w-4 h-4" />
          <span>{tf('backToKarigars', 'Back to Karigars')}</span>
        </Link>
        <div className="flex items-center gap-2">
          <button
            onClick={handleOpenEditModal}
            className="px-3.5 py-1.5 bg-bg-secondary hover:bg-bg-card-hover text-text-main border border-border-medium hover:border-color-accent-purple/50 font-bold rounded-xl shadow-lg text-xs cursor-pointer flex items-center gap-1 transition-all"
          >
            <MdEdit className="w-3.5 h-3.5 text-color-accent-purple" />
            <span>{tf('editProfile', 'Edit Profile')}</span>
          </button>
          <button
            onClick={() => setIsDeleteModalOpen(true)}
            className="px-3.5 py-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-500 border border-rose-500/20 font-bold rounded-xl shadow-lg text-xs cursor-pointer flex items-center gap-1 transition-all"
          >
            <MdDelete className="w-3.5 h-3.5 text-color-accent-pink" />
            <span>{tf('deleteProfile', 'Delete Profile')}</span>
          </button>
        </div>
      </div>

      {/* Karigar Profile Overview Card */}
      <Card className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div className="flex items-center gap-4">
          <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${avatarColors} flex items-center justify-center font-black text-white-forced text-xl shadow-md shrink-0`}>
            {getInitials(karigar.name)}
          </div>
          <div>
            <h3 className="text-xl font-bold text-text-main tracking-wide">{karigar.name}</h3>
            <div className="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-4 mt-1.5 text-xs text-text-muted">
              <span className="flex items-center gap-1">
                <MdPhone className="w-4 h-4 text-color-accent-purple" /> {karigar.phone}
              </span>
              <span>
                ⚙️ {tf('specialization', 'Specialization')}: <span className="text-text-main font-bold">{tf('spec' + karigar.specialization, karigar.specialization)}</span>
              </span>
            </div>
          </div>
        </div>
        <div>
          <span className={`px-3.5 py-1.5 text-xs font-black rounded-xl uppercase tracking-wider ${getStatusClass(karigar.status)}`}>
            {karigar.status === 'Active' ? tf('active', 'Active') : tf('inactive', 'Inactive')}
          </span>
        </div>
      </Card>

      {/* WORKLOAD PERFORMANCE STATS */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <Card className="p-4 flex flex-col gap-1.5">
          <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('totalJobs', 'Total Jobs')}</span>
          <div className="flex items-baseline gap-1.5">
            <h3 className="text-xl font-black text-text-main">{stats.totalOrders}</h3>
            <MdAssignmentInd className="w-4 h-4 text-color-accent-purple" />
          </div>
        </Card>

        <Card className="p-4 flex flex-col gap-1.5">
          <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('activeJobs', 'Active Jobs')}</span>
          <div className="flex items-baseline gap-1.5">
            <h3 className="text-xl font-black text-text-main">{stats.activeCount}</h3>
            <MdTimer className="w-4 h-4 text-color-accent-blue" />
          </div>
        </Card>

        <Card className="p-4 flex flex-col gap-1.5">
          <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('finishedJobs', 'Finished Jobs')}</span>
          <div className="flex items-baseline gap-1.5">
            <h3 className="text-xl font-black text-text-main">{stats.completedCount}</h3>
            <MdAssignmentTurnedIn className="w-4 h-4 text-color-accent-emerald" />
          </div>
        </Card>

        <Card className="p-4 flex flex-col gap-1.5">
          <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('valueCreated', 'Value Created')}</span>
          <div className="flex items-baseline gap-1.5">
            <h3 className="text-lg font-black text-color-accent-emerald truncate max-w-full">
              {formatCurrency(stats.completedValue)}
            </h3>
            <MdTrendingUp className="w-4 h-4 text-color-accent-emerald" />
          </div>
        </Card>

        <Card className="p-4 flex flex-col gap-1.5 col-span-2 md:col-span-1">
          <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('timelinessRate', 'On-Time Rate')}</span>
          <div className="flex items-center gap-2">
            <h3 className="text-xl font-black text-text-main">{stats.onTimeRate}%</h3>
            <div className="w-full bg-bg-hover h-2 rounded-full overflow-hidden border border-border-subtle">
              <div
                style={{ width: `${stats.onTimeRate}%` }}
                className={`h-full rounded-full ${
                  stats.onTimeRate >= 80 ? 'bg-emerald-500' : stats.onTimeRate >= 50 ? 'bg-amber-500' : 'bg-rose-500'
                }`}
              />
            </div>
          </div>
        </Card>
      </div>

      {/* Navigation tabs for orders */}
      <Card className="flex items-center gap-2 p-3">
        {['Active', 'History'].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 text-xs font-bold rounded-xl border transition-all cursor-pointer
              ${activeTab === tab ? 'delivery-active-tab border-color-accent-purple shadow-md' : 'filter-tab-inactive hover:text-text-main'}`}
          >
            <span>
              {tab === 'Active'
                ? `${tf('activeJobs', 'Active Jobs')} (${activeOrders.length})`
                : `${tf('jobHistory', 'Job History')} (${completedOrders.length})`}
            </span>
          </button>
        ))}
      </Card>

      {/* Orders List Container */}
      <div className="bg-bg-secondary rounded-[20px] border border-border-subtle overflow-hidden shadow-card">
        {activeTab === 'Active' ? (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-bg-primary/30 border-b border-border-subtle">
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('orderId', 'Order ID')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('customer', 'Customer')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('apparel', 'Apparel')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('deliveryDeadline', 'Delivery Deadline')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('price', 'Price')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('productionStatus', 'Production Status')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-center">{tf('actions', 'Actions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-subtle">
                {activeOrders.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="px-6 py-12 text-center text-sm text-text-muted font-bold">
                      🎉 {tf('noActiveJobsDesc', 'All assigned jobs have been completed!')}
                    </td>
                  </tr>
                ) : (
                  activeOrders.map((o) => (
                    <tr key={o._id} className="hover:bg-bg-hover transition-colors">
                      <td className="px-6 py-4 text-sm font-black">
                        <Link to={`/orders/${o._id}`} className="text-color-accent-purple hover:underline">
                          {o.orderId}
                        </Link>
                      </td>
                      <td className="px-6 py-4 text-sm font-bold text-text-main/90">{o.customerName}</td>
                      <td className="px-6 py-4 text-sm text-text-muted">{o.apparelType ? tf('apparel' + o.apparelType, o.apparelType) : '—'}</td>
                      <td className="px-6 py-4 text-xs font-bold text-text-main">{formatDate(o.deliveryDate)}</td>
                      <td className="px-6 py-4 text-sm font-bold text-color-accent-emerald">{formatCurrency(o.price)}</td>
                      <td className="px-6 py-4 text-sm font-bold">
                        <select
                          value={o.status}
                          onChange={(e) => handleOrderStatusChange(o._id, e.target.value)}
                          className={`px-3 py-1 border rounded-lg text-xs font-extrabold outline-none bg-bg-secondary cursor-pointer transition-all ${getOrderStatusBadgeClass(o.status)}`}
                        >
                          {statusList.map(s => (
                            <option key={s} value={s} className="bg-bg-card text-text-main font-bold">{tf('status' + s, s)}</option>
                          ))}
                        </select>
                      </td>
                      <td className="px-6 py-4 text-center">
                        <Link
                          to={`/orders/${o._id}`}
                          className="px-3 py-1.5 bg-bg-secondary hover:bg-bg-card-hover border border-border-subtle rounded-xl text-[10px] font-bold text-text-main transition-all"
                        >
                          {tf('viewDetails', 'View Details')}
                        </Link>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-bg-primary/30 border-b border-border-subtle">
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('orderId', 'Order ID')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('customer', 'Customer')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('apparel', 'Apparel')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('deliveryDate', 'Delivery Date')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('price', 'Price')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('status', 'Status')}</th>
                  <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-center">{tf('actions', 'Actions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-subtle">
                {completedOrders.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="px-6 py-12 text-center text-sm text-text-muted font-bold">
                      {tf('noHistoryDesc', 'No completed orders in history logs.')}
                    </td>
                  </tr>
                ) : (
                  completedOrders.map((o) => (
                    <tr key={o._id} className="hover:bg-bg-hover transition-colors">
                      <td className="px-6 py-4 text-sm font-black">
                        <Link to={`/orders/${o._id}`} className="text-color-accent-purple hover:underline">
                          {o.orderId}
                        </Link>
                      </td>
                      <td className="px-6 py-4 text-sm font-bold text-text-main/90">{o.customerName}</td>
                      <td className="px-6 py-4 text-sm text-text-muted">{o.apparelType ? tf('apparel' + o.apparelType, o.apparelType) : '—'}</td>
                      <td className="px-6 py-4 text-xs font-bold text-text-muted">{formatDate(o.deliveryDate)}</td>
                      <td className="px-6 py-4 text-sm font-bold text-color-accent-emerald">{formatCurrency(o.price)}</td>
                      <td className="px-6 py-4 text-xs font-bold">
                        <span className="flex items-center gap-1 px-2.5 py-0.5 rounded-md text-[10px] font-extrabold bg-emerald-500/10 text-emerald-500 border border-emerald-500/20 w-max">
                          <MdCheckCircle className="w-3.5 h-3.5" /> {tf('status' + o.status, o.status)}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-center">
                        <Link
                          to={`/orders/${o._id}`}
                          className="px-3 py-1.5 bg-bg-secondary hover:bg-bg-card-hover border border-border-subtle rounded-xl text-[10px] font-bold text-text-main transition-all"
                        >
                          {tf('viewDetails', 'View Details')}
                        </Link>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Edit Karigar Dialog Modal */}
      {isEditModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[440px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={() => setIsEditModalOpen(false)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-1">
              <MdAssignmentInd className="text-color-accent-purple w-5 h-5" />
              {tf('editKarigarDetails', 'Edit Karigar Details')}
            </h3>
            <p className="text-xs text-text-muted mb-5 font-semibold">
              {tf('editKarigarDetailsDesc', 'Modify contact info and skills specialization')}
            </p>

            <form onSubmit={handleEditSubmit} className="flex flex-col gap-4">
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('artisanName', 'Artisan Name')}</label>
                <input
                  type="text"
                  required
                  value={editForm.name}
                  onChange={e => { setEditForm({ ...editForm, name: e.target.value }); setEditError(''); }}
                  placeholder="e.g. Suresh Kumar"
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('phoneNumber', 'Phone Number')}</label>
                <input
                  type="tel"
                  required
                  value={editForm.phone}
                  onChange={e => { setEditForm({ ...editForm, phone: e.target.value }); setEditError(''); }}
                  placeholder="e.g. 9876543210"
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1">
                  <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('specialization', 'Specialization')}</label>
                  <select
                    value={editForm.specialization}
                    onChange={e => setEditForm({ ...editForm, specialization: e.target.value })}
                    className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all cursor-pointer font-bold"
                  >
                    <option value="Stitching" className="bg-bg-card">{tf('specStitching', 'Stitching')}</option>
                    <option value="Cutting" className="bg-bg-card">{tf('specCutting', 'Cutting')}</option>
                    <option value="Embroidery" className="bg-bg-card">{tf('specEmbroidery', 'Embroidery')}</option>
                    <option value="Measurements" className="bg-bg-card">{tf('specMeasurements', 'Measurements')}</option>
                    <option value="General" className="bg-bg-card">{tf('specGeneral', 'General')}</option>
                  </select>
                </div>

                <div className="flex flex-col gap-1">
                  <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('activityStatus', 'Activity Status')}</label>
                  <select
                    value={editForm.status}
                    onChange={e => setEditForm({ ...editForm, status: e.target.value })}
                    className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all cursor-pointer font-bold"
                  >
                    <option value="Active" className="bg-bg-card text-emerald-500 font-extrabold">{tf('active', 'Active')}</option>
                    <option value="Inactive" className="bg-bg-card text-text-muted font-extrabold">{tf('inactive', 'Inactive')}</option>
                  </select>
                </div>
              </div>

              {editError && (
                <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse">
                  {editError}
                </span>
              )}

              <div className="flex gap-3 mt-2">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="flex-1 py-2.5 bg-bg-secondary border border-border-medium text-text-main rounded-xl font-bold text-sm hover:bg-bg-card-hover transition-all cursor-pointer"
                >
                  {tf('cancel', 'Cancel')}
                </button>
                <button
                  type="submit"
                  disabled={editLoading}
                  className="flex-1 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50"
                >
                  {editLoading ? tf('saving', 'Saving...') : tf('save', 'Save')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {isDeleteModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={() => setIsDeleteModalOpen(false)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-2">
              <MdDelete className="text-color-accent-pink w-5 h-5" />
              {tf('deleteKarigar', 'Delete Karigar')}
            </h3>
            <p className="text-xs text-text-muted mb-4 font-semibold">
              {tf('deleteKarigarConfirm', 'Are you sure you want to permanently delete the profile for')} <span className="text-text-main font-bold">{karigar.name}</span>?
            </p>

            {deleteError && (
              <span className="text-xs text-color-accent-pink font-bold text-center block mb-4 animate-pulse">
                {deleteError}
              </span>
            )}

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setIsDeleteModalOpen(false)}
                className="flex-1 py-2.5 bg-bg-secondary border border-border-medium text-text-main rounded-xl font-bold text-sm hover:bg-bg-card-hover transition-all cursor-pointer"
              >
                {tf('cancel', 'Cancel')}
              </button>
              <button
                onClick={handleDeleteKarigar}
                disabled={deleteLoading}
                className="flex-1 py-2.5 bg-rose-600 hover:bg-rose-700 text-white-forced rounded-xl font-bold text-sm shadow-lg transition-all cursor-pointer disabled:opacity-50"
              >
                {deleteLoading ? tf('saving', 'Saving...') : tf('deleteKarigar', 'Delete Karigar')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default KarigarDetails;
