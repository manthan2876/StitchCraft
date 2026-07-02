/* src/features/profile/components/ShopModal.jsx */
import React from 'react';
import { MdClose, MdStorefront } from 'react-icons/md';

export const ShopModal = ({
  isOpen,
  onClose,
  mode,
  shopForm,
  setShopForm,
  shopError,
  setShopError,
  shopModalLoading,
  handleShopFormSubmit,
  t,
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
      <div className="w-full max-w-[440px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
        <button
          onClick={onClose}
          className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
        >
          <MdClose className="w-5 h-5" />
        </button>

        <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-1">
          <MdStorefront className="text-color-accent-purple w-5 h-5" />
          {mode === 'create' ? t('createShop') : t('editShopDetails')}
        </h3>
        <p className="text-xs text-text-muted mb-5 font-semibold">
          {mode === 'create' ? t('createShopDesc') : t('editShopDetailsDesc')}
        </p>

        <form onSubmit={handleShopFormSubmit} className="flex flex-col gap-4">
          <div className="flex flex-col gap-1">
            <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('shopName')} *</label>
            <input
              type="text"
              required
              value={shopForm.shopName}
              onChange={e => { setShopForm({ ...shopForm, shopName: e.target.value }); setShopError(''); }}
              placeholder={t('shopName')}
              className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('contactPhone')}</label>
            <input
              type="tel"
              value={shopForm.phone}
              onChange={e => setShopForm({ ...shopForm, phone: e.target.value })}
              placeholder={t('contactPhone')}
              className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('address')}</label>
            <input
              type="text"
              value={shopForm.address}
              onChange={e => setShopForm({ ...shopForm, address: e.target.value })}
              placeholder={t('address')}
              className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('planTier')}</label>
            <select
              value={shopForm.plan}
              onChange={e => setShopForm({ ...shopForm, plan: e.target.value })}
              className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all cursor-pointer font-bold"
            >
              <option value="Free" className="bg-bg-card text-text-main">{t('freePlan')}</option>
              <option value="Basic" className="bg-bg-card text-text-main">{t('basicPlan')}</option>
              <option value="Premium" className="bg-bg-card text-text-main">{t('premiumPlan')}</option>
            </select>
          </div>

          {shopError && (
            <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse">
              {shopError}
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
              disabled={shopModalLoading}
              className="flex-1 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50"
            >
              {shopModalLoading ? t('saving') : t('saveDetails')}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ShopModal;
