import { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { api } from '../../../services/api';
import { uploadToPrivateBucket } from '../../../services/supabase';
import {
  validateMinLength,
  validatePhone,
  validateNumber,
  validateDate,
} from '../../../utils/formValidators';

export const useNewOrder = (_tf) => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const queryCustomerId = searchParams.get('customerId');

  const [rawCustomers, setRawCustomers] = useState([]);
  const [karigars, setKarigars] = useState([]);
  const [machines, setMachines] = useState([]);
  const [inventoryItems, setInventoryItems] = useState([]);

  // Aster state
  const [needsAster, setNeedsAster] = useState(false);
  const [asterQuantity, setAsterQuantity] = useState('');
  const [asterInventoryItem, setAsterInventoryItem] = useState('');
  const [asterSellingPrice, setAsterSellingPrice] = useState('');

  // Karigar & Machine
  const [assignedKarigar, setAssignedKarigar] = useState('');
  const [assignedMachine, setAssignedMachine] = useState('');

  // Measurement type — default Maap
  const [measurementType, setMeasurementType] = useState('Maap');
  const [maapPhoto, setMaapPhoto] = useState(null); // { preview: string, base64: string }
  const [maapPhotoError, setMaapPhotoError] = useState('');

  const [custMode, setCustMode] = useState('select');
  const [selectedCustomerId, setSelectedCustomerId] = useState('');
  const [newCustName, setNewCustName] = useState('');
  const [newCustPhone, setNewCustPhone] = useState('');
  const [apparelType, setApparelType] = useState('Suit');
  const [items, setItems] = useState([
    { id: '1', apparelType: 'Suit', quantity: 1, price: '', fabric: '' }
  ]);
  const [deliveryDate, setDeliveryDate] = useState('');
  const [totalAmount, setTotalAmount] = useState('');
  const [advancePaid, setAdvancePaid] = useState('');

  const [measurements, setMeasurements] = useState({
    chest: '', waist: '', hips: '', shoulder: '', sleeves: '', neck: '', length: '', notes: ''
  });

  const [submitLoading, setSubmitLoading] = useState(false);
  const [submitError, setSubmitError] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});

  useEffect(() => {
    api.get('/customers').then(setRawCustomers).catch(console.error);
    api.get('/karigars').then(setKarigars).catch(err => {
      console.warn('Karigars not available:', err.message);
      setKarigars([]);
    });
    api.get('/machines').then(setMachines).catch(err => {
      console.warn('Machines not available:', err.message);
      setMachines([]);
    });
    api.get('/inventory').then(setInventoryItems).catch(err => {
      console.warn('Inventory not available:', err.message);
      setInventoryItems([]);
    });
  }, []);

  useEffect(() => {
    if (rawCustomers.length > 0) {
      if (queryCustomerId) {
        const match = rawCustomers.find(c => c._id === queryCustomerId || c.id === queryCustomerId);
        if (match) {
          setCustMode('select');
          setSelectedCustomerId(match._id);
          return;
        }
      }
      if (!selectedCustomerId) {
        setSelectedCustomerId(rawCustomers[0]._id);
      }
    }
  }, [queryCustomerId, rawCustomers, selectedCustomerId]);

  const handleApparelTypeChange = (e) => {
    const val = e.target.value;
    setApparelType(val);
    if (items.length > 0) {
      setItems((prev) => prev.map((it, idx) => idx === 0 ? { ...it, apparelType: val } : it));
    }
    setMeasurements({
      chest: '', waist: '', hips: '', shoulder: '', sleeves: '', neck: '', length: '', notes: '',
      frontNeck: '', backNeck: '', lehengaLength: '', choliLength: '', inseam: ''
    });
  };

  const addItem = () => {
    setItems((prev) => [
      ...prev,
      { id: String(Date.now()), apparelType: 'Shirt', quantity: 1, price: '', fabric: '' }
    ]);
  };

  const removeItem = (id) => {
    if (items.length <= 1) return;
    const nextItems = items.filter((it) => it.id !== id);
    setItems(nextItems);
    const sum = nextItems.reduce((acc, it) => acc + (parseFloat(it.price) || 0) * (parseInt(it.quantity) || 1), 0);
    if (sum > 0) setTotalAmount(String(sum));
  };

  const updateItem = (id, field, value) => {
    const nextItems = items.map((it) => {
      if (it.id !== id) return it;
      return { ...it, [field]: value };
    });
    setItems(nextItems);

    if (field === 'price' || field === 'quantity') {
      const sum = nextItems.reduce((acc, it) => acc + (parseFloat(it.price) || 0) * (parseInt(it.quantity) || 1), 0);
      if (sum > 0) setTotalAmount(String(sum));
    }
    if (field === 'apparelType' && items.length === 1) {
      setApparelType(value);
    }
  };

  const handlePhotoCapture = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) {
      setMaapPhotoError('Photo must be under 5 MB.');
      return;
    }
    setMaapPhotoError('');
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onloadend = () => {
      setMaapPhoto({ preview: reader.result, base64: reader.result });
    };
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitError('');
    setFieldErrors({});

    const errs = {};

    if (custMode === 'new') {
      const nameErr = validateMinLength(newCustName, 2, 'Customer name');
      if (nameErr) errs.newCustName = nameErr;
      const phoneErr = validatePhone(newCustPhone, true);
      if (phoneErr) errs.newCustPhone = phoneErr;
    } else {
      if (!selectedCustomerId) {
        errs.selectedCustomerId = 'Please select a customer';
      }
    }

    const dateErr = validateDate(deliveryDate, 'Delivery date');
    if (dateErr) errs.deliveryDate = dateErr;

    const priceErr = validateNumber(totalAmount, 'Total order value', { allowZero: false });
    if (priceErr) errs.totalAmount = priceErr;

    if (advancePaid !== '' && advancePaid !== undefined) {
      const advErr = validateNumber(advancePaid, 'Advance payment', {
        allowZero: true,
        max: parseFloat(totalAmount) || undefined,
      });
      if (advErr) errs.advancePaid = advErr;
    }

    if (needsAster) {
      const qtyErr = validateNumber(asterQuantity, 'Lining quantity', { allowZero: false });
      if (qtyErr) errs.asterQuantity = qtyErr;
      const spErr = validateNumber(asterSellingPrice, 'Lining price', { allowZero: false });
      if (spErr) errs.asterSellingPrice = spErr;
    }

    // Validate: Maap requires photo
    if (measurementType === 'Maap' && !maapPhoto) {
      errs.maapPhoto = 'Please take or upload a photo of the cloth (maap) before submitting.';
      setMaapPhotoError('Please take or upload a photo of the cloth (maap) before submitting.');
    }

    if (Object.keys(errs).length > 0) {
      setFieldErrors(errs);
      setSubmitError('Please fix the indicated errors before submitting.');
      return;
    }

    setSubmitLoading(true);

    let customerName;
    let customerId = undefined;
    if (custMode === 'select') {
      const selected = rawCustomers.find(c => c._id === selectedCustomerId);
      customerName = selected ? selected.name : 'Unknown Client';
      customerId = selected ? selected._id : undefined;
    } else {
      customerName = newCustName || 'New Client';
    }

    try {
      let storagePath = '';
      if (measurementType === 'Maap' && maapPhoto) {
        const response = await fetch(maapPhoto.base64);
        const blob = await response.blob();
        const file = new File([blob], 'maap-photo.jpg', { type: 'image/jpeg' });
        storagePath = await uploadToPrivateBucket('maap-images', file);
      }

      const shirtFields = ['neck', 'chest', 'waist', 'hips', 'shoulder', 'sleeves', 'length', 'frontNeck', 'backNeck', 'notes'];
      const pantFields = ['length', 'waist', 'hips', 'inseam', 'thigh', 'rise', 'bottom', 'notes'];
      const shirt = {};
      const pant = {};
      shirtFields.forEach(f => { if (measurements[f] !== undefined && measurements[f] !== '') shirt[f] = measurements[f]; });
      pantFields.forEach(f => { if (measurements[f] !== undefined && measurements[f] !== '') pant[f] = measurements[f]; });

      const effectiveApparelType = items.length > 1
        ? items.map(it => `${it.apparelType}${it.quantity > 1 ? ` x${it.quantity}` : ''}`).join(', ')
        : (items[0]?.apparelType || apparelType);

      const orderData = {
        customerName,
        customer: customerId,
        customerPhone: custMode === 'new' ? newCustPhone : undefined,
        apparelType: effectiveApparelType,
        items: items.map(it => ({
          id: it.id,
          name: it.apparelType,
          apparelType: it.apparelType,
          quantity: parseInt(it.quantity) || 1,
          price: parseFloat(it.price) || 0,
          fabric: it.fabric || '',
        })),
        deliveryDate: deliveryDate || new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        price: parseFloat(totalAmount) || 0,
        advancePaid: parseFloat(advancePaid) || 0,
        measurementType,
        maapImageUrl: storagePath,
        measurements: measurementType === 'Measurements' ? { shirt, pant, others: measurements.notes || '' } : undefined,
        needsAster,
        asterQuantity: needsAster ? (parseFloat(asterQuantity) || 0) : 0,
        asterInventoryItem: needsAster ? (asterInventoryItem || undefined) : undefined,
        asterSellingPrice: needsAster ? (parseFloat(asterSellingPrice) || 0) : 0,
        assignedKarigar: assignedKarigar || undefined,
        assignedMachine: assignedMachine || undefined,
      };

      await api.post('/orders', orderData);
      navigate('/orders');
    } catch (err) {
      setSubmitError(err.message || 'Failed to create order.');
    } finally {
      setSubmitLoading(false);
    }
  };

  const calculatedDue = (parseFloat(totalAmount) || 0) - (parseFloat(advancePaid) || 0);

  return {
    rawCustomers,
    karigars,
    machines,
    inventoryItems,
    needsAster,
    setNeedsAster,
    asterQuantity,
    setAsterQuantity,
    asterInventoryItem,
    setAsterInventoryItem,
    asterSellingPrice,
    setAsterSellingPrice,
    assignedKarigar,
    setAssignedKarigar,
    assignedMachine,
    setAssignedMachine,
    measurementType,
    setMeasurementType,
    maapPhoto,
    setMaapPhoto,
    maapPhotoError,
    setMaapPhotoError,
    custMode,
    setCustMode,
    selectedCustomerId,
    setSelectedCustomerId,
    newCustName,
    setNewCustName,
    newCustPhone,
    setNewCustPhone,
    apparelType,
    items,
    addItem,
    removeItem,
    updateItem,
    deliveryDate,
    setDeliveryDate,
    totalAmount,
    setTotalAmount,
    advancePaid,
    setAdvancePaid,
    measurements,
    setMeasurements,
    submitLoading,
    submitError,
    fieldErrors,
    setFieldErrors,
    handleApparelTypeChange,
    handlePhotoCapture,
    handleSubmit,
    calculatedDue,
  };
};
