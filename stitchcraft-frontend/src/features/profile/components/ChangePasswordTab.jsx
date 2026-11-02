/* src/features/profile/components/ChangePasswordTab.jsx */
import React, { useState } from 'react';
import Card from '../../../components/common/Card';
import { MdVisibility, MdVisibilityOff } from 'react-icons/md';

export const ChangePasswordTab = ({
  passwordForm,
  setPasswordForm,
  passwordError,
  passwordFieldErrors = {},
  setPasswordFieldErrors = () => {},
  passwordSuccess,
  passwordLoading,
  handlePasswordSubmit,
  t,
}) => {
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  return (
    <Card className="flex flex-col gap-5">
      <div className="border-b border-border-subtle pb-4">
        <h3 className="text-base font-bold text-text-main">{t('changePassword')}</h3>
        <p className="text-xs text-text-muted mt-0.5">{t('changePasswordSub')}</p>
      </div>

      <form onSubmit={handlePasswordSubmit} className="flex flex-col gap-5">
        <div className="flex flex-col gap-1.5">
          <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('currentPassword')}</label>
          <div className="relative">
            <input
              type={showCurrentPassword ? 'text' : 'password'}
              required
              value={passwordForm.currentPassword}
              onChange={e => {
                setPasswordForm({ ...passwordForm, currentPassword: e.target.value });
                if (passwordFieldErrors.currentPassword) setPasswordFieldErrors(prev => ({ ...prev, currentPassword: '' }));
              }}
              placeholder={t('currentPassword')}
              className={`w-full px-4 pr-11 py-2.5 bg-bg-input border ${passwordFieldErrors.currentPassword ? 'border-color-accent-pink' : 'border-border-medium'} rounded-xl text-sm text-text-main outline-none focus:border-color-accent-purple transition-all placeholder:text-text-muted/50`}
            />
            <button
              type="button"
              onClick={() => setShowCurrentPassword(prev => !prev)}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-main transition-colors cursor-pointer"
              aria-label={showCurrentPassword ? "Hide password" : "Show password"}
            >
              {showCurrentPassword ? <MdVisibilityOff className="w-4.5 h-4.5" /> : <MdVisibility className="w-4.5 h-4.5" />}
            </button>
          </div>
          {passwordFieldErrors.currentPassword && (
            <span className="text-[11px] text-color-accent-pink font-semibold">{passwordFieldErrors.currentPassword}</span>
          )}
        </div>

        <div className="flex flex-col gap-1.5">
          <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('newPassword')}</label>
          <div className="relative">
            <input
              type={showNewPassword ? 'text' : 'password'}
              required
              value={passwordForm.newPassword}
              onChange={e => {
                setPasswordForm({ ...passwordForm, newPassword: e.target.value });
                if (passwordFieldErrors.newPassword) setPasswordFieldErrors(prev => ({ ...prev, newPassword: '' }));
              }}
              placeholder={t('newPassword')}
              className={`w-full px-4 pr-11 py-2.5 bg-bg-input border ${passwordFieldErrors.newPassword ? 'border-color-accent-pink' : 'border-border-medium'} rounded-xl text-sm text-text-main outline-none focus:border-color-accent-purple transition-all placeholder:text-text-muted/50`}
            />
            <button
              type="button"
              onClick={() => setShowNewPassword(prev => !prev)}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-main transition-colors cursor-pointer"
              aria-label={showNewPassword ? "Hide password" : "Show password"}
            >
              {showNewPassword ? <MdVisibilityOff className="w-4.5 h-4.5" /> : <MdVisibility className="w-4.5 h-4.5" />}
            </button>
          </div>
          {passwordFieldErrors.newPassword && (
            <span className="text-[11px] text-color-accent-pink font-semibold">{passwordFieldErrors.newPassword}</span>
          )}
        </div>

        <div className="flex flex-col gap-1.5">
          <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('confirmNewPassword')}</label>
          <div className="relative">
            <input
              type={showConfirmPassword ? 'text' : 'password'}
              required
              value={passwordForm.confirmNewPassword}
              onChange={e => {
                setPasswordForm({ ...passwordForm, confirmNewPassword: e.target.value });
                if (passwordFieldErrors.confirmNewPassword) setPasswordFieldErrors(prev => ({ ...prev, confirmNewPassword: '' }));
              }}
              placeholder={t('confirmNewPassword')}
              className={`w-full px-4 pr-11 py-2.5 bg-bg-input border ${passwordFieldErrors.confirmNewPassword ? 'border-color-accent-pink' : 'border-border-medium'} rounded-xl text-sm text-text-main outline-none focus:border-color-accent-purple transition-all placeholder:text-text-muted/50`}
            />
            <button
              type="button"
              onClick={() => setShowConfirmPassword(prev => !prev)}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-main transition-colors cursor-pointer"
              aria-label={showConfirmPassword ? "Hide password" : "Show password"}
            >
              {showConfirmPassword ? <MdVisibilityOff className="w-4.5 h-4.5" /> : <MdVisibility className="w-4.5 h-4.5" />}
            </button>
          </div>
          {passwordFieldErrors.confirmNewPassword && (
            <span className="text-[11px] text-color-accent-pink font-semibold">{passwordFieldErrors.confirmNewPassword}</span>
          )}
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
