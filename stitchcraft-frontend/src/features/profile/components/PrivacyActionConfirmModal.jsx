/* src/features/profile/components/PrivacyActionConfirmModal.jsx */
import React from 'react';
import { MdClose, MdSecurity } from 'react-icons/md';

export const PrivacyActionConfirmModal = ({
  isOpen,
  privacyAction,
  privacyPassword,
  setPrivacyPassword,
  privacyError,
  setPrivacyError,
  privacyLoading,
  handleFileChange,
  handlePrivacyPasswordSubmit,
  onClose,
  t,
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
      <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
        <button
          onClick={onClose}
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
              onClick={onClose}
              className="flex-1 py-2.5 bg-bg-secondary border border-border-subtle hover:bg-bg-hover text-text-main font-bold text-sm transition-all cursor-pointer rounded-xl"
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
  );
};

export default PrivacyActionConfirmModal;
