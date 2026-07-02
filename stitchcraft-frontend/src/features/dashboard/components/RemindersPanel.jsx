/* src/features/dashboard/components/RemindersPanel.jsx */
import React from 'react';
import { Link } from 'react-router-dom';
import { MdNotificationsActive, MdArrowForward } from 'react-icons/md';
import Card from '../../../components/common/Card';
import { formatDate } from '../../../utils/formatters';

export const RemindersPanel = ({
  reminders = [],
  t,
}) => {
  return (
    <Card className="flex flex-col gap-4">
      <div className="flex items-center justify-between border-b border-border-subtle pb-3">
        <div>
          <h3 className="text-base font-bold text-text-main tracking-wide">{t('todayReminders')}</h3>
          <p className="text-xs text-text-muted mt-0.5">{t('todayRemindersSub')}</p>
        </div>
        <MdNotificationsActive className="w-5 h-5 text-color-accent-pink animate-pulse" />
      </div>

      <div className="flex flex-col gap-3">
        {reminders.length === 0 ? (
          <div className="text-xs text-text-muted text-center py-6">
            {t('noReminders')}
          </div>
        ) : (
          reminders.map((alert) => (
            <div
              key={alert._id}
              className="p-3 bg-bg-secondary border border-border-subtle rounded-xl flex items-start gap-3 hover:border-border-medium transition-colors"
            >
              <div className="w-1.5 h-1.5 rounded-full bg-color-accent-pink shrink-0 mt-1.5" />
              <div className="flex-1 min-w-0">
                <p className="text-xs text-text-main font-semibold leading-relaxed text-left">
                  {alert.message}
                </p>
                <span className="text-[9px] text-text-muted font-bold block mt-1 uppercase tracking-wider">
                  {formatDate(alert.createdAt)}
                </span>
              </div>
            </div>
          ))
        )}
      </div>

      <Link
        to="/notifications"
        className="mt-2 text-xs font-bold text-color-accent-purple hover:underline flex items-center justify-center gap-1"
      >
        <span>{t('viewFeed')}</span>
        <MdArrowForward className="w-3.5 h-3.5" />
      </Link>
    </Card>
  );
};

export default RemindersPanel;
