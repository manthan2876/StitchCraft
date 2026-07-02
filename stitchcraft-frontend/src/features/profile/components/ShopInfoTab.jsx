/* src/features/profile/components/ShopInfoTab.jsx */
import React from 'react';
import Card from '../../../components/common/Card';
import { MdAdd, MdStorefront, MdCheck, MdEdit, MdDelete } from 'react-icons/md';

export const ShopInfoTab = ({
  shops,
  shopsLoading,
  user,
  handleOpenCreateShopModal,
  handleSwitchShop,
  handleOpenEditShopModal,
  setDeleteTargetShop,
  t,
}) => {
  return (
    <div className="flex flex-col gap-6">
      <Card className="flex flex-col gap-5">
        <div className="flex items-center justify-between border-b border-border-subtle pb-4">
          <div>
            <h3 className="text-base font-bold text-text-main">{t('shopsManager')}</h3>
            <p className="text-xs text-text-muted mt-0.5">{t('shopsManagerSub')}</p>
          </div>
          <button
            onClick={handleOpenCreateShopModal}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-color-accent-purple hover:bg-color-accent-purple/90 text-white-forced font-bold rounded-xl text-xs shadow-lg transition-all cursor-pointer"
          >
            <MdAdd className="w-4 h-4 text-white-forced" />
            <span>{t('newShop')}</span>
          </button>
        </div>

        {shopsLoading ? (
          <div className="text-center py-8 text-xs text-text-muted">{t('syncing')}</div>
        ) : shops.length === 0 ? (
          <div className="text-center py-8 text-xs text-text-muted">{t('noRecords')}</div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {shops.map(shop => {
              const isActive = user?.shopId === shop._id;
              return (
                <div
                  key={shop._id}
                  className={`p-5 rounded-2xl border transition-all flex flex-col gap-4 text-left relative overflow-hidden
                    ${isActive
                      ? 'shop-active-card shadow-lg shadow-color-accent-purple/5'
                      : 'border-border-subtle bg-bg-secondary hover:border-border-medium'}`}
                >
                  {isActive && (
                    <div className="absolute right-4 top-4 px-2 py-0.5 text-[8px] font-black uppercase tracking-wider bg-color-accent-purple text-white-forced rounded-md border border-color-accent-purple/40">
                      {t('activeSession')}
                    </div>
                  )}

                  <div className="flex items-start gap-3">
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0
                      ${isActive ? 'bg-color-accent-purple/20 text-color-accent-purple' : 'bg-bg-hover text-text-muted'}`}
                    >
                      <MdStorefront className="w-5 h-5" />
                    </div>
                    <div className="min-w-0 pr-12">
                      <h4 className="text-sm font-bold text-text-main truncate">{shop.shopName}</h4>
                      <span className="text-[10px] font-extrabold uppercase tracking-widest text-[#007aff]">
                        {t((shop.plan || 'Free').toLowerCase() + 'Plan')}
                      </span>
                    </div>
                  </div>

                  <div className="flex flex-col gap-1 text-xs text-text-muted border-t border-border-subtle pt-3">
                    {shop.phone && <span className="truncate">📞 {shop.phone}</span>}
                    {shop.address && <span className="truncate">📍 {shop.address}</span>}
                  </div>

                  <div className="flex items-center gap-2 border-t border-border-subtle pt-3 mt-auto">
                    {!isActive ? (
                      <button
                        onClick={() => handleSwitchShop(shop._id)}
                        className="flex-1 py-1.5 bg-bg-card hover:bg-bg-card-hover text-text-main rounded-xl text-[10px] font-extrabold transition-all cursor-pointer border border-border-subtle hover:border-color-accent-purple/40"
                      >
                        {t('switchActive')}
                      </button>
                    ) : (
                      <span className="flex-1 text-[10px] text-color-accent-emerald font-black flex items-center gap-1">
                        <MdCheck className="w-3.5 h-3.5" />
                        <span>{t('currentlyActive')}</span>
                      </span>
                    )}
                    <button
                      onClick={() => handleOpenEditShopModal(shop)}
                      className="px-2.5 py-1.5 bg-bg-hover hover:bg-border-medium text-text-main rounded-xl text-[10px] font-bold transition-all cursor-pointer border border-border-subtle"
                      title={t('editDetails')}
                    >
                      <MdEdit className="w-3.5 h-3.5 text-color-accent-purple" />
                    </button>
                    <button
                      onClick={() => setDeleteTargetShop(shop)}
                      className="px-2.5 py-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-500 rounded-xl text-[10px] font-bold transition-all cursor-pointer border border-rose-500/10"
                      title={t('deleteShop')}
                    >
                      <MdDelete className="w-3.5 h-3.5 text-color-accent-pink" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </Card>
    </div>
  );
};

export default ShopInfoTab;
