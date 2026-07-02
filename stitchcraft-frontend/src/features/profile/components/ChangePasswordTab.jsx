/* src/features/profile/components/ChangePasswordTab.jsx */
import React from 'react';
import Card from '../../../components/common/Card';

export const ChangePasswordTab = ({
  passwordForm,
  setPasswordForm,
  passwordError,
  passwordSuccess,
  passwordLoading,
  handlePasswordSubmit,
  t,
}) => {
  return (
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
  );
};

export default ChangePasswordTab;
