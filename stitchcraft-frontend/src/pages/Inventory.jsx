/* src/pages/Inventory.jsx */
import React from 'react';
import Card from '../components/common/Card';
import { formatCurrency } from '../utils/formatters';
import { MdSearch, MdClose, MdAdd, MdEdit, MdDelete } from 'react-icons/md';
import { useLanguage } from '../context/LanguageContext';
import { useInventory } from '../features/inventory/hooks/useInventory';
import { InventoryModal } from '../features/inventory/components/InventoryModal';
import { InventoryDeleteModal } from '../features/inventory/components/InventoryDeleteModal';

export const Inventory = () => {
  const { t } = useLanguage();

  // Translation helper with fallback
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const {
    items,
    loading,
    searchTerm,
    setSearchTerm,
    isModalOpen,
    setIsModalOpen,
    modalMode,
    selectedItem,
    form,
    setForm,
    formError,
    setFormError,
    formLoading,
    deleteTarget,
    setDeleteTarget,
    deleteLoading,
    deleteError,
    setDeleteError,
    handleOpenAddModal,
    handleOpenEditModal,
    handleOpenRestockModal,
    handleFormSubmit,
    handleDeleteSubmit,
  } = useInventory(tf);

  const getStatusBadge = (status) => {
    switch (status) {
      case 'In Stock':
        return 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20';
      case 'Low Stock':
        return 'bg-amber-500/10 text-amber-500 border border-amber-500/20';
      case 'Out of Stock':
        return 'bg-rose-500/10 text-rose-500 border border-rose-500/20';
      default:
        return 'bg-bg-hover text-text-muted border border-border-subtle';
    }
  };

  return (
    <div className="flex flex-col gap-6 select-none">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 text-left">
        <div>
          <h2 className="text-xl font-bold text-text-main tracking-wide">{tf('inventoryManager', 'Inventory Manager')}</h2>
          <p className="text-xs text-text-muted mt-0.5 font-semibold">
            {tf('inventorySub', 'Track raw fabrics, threads, trims, and tailoring materials')}
          </p>
        </div>
        <button
          onClick={handleOpenAddModal}
          className="btn-tactile flex items-center gap-2 self-start sm:self-auto cursor-pointer"
        >
          <MdAdd className="w-5 h-5 text-white-forced" />
          <span className="text-white-forced">{tf('addMaterial', 'Add Material')}</span>
        </button>
      </div>

      {/* Search Bar */}
      <Card className="py-3 px-4">
        <div className="relative">
          <MdSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted w-5 h-5" />
          <input
            type="text"
            placeholder={tf('searchPlaceholder', 'Search inventory items...')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-bg-input border border-border-subtle rounded-xl text-sm text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple/50 transition-all text-left"
          />
          {searchTerm && (
            <button
              onClick={() => setSearchTerm('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-4 h-4" />
            </button>
          )}
        </div>
      </Card>

      {/* Inventory Grid/Table */}
      <div className="bg-bg-secondary rounded-[20px] border border-border-subtle overflow-hidden shadow-card">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-bg-primary/30 border-b border-border-subtle">
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('itemName', 'Item Name')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('stockLevel', 'Stock Level')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('unitType', 'Unit Type')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('minThreshold', 'Min Threshold')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('costPrice', 'Cost Price')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('lastCost', 'Last Cost')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('status', 'Status')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-center">{tf('actions', 'Actions')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-subtle">
              {loading ? (
                <tr>
                  <td colSpan="8" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('syncing', 'Syncing...')}
                  </td>
                </tr>
              ) : items.length === 0 ? (
                <tr>
                  <td colSpan="8" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('noRecords', 'No inventory records found.')}
                  </td>
                </tr>
              ) : (
                items.map((item) => (
                  <tr key={item._id} className="hover:bg-bg-hover transition-colors">
                    <td className="px-6 py-4 text-sm font-bold text-text-main">{item.itemName}</td>
                    <td className="px-6 py-4 text-sm font-black text-text-main">
                      {item.quantity} <span className="text-xs font-bold text-text-muted">{tf(item.unit, item.unit)}</span>
                    </td>
                    <td className="px-6 py-4 text-sm font-semibold text-text-muted capitalize">{tf(item.unit, item.unit)}</td>
                    <td className="px-6 py-4 text-sm font-bold text-text-muted">
                      {item.minQuantity} {tf(item.unit, item.unit)}
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-text-muted">
                      {item.costPerUnit > 0 ? formatCurrency(item.costPerUnit) : '—'}
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-text-main">
                      {item.lastPurchaseAmount > 0 ? formatCurrency(item.lastPurchaseAmount) : '—'}
                    </td>
                    <td className="px-6 py-4 text-xs font-bold">
                      <span style={{ whiteSpace: 'nowrap' }} className={`px-2 py-0.5 rounded-md text-[10px] font-extrabold ${getStatusBadge(item.status)}`}>
                        {item.status === 'In Stock'
                          ? tf('inStock', 'In Stock')
                          : item.status === 'Low Stock'
                          ? tf('lowStock', 'Low Stock')
                          : item.status === 'Out of Stock'
                          ? tf('outOfStock', 'Out of Stock')
                          : item.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-center">
                      <div className="flex items-center justify-center gap-2">
                        <button
                          onClick={() => handleOpenRestockModal(item)}
                          className="p-1.5 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-500 hover:text-emerald-600 transition-all cursor-pointer border border-emerald-500/10"
                          title={tf('restockMaterial', 'Restock Material')}
                        >
                          <MdAdd className="w-4 h-4 text-color-accent-emerald" />
                        </button>
                        <button
                          onClick={() => handleOpenEditModal(item)}
                          className="p-1.5 rounded-lg bg-bg-secondary hover:bg-bg-card-hover border border-border-subtle text-text-muted hover:text-text-main transition-all cursor-pointer"
                          title={tf('editDetails', 'Edit Details')}
                        >
                          <MdEdit className="w-4 h-4 text-color-accent-purple" />
                        </button>
                        <button
                          onClick={() => { setDeleteTarget(item); setDeleteError(''); }}
                          className="p-1.5 rounded-lg bg-rose-500/10 hover:bg-rose-500/20 text-rose-500 hover:text-rose-600 transition-all cursor-pointer border border-rose-500/10"
                          title={tf('deleteMaterial', 'Delete Material')}
                        >
                          <MdDelete className="w-4 h-4 text-color-accent-pink" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <InventoryModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        modalMode={modalMode}
        selectedItem={selectedItem}
        form={form}
        setForm={setForm}
        formError={formError}
        setFormError={setFormError}
        formLoading={formLoading}
        onSubmit={handleFormSubmit}
        tf={tf}
      />

      <InventoryDeleteModal
        deleteTarget={deleteTarget}
        onClose={() => setDeleteTarget(null)}
        deleteLoading={deleteLoading}
        deleteError={deleteError}
        onSubmit={handleDeleteSubmit}
        tf={tf}
      />
    </div>
  );
};

export default Inventory;
