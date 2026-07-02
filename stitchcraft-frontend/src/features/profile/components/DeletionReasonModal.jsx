/* src/features/profile/components/DeletionReasonModal.jsx */
import React from 'react';
import { MdClose, MdDelete } from 'react-icons/md';

export const DeletionReasonModal = ({
  isOpen,
  deletionReason,
  setDeletionReason,
  reasonLoading,
  handleDeletionReasonSubmit,
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
              onClick={onClose}
              className="flex-1 py-2.5 bg-bg-secondary border border-border-subtle hover:bg-bg-hover text-text-main font-bold text-sm transition-all cursor-pointer rounded-xl"
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
  );
};

export default DeletionReasonModal;
