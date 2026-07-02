/* src/features/profile/components/DeleteShopModal.jsx */
import React from 'react';
import { MdClose, MdDelete } from 'react-icons/md';

export const DeleteShopModal = ({
  deleteTargetShop,
  onClose,
  deleteShopLoading,
  deleteShopError,
  handleDeleteShopSubmit,
  t,
}) => {
  if (!deleteTargetShop) return null;

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
            onClick={onClose}
            className="flex-1 py-2.5 bg-bg-secondary border border-border-subtle hover:bg-bg-hover text-text-main font-bold text-sm transition-all cursor-pointer rounded-xl"
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
  );
};

export default DeleteShopModal;
