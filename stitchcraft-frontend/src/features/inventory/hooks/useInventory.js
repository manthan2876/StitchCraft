import { useState, useEffect } from 'react';
import { api } from '../../../services/api';

export const useInventory = (tf) => {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  // Add/Edit Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState('add'); // 'add' | 'edit' | 'restock'
  const [selectedItem, setSelectedItem] = useState(null);
  const [form, setForm] = useState({ itemName: '', quantity: '', unit: 'meters', minQuantity: '10', purchaseAmount: '', description: '', costPerUnit: '', quantityToAdd: '' });
  const [formError, setFormError] = useState('');
  const [formLoading, setFormLoading] = useState(false);

  // Delete Modal states
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [deleteError, setDeleteError] = useState('');

  const fetchInventory = async (search = '') => {
    setLoading(true);
    try {
      const data = await api.get(`/inventory?search=${encodeURIComponent(search)}`);
      setItems(data);
    } catch (err) {
      console.error('Failed to fetch inventory:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchInventory(searchTerm);
  }, [searchTerm]);

  const handleOpenAddModal = () => {
    setForm({ itemName: '', quantity: '0', unit: 'meters', minQuantity: '10', purchaseAmount: '', description: '', costPerUnit: '0', quantityToAdd: '' });
    setModalMode('add');
    setSelectedItem(null);
    setFormError('');
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (item) => {
    setForm({
      itemName: item.itemName,
      quantity: String(item.quantity),
      unit: item.unit || 'meters',
      minQuantity: String(item.minQuantity),
      purchaseAmount: '',
      description: '',
      costPerUnit: String(item.costPerUnit || 0),
      quantityToAdd: ''
    });
    setModalMode('edit');
    setSelectedItem(item);
    setFormError('');
    setIsModalOpen(true);
  };

  const handleOpenRestockModal = (item) => {
    setForm({
      itemName: item.itemName,
      quantity: String(item.quantity),
      unit: item.unit || 'meters',
      minQuantity: String(item.minQuantity),
      purchaseAmount: '',
      description: '',
      costPerUnit: String(item.costPerUnit || 0),
      quantityToAdd: ''
    });
    setModalMode('restock');
    setSelectedItem(item);
    setFormError('');
    setIsModalOpen(true);
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    if (modalMode !== 'restock' && !form.itemName) {
      setFormError(tf('itemNameRequired', 'Item name is required.'));
      return;
    }
    if (modalMode === 'restock' && (!form.quantityToAdd || Number(form.quantityToAdd) <= 0)) {
      setFormError(tf('quantityToAddRequired', 'Please enter a valid quantity to add.'));
      return;
    }
    setFormLoading(true);
    setFormError('');
    try {
      let payload;
      if (modalMode === 'add') {
        payload = {
          itemName: form.itemName,
          quantity: Number(form.quantity) || 0,
          unit: form.unit,
          minQuantity: Number(form.minQuantity) || 10,
          purchaseAmount: Number(form.purchaseAmount) || 0,
          description: form.description || '',
          costPerUnit: Number(form.costPerUnit) || 0
        };
        const data = await api.post('/inventory', payload);
        setItems(prev => [data, ...prev]);
      } else if (modalMode === 'edit') {
        payload = {
          itemName: form.itemName,
          quantity: Number(form.quantity) || 0,
          unit: form.unit,
          minQuantity: Number(form.minQuantity) || 10,
          purchaseAmount: 0,
          description: '',
          costPerUnit: Number(form.costPerUnit) || 0
        };
        const data = await api.put(`/inventory/${selectedItem._id}`, payload);
        setItems(prev => prev.map(item => item._id === data._id ? data : item));
      } else if (modalMode === 'restock') {
        const addedQty = Number(form.quantityToAdd) || 0;
        payload = {
          itemName: selectedItem.itemName,
          quantity: selectedItem.quantity + addedQty,
          unit: selectedItem.unit,
          minQuantity: selectedItem.minQuantity,
          purchaseAmount: Number(form.purchaseAmount) || 0,
          description: form.description || `Restocked ${addedQty} ${form.unit} of ${selectedItem.itemName}`,
          costPerUnit: Number(form.costPerUnit) || 0
        };
        const data = await api.put(`/inventory/${selectedItem._id}`, payload);
        setItems(prev => prev.map(item => item._id === data._id ? data : item));
      }
      setIsModalOpen(false);
    } catch (err) {
      setFormError(err.message || tf('failedSaveInventory', 'Failed to save inventory item.'));
    } finally {
      setFormLoading(false);
    }
  };

  const handleDeleteSubmit = async () => {
    if (!deleteTarget) return;
    setDeleteLoading(true);
    setDeleteError('');
    try {
      await api.delete(`/inventory/${deleteTarget._id}`);
      setItems(prev => prev.filter(item => item._id !== deleteTarget._id));
      setDeleteTarget(null);
    } catch (err) {
      setDeleteError(err.message || tf('failedDeleteInventory', 'Failed to delete item.'));
    } finally {
      setDeleteLoading(false);
    }
  };

  return {
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
  };
};
