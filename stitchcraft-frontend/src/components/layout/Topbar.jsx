import React from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useNavigate } from 'react-router-dom';
import {
  MdSearch, MdMenu, MdWbSunny, MdNightsStay,
  MdNotifications, MdCheck, MdDrafts, MdInfo,
  MdReceipt, MdLocalShipping, MdPerson
} from 'react-icons/md';
import { useLanguage } from '../../context/LanguageContext';
import { useTheme } from '../../context/ThemeContext';
import ProfileImage from '../../assets/profile.png';
import { useState, useEffect } from 'react';
import { getSignedUrl } from '../../services/supabase';
import { api } from '../../services/api';
import { formatDate } from '../../utils/formatters';

export const Topbar = ({ pageTitle = 'Dashboard', onMenuToggle }) => {
  const { user } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const { language, changeLanguage, t } = useLanguage();
  const navigate = useNavigate();
  const [avatarUrl, setAvatarUrl] = useState(ProfileImage);
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const handleResize = () => setIsMobile(window.innerWidth < 640);
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  useEffect(() => {
    const loadAvatar = async () => {
      if (user?.avatar && user.avatar !== 'profile.png') {
        const url = await getSignedUrl('profile-images', user.avatar);
        if (url) setAvatarUrl(url);
      } else {
        setAvatarUrl(ProfileImage); // Fallback to initials
      }
    };
    loadAvatar();
  }, [user]);

  // Notifications state and functions
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [showDropdown, setShowDropdown] = useState(false);
  const [loadingNotifications, setLoadingNotifications] = useState(false);

  const fetchNotifications = async () => {
    setLoadingNotifications(true);
    try {
      const data = await api.get('/notifications');
      setNotifications(data || []);
      setUnreadCount((data || []).filter(n => !n.read).length);
    } catch (err) {
      console.error('Failed to fetch notifications in topbar:', err);
    } finally {
      setLoadingNotifications(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
    const interval = setInterval(fetchNotifications, 30000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (!showDropdown) return;
    const handleDocumentClick = (e) => {
      const dropdownEl = document.getElementById('notification-dropdown-container');
      if (dropdownEl && !dropdownEl.contains(e.target)) {
        setShowDropdown(false);
      }
    };
    document.addEventListener('click', handleDocumentClick);
    return () => document.removeEventListener('click', handleDocumentClick);
  }, [showDropdown]);

  const handleMarkAllRead = async (e) => {
    e.stopPropagation();
    try {
      await api.put('/notifications/mark-read');
      fetchNotifications();
    } catch (err) {
      console.error('Failed to mark all read in topbar:', err);
    }
  };

  const handleMarkSingleRead = async (id, e) => {
    e.stopPropagation();
    try {
      await api.put(`/notifications/${id}/read`);
      setNotifications(prev =>
        prev.map(n => n._id === id ? { ...n, read: true } : n)
      );
      setUnreadCount(prev => Math.max(0, prev - 1));
    } catch (err) {
      console.error('Failed to mark read in topbar:', err);
    }
  };

  const getNotificationIcon = (message) => {
    const msg = message.toLowerCase();
    if (msg.includes('payment') || msg.includes('₹')) {
      return <MdReceipt className="w-4 h-4 text-color-accent-emerald animate-pulse" />;
    } else if (msg.includes('deliver')) {
      return <MdLocalShipping className="w-4 h-4 text-color-accent-blue" />;
    } else if (msg.includes('customer') || msg.includes('profile')) {
      return <MdPerson className="w-4 h-4 text-color-accent-pink" />;
    }
    return <MdInfo className="w-4 h-4 text-color-accent-purple" />;
  };

  const getRelativeTime = (dateString) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now - date;
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHr = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHr / 24);

    if (diffSec < 60) return 'Just now';
    if (diffMin < 60) return `${diffMin}m ago`;
    if (diffHr < 24) return `${diffHr}h ago`;
    if (diffDay === 1) return 'Yesterday';
    return formatDate(dateString);
  };

  return (
    <div className="h-[80px] px-4 sm:px-8 border-b border-border-subtle flex items-center justify-between bg-bg-secondary select-none print-hidden-element">
      {/* Title & Mobile Toggle */}
      <div className="flex items-center">
        <button
          onClick={onMenuToggle}
          className="lg:hidden p-2 rounded-lg topbar-icon-btn hover:bg-bg-hover border border-border-subtle text-text-muted hover:text-text-main transition-all cursor-pointer mr-3"
          title="Toggle Navigation"
        >
          <MdMenu className="w-5 h-5" />
        </button>
        <h2 className="text-sm sm:text-xl font-bold text-text-main tracking-wide truncate max-w-[100px] sm:max-w-none">{pageTitle}</h2>
      </div>

      {/* Center Search bar */}
      <div className="hidden sm:block w-full max-w-[200px] md:max-w-[380px] mx-4 relative">
        <input
          type="text"
          placeholder={t('searchPlaceholder')}
          className="w-full bg-bg-input border border-border-subtle text-xs sm:text-sm rounded-lg px-4 py-2.5 pl-11 text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple transition-all duration-200"
        />
        <MdSearch className="w-4 h-4 sm:w-5 sm:h-5 text-text-muted absolute left-4 top-1/2 transform -translate-y-1/2" />
      </div>

      {/* Right widgets */}
      <div className="flex items-center gap-1.5 sm:gap-6">
        {/* Language Switcher */}
        <div className="flex items-center gap-1 bg-bg-primary border border-border-subtle rounded-xl px-2 py-1 sm:px-2.5 sm:py-1.5 shadow-sm">
          <select
            value={language}
            onChange={(e) => changeLanguage(e.target.value)}
            className="bg-transparent text-[10px] sm:text-xs font-bold text-text-main outline-none cursor-pointer"
          >
            <option value="en" className="bg-bg-card">{isMobile ? 'EN' : 'English (EN)'}</option>
            <option value="gu" className="bg-bg-card">{isMobile ? 'GU' : 'ગુજરાતી (GU)'}</option>
            <option value="hi" className="bg-bg-card">{isMobile ? 'HI' : 'हिन्दी (HI)'}</option>
          </select>
        </div>

        {/* Theme Toggle Button */}
        <button
          onClick={toggleTheme}
          className="w-9 h-9 rounded-xl hover:bg-bg-hover flex items-center justify-center border border-border-subtle text-text-muted hover:text-text-main transition-all cursor-pointer bg-bg-primary shadow-sm"
          title={`Switch to ${theme === 'light' ? 'Dark' : 'Light'} Mode`}
        >
          {theme === 'light' ? (
            <MdWbSunny className="w-5 h-5 text-amber-500" />
          ) : (
            <MdNightsStay className="w-5 h-5 text-purple-400" />
          )}
        </button>

        {/* Notifications Icon & Dropdown */}
        <div id="notification-dropdown-container" className="relative flex items-center">
          <button
            onClick={() => setShowDropdown(prev => !prev)}
            className="w-9 h-9 rounded-xl hover:bg-bg-hover flex items-center justify-center border border-border-subtle text-text-muted hover:text-text-main transition-all cursor-pointer bg-bg-primary shadow-sm relative"
            title="Notifications"
          >
            <MdNotifications className={`w-5 h-5 ${unreadCount > 0 ? 'text-color-accent-pink animate-pulse' : ''}`} />
            {unreadCount > 0 && (
              <span className="absolute -top-1 -right-1 min-w-4 h-4 bg-color-accent-pink text-white-forced rounded-full text-[9px] font-black flex items-center justify-center px-1 border border-bg-secondary shadow-md">
                {unreadCount}
              </span>
            )}
          </button>

          {showDropdown && (
            <div className="absolute right-[-60px] sm:right-0 top-11 w-[290px] sm:w-[360px] bg-bg-modal border border-border-medium rounded-2xl shadow-2xl z-50 overflow-hidden text-left flex flex-col transition-all duration-200">
              {/* Header */}
              <div className="px-4 py-3 border-b border-border-subtle flex items-center justify-between bg-bg-secondary/30">
                <div className="flex items-center gap-2">
                  <span className="text-xs sm:text-sm font-black text-text-main">Notifications</span>
                  {unreadCount > 0 && (
                    <span className="px-1.5 py-0.5 rounded-md bg-color-accent-purple/15 text-color-accent-purple text-[9px] font-black">
                      {unreadCount} New
                    </span>
                  )}
                </div>
                {unreadCount > 0 && (
                  <button
                    onClick={handleMarkAllRead}
                    className="text-[10px] sm:text-xs font-bold text-color-accent-purple hover:underline cursor-pointer flex items-center gap-1"
                  >
                    <MdDrafts className="w-3.5 h-3.5" />
                    <span>Mark all read</span>
                  </button>
                )}
              </div>

              {/* List */}
              <div className="max-h-72 overflow-y-auto divide-y divide-border-subtle">
                {loadingNotifications && notifications.length === 0 ? (
                  <div className="py-8 text-center text-xs text-text-muted font-semibold">
                    Loading updates...
                  </div>
                ) : notifications.length === 0 ? (
                  <div className="py-10 flex flex-col items-center justify-center text-center px-4">
                    <MdNotifications className="w-8 h-8 text-text-muted/40 mb-2" />
                    <p className="text-xs font-bold text-text-main">All caught up!</p>
                    <p className="text-[10px] text-text-muted mt-0.5">No notifications recorded.</p>
                  </div>
                ) : (
                  notifications.slice(0, 5).map(n => (
                    <div
                      key={n._id}
                      onClick={() => {
                        if (!n.read) handleMarkSingleRead(n._id, { stopPropagation: () => { } });
                      }}
                      className={`p-3 sm:p-4 hover:bg-bg-hover/40 transition-colors flex items-start gap-3 cursor-pointer ${n.read ? 'opacity-70' : 'bg-color-accent-purple/5'
                        }`}
                    >
                      <div className="p-2 rounded-xl bg-bg-secondary border border-border-subtle flex items-center justify-center shrink-0">
                        {getNotificationIcon(n.message)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <p className={`text-xs leading-normal ${n.read ? 'text-text-muted' : 'text-text-main font-bold'}`}>
                            {n.message}
                          </p>
                          {!n.read && (
                            <span className="w-1.5 h-1.5 rounded-full bg-color-accent-pink shrink-0 mt-1.5" />
                          )}
                        </div>
                        <div className="flex items-center gap-2 mt-1.5">
                          <span className="text-[9px] text-text-muted font-bold">
                            {getRelativeTime(n.createdAt)}
                          </span>
                          {!n.read && (
                            <button
                              onClick={(e) => handleMarkSingleRead(n._id, e)}
                              className="text-[9px] text-color-accent-purple font-bold hover:underline"
                            >
                              Mark read
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* Footer */}
              <div className="p-2 bg-bg-secondary/20 border-t border-border-subtle text-center">
                <button
                  onClick={() => {
                    setShowDropdown(false);
                    navigate('/notifications');
                  }}
                  className="w-full py-1.5 text-xs font-bold text-color-accent-purple hover:bg-bg-hover rounded-lg transition-colors cursor-pointer flex items-center justify-center gap-1 border-0 outline-none"
                >
                  <span>See all notifications</span>
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Divider */}
        <div className="h-6 sm:h-8 w-[1px] bg-border-subtle" />

        {/* Profile info - clickable */}
        <button
          onClick={() => navigate('/profile')}
          className="flex items-center gap-2 sm:gap-3 group cursor-pointer text-left"
          title="View Profile"
        >
          <div className="text-right hidden sm:block">
            <h4 className="text-xs sm:text-sm font-bold text-text-main group-hover:text-color-accent-purple transition-colors">
              {user?.name || 'Masterji Ramesh'}
            </h4>
            <span className="text-[10px] sm:text-xs font-semibold text-text-muted capitalize">
              {user?.role?.toLowerCase() === 'owner' ? t('roleOwner') : (user?.role || t('roleOwner'))}
            </span>
          </div>

          <div className="w-9 h-9 sm:w-11 sm:h-11 rounded-full overflow-hidden border-2 border-border-medium group-hover:border-color-accent-purple/60 bg-bg-card flex items-center justify-center shadow-md transition-all">
            {/* HERE IS THE FIX: Use avatarUrl instead of user.avatar */}
            <img
              src={avatarUrl || ProfileImage}
              alt="Profile"
              className="w-full h-full object-cover"
              onError={() => setImageError(true)}
            />
          </div>
        </button>
      </div>
    </div>
  );
};

export default Topbar;
