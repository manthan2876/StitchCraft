/* src/features/profile/components/DataConflictModal.jsx */
import React from 'react';
import { MdClose, MdSecurity } from 'react-icons/md';

export const DataConflictModal = ({
  isConflictModalOpen,
  setIsConflictModalOpen,
  conflictsList,
  resolutions,
  setResolutions,
  performImport,
  reasonLoading,
  t,
}) => {
  if (!isConflictModalOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
      <div className="w-full max-w-[600px] max-h-[90vh] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left flex flex-col">
        <button
          onClick={() => setIsConflictModalOpen(false)}
          className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
        >
          <MdClose className="w-5 h-5" />
        </button>

        <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-2">
          <MdSecurity className="text-color-accent-purple w-5 h-5" />
          {t('conflictResolutionTitle')}
        </h3>
        <p className="text-xs text-text-muted mb-4 font-semibold">
          {t('conflictResolutionDesc')}
        </p>

        {/* Bulk Selection Helpers */}
        <div className="flex gap-3 mb-4">
          <button
            type="button"
            onClick={() => {
              const bulk = {};
              conflictsList.forEach(c => { bulk[c._id] = 'database'; });
              setResolutions(bulk);
            }}
            className="flex-1 py-1.5 bg-bg-secondary border border-border-subtle rounded-xl text-xs font-bold text-text-main hover:bg-bg-hover transition-all cursor-pointer text-center"
          >
            {t('selectAllExisting')}
          </button>
          <button
            type="button"
            onClick={() => {
              const bulk = {};
              conflictsList.forEach(c => { bulk[c._id] = 'backup'; });
              setResolutions(bulk);
            }}
            className="flex-1 py-1.5 bg-bg-secondary border border-border-subtle rounded-xl text-xs font-bold text-text-main hover:bg-bg-hover transition-all cursor-pointer text-center"
          >
            {t('selectAllBackup')}
          </button>
        </div>

        {/* Scrollable list of conflicts */}
        <div className="flex-1 overflow-y-auto pr-1 flex flex-col gap-3 max-h-[50vh]">
          {conflictsList.map(conflict => {
            const choice = resolutions[conflict._id] || 'database';
            return (
              <div key={conflict._id} className="border border-border-subtle rounded-xl p-3 flex flex-col gap-2 bg-bg-secondary/40">
                <div className="flex justify-between items-center border-b border-border-subtle pb-1.5">
                  <span className="text-xs font-bold text-text-main">{conflict.name}</span>
                  <span className="text-[10px] uppercase font-black px-2 py-0.5 rounded-md bg-color-accent-purple/15 text-color-accent-purple">
                    {conflict.model}
                  </span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-1">
                  {/* Database option */}
                  <div
                    onClick={() => setResolutions(prev => ({ ...prev, [conflict._id]: 'database' }))}
                    className={`border rounded-xl p-3 cursor-pointer transition-all flex flex-col justify-between ${
                      choice === 'database'
                        ? 'bg-color-accent-purple/5 border-color-accent-purple'
                        : 'bg-bg-input border-border-medium hover:border-border-medium/80'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] uppercase font-bold text-text-muted">Database Version</span>
                      <span className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center ${
                        choice === 'database' ? 'border-color-accent-purple bg-color-accent-purple' : 'border-border-medium'
                      }`}>
                        {choice === 'database' && <span className="w-1.5 h-1.5 rounded-full bg-white" />}
                      </span>
                    </div>
                    <p className="text-[11px] font-bold text-text-main mt-1.5 line-clamp-2">{conflict.existing.summary}</p>
                    <p className="text-[9px] text-text-muted mt-1 font-semibold">
                      Modified: {new Date(conflict.existing.updatedAt).toLocaleDateString()}
                    </p>
                  </div>

                  {/* Backup option */}
                  <div
                    onClick={() => setResolutions(prev => ({ ...prev, [conflict._id]: 'backup' }))}
                    className={`border rounded-xl p-3 cursor-pointer transition-all flex flex-col justify-between ${
                      choice === 'backup'
                        ? 'bg-color-accent-purple/5 border-color-accent-purple'
                        : 'bg-bg-input border-border-medium hover:border-border-medium/80'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] uppercase font-bold text-text-muted">Backup Version</span>
                      <span className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center ${
                        choice === 'backup' ? 'border-color-accent-purple bg-color-accent-purple' : 'border-border-medium'
                      }`}>
                        {choice === 'backup' && <span className="w-1.5 h-1.5 rounded-full bg-white" />}
                      </span>
                    </div>
                    <p className="text-[11px] font-bold text-text-main mt-1.5 line-clamp-2">{conflict.backup.summary}</p>
                    <p className="text-[9px] text-text-muted mt-1 font-semibold">
                      Modified: {new Date(conflict.backup.updatedAt).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        <div className="flex gap-3 mt-5">
          <button
            type="button"
            onClick={() => setIsConflictModalOpen(false)}
            className="flex-1 py-2.5 bg-bg-secondary border border-border-subtle hover:bg-bg-hover text-text-main font-bold text-sm transition-all cursor-pointer rounded-xl"
          >
            {t('cancel')}
          </button>
          <button
            type="button"
            onClick={() => performImport(resolutions)}
            disabled={reasonLoading}
            className="flex-1 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50"
          >
            {reasonLoading ? t('loadingAction') : t('resolveAndImport')}
          </button>
        </div>
      </div>
    </div>
  );
};

export default DataConflictModal;
