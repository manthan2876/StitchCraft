import { useState, useEffect } from 'react';
import { api } from '../../../services/api';
import { validateMinLength, validateNumber } from '../../../utils/formValidators';

export const useInventory = (tf) => {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  // Add/Edit Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState('add'); // 'add' | 'edit' | 'restock'
  const [selectedItem, setSelectedItem] = useState(null);
  const [form, setForm] = useState({ itemName: '', itemType: 'Lining', quantity: '', unit: 'meters', minQuantity: '10', purchaseAmount: '', description: '', costPerUnit: '', quantityToAdd: '' });
  const [formError, setFormError] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});
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
    setForm({ itemName: '', itemType: 'Lining', quantity: '0', unit: 'meters', minQuantity: '10', purchaseAmount: '', description: '', costPerUnit: '0', quantityToAdd: '' });
    setModalMode('add');
    setSelectedItem(null);
    setFormError('');
    setFieldErrors({});
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (item) => {
    setForm({
      itemName: item.itemName,
      itemType: item.itemType || 'Lining',
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
    setFieldErrors({});
    setIsModalOpen(true);
  };

  const handleOpenRestockModal = (item) => {
    setForm({
      itemName: item.itemName,
      itemType: item.itemType || 'Lining',
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
    setFieldErrors({});
    setIsModalOpen(true);
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    const errors = {};

    if (modalMode !== 'restock') {
      const nameErr = validateMinLength(form.itemName, 2, 'Item name');
      if (nameErr) errors.itemName = nameErr;

      const qtyErr = validateNumber(form.quantity, { min: 0, fieldName: 'Quantity' });
      if (qtyErr) errors.quantity = qtyErr;

      const minQtyErr = validateNumber(form.minQuantity, { min: 0, fieldName: 'Minimum quantity' });
      if (minQtyErr) errors.minQuantity = minQtyErr;

      const costErr = validateNumber(form.costPerUnit, { min: 0, fieldName: 'Cost per unit' });
      if (costErr) errors.costPerUnit = costErr;

      if (form.purchaseAmount !== '' && form.purchaseAmount !== undefined) {
        const purchaseErr = validateNumber(form.purchaseAmount, { min: 0, fieldName: 'Purchase cost' });
        if (purchaseErr) errors.purchaseAmount = purchaseErr;
      }
    } else {
      const restockErr = validateNumber(form.quantityToAdd, { min: 0.01, fieldName: 'Quantity to add' });
      if (restockErr) errors.quantityToAdd = restockErr;

      if (form.purchaseAmount !== '' && form.purchaseAmount !== undefined) {
        const purchaseErr = validateNumber(form.purchaseAmount, { min: 0, fieldName: 'Restock cost' });
        if (purchaseErr) errors.purchaseAmount = purchaseErr;
      }
    }

    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors);
      setFormError(tf('fixFormErrors', 'Please fix the highlighted errors before saving.'));
      return;
    }

    setFieldErrors({});
    setFormLoading(true);
    setFormError('');
    try {
      let payload;
      if (modalMode === 'add') {
        payload = {
          itemName: form.itemName,
          itemType: form.itemType,
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
          itemType: form.itemType,
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
          itemType: selectedItem.itemType || 'Lining',
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
    fieldErrors,
    setFieldErrors,
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
