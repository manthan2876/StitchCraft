/* src/pages/NewOrder.jsx */
import React, { useState, useEffect, useRef } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useLanguage } from '../context/LanguageContext';
import { api } from '../services/api';
import Card from '../components/common/Card';
import Button from '../components/common/Button';
import InputField from '../components/common/InputField';
import MeasurementForm from '../components/specific/MeasurementForm';
import { GiSewingNeedle } from 'react-icons/gi';
import {
  MdCamera, MdPhotoLibrary, MdClose, MdCheckCircle,
  MdStraighten, MdContentCut
} from 'react-icons/md';
// Add this line at the top of your imports
import { uploadToPrivateBucket } from '../services/supabase';

export const NewOrder = () => {
  const navigate = useNavigate();
  const { t } = useLanguage();
  const [searchParams] = useSearchParams();
  const queryCustomerId = searchParams.get('customerId');
  const cameraInputRef = useRef(null);
  const fileInputRef = useRef(null);

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

  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

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

  const [custMode, setCustMode] = useState('select');
  const [selectedCustomerId, setSelectedCustomerId] = useState('');

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

  const [newCustName, setNewCustName] = useState('');
  const [newCustPhone, setNewCustPhone] = useState('');
  const [apparelType, setApparelType] = useState('Suit');
  const [deliveryDate, setDeliveryDate] = useState('');
  const [totalAmount, setTotalAmount] = useState('');
  const [advancePaid, setAdvancePaid] = useState('');

  const [measurements, setMeasurements] = useState({
    chest: '', waist: '', hips: '', shoulder: '', sleeves: '', neck: '', length: '', notes: ''
  });

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

  const [submitLoading, setSubmitLoading] = useState(false);
  const [submitError, setSubmitError] = useState('');

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
      // Handle Supabase Upload for Maap
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
        maapImageUrl: storagePath, // Save the path string, not the base64
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

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-8 select-none text-left">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">

        {/* ── Left: Order Info ── */}
        <div className="lg:col-span-1 flex flex-col gap-6">
          <Card className="flex flex-col gap-6">
            <div>
              <h3 className="text-lg font-bold text-text-main tracking-wide">{tf('clientSettings', 'Client Settings')}</h3>
              <p className="text-xs text-text-muted mt-0.5">{tf('customerSub', 'Select existing or create a temporary booking client profile')}</p>
            </div>

            {/* Customer Mode Toggle */}
            <div className="flex bg-bg-secondary p-1.5 rounded-xl border border-border-subtle">
              <button type="button" onClick={() => setCustMode('select')}
                className={`flex-1 py-2 text-xs font-bold rounded-lg transition-all cursor-pointer
                  ${custMode === 'select' ? 'bg-color-accent-purple text-white-forced shadow-md' : 'text-text-muted hover:text-text-main'}`}>
                {tf('existingClient', 'Existing Client')}
              </button>
              <button type="button" onClick={() => setCustMode('new')}
                className={`flex-1 py-2 text-xs font-bold rounded-lg transition-all cursor-pointer
                  ${custMode === 'new' ? 'bg-color-accent-purple text-white-forced shadow-md' : 'text-text-muted hover:text-text-main'}`}>
                {tf('newProfile', 'New Profile')}
              </button>
            </div>

            {custMode === 'select' ? (
              <div className="flex flex-col gap-2">
                <label className="text-sm font-medium text-text-muted">{tf('selectCustomer', 'Select Customer')}</label>
                <select value={selectedCustomerId} onChange={(e) => setSelectedCustomerId(e.target.value)}
                  className="w-full px-4 py-3 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple transition-all text-sm font-semibold" required>
                  <option value="">-- {tf('selectCustomer', 'Select Customer')} --</option>
                  {rawCustomers.map(c => (
                    <option key={c._id} value={c._id}>{c.name} ({c.phone})</option>
                  ))}
                </select>
              </div>
            ) : (
              <div className="flex flex-col gap-4">
                <InputField label={tf('customerName', 'Customer Name')} value={newCustName} onChange={(e) => setNewCustName(e.target.value)} placeholder="e.g. Anand Sharma" required={custMode === 'new'} />
                <InputField label={tf('contactPhone', 'Contact Phone')} type="tel" value={newCustPhone} onChange={(e) => setNewCustPhone(e.target.value)} placeholder="e.g. 9876543210" required={custMode === 'new'} />
              </div>
            )}

            <div className="h-[1px] bg-border-subtle" />

            <div className="flex flex-col gap-4">
              {/* Apparel Type */}
              <div className="flex flex-col gap-2">
                <label className="text-sm font-medium text-text-muted">{tf('apparelCategory', 'Apparel Category')}</label>
                <select value={apparelType} onChange={handleApparelTypeChange}
                  className="w-full px-4 py-3 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple transition-all text-sm font-semibold">
                  <option value="Suit">{tf('suit', 'Suit')}</option>
                  <option value="Shirt">{tf('shirt', 'Shirt')}</option>
                  <option value="Kurta">{tf('kurta', 'Kurta')}</option>
                  <option value="Blouse">{tf('blouse', 'Blouse')}</option>
                  <option value="Lehenga">{tf('lehenga', 'Lehenga')}</option>
                  <option value="Pants">{tf('pants', 'Pants')}</option>
                </select>
              </div>

              <InputField label={tf('deliveryDeadline', 'Delivery Deadline')} type="date" value={deliveryDate} onChange={(e) => setDeliveryDate(e.target.value)} required />

              {/* Needs Aster toggle */}
              <div className="flex items-center justify-between bg-bg-secondary border border-border-subtle rounded-xl px-4 py-3">
                <div>
                  <p className="text-sm font-bold text-text-main">{tf('addAster', 'Lining Needed (Astar)')}</p>
                  <p className="text-[10px] text-text-muted mt-0.5">{tf('addAsterDesc', 'Requires extra inner lining material')}</p>
                </div>
                <button type="button" onClick={() => { setNeedsAster(prev => !prev); setAsterQuantity(''); setAsterInventoryItem(''); }}
                  className={`w-11 h-6 rounded-full border-2 transition-all cursor-pointer relative ${needsAster ? 'bg-color-accent-purple border-color-accent-purple' : 'bg-bg-hover border-border-medium'}`}>
                  <span className={`absolute top-0.5 w-4 h-4 rounded-full bg-white transition-all ${needsAster ? 'left-[calc(100%-18px)]' : 'left-0.5'}`} />
                </button>
              </div>

              {/* Aster details — shown when needsAster is ON */}
              {needsAster && (
                <div className="flex flex-col gap-3 bg-color-accent-purple/5 border border-color-accent-purple/20 rounded-xl p-4">
                  <p className="text-[10px] font-extrabold text-color-accent-purple uppercase tracking-wider">{tf('astarLiningDetails', 'Astar / Lining Details')}</p>

                  <div className="flex flex-col gap-2">
                    <label className="text-xs font-bold text-text-muted">{tf('inventoryItemLining', 'Inventory Item (Lining)')}</label>
                    <select value={asterInventoryItem} onChange={(e) => setAsterInventoryItem(e.target.value)}
                      className="w-full px-3 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple transition-all text-sm font-semibold">
                      <option value="">{tf('selectInventoryItem', '-- Select Inventory Item --')}</option>
                      {inventoryItems.map(item => (
                        <option key={item._id} value={item._id}>
                          {item.itemName} ({item.quantity} {item.unit} available)
                        </option>
                      ))}
                    </select>
                  </div>

                  <InputField
                    label={tf('astarQuantityNeeded', 'Astar Quantity Needed')}
                    type="number"
                    value={asterQuantity}
                    onChange={(e) => setAsterQuantity(e.target.value)}
                    placeholder={`e.g. 2 ${inventoryItems.find(i => i._id === asterInventoryItem)?.unit || 'meters'}`}
                  />

                  <InputField
                    label={tf('liningSellingPriceLabel', `Lining Selling Price (per ${inventoryItems.find(i => i._id === asterInventoryItem)?.unit || 'unit'})`)}
                    type="number"
                    value={asterSellingPrice}
                    onChange={(e) => setAsterSellingPrice(e.target.value)}
                    placeholder={tf('liningSellingPricePlaceholder', 'e.g. 35')}
                  />

                  {asterInventoryItem && asterSellingPrice && (
                    <p className="text-[10px] font-bold text-color-accent-emerald">
                      {tf('marginPerUnit', 'Margin per unit')}: ₹{((parseFloat(asterSellingPrice) || 0) - (inventoryItems.find(i => i._id === asterInventoryItem)?.costPerUnit || 0)).toFixed(2)}
                    </p>
                  )}

                  {asterInventoryItem && asterQuantity && (
                    <div className="flex items-center gap-2 text-xs text-text-muted font-semibold bg-bg-secondary border border-border-subtle rounded-lg px-3 py-2">
                      <MdContentCut className="w-3.5 h-3.5 text-color-accent-purple" />
                      <span>{tf('stockReduceNoticePrefix', 'Stock will reduce by')} <strong className="text-text-main">{asterQuantity} {inventoryItems.find(i => i._id === asterInventoryItem)?.unit || 'units'}</strong> {tf('stockReduceNoticeSuffix', 'when order reaches Stitching stage')}</span>
                    </div>
                  )}
                </div>
              )}

              {/* Assign Karigar */}
              <div className="flex flex-col gap-2">
                <label className="text-sm font-medium text-text-muted">{tf('assignKarigar', 'Assign Karigar')}</label>
                <select value={assignedKarigar} onChange={(e) => setAssignedKarigar(e.target.value)}
                  className="w-full px-4 py-3 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple transition-all text-sm font-semibold">
                  <option value="">-- {tf('unassigned', 'Unassigned')} --</option>
                  {karigars.filter(k => k.status === 'Active').map(k => (
                    <option key={k._id} value={k._id}>{k.name} ({k.specialization})</option>
                  ))}
                </select>
              </div>

              {/* Assign Machine */}
              <div className="flex flex-col gap-2">
                <label className="text-sm font-medium text-text-muted">{tf('assignMachine', 'Assign Machine')}</label>
                <select value={assignedMachine} onChange={(e) => setAssignedMachine(e.target.value)}
                  className="w-full px-4 py-3 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple transition-all text-sm font-semibold">
                  <option value="">-- {tf('unassigned', 'Unassigned')} --</option>
                  {machines.filter(m => m.status === 'Working').map(m => (
                    <option key={m._id} value={m._id}>{m.name} ({m.type})</option>
                  ))}
                </select>
              </div>
            </div>

            <div className="h-[1px] bg-border-subtle" />

            {/* Payment */}
            <div className="flex flex-col gap-4">
              <InputField label={tf('totalOrderValue', 'Total Order Value')} type="number" value={totalAmount} onChange={(e) => setTotalAmount(e.target.value)} placeholder="e.g. 15000" required />
              <InputField label={tf('advancePayment', 'Advance Payment')} type="number" value={advancePaid} onChange={(e) => setAdvancePaid(e.target.value)} placeholder="e.g. 5000" />
              <div className="bg-bg-secondary p-4 rounded-xl border border-border-subtle flex items-center justify-between">
                <span className="text-xs font-bold text-text-muted uppercase tracking-wider">{tf('remainingDues', 'Remaining Dues')}:</span>
                <span className={`text-lg font-black ${calculatedDue > 0 ? 'text-color-accent-pink' : 'text-color-accent-emerald'}`}>
                  ₹{calculatedDue.toLocaleString('en-IN')}
                </span>
              </div>
            </div>
          </Card>
        </div>

        {/* ── Right: Measurement Type ── */}
        <div className="lg:col-span-2 flex flex-col gap-6">
          <Card className="flex flex-col gap-6">
            {/* Measurement Mode Toggle */}
            <div>
              <h3 className="text-lg font-bold text-text-main tracking-wide">Measurement / Maap</h3>
              <p className="text-xs text-text-muted mt-0.5">Choose how measurements are handled for this order</p>
            </div>

            <div className="grid grid-cols-2 gap-3">
              {/* Maap card */}
              <button type="button" onClick={() => { setMeasurementType('Maap'); setMaapPhotoError(''); }}
                className={`flex flex-col items-center gap-3 p-5 rounded-2xl border-2 transition-all cursor-pointer text-center
                  ${measurementType === 'Maap'
                    ? 'border-color-accent-purple bg-color-accent-purple/10 shadow-lg shadow-color-accent-purple/10'
                    : 'border-border-subtle bg-bg-secondary hover:border-border-medium'}`}>
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center text-2xl transition-all
                  ${measurementType === 'Maap' ? 'bg-color-accent-purple/20 text-color-accent-purple' : 'bg-bg-hover text-text-muted'}`}>
                  🧵
                </div>
                <div>
                  <p className={`text-sm font-extrabold ${measurementType === 'Maap' ? 'text-color-accent-purple' : 'text-text-main'}`}>Maap</p>
                  <p className="text-[10px] text-text-muted mt-0.5 leading-relaxed">Customer gives cloth directly. Tailor takes photo as reference.</p>
                </div>
                {measurementType === 'Maap' && (
                  <span className="text-[9px] font-black uppercase tracking-wider px-2 py-0.5 bg-color-accent-purple text-white-forced rounded-full">Selected</span>
                )}
              </button>

              {/* Measurements card */}
              <button type="button" onClick={() => { setMeasurementType('Measurements'); setMaapPhoto(null); setMaapPhotoError(''); }}
                className={`flex flex-col items-center gap-3 p-5 rounded-2xl border-2 transition-all cursor-pointer text-center
                  ${measurementType === 'Measurements'
                    ? 'border-color-accent-blue bg-[#007aff]/10 shadow-lg shadow-[#007aff]/10'
                    : 'border-border-subtle bg-bg-secondary hover:border-border-medium'}`}>
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center transition-all
                  ${measurementType === 'Measurements' ? 'bg-[#007aff]/20 text-[#007aff]' : 'bg-bg-hover text-text-muted'}`}>
                  <MdStraighten className="w-6 h-6" />
                </div>
                <div>
                  <p className={`text-sm font-extrabold ${measurementType === 'Measurements' ? 'text-[#007aff]' : 'text-text-main'}`}>Measurements</p>
                  <p className="text-[10px] text-text-muted mt-0.5 leading-relaxed">Fill in standard body measurements for this garment.</p>
                </div>
                {measurementType === 'Measurements' && (
                  <span className="text-[9px] font-black uppercase tracking-wider px-2 py-0.5 bg-[#007aff] text-white-forced rounded-full">Selected</span>
                )}
              </button>
            </div>

            {/* ── Maap: Photo Capture ── */}
            {measurementType === 'Maap' && (
              <div className="flex flex-col gap-4">
                <div className="flex items-center gap-2">
                  <MdCamera className="w-4 h-4 text-color-accent-purple" />
                  <p className="text-sm font-bold text-text-main">Maap Photo <span className="text-color-accent-pink">*</span></p>
                  <span className="text-[10px] text-text-muted font-semibold">Required — take photo of the cloth given by customer</span>
                </div>

                {maapPhoto ? (
                  <div className="relative rounded-2xl overflow-hidden border-2 border-color-accent-purple/40 shadow-lg">
                    <img src={maapPhoto.preview} alt="Maap" className="w-full max-h-64 object-cover" />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
                    <div className="absolute bottom-3 left-4 right-4 flex items-center justify-between">
                      <div className="flex items-center gap-1.5 text-xs text-white font-bold">
                        <MdCheckCircle className="w-4 h-4 text-emerald-400" />
                        Photo captured
                      </div>
                      <button type="button" onClick={() => setMaapPhoto(null)}
                        className="p-1 bg-white/20 hover:bg-white/30 rounded-lg text-white transition-all cursor-pointer">
                        <MdClose className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className={`flex flex-col items-center justify-center gap-4 p-8 rounded-2xl border-2 border-dashed transition-all
                    ${maapPhotoError ? 'border-color-accent-pink bg-color-accent-pink/5' : 'border-border-medium bg-bg-secondary hover:border-color-accent-purple/40'}`}>
                    <div className="w-16 h-16 rounded-2xl bg-bg-hover flex items-center justify-center">
                      <MdCamera className="w-8 h-8 text-text-muted" />
                    </div>
                    <div className="text-center">
                      <p className="text-sm font-bold text-text-main">No photo yet</p>
                      <p className="text-[11px] text-text-muted mt-0.5">Take a photo with your camera or upload from gallery</p>
                    </div>
                    <div className="flex gap-3">
                      {/* Camera capture (mobile) */}
                      <input ref={cameraInputRef} type="file" accept="image/*" capture="environment" className="hidden" onChange={handlePhotoCapture} />
                      <button type="button" onClick={() => cameraInputRef.current?.click()}
                        className="flex items-center gap-2 px-4 py-2.5 bg-color-accent-purple text-white-forced rounded-xl text-xs font-bold shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer">
                        <MdCamera className="w-4 h-4 text-white-forced" />
                        Take Photo
                      </button>
                      {/* Gallery upload */}
                      <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={handlePhotoCapture} />
                      <button type="button" onClick={() => fileInputRef.current?.click()}
                        className="flex items-center gap-2 px-4 py-2.5 bg-bg-hover border border-border-medium text-text-main rounded-xl text-xs font-bold hover:bg-bg-card-hover transition-all cursor-pointer">
                        <MdPhotoLibrary className="w-4 h-4" />
                        Upload
                      </button>
                    </div>
                  </div>
                )}

                {maapPhotoError && (
                  <p className="text-xs text-color-accent-pink font-bold flex items-center gap-1">
                    ⚠ {maapPhotoError}
                  </p>
                )}
              </div>
            )}

            {/* ── Measurements Form ── */}
            {measurementType === 'Measurements' && (
              <MeasurementForm apparelType={apparelType} measurements={measurements} onChange={setMeasurements} />
            )}

            {/* Submit row */}
            <div className="flex flex-col gap-3 border-t border-border-subtle pt-4">
              {submitError && (
                <p className="text-xs text-color-accent-pink font-bold text-center animate-pulse">{submitError}</p>
              )}
              <div className="flex justify-end gap-3">
                <Button variant="dark" onClick={() => navigate('/orders')} className="cursor-pointer">
                  {tf('cancel', 'Cancel')}
                </Button>
                <Button variant="primary" type="submit" disabled={submitLoading} className="cursor-pointer">
                  <GiSewingNeedle className="w-5 h-5 animate-spin" style={{ animationDuration: '3s' }} />
                  <span>{submitLoading ? tf('saving', 'Saving...') : tf('createOrderLockLedger', 'Create Order & Lock to Ledger')}</span>
                </Button>
              </div>
            </div>
          </Card>
        </div>
      </div>
    </form>
  );
};

export default NewOrder;
