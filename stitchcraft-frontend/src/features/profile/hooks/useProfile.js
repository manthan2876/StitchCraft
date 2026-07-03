/* src/features/profile/hooks/useProfile.js */
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../../hooks/useAuth';
import { useTheme } from '../../../context/ThemeContext';
import { useLanguage } from '../../../context/LanguageContext';
import { api } from '../../../services/api';
import { uploadToPrivateBucket, getSignedUrl } from '../../../services/supabase';
import ProfileImage from '../../../assets/profile.png';

export const useProfile = () => {
  const { user, logout, updateUser } = useAuth();
  const navigate = useNavigate();
  const { language, changeLanguage, t } = useLanguage();
  const { theme, toggleTheme } = useTheme();

  const [activeTab, setActiveTab] = useState('Profile');
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  // null means no real avatar — UI should show initials
  const [avatarUrl, setAvatarUrl] = useState(null);

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

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  useEffect(() => {
    const loadAvatar = async () => {
      if (!user?.avatar || user.avatar === 'profile.png') {
        setAvatarUrl(null); // no real photo — show initials
        return;
      }
      // If it's already a full URL (e.g. stored from a previous version), use it directly
      if (user.avatar.startsWith('http')) {
        setAvatarUrl(user.avatar);
        return;
      }
      const url = await getSignedUrl('profile-images', user.avatar);
      setAvatarUrl(url || null);
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

    setShopModalLoading(true);
    try {
      const path = await uploadToPrivateBucket('profile-images', file);
      const data = await api.put('/auth/profile', { avatar: path });
      updateUser(data);
      // Immediately refresh the signed URL so the new photo shows without reload
      const freshUrl = await getSignedUrl('profile-images', path);
      setAvatarUrl(freshUrl || null);
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
        if (user.shopId === selectedShop._id) {
          const profile = await api.get('/auth/profile');
          updateUser(profile);
        }
      }
      setIsShopModalOpen(false);
    } catch (err) {
      setShopError(err.message || 'Failed to save shop details.');
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

        await api.post('/auth/verify-password', { password: privacyPassword });
        setIsPrivacyModalOpen(false);

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

  const tabKeys = ['Profile', 'Shop Info', 'Settings', 'Change Password'];
  const getTabLabel = (key) => {
    if (key === 'Profile') return t('profile');
    if (key === 'Shop Info') return t('shopsManager');
    if (key === 'Settings') return t('settings');
    if (key === 'Change Password') return t('changePassword');
    return key;
  };

  return {
    user,
    language,
    changeLanguage,
    t,
    theme,
    toggleTheme,
    activeTab,
    setActiveTab,
    isEditingProfile,
    setIsEditingProfile,
    avatarUrl,
    passwordForm,
    setPasswordForm,
    passwordError,
    passwordSuccess,
    passwordLoading,
    privacyAction,
    privacyPassword,
    setPrivacyPassword,
    isPrivacyModalOpen,
    setIsPrivacyModalOpen,
    privacyError,
    privacyLoading,
    isReasonModalOpen,
    setIsReasonModalOpen,
    deletionReason,
    setDeletionReason,
    reasonLoading,
    conflictsList,
    resolutions,
    setResolutions,
    shops,
    shopsLoading,
    isShopModalOpen,
    setIsShopModalOpen,
    shopModalMode,
    shopForm,
    setShopForm,
    shopError,
    setShopError,
    shopModalLoading,
    deleteTargetShop,
    setDeleteTargetShop,
    deleteShopLoading,
    deleteShopError,
    handleActionClick,
    handleFileChange,
    performImport,
    handlePrivacyPasswordSubmit,
    handleDeletionReasonSubmit,
    handlePasswordSubmit,
    handleLogout,
    handleAvatarChange,
    handleSwitchShop,
    handleOpenCreateShopModal,
    handleOpenEditShopModal,
    handleShopFormSubmit,
    handleDeleteShopSubmit,
    tabKeys,
    getTabLabel,
  };
};

export default useProfile;
