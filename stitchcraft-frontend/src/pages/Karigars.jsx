/* src/pages/Karigars.jsx */
import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../services/api';
import { useLanguage } from '../context/LanguageContext';
import Card from '../components/common/Card';
import { MdSearch, MdClose, MdAdd, MdEdit, MdDelete, MdAssignmentInd } from 'react-icons/md';

export const Karigars = () => {
  const { t } = useLanguage();
  const [karigars, setKarigars] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  // Add/Edit Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState('add'); // 'add' | 'edit'
  const [selectedKarigar, setSelectedKarigar] = useState(null);
  const [form, setForm] = useState({ name: '', phone: '', specialization: 'Stitching', status: 'Active' });
  const [formError, setFormError] = useState('');
  const [formLoading, setFormLoading] = useState(false);

  // Delete Modal states
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [deleteError, setDeleteError] = useState('');

  // Helper with fallbacks for translations
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const fetchKarigars = async (search = '') => {
    setLoading(true);
    try {
      const data = await api.get(`/karigars?search=${encodeURIComponent(search)}`);
      setKarigars(data);
    } catch (err) {
      console.error('Failed to fetch karigars:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchKarigars(searchTerm);
  }, [searchTerm]);

  const handleOpenAddModal = () => {
    setForm({ name: '', phone: '', specialization: 'Stitching', status: 'Active' });
    setModalMode('add');
    setSelectedKarigar(null);
    setFormError('');
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (karigar) => {
    setForm({
      name: karigar.name,
      phone: karigar.phone,
      specialization: karigar.specialization || 'Stitching',
      status: karigar.status || 'Active'
    });
    setModalMode('edit');
    setSelectedKarigar(karigar);
    setFormError('');
    setIsModalOpen(true);
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    if (!form.name || !form.phone) {
      setFormError('Karigar name and phone number are required.');
      return;
    }
    setFormLoading(true);
    setFormError('');
    try {
      const payload = {
        name: form.name,
        phone: form.phone,
        specialization: form.specialization,
        status: form.status
      };

      if (modalMode === 'add') {
        const data = await api.post('/karigars', payload);
        setKarigars(prev => [data, ...prev]);
      } else {
        const data = await api.put(`/karigars/${selectedKarigar._id}`, payload);
        setKarigars(prev => prev.map(k => k._id === data._id ? data : k));
      }
      setIsModalOpen(false);
    } catch (err) {
      setFormError(err.message || 'Failed to save karigar details.');
    } finally {
      setFormLoading(false);
    }
  };

  const handleDeleteSubmit = async () => {
    if (!deleteTarget) return;
    setDeleteLoading(true);
    setDeleteError('');
    try {
      await api.delete(`/karigars/${deleteTarget._id}`);
      setKarigars(prev => prev.filter(k => k._id !== deleteTarget._id));
      setDeleteTarget(null);
    } catch (err) {
      setDeleteError(err.message || 'Failed to delete karigar.');
    } finally {
      setDeleteLoading(false);
    }
  };

  const getInitials = (name = '') =>
    name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();

  const getStatusClass = (status) => {
    return status === 'Active'
      ? 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20'
      : 'bg-gray-500/10 text-gray-500 border border-gray-500/20';
  };

  const avatarColors = [
    'from-indigo-600 to-cyan-500',
    'from-purple-600 to-pink-500',
    'from-emerald-600 to-teal-500',
    'from-amber-600 to-orange-500',
  ];

  return (
    <div className="flex flex-col gap-6 select-none text-left">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-text-main tracking-wide">{tf('karigarRegistry', 'Karigar Registry')}</h2>
          <p className="text-xs text-text-muted mt-0.5 font-semibold">
            {tf('karigarSub', 'List, add, and update specialized tailoring karigars and active work status')}
          </p>
        </div>
        <button
          onClick={handleOpenAddModal}
          className="btn-tactile flex items-center gap-2 self-start sm:self-auto cursor-pointer"
        >
          <MdAssignmentInd className="w-5 h-5 text-white-forced" />
          <span className="text-white-forced">{tf('registerKarigar', 'Register Karigar')}</span>
        </button>
      </div>

      {/* Search Bar */}
      <Card className="py-3 px-4">
        <div className="relative">
          <MdSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted w-5 h-5" />
          <input
            type="text"
            placeholder={tf('searchPlaceholder', 'Search...')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-bg-input border border-border-subtle rounded-xl text-sm text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple/50 transition-all"
          />
          {searchTerm && (
            <button
              onClick={() => setSearchTerm('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-4 h-4" />
            </button>
          )}
        </div>
      </Card>

      {/* Karigars Grid */}
      {loading ? (
        <div className="text-center py-16 text-sm text-text-muted">{tf('syncing', 'Syncing...')}</div>
      ) : karigars.length === 0 ? (
        <Card className="flex flex-col items-center justify-center py-16 text-center gap-4">
          <div className="w-14 h-14 rounded-full bg-bg-hover flex items-center justify-center text-text-muted">
            <MdAssignmentInd className="w-7 h-7" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-text-main">{tf('noRecords', 'No artisan records found.')}</h4>
          </div>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
          {karigars.map((karigar, idx) => (
            <Card key={karigar._id} className="flex flex-col gap-4 text-left relative overflow-hidden group hover:border-color-accent-purple/40 hover:shadow-lg hover:shadow-color-accent-purple/5 transition-all">
              {/* Profile Image Initials & Status */}
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-11 h-11 rounded-xl bg-gradient-to-br ${avatarColors[idx % avatarColors.length]} flex items-center justify-center font-black text-white-forced text-sm shadow-md shrink-0`}>
                    {getInitials(karigar.name)}
                  </div>
                  <div>
                    <Link to={`/karigars/${karigar._id}`}>
                      <h4 className="text-sm font-bold text-text-main group-hover:text-color-accent-purple transition-colors truncate max-w-[140px] hover:underline cursor-pointer">{karigar.name}</h4>
                    </Link>
                    <span className="text-[10px] font-black text-text-muted uppercase tracking-wider">{tf('spec' + karigar.specialization, karigar.specialization)}</span>
                  </div>
                </div>

                <span style={{ whiteSpace: 'nowrap' }} className={`px-2 py-0.5 rounded-md text-[9px] font-black uppercase tracking-wider ${getStatusClass(karigar.status)}`}>
                  {karigar.status === 'Active' ? tf('active', 'Active') : tf('inactive', 'Inactive')}
                </span>
              </div>

              {/* Contact Information */}
              <div className="flex flex-col gap-1 text-xs text-text-muted border-t border-border-subtle pt-3">
                <span>📞 {karigar.phone}</span>
                <span>⚙️ {tf('specialization', 'Specialization')}: {tf('spec' + karigar.specialization, karigar.specialization)}</span>
              </div>

              {/* Action buttons */}
              <div className="flex items-center gap-2 border-t border-border-subtle pt-3 mt-auto">
                <button
                  onClick={() => handleOpenEditModal(karigar)}
                  className="flex-1 py-1.5 bg-bg-card hover:bg-bg-card-hover border border-border-subtle rounded-xl text-[10px] font-bold text-text-main cursor-pointer hover:border-color-accent-purple/40 transition-all flex items-center justify-center gap-1"
                >
                  <MdEdit className="w-3.5 h-3.5 text-color-accent-purple" />
                  <span>{tf('edit', 'Edit')}</span>
                </button>
                <button
                  onClick={() => { setDeleteTarget(karigar); setDeleteError(''); }}
                  className="px-2.5 py-1.5 bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/10 rounded-xl text-[10px] font-bold text-rose-500 cursor-pointer transition-all flex items-center justify-center"
                  title="Remove Karigar"
                >
                  <MdDelete className="w-3.5 h-3.5 text-color-accent-pink" />
                </button>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Add/Edit Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[440px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={() => setIsModalOpen(false)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-1">
              <MdAssignmentInd className="text-color-accent-purple w-5 h-5" />
              {modalMode === 'add' ? tf('registerKarigar', 'Register Karigar') : tf('editKarigarDetails', 'Edit Karigar Details')}
            </h3>
            <p className="text-xs text-text-muted mb-5 font-semibold">
              {modalMode === 'add' ? tf('registerKarigarDesc', 'Create a profile for a new tailor workshop artisan') : tf('editKarigarDetailsDesc', 'Modify contact info and skills specialization')}
            </p>

            <form onSubmit={handleFormSubmit} className="flex flex-col gap-4">
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('artisanName', 'Artisan Name')}</label>
                <input
                  type="text"
                  required
                  value={form.name}
                  onChange={e => { setForm({ ...form, name: e.target.value }); setFormError(''); }}
                  placeholder="e.g. Suresh Kumar"
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('phoneNumber', 'Phone Number')}</label>
                <input
                  type="tel"
                  required
                  value={form.phone}
                  onChange={e => { setForm({ ...form, phone: e.target.value }); setFormError(''); }}
                  placeholder="e.g. 9876543210"
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1">
                  <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('specialization', 'Specialization')}</label>
                  <select
                    value={form.specialization}
                    onChange={e => setForm({ ...form, specialization: e.target.value })}
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
                    value={form.status}
                    onChange={e => setForm({ ...form, status: e.target.value })}
                    className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all cursor-pointer font-bold"
                  >
                    <option value="Active" className="bg-bg-card text-emerald-500 font-extrabold">{tf('active', 'Active')}</option>
                    <option value="Inactive" className="bg-bg-card text-text-muted font-extrabold">{tf('inactive', 'Inactive')}</option>
                  </select>
                </div>
              </div>

              {formError && (
                <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse">
                  {formError}
                </span>
              )}

              <div className="flex gap-3 mt-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="flex-1 py-2.5 btn-tactile-dark font-bold text-sm transition-all cursor-pointer"
                >
                  {tf('cancel', 'Cancel')}
                </button>
                <button
                  type="submit"
                  disabled={formLoading}
                  className="flex-1 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50"
                >
                  {formLoading ? tf('saving', 'Saving...') : tf('save', 'Save')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {deleteTarget && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={() => setDeleteTarget(null)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-2">
              <MdDelete className="text-color-accent-pink w-5 h-5" />
              {tf('deleteKarigar', 'Delete Karigar')}
            </h3>
            <p className="text-xs text-text-muted mb-4 font-semibold">
              {tf('deleteKarigarConfirm', 'Are you sure you want to permanently delete the profile for')} <span className="text-text-main font-bold">{deleteTarget.name}</span>?
            </p>

            {deleteError && (
              <span className="text-xs text-color-accent-pink font-bold text-center block mb-4 animate-pulse">
                {deleteError}
              </span>
            )}

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setDeleteTarget(null)}
                className="flex-1 py-2.5 btn-tactile-dark font-bold text-sm transition-all cursor-pointer"
              >
                {tf('cancel', 'Cancel')}
              </button>
              <button
                onClick={handleDeleteSubmit}
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

export default Karigars;
