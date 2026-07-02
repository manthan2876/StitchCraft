/* src/features/profile/components/SettingsTab.jsx */
import React from 'react';
import Card from '../../../components/common/Card';
import { MdNotifications, MdPalette, MdCloudDownload, MdCloudUpload, MdDelete } from 'react-icons/md';

export const SettingsTab = ({
  settings,
  setSettings,
  theme,
  toggleTheme,
  language,
  changeLanguage,
  handleActionClick,
  t,
}) => {
  return (
    <Card className="flex flex-col gap-5">
      <div className="border-b border-border-subtle pb-4">
        <h3 className="text-base font-bold text-text-main">{t('preferences')}</h3>
        <p className="text-xs text-text-muted mt-0.5">{t('preferencesSub')}</p>
      </div>

      {/* App Preferences */}
      <div className="flex flex-col gap-3">
        <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider flex items-center gap-1">
          <MdNotifications className="w-3.5 h-3.5 text-color-accent-purple" /> {t('appPreferences')}
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

      {/* Dashboard Customization */}
      <div className="flex flex-col gap-3">
        <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider flex items-center gap-1">
          <MdNotifications className="w-3.5 h-3.5 text-color-accent-purple" /> {t('dashboardCustomization')}
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

      {/* Display Settings */}
      <div className="flex flex-col gap-3">
        <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider flex items-center gap-1">
          <MdPalette className="w-3.5 h-3.5 text-color-accent-purple" /> {t('display')}
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

      {/* Account Actions */}
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
  );
};

export default SettingsTab;
