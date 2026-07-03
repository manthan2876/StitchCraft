import React from 'react';
import { MdClose, MdDelete } from 'react-icons/md';

export const InventoryDeleteModal = ({
  deleteTarget,
  onClose,
  deleteLoading,
  deleteError,
  onSubmit,
  tf,
}) => {
  if (!deleteTarget) return null;

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
          {tf('deleteMaterial', 'Delete Material')}
        </h3>
        <p className="text-xs text-text-muted mb-4 font-semibold">
          {tf('deleteMaterialConfirm', 'Are you sure you want to permanently delete')} <span className="text-text-main font-bold">{deleteTarget.itemName}</span>?
        </p>

        {deleteError && (
          <span className="text-xs text-color-accent-pink font-bold text-center block mb-4 animate-pulse">
            {deleteError}
          </span>
        )}

        <div className="flex gap-3">
          <button
            type="button"
            onClick={onClose}
            className="flex-1 py-2.5 btn-tactile-dark font-bold text-sm transition-all cursor-pointer"
          >
            {tf('cancel', 'Cancel')}
          </button>
          <button
            onClick={onSubmit}
            disabled={deleteLoading}
            className="flex-1 py-2.5 bg-rose-600 hover:bg-rose-700 text-white-forced rounded-xl font-bold text-sm shadow-lg transition-all cursor-pointer disabled:opacity-50"
          >
            {deleteLoading ? tf('saving', 'Saving...') : tf('deleteMaterial', 'Delete Material')}
          </button>
        </div>
      </div>
    </div>
  );
};
