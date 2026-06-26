/* src/pages/Notifications.jsx */
import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import Card from '../components/common/Card';
import { useLanguage } from '../context/LanguageContext';
import { formatDate } from '../utils/formatters';
import { MdNotifications, MdCheck, MdDrafts, MdInfo, MdReceipt, MdLocalShipping, MdPerson } from 'react-icons/md';

export const Notifications = () => {
  const { t } = useLanguage();
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(false);

  // Helper with fallbacks for translations
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const fetchNotifications = async () => {
    setLoading(true);
    try {
      const data = await api.get('/notifications');
      setNotifications(data);
    } catch (err) {
      console.error('Failed to fetch notifications:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
  }, []);

  const handleMarkAllRead = async () => {
    try {
      await api.put('/notifications/mark-read');
      fetchNotifications();
    } catch (err) {
      console.error('Failed to mark all read:', err);
    }
  };

  const handleMarkSingleRead = async (id) => {
    try {
      await api.put(`/notifications/${id}/read`);
      setNotifications(prev =>
        prev.map(n => n._id === id ? { ...n, read: true } : n)
      );
    } catch (err) {
      console.error('Failed to mark read:', err);
    }
  };

  const getNotificationIcon = (message) => {
    const msg = message.toLowerCase();
    if (msg.includes('payment') || msg.includes('₹')) {
      return <MdReceipt className="w-5 h-5 text-color-accent-emerald" />;
    } else if (msg.includes('deliver')) {
      return <MdLocalShipping className="w-5 h-5 text-color-accent-blue" />;
    } else if (msg.includes('customer') || msg.includes('profile')) {
      return <MdPerson className="w-5 h-5 text-color-accent-pink" />;
    }
    return <MdInfo className="w-5 h-5 text-color-accent-purple" />;
  };

  const unreadCount = notifications.filter(n => !n.read).length;

  return (
    <div className="flex flex-col gap-6 select-none max-w-4xl mx-auto text-left">

      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-text-main tracking-wide">{tf('notificationsFeed', 'Notifications Feed')}</h2>
          <p className="text-xs text-text-muted mt-0.5 font-semibold">
            {tf('notificationsSub', 'Real-time tailor orders tracking alerts and journal logs')}
          </p>
        </div>
        {unreadCount > 0 && (
          <button
            onClick={handleMarkAllRead}
            className="px-4 py-2 bg-bg-secondary border border-border-subtle hover:border-border-medium text-text-main rounded-xl text-xs font-bold flex items-center gap-1.5 cursor-pointer hover:bg-bg-primary transition-all duration-200 self-start sm:self-auto"
          >
            <MdDrafts className="w-4 h-4 text-color-accent-purple" />
            <span>{tf('markAllRead', 'Mark All Read')}</span>
          </button>
        )}
      </div>

      {/* Notifications List */}
      <div className="flex flex-col gap-4">
        {loading && notifications.length === 0 ? (
          <div className="text-center py-12 text-sm text-text-muted">
            {tf('syncingNotifications', 'Syncing notifications...')}
          </div>
        ) : notifications.length === 0 ? (
          <Card className="flex flex-col items-center justify-center py-12 text-center">
            <div className="w-12 h-12 rounded-full bg-bg-hover flex items-center justify-center text-text-muted mb-3">
              <MdNotifications className="w-6 h-6" />
            </div>
            <h4 className="text-sm font-bold text-text-main">{tf('inboxClean', 'Inbox Clean')}</h4>
            <p className="text-xs text-text-muted mt-1 font-semibold">{tf('noNotifications', 'No notifications recorded today.')}</p>
          </Card>
        ) : (
          notifications.map((n) => (
            <Card
              key={n._id}
              className={`flex items-start gap-4 transition-all duration-300 border
                ${n.read
                  ? 'border-border-subtle bg-bg-secondary/40 opacity-70'
                  : 'border-color-accent-purple/20 bg-bg-secondary'}`}
            >
              {/* Notification Icon */}
              <div className={`p-2.5 rounded-xl flex items-center justify-center shrink-0
                ${n.read ? 'bg-bg-hover' : 'bg-color-accent-purple/10'}`}
              >
                {getNotificationIcon(n.message)}
              </div>

              {/* Message Details */}
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-4 text-left">
                  <p className={`text-sm leading-relaxed ${n.read ? 'text-text-muted' : 'text-text-main font-bold'}`}>
                    {n.message}
                  </p>

                  {/* Status Indicator */}
                  {!n.read && (
                    <span className="w-2 h-2 rounded-full bg-color-accent-purple shrink-0 mt-1.5" title="Unread"></span>
                  )}
                </div>

                <div className="flex items-center gap-4 mt-2">
                  <span className="text-[10px] text-text-muted font-bold uppercase tracking-wider">
                    {formatDate(n.createdAt)}
                  </span>

                  {n.customerId && (
                    <span className="text-[10px] text-color-accent-pink font-bold">
                      👤 {n.customerId.name}
                    </span>
                  )}
                  {n.orderId && (
                    <span className="text-[10px] text-color-accent-blue font-mono font-black">
                      📦 {n.orderId.orderId}
                    </span>
                  )}
                </div>
              </div>

              {/* Individual Actions */}
              {!n.read && (
                <button
                  onClick={() => handleMarkSingleRead(n._id)}
                  className="p-1.5 rounded-lg bg-bg-hover hover:bg-border-medium border border-border-subtle hover:border-color-accent-purple/35 text-text-muted hover:text-text-main transition-all duration-200 cursor-pointer shrink-0"
                  title={tf('markAsRead', 'Mark as Read')}
                >
                  <MdCheck className="w-4 h-4 text-color-accent-emerald" />
                </button>
              )}
            </Card>
          ))
        )}
      </div>

    </div>
  );
};

export default Notifications;
