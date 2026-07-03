import { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { api } from '../../../services/api';
import { uploadToPrivateBucket } from '../../../services/supabase';

export const useNewOrder = (tf) => {
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
  const [deliveryDate, setDeliveryDate] = useState('');
  const [totalAmount, setTotalAmount] = useState('');
  const [advancePaid, setAdvancePaid] = useState('');

  const [measurements, setMeasurements] = useState({
    chest: '', waist: '', hips: '', shoulder: '', sleeves: '', neck: '', length: '', notes: ''
  });

  const [submitLoading, setSubmitLoading] = useState(false);
  const [submitError, setSubmitError] = useState('');

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
    setApparelType(e.target.value);
    setMeasurements({
      chest: '', waist: '', hips: '', shoulder: '', sleeves: '', neck: '', length: '', notes: '',
      frontNeck: '', backNeck: '', lehengaLength: '', choliLength: '', inseam: ''
    });
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

    // Validate: Maap requires photo
    if (measurementType === 'Maap' && !maapPhoto) {
      setMaapPhotoError('Please take or upload a photo of the cloth (maap) before submitting.');
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

      const orderData = {
        customerName,
        customer: customerId,
        customerPhone: custMode === 'new' ? newCustPhone : undefined,
        apparelType,
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
    handleApparelTypeChange,
    handlePhotoCapture,
    handleSubmit,
    calculatedDue,
  };
};
