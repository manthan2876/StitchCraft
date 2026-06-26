/* src/pages/Profile.jsx */
import React, { useState, useEffect } from 'react';
import { useAuth } from '../hooks/useAuth';
import { useTheme } from '../context/ThemeContext';
import { useLanguage } from '../context/LanguageContext';
import { useNavigate } from 'react-router-dom';
import Card from '../components/common/Card';
import { api } from '../services/api';
import {
  MdPerson, MdEmail, MdBusiness, MdEdit, MdSave,
  MdLogout, MdPalette, MdNotifications, MdSecurity, MdStorefront,
  MdClose, MdCheck, MdAdd, MdDelete, MdCloudDownload, MdCloudUpload
} from 'react-icons/md';
import ProfileImage from '../assets/profile.png';
import { uploadToPrivateBucket, getSignedUrl } from '../services/supabase';

export const Profile = () => {
  const { user, logout, updateUser } = useAuth();
  const navigate = useNavigate();
  const { language, changeLanguage, t } = useLanguage();

  const [activeTab, setActiveTab] = useState('Profile');
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [avatarUrl, setAvatarUrl] = useState(ProfileImage)

  // Password update states
  const [passwordForm, setPasswordForm] = useState({ currentPassword: '', newPassword: '', confirmNewPassword: '' });
  const [passwordError, setPasswordError] = useState('');
  const [passwordSuccess, setPasswordSuccess] = useState('');
  const [passwordLoading, setPasswordLoading] = useState(false);

  // Data Privacy and Account Deletion States
  const [privacyAction, setPrivacyAction] = useState(null); // 'DOWNLOAD' | 'WIPE' | 'DELETE_ACCOUNT' | 'IMPORT'
  const [privacyPassword, setPrivacyPassword] = useState('');
  const [isPrivacyModalOpen, setIsPrivacyModalOpen] = useState(false);
  const [privacyError, setPrivacyError] = useState('');
  const [privacyLoading, setPrivacyLoading] = useState(false);

  const [isReasonModalOpen, setIsReasonModalOpen] = useState(false);
  const [deletionReason, setDeletionReason] = useState('');
  const [reasonLoading, setReasonLoading] = useState(false);

  // Import and Conflict Resolution States
  const [importJsonData, setImportJsonData] = useState(null);
  const [isConflictModalOpen, setIsConflictModalOpen] = useState(false);
  const [conflictsList, setConflictsList] = useState([]);
  const [resolutions, setResolutions] = useState({}); // { [id]: 'database' | 'backup' }
  const [conflictLoading, setConflictLoading] = useState(false);

  const handleActionClick = (type) => {
    setPrivacyAction(type);
    setPrivacyPassword('');
    setPrivacyError('');
    setPrivacyLoading(false);
    setImportJsonData(null);
    setIsPrivacyModalOpen(true);
  };

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (!file) {
      setImportJsonData(null);
      return;
    }
    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const parsed = JSON.parse(event.target.result);
        setImportJsonData(parsed);
        setPrivacyError('');
      } catch (err) {
        setPrivacyError('Invalid JSON file format.');
        setImportJsonData(null);
      }
    };
    reader.readAsText(file);
  };

  const performImport = async (resolutionsMap) => {
    setReasonLoading(true);
    try {
      await api.post('/auth/account/import-data', {
        password: privacyPassword,
        data: importJsonData,
        resolutions: resolutionsMap
      });
      setIsConflictModalOpen(false);
      setPrivacyPassword('');
      setImportJsonData(null);
      alert('All shop records have been successfully imported and merged.');
      window.location.reload();
    } catch (err) {
      alert(err.message || 'Import failed.');
    } finally {
      setReasonLoading(false);
    }
  };

  const handlePrivacyPasswordSubmit = async (e) => {
    e.preventDefault();
    setPrivacyError('');
    setPrivacyLoading(true);

    try {
      if (privacyAction === 'DOWNLOAD') {
        const response = await api.post('/auth/account/download-data', { password: privacyPassword });
        
        // Trigger file download
        const blob = new Blob([JSON.stringify(response, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `stitchcraft_data_${new Date().toISOString().slice(0, 10)}.json`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);

        setIsPrivacyModalOpen(false);
        setPrivacyPassword('');
        alert('Data downloaded successfully!');
      } else if (privacyAction === 'WIPE') {
        await api.post('/auth/account/delete-all-data', { password: privacyPassword });
        setIsPrivacyModalOpen(false);
        setPrivacyPassword('');
        alert('All shop records have been permanently deleted.');
      } else if (privacyAction === 'DELETE_ACCOUNT') {
        // Verify password
        await api.post('/auth/verify-password', { password: privacyPassword });
        setIsPrivacyModalOpen(false);
        setDeletionReason('');
        setIsReasonModalOpen(true);
      } else if (privacyAction === 'IMPORT') {
        if (!importJsonData) {
          setPrivacyError('Please select a valid JSON backup file.');
          setPrivacyLoading(false);
          return;
        }

        // Verify password
        await api.post('/auth/verify-password', { password: privacyPassword });
        setIsPrivacyModalOpen(false);

        // Check for conflicts
        setConflictLoading(true);
        try {
          const res = await api.post('/auth/account/check-conflicts', { data: importJsonData });
          setConflictLoading(false);
          if (res.hasConflicts) {
            setConflictsList(res.conflicts || []);
            const initialResolutions = {};
            res.conflicts.forEach(c => {
              initialResolutions[c._id] = 'database';
            });
            setResolutions(initialResolutions);
            setIsConflictModalOpen(true);
          } else {
            await performImport({});
          }
        } catch (err) {
          alert(err.message || 'Failed to check backup duplicate records.');
        }
      }
    } catch (err) {
      setPrivacyError(err.message || 'Verification failed. Please try again.');
    } finally {
      setPrivacyLoading(false);
    }
  };

  const handleDeletionReasonSubmit = async (e) => {
    e.preventDefault();
    setReasonLoading(true);

    try {
      await api.post('/auth/account/delete-account', {
        password: privacyPassword,
        reason: deletionReason
      });
      setIsReasonModalOpen(false);
      setPrivacyPassword('');
      alert('Your account deletion request has been registered. You will now be logged out. You can reactivate your account anytime within the next 15 days by logging back in.');
      handleLogout();
    } catch (err) {
      alert(err.message || 'Failed to process account deletion request.');
    } finally {
      setReasonLoading(false);
    }
  };

  const handlePasswordSubmit = async (e) => {
    e.preventDefault();
    setPasswordError('');
    setPasswordSuccess('');

    if (passwordForm.newPassword !== passwordForm.confirmNewPassword) {
      setPasswordError('New passwords do not match.');
      return;
    }

    if (passwordForm.newPassword.length < 4) {
      setPasswordError('New password must be at least 4 characters long.');
      return;
    }

    setPasswordLoading(true);
    try {
      await api.put('/auth/update-password', {
        currentPassword: passwordForm.currentPassword,
        newPassword: passwordForm.newPassword,
      });
      setPasswordSuccess('Password updated successfully!');
      setPasswordForm({ currentPassword: '', newPassword: '', confirmNewPassword: '' });
    } catch (err) {
      setPasswordError(err.message || 'Failed to update password.');
    } finally {
      setPasswordLoading(false);
    }
  };

  // Shop states
  const [shops, setShops] = useState([]);
  const [shopsLoading, setShopsLoading] = useState(false);
  const [isShopModalOpen, setIsShopModalOpen] = useState(false);
  const [shopModalMode, setShopModalMode] = useState('create'); // 'create' | 'edit'
  const [selectedShop, setSelectedShop] = useState(null);
  const [shopForm, setShopForm] = useState({ shopName: '', phone: '', address: '', plan: 'Free' });
  const [shopError, setShopError] = useState('');
  const [shopModalLoading, setShopModalLoading] = useState(false);

  const [deleteTargetShop, setDeleteTargetShop] = useState(null);
  const [deleteShopLoading, setDeleteShopLoading] = useState(false);
  const [deleteShopError, setDeleteShopError] = useState('');

  // Load Settings from LocalStorage
  const [settings, setSettings] = useState(() => {
    const saved = localStorage.getItem('stitchcraft_settings');
    const defaultSettings = {
      emailNotifications: true,
      smsNotifications: false,
      darkMode: true,
      language: 'English',
      currency: 'INR (₹)',
      dateFormat: 'DD/MM/YYYY',
      showStatsCards: true,
      showRecentOrders: true,
      showWeeklyStitching: true,
      showPerformanceTracking: true,
      showCalendar: true,
      showReminders: true,
    };
    if (!saved) return defaultSettings;
    try {
      const parsed = JSON.parse(saved);
      return { ...defaultSettings, ...parsed };
    } catch (e) {
      return defaultSettings;
    }
  });

  const { theme, toggleTheme } = useTheme();

  // Save settings automatically when they change
  useEffect(() => {
    localStorage.setItem('stitchcraft_settings', JSON.stringify(settings));
  }, [settings]);

  // Fetch shops when Shop Info is loaded
  const fetchShops = async () => {
    setShopsLoading(true);
    try {
      const data = await api.get('/shops');
      setShops(data);
    } catch (err) {
      console.error('Failed to fetch shops:', err);
    } finally {
      setShopsLoading(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'Shop Info') {
      fetchShops();
    }
  }, [activeTab]);

  const tabKeys = ['Profile', 'Shop Info', 'Settings', 'Change Password'];
  const getTabLabel = (key) => {
    if (key === 'Profile') return t('profile');
    if (key === 'Shop Info') return t('shopsManager');
    if (key === 'Settings') return t('settings');
    if (key === 'Change Password') return t('changePassword');
    return key;
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  useEffect(() => {
    const loadAvatar = async () => {
      if (user?.avatar && user.avatar !== 'profile.png') {
        const url = await getSignedUrl('profile-images', user.avatar);
        if (url) setAvatarUrl(url);
      }
    };
    loadAvatar();
  }, [user]);

  const handleAvatarChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    if (file.size > 1 * 1024 * 1024) {
      alert('Image size should be less than 1MB');
      return;
    }

    setShopModalLoading(true); // Using a loading state to disable UI during upload
    try {
      // 1. Upload to Supabase and get back the storage path
      const path = await uploadToPrivateBucket('profile-images', file);

      // 2. Save the path string to your MongoDB User model
      const data = await api.put('/auth/profile', { avatar: path });
      updateUser(data);
    } catch (err) {
      console.error('Failed to upload photo:', err);
      alert(err.message || 'Failed to upload profile photo');
    } finally {
      setShopModalLoading(false);
    }
  };

  const handleSwitchShop = async (shopId) => {
    try {
      const data = await api.put(`/auth/switch-shop/${shopId}`);
      updateUser(data);
      navigate('/dashboard');
    } catch (err) {
      alert(err.message || 'Failed to switch shop');
    }
  };

  const handleOpenCreateShopModal = () => {
    setShopForm({ shopName: '', phone: '', address: '', plan: 'Free' });
    setShopModalMode('create');
    setSelectedShop(null);
    setShopError('');
    setIsShopModalOpen(true);
  };

  const handleOpenEditShopModal = (shop) => {
    setShopForm({
      shopName: shop.shopName,
      phone: shop.phone || '',
      address: shop.address || '',
      plan: shop.plan || 'Free'
    });
    setShopModalMode('edit');
    setSelectedShop(shop);
    setShopError('');
    setIsShopModalOpen(true);
  };

  const handleShopFormSubmit = async (e) => {
    e.preventDefault();
    if (!shopForm.shopName) {
      setShopError('Shop name is required.');
      return;
    }
    setShopModalLoading(true);
    setShopError('');
    try {
      if (shopModalMode === 'create') {
        const data = await api.post('/shops', shopForm);
        setShops(prev => [...prev, data]);
        if (!user.shopId) {
          const profile = await api.get('/auth/profile');
          updateUser(profile);
        }
      } else {
        const data = await api.put(`/shops/${selectedShop._id}`, shopForm);
        setShops(prev => prev.map(s => s._id === data._id ? data : s));
        if (user.shopId === data._id) {
          const updatedSession = { ...user, shopName: data.shopName };
          updateUser(updatedSession);
        }
      }
      setIsShopModalOpen(false);
    } catch (err) {
      setShopError(err.message || 'Failed to save shop.');
    } finally {
      setShopModalLoading(false);
    }
  };

  const handleDeleteShopSubmit = async () => {
    if (!deleteTargetShop) return;
    setDeleteShopLoading(true);
    setDeleteShopError('');
    try {
      await api.delete(`/shops/${deleteTargetShop._id}`);
      setShops(prev => prev.filter(s => s._id !== deleteTargetShop._id));
      if (user.shopId === deleteTargetShop._id) {
        const profile = await api.get('/auth/profile');
        updateUser(profile);
        navigate('/dashboard');
      }
      setDeleteTargetShop(null);
    } catch (err) {
      setDeleteShopError(err.message || 'Failed to delete shop.');
    } finally {
      setDeleteShopLoading(false);
    }
  };

  const initials = (user?.name || 'MR')
    .split(' ')
    .map(n => n[0])
    .join('')
    .substring(0, 2)
    .toUpperCase();

  return (
    <div className="flex flex-col gap-6 select-none max-w-3xl mx-auto">

      {/* Profile Hero Card */}
      <Card className="relative overflow-hidden">
        <div className="absolute inset-x-0 top-0 h-24 bg-gradient-to-r from-color-accent-purple/40 via-color-accent-blue/30 to-color-accent-pink/30 blur-sm" />

        <div className="relative flex flex-col sm:flex-row items-center sm:items-end gap-4 pt-10 pb-2">
          <input type="file" id="avatar-upload" accept="image/*" className="hidden" onChange={handleAvatarChange} />
          <div
            onClick={() => document.getElementById('avatar-upload').click()}
            className="w-20 h-20 rounded-2xl border-4 border-[var(--color-bg-primary)] overflow-hidden shadow-2xl shrink-0 bg-gradient-to-br from-color-accent-purple to-color-accent-blue flex items-center justify-center cursor-pointer group relative"
            title="Upload Profile Photo"
          >
            <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 flex flex-col items-center justify-center text-[10px] text-white-forced font-bold transition-opacity z-20">
              <MdEdit className="w-4 h-4 mb-0.5 text-color-accent-purple" />
              <span>Upload</span>
            </div>
            <img
              src={avatarUrl}
              alt="Profile"
              className="w-full h-full object-cover"
              onError={e => {
                e.target.style.display = 'none';
                e.target.parentElement.querySelector('.initials-fallback').style.display = 'flex';
              }}
            />
            <span className="initials-fallback hidden text-white-forced font-black text-2xl items-center justify-center w-full h-full">
              {initials}
            </span>
          </div>

          <div className="flex-1 text-center sm:text-left">
            <h2 className="text-2xl font-black text-text-main">{user?.name || 'Masterji Ramesh'}</h2>
            <p className="text-sm text-text-muted font-semibold mt-0.5">
              <span className="text-color-accent-purple font-bold capitalize">{user?.role?.toLowerCase() === 'owner' ? t('roleOwner') : (user?.role || t('roleOwner'))}</span>
              {' • '}
              <span>{user?.shopName || 'Ramesh Tailors'}</span>
            </p>
            <p className="text-xs text-text-muted mt-1">{user?.email}</p>
          </div>

          <button
            onClick={handleLogout}
            className="flex items-center gap-2 px-4 py-2 bg-rose-500/10 border border-rose-500/20 text-rose-500 rounded-xl text-xs font-bold hover:bg-rose-500/20 transition-all cursor-pointer self-end sm:self-auto"
          >
            <MdLogout className="w-4 h-4" />
            <span>{t('logout')}</span>
          </button>
        </div>
      </Card>

      {/* Tabs */}
      <div className="flex gap-2 bg-bg-secondary border border-border-subtle rounded-2xl p-1.5">
        {tabKeys.map(tabKey => (
          <button
            key={tabKey}
            onClick={() => setActiveTab(tabKey)}
            className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all cursor-pointer ${activeTab === tabKey
              ? 'delivery-active-tab border border-color-accent-purple/30 shadow'
              : 'filter-tab-inactive hover:text-text-main'
              }`}
          >
            {getTabLabel(tabKey)}
          </button>
        ))}
      </div>

      {/* ── PROFILE TAB ── */}
      {activeTab === 'Profile' && (
        <Card className="flex flex-col gap-5">
          <div className="flex items-center justify-between border-b border-border-subtle pb-4">
            <div>
              <h3 className="text-base font-bold text-text-main">{t('personalInfo')}</h3>
              <p className="text-xs text-text-muted mt-0.5">{t('personalInfoSub')}</p>
            </div>
            {!isEditingProfile ? (
              <button
                onClick={() => setIsEditingProfile(true)}
                className="flex items-center gap-1.5 px-3 py-1.5 bg-bg-secondary border border-border-medium rounded-xl text-xs font-bold text-text-muted hover:text-text-main cursor-pointer"
              >
                <MdEdit className="w-4 h-4" />{t('edit')}
              </button>
            ) : (
              <button
                onClick={() => setIsEditingProfile(false)}
                className="flex items-center gap-1.5 px-3 py-1.5 bg-color-accent-purple rounded-xl text-xs font-bold text-white-forced cursor-pointer"
              >
                <MdSave className="w-4 h-4 text-white-forced" />{t('save')}
              </button>
            )}
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
            {[
              { label: t('fullName'), value: user?.name || 'Masterji Ramesh', icon: <MdPerson />, key: 'fullName' },
              { label: t('emailAddress'), value: user?.email || 'ramesh@stitchcraft.com', icon: <MdEmail />, key: 'email' },
              { label: t('role'), value: user?.role?.toLowerCase() === 'owner' ? t('roleOwner') : (user?.role || t('roleOwner')), icon: <MdSecurity />, key: 'role' },
              { label: t('shopName'), value: user?.shopName || 'Ramesh Tailors', icon: <MdBusiness />, key: 'shopName' },
            ].map(field => (
              <div key={field.key} className="flex flex-col gap-1.5">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider flex items-center gap-1">
                  {React.cloneElement(field.icon, { className: 'w-3.5 h-3.5 text-color-accent-purple' })}
                  {field.label}
                </label>
                {isEditingProfile ? (
                  <input
                    defaultValue={field.value}
                    className="px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-sm text-text-main outline-none focus:border-color-accent-purple transition-all"
                  />
                ) : (
                  <p className="px-4 py-2.5 bg-bg-secondary border border-border-subtle rounded-xl text-sm text-text-main font-semibold">
                    {field.value}
                  </p>
                )}
              </div>
            ))}
          </div>

          <div className="grid grid-cols-3 gap-4 mt-2 border-t border-border-subtle pt-5">
            {[
              { label: t('accountType'), value: user?.role?.toLowerCase() === 'owner' ? t('roleOwner') : (user?.role || t('roleOwner')) },
              { label: t('shopsManaged'), value: String(shops.length || 1) },
              { label: t('memberSince'), value: '2026' },
            ].map(s => (
              <div key={s.label} className="bg-bg-secondary p-4 rounded-xl border border-border-subtle text-center">
                <p className="text-xl font-black text-text-main">{s.value}</p>
                <p className="text-[10px] text-text-muted font-bold uppercase tracking-wider mt-1">{s.label}</p>
              </div>
            ))}
          </div>
        </Card>
      )}

      {/* ── SHOP INFO TAB ── */}
      {activeTab === 'Shop Info' && (
        <div className="flex flex-col gap-6">
          <Card className="flex flex-col gap-5">
            <div className="flex items-center justify-between border-b border-border-subtle pb-4">
              <div>
                <h3 className="text-base font-bold text-text-main">{t('shopsManager')}</h3>
                <p className="text-xs text-text-muted mt-0.5">{t('shopsManagerSub')}</p>
              </div>
              <button
                onClick={handleOpenCreateShopModal}
                className="flex items-center gap-1.5 px-3 py-1.5 bg-color-accent-purple hover:bg-color-accent-purple/90 text-white-forced font-bold rounded-xl text-xs shadow-lg transition-all cursor-pointer"
              >
                <MdAdd className="w-4 h-4 text-white-forced" />
                <span>{t('newShop')}</span>
              </button>
            </div>

            {shopsLoading ? (
              <div className="text-center py-8 text-xs text-text-muted">{t('syncing')}</div>
            ) : shops.length === 0 ? (
              <div className="text-center py-8 text-xs text-text-muted">{t('noRecords')}</div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {shops.map(shop => {
                  const isActive = user?.shopId === shop._id;
                  return (
                    <div
                      key={shop._id}
                      className={`p-5 rounded-2xl border transition-all flex flex-col gap-4 text-left relative overflow-hidden
                        ${isActive
                          ? 'shop-active-card shadow-lg shadow-color-accent-purple/5'
                          : 'border-border-subtle bg-bg-secondary hover:border-border-medium'}`}
                    >
                      {isActive && (
                        <div className="absolute right-4 top-4 px-2 py-0.5 text-[8px] font-black uppercase tracking-wider bg-color-accent-purple text-white-forced rounded-md border border-color-accent-purple/40">
                          {t('activeSession')}
                        </div>
                      )}

                      <div className="flex items-start gap-3">
                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0
                          ${isActive ? 'bg-color-accent-purple/20 text-color-accent-purple' : 'bg-bg-hover text-text-muted'}`}
                        >
                          <MdStorefront className="w-5 h-5" />
                        </div>
                        <div className="min-w-0 pr-12">
                          <h4 className="text-sm font-bold text-text-main truncate">{shop.shopName}</h4>
                          <span className="text-[10px] font-extrabold uppercase tracking-widest text-[#007aff]">
                            {t((shop.plan || 'Free').toLowerCase() + 'Plan')}
                          </span>
                        </div>
                      </div>

                      <div className="flex flex-col gap-1 text-xs text-text-muted border-t border-border-subtle pt-3">
                        {shop.phone && <span className="truncate">📞 {shop.phone}</span>}
                        {shop.address && <span className="truncate">📍 {shop.address}</span>}
                      </div>

                      <div className="flex items-center gap-2 border-t border-border-subtle pt-3 mt-auto">
                        {!isActive ? (
                          <button
                            onClick={() => handleSwitchShop(shop._id)}
                            className="flex-1 py-1.5 bg-bg-card hover:bg-bg-card-hover text-text-main rounded-xl text-[10px] font-extrabold transition-all cursor-pointer border border-border-subtle hover:border-color-accent-purple/40"
                          >
                            {t('switchActive')}
                          </button>
                        ) : (
                          <span className="flex-1 text-[10px] text-color-accent-emerald font-black flex items-center gap-1">
                            <MdCheck className="w-3.5 h-3.5" />
                            <span>{t('currentlyActive')}</span>
                          </span>
                        )}
                        <button
                          onClick={() => handleOpenEditShopModal(shop)}
                          className="px-2.5 py-1.5 bg-bg-hover hover:bg-border-medium text-text-main rounded-xl text-[10px] font-bold transition-all cursor-pointer border border-border-subtle"
                          title={t('editDetails')}
                        >
                          <MdEdit className="w-3.5 h-3.5 text-color-accent-purple animate-pulse" />
                        </button>
                        <button
                          onClick={() => setDeleteTargetShop(shop)}
                          className="px-2.5 py-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-500 rounded-xl text-[10px] font-bold transition-all cursor-pointer border border-rose-500/10"
                          title={t('deleteShop')}
                        >
                          <MdDelete className="w-3.5 h-3.5 text-color-accent-pink" />
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </Card>
        </div>
      )}

      {/* ── SETTINGS TAB ── */}
      {activeTab === 'Settings' && (
        <Card className="flex flex-col gap-5">
          <div className="border-b border-border-subtle pb-4">
            <h3 className="text-base font-bold text-text-main">{t('preferences')}</h3>
            <p className="text-xs text-text-muted mt-0.5">{t('preferencesSub')}</p>
          </div>

          <div className="flex flex-col gap-3">
            <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider flex items-center gap-1">
              <MdNotifications className="w-3.5 h-3.5" /> {t('appPreferences')}
            </p>
            {[
              { key: 'emailNotifications', label: t('emailNotifications'), desc: t('emailNotificationsDesc') },
              { key: 'smsNotifications', label: t('smsNotifications'), desc: t('smsNotificationsDesc') },
              { key: 'darkMode', label: t('darkModeTheme'), desc: t('darkModeThemeDesc') },
            ].map(s => (
              <div key={s.key} className="flex items-center justify-between bg-bg-secondary border border-border-subtle rounded-xl px-4 py-3">
                <div>
                  <p className="text-sm font-bold text-text-main">{s.label}</p>
                  <p className="text-[10px] text-text-muted mt-0.5">{s.desc}</p>
                </div>
                <button
                  onClick={() => {
                    if (s.key === 'darkMode') {
                      toggleTheme();
                    } else {
                      setSettings(prev => ({ ...prev, [s.key]: !prev[s.key] }));
                    }
                  }}
                  className={`w-11 h-6 rounded-full border-2 transition-all cursor-pointer relative ${(s.key === 'darkMode' ? theme === 'dark' : settings[s.key])
                    ? 'bg-color-accent-purple border-color-accent-purple'
                    : 'bg-bg-hover border-border-medium'
                    }`}
                >
                  <span className={`absolute top-0.5 w-4 h-4 rounded-full bg-white transition-all ${(s.key === 'darkMode' ? theme === 'dark' : settings[s.key]) ? 'left-[calc(100%-18px)]' : 'left-0.5'
                    }`} />
                </button>
              </div>
            ))}
          </div>

          <div className="flex flex-col gap-3">
            <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider flex items-center gap-1">
              <MdNotifications className="w-3.5 h-3.5" /> {t('dashboardCustomization')}
            </p>
            <p className="text-xs text-text-muted -mt-1 mb-1 font-semibold">{t('dashboardCustomizationDesc')}</p>
            {[
              { key: 'showStatsCards', label: t('showStatsCards'), desc: t('showStatsCardsDesc') },
              { key: 'showRecentOrders', label: t('showRecentOrders'), desc: t('showRecentOrdersDesc') },
              { key: 'showWeeklyStitching', label: t('showWeeklyStitching'), desc: t('showWeeklyStitchingDesc') },
              { key: 'showPerformanceTracking', label: t('showPerformanceTracking'), desc: t('showPerformanceTrackingDesc') },
              { key: 'showCalendar', label: t('showCalendar'), desc: t('showCalendarDesc') },
              { key: 'showReminders', label: t('showReminders'), desc: t('showRemindersDesc') },
            ].map(s => (
              <div key={s.key} className="flex items-center justify-between bg-bg-secondary border border-border-subtle rounded-xl px-4 py-3">
                <div>
                  <p className="text-sm font-bold text-text-main">{s.label}</p>
                  <p className="text-[10px] text-text-muted mt-0.5">{s.desc}</p>
                </div>
                <button
                  type="button"
                  onClick={() => {
                    setSettings(prev => ({ ...prev, [s.key]: !prev[s.key] }));
                  }}
                  className={`w-11 h-6 rounded-full border-2 transition-all cursor-pointer relative ${settings[s.key]
                    ? 'bg-color-accent-purple border-color-accent-purple'
                    : 'bg-bg-hover border-border-medium'
                    }`}
                >
                  <span className={`absolute top-0.5 w-4 h-4 rounded-full bg-white transition-all ${settings[s.key] ? 'left-[calc(100%-18px)]' : 'left-0.5'
                    }`} />
                </button>
              </div>
            ))}
          </div>

          <div className="flex flex-col gap-3">
            <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider flex items-center gap-1">
              <MdPalette className="w-3.5 h-3.5" /> {t('display')}
            </p>
            {[
              { key: 'currency', label: t('currency'), options: ['INR (₹)', 'USD ($)', 'EUR (€)'] },
              { key: 'dateFormat', label: t('dateFormat'), options: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'] },
              { key: 'language', label: t('languageLabel'), options: [] },
            ].map(s => (
              <div key={s.key} className="flex items-center justify-between bg-bg-input border border-border-subtle rounded-xl px-4 py-3">
                <p className="text-sm font-bold text-text-main">{s.label}</p>
                <select
                  value={s.key === 'language' ? language : settings[s.key]}
                  onChange={e => {
                    if (s.key === 'language') {
                      changeLanguage(e.target.value);
                    } else {
                      setSettings(prev => ({ ...prev, [s.key]: e.target.value }));
                    }
                  }}
                  className="bg-bg-primary border border-border-medium rounded-lg px-3 py-1.5 text-xs text-text-main outline-none focus:border-color-accent-purple cursor-pointer"
                >
                  {s.key === 'language' ? (
                    <>
                      <option value="en" className="bg-bg-card">English</option>
                      <option value="gu" className="bg-bg-card">Gujarati (ગુજરાતી)</option>
                      <option value="hi" className="bg-bg-card">Hindi (हिन्दी)</option>
                    </>
                  ) : (
                    s.options.map(o => <option key={o} value={o} className="bg-bg-card">{o}</option>)
                  )}
                </select>
              </div>
            ))}
          </div>

          <div className="border border-rose-500/20 bg-rose-500/5 rounded-2xl p-4 flex flex-col gap-4">
            <p className="text-xs font-bold text-rose-500 uppercase tracking-wider">⚠ {t('accountActions')}</p>
            
            {/* Download Data */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-bg-secondary border border-border-subtle rounded-xl p-4">
              <div className="flex-1">
                <p className="text-sm font-bold text-text-main">{t('downloadData')}</p>
                <p className="text-xs text-text-muted mt-1 font-semibold">{t('downloadDataDesc')}</p>
              </div>
              <button
                type="button"
                onClick={() => handleActionClick('DOWNLOAD')}
                className="px-4 py-2.5 bg-color-accent-purple/10 border border-color-accent-purple/20 text-color-accent-purple rounded-xl text-xs font-bold hover:bg-color-accent-purple/20 transition-all cursor-pointer whitespace-nowrap self-start sm:self-center flex items-center gap-1.5"
              >
                <MdCloudDownload className="w-4 h-4" />
                {t('downloadData')}
              </button>
            </div>

            {/* Import Data */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-bg-secondary border border-border-subtle rounded-xl p-4">
              <div className="flex-1">
                <p className="text-sm font-bold text-text-main">{t('importData')}</p>
                <p className="text-xs text-text-muted mt-1 font-semibold">{t('importDataDesc')}</p>
              </div>
              <button
                type="button"
                onClick={() => handleActionClick('IMPORT')}
                className="px-4 py-2.5 bg-color-accent-purple/10 border border-color-accent-purple/20 text-color-accent-purple rounded-xl text-xs font-bold hover:bg-color-accent-purple/20 transition-all cursor-pointer whitespace-nowrap self-start sm:self-center flex items-center gap-1.5"
              >
                <MdCloudUpload className="w-4 h-4" />
                {t('importData')}
              </button>
            </div>

            {/* Wipe Data */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-bg-secondary border border-rose-500/20 rounded-xl p-4">
              <div className="flex-1">
                <p className="text-sm font-bold text-rose-500">{t('wipeData')}</p>
                <p className="text-xs text-text-muted mt-1 font-semibold">{t('wipeDataDesc')}</p>
              </div>
              <button
                type="button"
                onClick={() => handleActionClick('WIPE')}
                className="px-4 py-2.5 bg-rose-500/10 border border-rose-500/20 text-rose-500 rounded-xl text-xs font-bold hover:bg-rose-500/20 transition-all cursor-pointer whitespace-nowrap self-start sm:self-center flex items-center gap-1.5"
              >
                <MdDelete className="w-4 h-4" />
                {t('wipeData')}
              </button>
            </div>

            {/* Delete Account */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-bg-secondary border border-rose-600/30 rounded-xl p-4">
              <div className="flex-1">
                <p className="text-sm font-bold text-rose-600">{t('deleteAccount')}</p>
                <p className="text-xs text-text-muted mt-1 font-semibold">{t('deleteAccountDesc')}</p>
              </div>
              <button
                type="button"
                onClick={() => handleActionClick('DELETE_ACCOUNT')}
                className="px-4 py-2.5 bg-rose-600 hover:bg-rose-700 text-white-forced rounded-xl text-xs font-bold transition-all cursor-pointer whitespace-nowrap self-start sm:self-center flex items-center gap-1.5"
              >
                <MdDelete className="w-4 h-4" />
                {t('deleteAccount')}
              </button>
            </div>
          </div>
        </Card>
      )}

      {/* ── CHANGE PASSWORD TAB ── */}
      {activeTab === 'Change Password' && (
        <Card className="flex flex-col gap-5">
          <div className="border-b border-border-subtle pb-4">
            <h3 className="text-base font-bold text-text-main">{t('changePassword')}</h3>
            <p className="text-xs text-text-muted mt-0.5">{t('changePasswordSub')}</p>
          </div>

          <form onSubmit={handlePasswordSubmit} className="flex flex-col gap-5">
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('currentPassword')}</label>
              <input
                type="password"
                required
                value={passwordForm.currentPassword}
                onChange={e => setPasswordForm({ ...passwordForm, currentPassword: e.target.value })}
                placeholder={t('currentPassword')}
                className="px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-sm text-text-main outline-none focus:border-color-accent-purple transition-all placeholder:text-text-muted/50"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('newPassword')}</label>
              <input
                type="password"
                required
                value={passwordForm.newPassword}
                onChange={e => setPasswordForm({ ...passwordForm, newPassword: e.target.value })}
                placeholder={t('newPassword')}
                className="px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-sm text-text-main outline-none focus:border-color-accent-purple transition-all placeholder:text-text-muted/50"
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('confirmNewPassword')}</label>
              <input
                type="password"
                required
                value={passwordForm.confirmNewPassword}
                onChange={e => setPasswordForm({ ...passwordForm, confirmNewPassword: e.target.value })}
                placeholder={t('confirmNewPassword')}
                className="px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-sm text-text-main outline-none focus:border-color-accent-purple transition-all placeholder:text-text-muted/50"
              />
            </div>

            {passwordError && (
              <p className="text-xs text-color-accent-pink font-bold text-center animate-pulse">{passwordError}</p>
            )}

            {passwordSuccess && (
              <p className="text-xs text-color-accent-emerald font-bold text-center animate-pulse">{passwordSuccess}</p>
            )}

            <button
              type="submit"
              disabled={passwordLoading}
              className="py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50"
            >
              {passwordLoading ? t('updatingLock') : t('changePasswordBtn')}
            </button>
          </form>
        </Card>
      )}

      {/* Create/Edit Shop Modal */}
      {isShopModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[440px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={() => setIsShopModalOpen(false)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-1">
              <MdStorefront className="text-color-accent-purple w-5 h-5" />
              {shopModalMode === 'create' ? t('createShop') : t('editShopDetails')}
            </h3>
            <p className="text-xs text-text-muted mb-5 font-semibold">
              {shopModalMode === 'create' ? t('createShopDesc') : t('editShopDetailsDesc')}
            </p>

            <form onSubmit={handleShopFormSubmit} className="flex flex-col gap-4">
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('shopName')} *</label>
                <input
                  type="text"
                  required
                  value={shopForm.shopName}
                  onChange={e => { setShopForm({ ...shopForm, shopName: e.target.value }); setShopError(''); }}
                  placeholder={t('shopName')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('contactPhone')}</label>
                <input
                  type="tel"
                  value={shopForm.phone}
                  onChange={e => setShopForm({ ...shopForm, phone: e.target.value })}
                  placeholder={t('contactPhone')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('address')}</label>
                <input
                  type="text"
                  value={shopForm.address}
                  onChange={e => setShopForm({ ...shopForm, address: e.target.value })}
                  placeholder={t('address')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('planTier')}</label>
                <select
                  value={shopForm.plan}
                  onChange={e => setShopForm({ ...shopForm, plan: e.target.value })}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all cursor-pointer font-bold"
                >
                  <option value="Free" className="bg-bg-card text-text-main">{t('freePlan')}</option>
                  <option value="Basic" className="bg-bg-card text-text-main">{t('basicPlan')}</option>
                  <option value="Premium" className="bg-bg-card text-text-main">{t('premiumPlan')}</option>
                </select>
              </div>

              {shopError && (
                <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse">
                  {shopError}
                </span>
              )}

              <div className="flex gap-3 mt-2">
                <button
                  type="button"
                  onClick={() => setIsShopModalOpen(false)}
                  className="flex-1 py-2.5 btn-tactile-dark font-bold text-sm transition-all cursor-pointer"
                >
                  {t('cancel')}
                </button>
                <button
                  type="submit"
                  disabled={shopModalLoading}
                  className="flex-1 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50"
                >
                  {shopModalLoading ? t('saving') : t('saveDetails')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Shop Confirmation Modal */}
      {deleteTargetShop && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={() => setDeleteTargetShop(null)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-2">
              <MdDelete className="text-color-accent-pink w-5 h-5" />
              {t('deleteShopConfirmTitle')}
            </h3>
            <p className="text-xs text-text-muted mb-4 font-semibold">
              {t('deleteShopConfirmDesc').replace('{shopName}', deleteTargetShop.shopName)}
            </p>

            {deleteShopError && (
              <span className="text-xs text-color-accent-pink font-bold text-center block mb-4 animate-pulse">
                {deleteShopError}
              </span>
            )}

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setDeleteTargetShop(null)}
                className="flex-1 py-2.5 btn-tactile-dark font-bold text-sm transition-all cursor-pointer"
              >
                {t('cancel')}
              </button>
              <button
                onClick={handleDeleteShopSubmit}
                disabled={deleteShopLoading}
                className="flex-1 py-2.5 bg-rose-600 hover:bg-rose-700 text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-rose-950/20 transition-all cursor-pointer disabled:opacity-50"
              >
                {deleteShopLoading ? t('saving') : t('deleteShop')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Password Confirmation Modal */}
      {isPrivacyModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={() => setIsPrivacyModalOpen(false)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-2">
              <MdSecurity className="text-color-accent-purple w-5 h-5" />
              {t('confirmActionTitle')}
            </h3>
            <p className="text-xs text-text-muted mb-4 font-semibold">
              {t('confirmActionDesc')}
            </p>

            <form onSubmit={handlePrivacyPasswordSubmit} className="flex flex-col gap-4">
              {privacyAction === 'IMPORT' && (
                <div className="flex flex-col gap-1.5">
                  <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Select Backup File (.json)</label>
                  <input
                    type="file"
                    accept=".json"
                    required
                    onChange={handleFileChange}
                    className="w-full text-xs text-text-muted file:mr-3 file:py-1.5 file:px-3 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-color-accent-purple/10 file:text-color-accent-purple hover:file:bg-color-accent-purple/20 cursor-pointer"
                  />
                </div>
              )}

              <div className="flex flex-col gap-1">
                <input
                  type="password"
                  required
                  value={privacyPassword}
                  onChange={e => { setPrivacyPassword(e.target.value); setPrivacyError(''); }}
                  placeholder={t('enterPasswordPlaceholder')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                  autoFocus
                />
              </div>

              {privacyError && (
                <span className="text-xs text-color-accent-pink font-bold text-center block animate-pulse">
                  {privacyError}
                </span>
              )}

              <div className="flex gap-3 mt-2">
                <button
                  type="button"
                  onClick={() => setIsPrivacyModalOpen(false)}
                  className="flex-1 py-2.5 btn-tactile-dark font-bold text-sm transition-all cursor-pointer"
                >
                  {t('cancel')}
                </button>
                <button
                  type="submit"
                  disabled={privacyLoading}
                  className="flex-1 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50"
                >
                  {privacyLoading ? t('loadingAction') : t('confirm')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Account Deletion Reason Modal */}
      {isReasonModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button
              onClick={() => setIsReasonModalOpen(false)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-2">
              <MdDelete className="text-color-accent-pink w-5 h-5" />
              {t('deleteReasonTitle')}
            </h3>
            <p className="text-xs text-text-muted mb-4 font-semibold">
              {t('deleteReasonDesc')}
            </p>

            <form onSubmit={handleDeletionReasonSubmit} className="flex flex-col gap-4">
              <div className="flex flex-col gap-1">
                <textarea
                  value={deletionReason}
                  onChange={e => setDeletionReason(e.target.value)}
                  placeholder={t('deleteReasonPlaceholder')}
                  className="w-full h-24 px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50 resize-none font-semibold"
                  autoFocus
                />
              </div>

              <div className="flex gap-3 mt-2">
                <button
                  type="button"
                  onClick={() => setIsReasonModalOpen(false)}
                  className="flex-1 py-2.5 btn-tactile-dark font-bold text-sm transition-all cursor-pointer"
                >
                  {t('cancel')}
                </button>
                <button
                  type="submit"
                  disabled={reasonLoading}
                  className="flex-1 py-2.5 bg-rose-600 hover:bg-rose-700 text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-rose-950/20 transition-all cursor-pointer disabled:opacity-50"
                >
                  {reasonLoading ? t('loadingAction') : t('deleteAccount')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Conflict Resolution Modal */}
      {isConflictModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[600px] max-h-[90vh] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left flex flex-col">
            <button
              onClick={() => setIsConflictModalOpen(false)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-2">
              <MdSecurity className="text-color-accent-purple w-5 h-5" />
              {t('conflictResolutionTitle')}
            </h3>
            <p className="text-xs text-text-muted mb-4 font-semibold">
              {t('conflictResolutionDesc')}
            </p>

            {/* Bulk Selection Helpers */}
            <div className="flex gap-3 mb-4">
              <button
                type="button"
                onClick={() => {
                  const bulk = {};
                  conflictsList.forEach(c => { bulk[c._id] = 'database'; });
                  setResolutions(bulk);
                }}
                className="flex-1 py-1.5 bg-bg-secondary border border-border-subtle rounded-xl text-xs font-bold text-text-main hover:bg-bg-hover transition-all cursor-pointer text-center"
              >
                {t('selectAllExisting')}
              </button>
              <button
                type="button"
                onClick={() => {
                  const bulk = {};
                  conflictsList.forEach(c => { bulk[c._id] = 'backup'; });
                  setResolutions(bulk);
                }}
                className="flex-1 py-1.5 bg-bg-secondary border border-border-subtle rounded-xl text-xs font-bold text-text-main hover:bg-bg-hover transition-all cursor-pointer text-center"
              >
                {t('selectAllBackup')}
              </button>
            </div>

            {/* Scrollable list of conflicts */}
            <div className="flex-1 overflow-y-auto pr-1 flex flex-col gap-3 max-h-[50vh]">
              {conflictsList.map(conflict => {
                const choice = resolutions[conflict._id] || 'database';
                return (
                  <div key={conflict._id} className="border border-border-subtle rounded-xl p-3 flex flex-col gap-2 bg-bg-secondary/40">
                    <div className="flex justify-between items-center border-b border-border-subtle pb-1.5">
                      <span className="text-xs font-bold text-text-main">{conflict.name}</span>
                      <span className="text-[10px] uppercase font-black px-2 py-0.5 rounded-md bg-color-accent-purple/15 text-color-accent-purple">
                        {conflict.model}
                      </span>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-1">
                      {/* Database option */}
                      <div
                        onClick={() => setResolutions(prev => ({ ...prev, [conflict._id]: 'database' }))}
                        className={`border rounded-xl p-3 cursor-pointer transition-all flex flex-col justify-between ${
                          choice === 'database'
                            ? 'bg-color-accent-purple/5 border-color-accent-purple'
                            : 'bg-bg-input border-border-medium hover:border-border-medium/80'
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <span className="text-[10px] uppercase font-bold text-text-muted">Database Version</span>
                          <span className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center ${
                            choice === 'database' ? 'border-color-accent-purple bg-color-accent-purple' : 'border-border-medium'
                          }`}>
                            {choice === 'database' && <span className="w-1.5 h-1.5 rounded-full bg-white" />}
                          </span>
                        </div>
                        <p className="text-[11px] font-bold text-text-main mt-1.5 line-clamp-2">{conflict.existing.summary}</p>
                        <p className="text-[9px] text-text-muted mt-1 font-semibold">
                          Modified: {new Date(conflict.existing.updatedAt).toLocaleDateString()}
                        </p>
                      </div>

                      {/* Backup option */}
                      <div
                        onClick={() => setResolutions(prev => ({ ...prev, [conflict._id]: 'backup' }))}
                        className={`border rounded-xl p-3 cursor-pointer transition-all flex flex-col justify-between ${
                          choice === 'backup'
                            ? 'bg-color-accent-purple/5 border-color-accent-purple'
                            : 'bg-bg-input border-border-medium hover:border-border-medium/80'
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <span className="text-[10px] uppercase font-bold text-text-muted">Backup Version</span>
                          <span className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center ${
                            choice === 'backup' ? 'border-color-accent-purple bg-color-accent-purple' : 'border-border-medium'
                          }`}>
                            {choice === 'backup' && <span className="w-1.5 h-1.5 rounded-full bg-white" />}
                          </span>
                        </div>
                        <p className="text-[11px] font-bold text-text-main mt-1.5 line-clamp-2">{conflict.backup.summary}</p>
                        <p className="text-[9px] text-text-muted mt-1 font-semibold">
                          Modified: {new Date(conflict.backup.updatedAt).toLocaleDateString()}
                        </p>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="flex gap-3 mt-5">
              <button
                type="button"
                onClick={() => setIsConflictModalOpen(false)}
                className="flex-1 py-2.5 btn-tactile-dark font-bold text-sm transition-all cursor-pointer"
              >
                {t('cancel')}
              </button>
              <button
                type="button"
                onClick={() => performImport(resolutions)}
                disabled={reasonLoading}
                className="flex-1 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50"
              >
                {reasonLoading ? t('loadingAction') : t('resolveAndImport')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Profile;