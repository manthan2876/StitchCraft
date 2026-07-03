/* src/pages/NewOrder.jsx */
import React, { useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useLanguage } from '../context/LanguageContext';
import Card from '../components/common/Card';
import Button from '../components/common/Button';
import InputField from '../components/common/InputField';
import MeasurementForm from '../components/specific/MeasurementForm';
import { GiSewingNeedle } from 'react-icons/gi';
import {
  MdCamera, MdPhotoLibrary, MdClose, MdCheckCircle,
  MdStraighten, MdContentCut
} from 'react-icons/md';
import { useNewOrder } from '../features/orders/hooks/useNewOrder';

export const NewOrder = () => {
  const navigate = useNavigate();
  const { t } = useLanguage();
  const cameraInputRef = useRef(null);
  const fileInputRef = useRef(null);

  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const {
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
  } = useNewOrder(tf);

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
