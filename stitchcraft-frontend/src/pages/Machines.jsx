/* src/pages/Machines.jsx */
import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import { useLanguage } from '../context/LanguageContext';
import Card from '../components/common/Card';
import { MdSearch, MdClose, MdAdd, MdEdit, MdDelete } from 'react-icons/md';
import { GiSewingMachine } from 'react-icons/gi';

export const Machines = () => {
  const { t } = useLanguage();
  const [machines, setMachines] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  // Add/Edit Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState('add'); // 'add' | 'edit'
  const [selectedMachine, setSelectedMachine] = useState(null);
  const [form, setForm] = useState({ name: '', type: 'Sewing', status: 'Working', notes: '' });
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

  const fetchMachines = async (search = '') => {
    setLoading(true);
    try {
      const data = await api.get(`/machines?search=${encodeURIComponent(search)}`);
      setMachines(data);
    } catch (err) {
      console.error('Failed to fetch machines:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMachines(searchTerm);
  }, [searchTerm]);

  const handleOpenAddModal = () => {
    setForm({ name: '', type: 'Sewing', status: 'Working', notes: '' });
    setModalMode('add');
    setSelectedMachine(null);
    setFormError('');
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (machine) => {
    setForm({
      name: machine.name,
      type: machine.type || 'Sewing',
      status: machine.status || 'Working',
      notes: machine.notes || ''
    });
    setModalMode('edit');
    setSelectedMachine(machine);
    setFormError('');
    setIsModalOpen(true);
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    if (!form.name || !form.type) {
      setFormError('Machine name/number and type are required.');
      return;
    }
    setFormLoading(true);
    setFormError('');
    try {
      const payload = {
        name: form.name,
        type: form.type,
        status: form.status,
        notes: form.notes
      };

      if (modalMode === 'add') {
        const data = await api.post('/machines', payload);
        setMachines(prev => [data, ...prev]);
      } else {
        const data = await api.put(`/machines/${selectedMachine._id}`, payload);
        setMachines(prev => prev.map(m => m._id === data._id ? data : m));
      }
      setIsModalOpen(false);
    } catch (err) {
      setFormError(err.message || 'Failed to save machine details.');
    } finally {
      setFormLoading(false);
    }
  };

  const handleDeleteSubmit = async () => {
    if (!deleteTarget) return;
    setDeleteLoading(true);
    setDeleteError('');
    try {
      await api.delete(`/machines/${deleteTarget._id}`);
      setMachines(prev => prev.filter(m => m._id !== deleteTarget._id));
      setDeleteTarget(null);
    } catch (err) {
      setDeleteError(err.message || 'Failed to delete machine.');
    } finally {
      setDeleteLoading(false);
    }
  };

  const getStatusClass = (status) => {
    switch (status) {
      case 'Working':
        return 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20';
      case 'Maintenance':
        return 'bg-amber-500/10 text-amber-500 border border-amber-500/20';
      case 'Broken':
        return 'bg-rose-500/10 text-rose-500 border border-rose-500/20';
      default:
        return 'bg-bg-hover text-text-muted border border-border-subtle';
    }
  };

  return (
    <div className="flex flex-col gap-6 select-none text-left">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-text-main tracking-wide">{tf('machineRegistry', 'Machine Registry')}</h2>
          <p className="text-xs text-text-muted mt-0.5 font-semibold">
            {tf('machineSub', 'Track sewing and laundry machinery assets, maintenance logs, and operating status')}
          </p>
        </div>
        <button
          onClick={handleOpenAddModal}
          className="btn-tactile flex items-center gap-2 self-start sm:self-auto cursor-pointer"
        >
          <GiSewingMachine className="w-5 h-5 text-white-forced animate-pulse" />
          <span className="text-white-forced">{tf('registerMachine', 'Register Machine')}</span>
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

      {/* Machines Registry List */}
      {loading ? (
        <div className="text-center py-16 text-sm text-text-muted">{tf('syncing', 'Syncing...')}</div>
      ) : machines.length === 0 ? (
        <Card className="flex flex-col items-center justify-center py-16 text-center gap-4">
          <div className="w-14 h-14 rounded-full bg-bg-hover flex items-center justify-center text-text-muted">
            <GiSewingMachine className="w-7 h-7" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-text-main">{tf('noRecords', 'No machinery records registered yet.')}</h4>
          </div>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
          {machines.map((machine) => (
            <Card key={machine._id} className="flex flex-col gap-4 text-left relative overflow-hidden group hover:border-color-accent-purple/40 hover:shadow-lg hover:shadow-color-accent-purple/5 transition-all">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-bg-hover flex items-center justify-center text-color-accent-purple group-hover:bg-color-accent-purple/10 group-hover:text-color-accent-purple transition-all">
                    <GiSewingMachine className="w-6 h-6" />
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-text-main group-hover:text-color-accent-purple transition-colors truncate max-w-[140px]">{machine.name}</h4>
                    <span className="text-[10px] font-black text-text-muted uppercase tracking-wider">{tf('machine' + machine.type, machine.type)}</span>
                  </div>
                </div>

                <span style={{ whiteSpace: 'nowrap' }} className={`px-2 py-0.5 rounded-md text-[9px] font-black uppercase tracking-wider ${getStatusClass(machine.status)}`}>
                  {machine.status === 'Working' ? tf('working', 'Working') : machine.status === 'Maintenance' ? tf('maintenance', 'Maintenance') : machine.status === 'Broken' ? tf('broken', 'Broken') : machine.status}
                </span>
              </div>

              {machine.notes && (
                <div className="bg-bg-primary/50 border border-border-subtle rounded-xl p-3 text-xs text-text-muted font-medium">
                  📝 {machine.notes}
                </div>
              )}

              <div className="flex items-center gap-2 border-t border-border-subtle pt-3 mt-auto">
                <button
                  onClick={() => handleOpenEditModal(machine)}
                  className="flex-1 py-1.5 bg-bg-card hover:bg-bg-card-hover border border-border-subtle rounded-xl text-[10px] font-bold text-text-main cursor-pointer hover:border-color-accent-purple/40 transition-all flex items-center justify-center gap-1"
                >
                  <MdEdit className="w-3.5 h-3.5 text-color-accent-purple" />
                  <span>{tf('edit', 'Edit')}</span>
                </button>
                <button
                  onClick={() => { setDeleteTarget(machine); setDeleteError(''); }}
                  className="px-2.5 py-1.5 bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/10 rounded-xl text-[10px] font-bold text-rose-500 cursor-pointer transition-all flex items-center justify-center"
                  title="Remove Machine"
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
              <GiSewingMachine className="text-color-accent-purple w-5 h-5 animate-pulse" />
              {modalMode === 'add' ? tf('registerMachine', 'Register Machine') : tf('editMachineDetails', 'Edit Machine Details')}
            </h3>
            <p className="text-xs text-text-muted mb-5 font-semibold">
              {modalMode === 'add' ? tf('registerMachineDesc', 'Create an operating profile entry for a workshop sewing machine') : tf('editMachineDetailsDesc', 'Update maintenance parameters and status details')}
            </p>

            <form onSubmit={handleFormSubmit} className="flex flex-col gap-4">
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('machineNameNum', 'Machine Name / Number')}</label>
                <input
                  type="text"
                  required
                  value={form.name}
                  onChange={e => { setForm({ ...form, name: e.target.value }); setFormError(''); }}
                  placeholder="e.g. Sewing Machine #A3 or Juki Overlock"
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1">
                  <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('machineType', 'Machine Type')}</label>
                  <select
                    value={form.type}
                    onChange={e => setForm({ ...form, type: e.target.value })}
                    className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all cursor-pointer font-bold"
                  >
                    <option value="Sewing" className="bg-bg-card">{tf('sewing', 'Sewing')}</option>
                    <option value="Overlock" className="bg-bg-card">{tf('overlock', 'Overlock')}</option>
                    <option value="Embroidery" className="bg-bg-card">{tf('embroidery', 'Embroidery')}</option>
                    <option value="Buttonhole" className="bg-bg-card">{tf('buttonhole', 'Buttonhole')}</option>
                    <option value="Ironing" className="bg-bg-card">{tf('ironing', 'Ironing')}</option>
                  </select>
                </div>

                <div className="flex flex-col gap-1">
                  <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('operatingStatus', 'Operating Status')}</label>
                  <select
                    value={form.status}
                    onChange={e => setForm({ ...form, status: e.target.value })}
                    className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all cursor-pointer font-bold"
                  >
                    <option value="Working" className="bg-bg-card text-emerald-500 font-extrabold">{tf('working', 'Working')}</option>
                    <option value="Maintenance" className="bg-bg-card text-amber-500 font-extrabold">{tf('maintenance', 'Maintenance')}</option>
                    <option value="Broken" className="bg-bg-card text-rose-500 font-extrabold">{tf('broken', 'Broken')}</option>
                  </select>
                </div>
              </div>

              <div className="flex flex-col gap-1 text-left">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('maintenanceNotes', 'Maintenance Notes')}</label>
                <textarea
                  value={form.notes}
                  onChange={e => setForm({ ...form, notes: e.target.value })}
                  placeholder="e.g. Needle bar replacement due on next service, skipping stitches sometimes"
                  rows="3"
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all resize-none placeholder:text-text-muted/50"
                />
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
              {tf('deleteMachine', 'Delete Machine')}
            </h3>
            <p className="text-xs text-text-muted mb-4 font-semibold">
              {tf('deleteMachineConfirm', 'Are you sure you want to permanently delete the profile entry for')} <span className="text-text-main font-bold">{deleteTarget.name}</span>?
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
                {deleteLoading ? tf('saving', 'Saving...') : tf('deleteMachine', 'Delete Machine')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Machines;
