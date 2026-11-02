/* src/pages/StaffManagement.jsx */
import React, { useState, useEffect } from 'react';
import Card from '../components/common/Card';
import { useAuth } from '../hooks/useAuth';
import { useLanguage } from '../context/LanguageContext';
import { api } from '../services/api';
import {
  MdSupervisorAccount,
  MdAdd,
  MdSearch,
  MdClose,
  MdCheckCircle,
  MdBlock,
  MdDeleteOutline,
  MdAdminPanelSettings,
  MdWork,
  MdEngineering,
  MdBadge,
} from 'react-icons/md';

export const StaffManagement = () => {
  const { user } = useAuth();
  const { t } = useLanguage();

  const [staffList, setStaffList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState('ALL');

  // Modal State
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [modalLoading, setModalLoading] = useState(false);
  const [modalError, setModalError] = useState('');
  const [newStaff, setNewStaff] = useState({
    name: '',
    email: '',
    phone: '',
    role: 'staff',
  });

  const isOwner = user?.role === 'owner';
  const isManagerOrOwner = user?.role === 'owner' || user?.role === 'manager';

  const fetchStaff = async () => {
    setLoading(true);
    try {
      const data = await api.get('/staff');
      setStaffList(data || []);
    } catch (err) {
      console.error('Failed to load staff members:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStaff();
  }, []);

  const handleAddStaffSubmit = async (e) => {
    e.preventDefault();
    setModalError('');
    setModalLoading(true);

    try {
      await api.post('/staff', newStaff);
      setIsAddModalOpen(false);
      setNewStaff({ name: '', email: '', phone: '', role: 'staff' });
      await fetchStaff();
    } catch (err) {
      setModalError(err.message || 'Failed to add staff member');
    } finally {
      setModalLoading(false);
    }
  };

  const handleRoleChange = async (staffId, newRole) => {
    try {
      await api.put(`/staff/${staffId}/role`, { role: newRole });
      setStaffList(prev => prev.map(m => m._id === staffId ? { ...m, role: newRole } : m));
    } catch (err) {
      alert(err.message || 'Failed to update role');
    }
  };

  const handleToggleStatus = async (staffId, currentStatus) => {
    try {
      await api.put(`/staff/${staffId}/status`, { isActive: !currentStatus });
      setStaffList(prev => prev.map(m => m._id === staffId ? { ...m, isActive: !currentStatus } : m));
    } catch (err) {
      alert(err.message || 'Failed to update status');
    }
  };

  const handleRemoveStaff = async (staffId, name) => {
    const confirmMsg = (t('confirmRemoveStaff') || 'Are you sure you want to remove {name} from this shop?').replace('{name}', name);
    if (!window.confirm(confirmMsg)) {
      return;
    }

    try {
      await api.delete(`/staff/${staffId}`);
      setStaffList(prev => prev.filter(m => m._id !== staffId));
    } catch (err) {
      alert(err.message || 'Failed to remove staff member');
    }
  };

  const filteredStaff = staffList.filter(member => {
    const matchesSearch =
      (member.name || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (member.email || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (member.phone || '').toLowerCase().includes(searchQuery.toLowerCase());

    const matchesRole = roleFilter === 'ALL' || member.role === roleFilter;

    return matchesSearch && matchesRole;
  });

  const getRoleBadge = (role) => {
    switch (role) {
      case 'owner':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-black uppercase tracking-wider bg-amber-500/15 text-amber-600 border border-amber-500/20">
            <MdAdminPanelSettings className="w-3.5 h-3.5" /> {t('roleOwner')}
          </span>
        );
      case 'manager':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-black uppercase tracking-wider bg-color-accent-purple/15 text-color-accent-purple border border-color-accent-purple/20">
            <MdWork className="w-3.5 h-3.5" /> {t('roleManager')}
          </span>
        );
      case 'karigar':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-black uppercase tracking-wider bg-emerald-500/15 text-emerald-600 border border-emerald-500/20">
            <MdEngineering className="w-3.5 h-3.5" /> {t('roleKarigar')}
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-black uppercase tracking-wider bg-sky-500/15 text-sky-600 border border-sky-500/20">
            <MdBadge className="w-3.5 h-3.5" /> {t('roleStaff')}
          </span>
        );
    }
  };

  const getRoleFilterLabel = (r) => {
    if (r === 'ALL') return t('all');
    if (r === 'owner') return t('roleOwner');
    if (r === 'manager') return t('roleManager');
    if (r === 'karigar') return t('roleKarigar');
    if (r === 'staff') return t('roleStaff');
    return r;
  };

  return (
    <div className="flex flex-col gap-6 text-left select-none pb-12">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-main flex items-center gap-2">
            <MdSupervisorAccount className="text-color-accent-purple w-7 h-7" />
            {t('staffManagement')}
          </h1>
          <p className="text-xs text-text-muted mt-1 font-semibold">
            {t('staffManagementSub')}
          </p>
        </div>

        {isManagerOrOwner && (
          <button
            onClick={() => {
              setNewStaff({ name: '', email: '', phone: '', role: 'staff' });
              setModalError('');
              setIsAddModalOpen(true);
            }}
            className="flex items-center gap-1.5 px-4 py-2.5 bg-color-accent-purple hover:bg-color-accent-purple-hover text-white-forced font-bold rounded-xl text-xs shadow-lg shadow-color-accent-purple/20 transition-all cursor-pointer"
          >
            <MdAdd className="w-4 h-4 text-white-forced" />
            <span>{t('addTeamMember')}</span>
          </button>
        )}
      </div>

      {/* Filter / Search Bar */}
      <Card className="flex flex-col sm:flex-row gap-4 justify-between items-center p-4">
        <div className="relative w-full sm:w-72">
          <MdSearch className="absolute left-3.5 top-1/2 -translate-y-1/2 text-text-muted w-4 h-4" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={t('searchStaffPlaceholder')}
            className="w-full pl-9 pr-4 py-2 bg-bg-input border border-border-subtle rounded-xl text-xs text-text-main outline-none focus:border-color-accent-purple transition-all placeholder:text-text-muted/50"
          />
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto overflow-x-auto">
          {['ALL', 'owner', 'manager', 'karigar', 'staff'].map((role) => (
            <button
              key={role}
              onClick={() => setRoleFilter(role)}
              className={`px-3 py-1.5 rounded-xl text-[10px] font-black uppercase tracking-wider transition-all cursor-pointer border
                ${roleFilter === role
                  ? 'bg-color-accent-purple text-white-forced border-color-accent-purple shadow-sm'
                  : 'bg-bg-secondary text-text-muted border-border-subtle hover:bg-bg-hover hover:text-text-main'}`}
            >
              {getRoleFilterLabel(role)}
            </button>
          ))}
        </div>
      </Card>

      {/* Staff Table */}
      <Card className="p-0 overflow-hidden border border-border-subtle">
        {loading ? (
          <div className="py-16 text-center text-xs text-text-muted font-bold flex flex-col items-center justify-center gap-3">
            <div className="w-8 h-8 rounded-full border-3 border-color-accent-purple border-t-transparent animate-spin"></div>
            <span>{t('loadingTeamMembers')}</span>
          </div>
        ) : filteredStaff.length === 0 ? (
          <div className="py-16 text-center text-xs text-text-muted font-semibold">
            {t('noStaffFound')}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-left text-xs">
              <thead>
                <tr className="bg-bg-secondary border-b border-border-subtle text-[10px] font-extrabold text-text-muted uppercase tracking-wider">
                  <th className="px-5 py-3.5">{t('member')}</th>
                  <th className="px-5 py-3.5">{t('contact')}</th>
                  <th className="px-5 py-3.5">{t('role')}</th>
                  <th className="px-5 py-3.5">{t('status')}</th>
                  {isManagerOrOwner && <th className="px-5 py-3.5 text-right">{t('actions')}</th>}
                </tr>
              </thead>
              <tbody className="divide-y divide-border-subtle font-medium text-text-main">
                {filteredStaff.map((member) => {
                  const isCurrentLoggedUser = String(member._id) === String(user?._id);
                  const isOwnerMember = member.role === 'owner';

                  return (
                    <tr key={member._id} className="hover:bg-bg-hover/50 transition-colors">
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-xl bg-color-accent-purple/15 text-color-accent-purple font-black flex items-center justify-center uppercase text-sm border border-color-accent-purple/20">
                            {(member.name || 'U')[0]}
                          </div>
                          <div>
                            <span className="font-bold text-text-main block">
                              {member.name}
                              {isCurrentLoggedUser && (
                                <span className="ml-1.5 text-[9px] font-extrabold text-color-accent-purple uppercase tracking-wider bg-color-accent-purple/10 px-1.5 py-0.5 rounded">
                                  {t('you')}
                                </span>
                              )}
                            </span>
                            <span className="text-[10px] text-text-muted font-mono">{member.email}</span>
                          </div>
                        </div>
                      </td>

                      <td className="px-5 py-4 text-text-muted font-mono">
                        {member.phone || '—'}
                      </td>

                      <td className="px-5 py-4">
                        {isOwner && !isCurrentLoggedUser && !isOwnerMember ? (
                          <select
                            value={member.role}
                            onChange={(e) => handleRoleChange(member._id, e.target.value)}
                            className="bg-bg-input border border-border-subtle rounded-lg px-2.5 py-1 text-xs font-bold text-text-main outline-none focus:border-color-accent-purple cursor-pointer"
                          >
                            <option value="manager">{t('roleManager')}</option>
                            <option value="karigar">{t('roleKarigar')}</option>
                            <option value="staff">{t('roleStaff')}</option>
                          </select>
                        ) : (
                          getRoleBadge(member.role)
                        )}
                      </td>

                      <td className="px-5 py-4">
                        {member.isActive ? (
                          <span className="inline-flex items-center gap-1 text-[11px] font-bold text-emerald-500">
                            <MdCheckCircle className="w-3.5 h-3.5" /> {t('active')}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] font-bold text-rose-500">
                            <MdBlock className="w-3.5 h-3.5" /> {t('suspended')}
                          </span>
                        )}
                      </td>

                      {isManagerOrOwner && (
                        <td className="px-5 py-4 text-right">
                          {!isCurrentLoggedUser && !isOwnerMember ? (
                            <div className="inline-flex items-center gap-2">
                              <button
                                onClick={() => handleToggleStatus(member._id, member.isActive)}
                                className={`px-2.5 py-1 rounded-lg text-[10px] font-extrabold uppercase tracking-wider transition-all cursor-pointer border
                                  ${member.isActive
                                    ? 'bg-rose-500/10 text-rose-500 border-rose-500/20 hover:bg-rose-500/20'
                                    : 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20 hover:bg-emerald-500/20'}`}
                              >
                                {member.isActive ? t('deactivate') : t('reactivate')}
                              </button>

                              {isOwner && (
                                <button
                                  onClick={() => handleRemoveStaff(member._id, member.name)}
                                  className="p-1.5 rounded-lg text-text-muted hover:text-rose-500 hover:bg-rose-500/10 transition-colors cursor-pointer"
                                  title={t('confirmRemoveStaff')}
                                >
                                  <MdDeleteOutline className="w-4 h-4" />
                                </button>
                              )}
                            </div>
                          ) : (
                            <span className="text-[10px] font-semibold text-text-muted italic">{t('protected')}</span>
                          )}
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Add Staff Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={() => setIsAddModalOpen(false)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-1">
              <MdSupervisorAccount className="text-color-accent-purple w-5 h-5" />
              {t('addTeamMember')}
            </h3>
            <p className="text-xs text-text-muted mb-5 font-semibold">
              {t('addMemberDesc')}
            </p>

            <form onSubmit={handleAddStaffSubmit} className="flex flex-col gap-4">
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('fullName')} *</label>
                <input
                  type="text"
                  required
                  value={newStaff.name}
                  onChange={(e) => setNewStaff({ ...newStaff, name: e.target.value })}
                  placeholder="e.g. Salim Tailor"
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                  autoFocus
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('emailAddress')} *</label>
                <input
                  type="email"
                  required
                  value={newStaff.email}
                  onChange={(e) => setNewStaff({ ...newStaff, email: e.target.value })}
                  placeholder="salim@stitchcraft.com"
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('phoneNumberOptional')}</label>
                <input
                  type="tel"
                  value={newStaff.phone}
                  onChange={(e) => setNewStaff({ ...newStaff, phone: e.target.value })}
                  placeholder="+91 98765 43210"
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('assignedRole')}</label>
                <select
                  value={newStaff.role}
                  onChange={(e) => setNewStaff({ ...newStaff, role: e.target.value })}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all font-bold cursor-pointer"
                >
                  {isOwner && <option value="manager">{t('roleManagerDesc')}</option>}
                  <option value="karigar">{t('roleKarigarDesc')}</option>
                  <option value="staff">{t('roleStaffDesc')}</option>
                </select>
              </div>

              {modalError && (
                <span className="text-xs text-color-accent-pink font-bold text-center block animate-pulse">
                  {modalError}
                </span>
              )}

              <div className="flex gap-3 mt-2">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="flex-1 py-2.5 bg-bg-secondary border border-border-subtle hover:bg-bg-hover text-text-main font-bold text-sm transition-all cursor-pointer rounded-xl"
                >
                  {t('cancel')}
                </button>
                <button
                  type="submit"
                  disabled={modalLoading}
                  className="flex-1 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50"
                >
                  {modalLoading ? t('adding') : t('addTeamMember')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default StaffManagement;

