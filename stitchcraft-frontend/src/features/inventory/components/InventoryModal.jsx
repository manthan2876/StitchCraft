import React from 'react';
import { MdClose, MdInventory } from 'react-icons/md';

export const InventoryModal = ({
  isOpen,
  onClose,
  modalMode,
  selectedItem,
  form,
  setForm,
  formError,
  setFormError,
  formLoading,
  onSubmit,
  tf,
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
          <MdInventory className="text-color-accent-purple w-5 h-5" />
          {modalMode === 'add' ? tf('addInventoryItem', 'Add Inventory Item') : modalMode === 'edit' ? tf('editInventoryDetails', 'Edit Inventory Details') : tf('restockMaterial', 'Restock Material')}
        </h3>
        <p className="text-xs text-text-muted mb-5 font-semibold">
          {modalMode === 'add' 
            ? tf('addInventoryItemDesc', 'Register new materials to your workshop inventory.') 
            : modalMode === 'edit'
            ? tf('editInventoryDetailsDesc', 'Update material counts, units, and alert thresholds.')
            : tf('restockMaterialDesc', 'Add restocking quantities and record expense in ledger.')}
        </p>

        <form onSubmit={onSubmit} className="flex flex-col gap-4">
          {modalMode !== 'restock' && (
            <>
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('itemName', 'Item Name')}</label>
                <input
                  type="text"
                  required
                  value={form.itemName}
                  onChange={e => { setForm({ ...form, itemName: e.target.value }); setFormError(''); }}
                  placeholder={tf('itemNamePlaceholder', 'e.g. Silk, Velvet fabric, Cotton Thread')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('itemType', 'Item Type')}</label>
                <select
                  value={form.itemType}
                  onChange={e => setForm({ ...form, itemType: e.target.value })}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all cursor-pointer font-bold"
                >
                  <option value="Lining" className="bg-bg-card">{tf('lining', 'Lining / Astar')}</option>
                  <option value="Fabric" className="bg-bg-card">{tf('fabric', 'Fabric')}</option>
                  <option value="Thread" className="bg-bg-card">{tf('thread', 'Thread')}</option>
                  <option value="Accessories" className="bg-bg-card">{tf('accessories', 'Accessories / Trims')}</option>
                  <option value="Other" className="bg-bg-card">{tf('other', 'Other')}</option>
                </select>
              </div>
            </>
          )}

          {modalMode === 'restock' && (
            <div className="flex flex-col gap-1 bg-bg-secondary p-3 border border-border-subtle rounded-xl mb-2">
              <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('restockingItem', 'Restocking Item')}</span>
              <span className="text-sm font-black text-text-main mt-0.5">{selectedItem?.itemName}</span>
              <span className="text-[10px] text-text-muted mt-0.5">{tf('stockLevel', 'Stock Level')}: {selectedItem?.quantity} {tf(selectedItem?.unit, selectedItem?.unit)}</span>
            </div>
          )}

          {modalMode === 'restock' ? (
            <div className="flex flex-col gap-1">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('quantityToAdd', 'Quantity to Add')}</label>
              <input
                type="number"
                required
                min="0.01"
                step="any"
                value={form.quantityToAdd}
                onChange={e => setForm({ ...form, quantityToAdd: e.target.value })}
                placeholder={`e.g. 50 (in ${form.unit})`}
                className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all font-semibold"
              />
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-4">
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('quantity', 'Quantity')}</label>
                <input
                  type="number"
                  required
                  min="0"
                  step="any"
                  value={form.quantity}
                  onChange={e => setForm({ ...form, quantity: e.target.value })}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all font-semibold"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('unitType', 'Unit Type')}</label>
                <select
                  value={form.unit}
                  onChange={e => setForm({ ...form, unit: e.target.value })}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all cursor-pointer font-bold"
                >
                  <option value="meters" className="bg-bg-card">{tf('meters', 'Meters')}</option>
                  <option value="pieces" className="bg-bg-card">{tf('pieces', 'Pieces')}</option>
                  <option value="rolls" className="bg-bg-card">{tf('rolls', 'Rolls')}</option>
                  <option value="yards" className="bg-bg-card">{tf('yards', 'Yards')}</option>
                  <option value="packs" className="bg-bg-card">{tf('packs', 'Packs')}</option>
                </select>
              </div>
            </div>
          )}

          {modalMode !== 'restock' && (
            <>
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('minThresholdAlert', 'Min Threshold Alert')}</label>
                <input
                  type="number"
                  required
                  min="0"
                  value={form.minQuantity}
                  onChange={e => setForm({ ...form, minQuantity: e.target.value })}
                  placeholder="Low stock alert trigger (e.g. 10)"
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all font-semibold"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('costPerUnit', 'Cost Price per Unit (₹)')}</label>
                <input
                  type="number"
                  required
                  min="0"
                  value={form.costPerUnit}
                  onChange={e => setForm({ ...form, costPerUnit: e.target.value })}
                  placeholder={tf('costPerUnitPlaceholder', 'e.g. 30')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all font-semibold"
                />
              </div>
            </>
          )}

          {(modalMode === 'add' || modalMode === 'restock') && (
            <div className="grid grid-cols-2 gap-4">
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">
                  {modalMode === 'restock' ? tf('restockCost', 'Restock Cost (₹)') : tf('purchaseCost', 'Purchase Cost (₹)')}
                </label>
                <input
                  type="number"
                  min="0"
                  value={form.purchaseAmount}
                  onChange={e => setForm({ ...form, purchaseAmount: e.target.value })}
                  placeholder={tf('costPlaceholder', 'e.g. 1200')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all font-semibold"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('purchaseDescription', 'Description')}</label>
                <input
                  type="text"
                  value={form.description}
                  onChange={e => setForm({ ...form, description: e.target.value })}
                  placeholder={tf('descriptionPlaceholder', 'e.g. Supplier X roll')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all font-semibold"
                />
              </div>
            </div>
          )}

          {formError && (
            <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse">
              {formError}
            </span>
          )}

          <div className="flex gap-3 mt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2.5 btn-tactile-dark font-bold text-sm transition-all cursor-pointer"
            >
              {tf('cancel', 'Cancel')}
            </button>
            <button
              type="submit"
              disabled={formLoading}
              className="flex-1 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50"
            >
              {formLoading ? tf('saving', 'Saving...') : tf('save', 'Save')}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
