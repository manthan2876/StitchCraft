import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { api } from '../services/api';
import Card from '../components/common/Card';
import {
  MdArrowBack, MdPhone, MdMail, MdLocationOn, MdEdit, MdSave,
  MdAssignmentInd, MdBookmarkBorder, MdClose, MdDelete
} from 'react-icons/md';
import { FaWhatsapp } from 'react-icons/fa';
import { useAuth } from '../hooks/useAuth';
import { useLanguage } from '../context/LanguageContext';

export const CustomerDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { t } = useLanguage();
  const [customer, setCustomer] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('Overview'); // 'Overview', 'Measurements'
  const [isEditingMeasures, setIsEditingMeasures] = useState(false);

  // Edit Profile form states
  const [isEditProfileModalOpen, setIsEditProfileModalOpen] = useState(false);
  const [editName, setEditName] = useState('');
  const [editPhone, setEditPhone] = useState('');
  const [editEmail, setEditEmail] = useState('');
  const [editAddress, setEditAddress] = useState('');
  const [editLoading, setEditLoading] = useState(false);
  const [editError, setEditError] = useState('');

  // Delete Customer states
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [deleteError, setDeleteError] = useState('');

  // Measurements form states
  const [shirtMeasures, setShirtMeasures] = useState({});
  const [pantMeasures, setPantMeasures] = useState({});
  const [otherNotes, setOtherNotes] = useState('');

  const tabs = ['Overview', 'Measurements'];

  // Helper with fallbacks for translations
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const fetchCustomerDetails = async () => {
    setLoading(true);
    try {
      const data = await api.get(`/customers/${id}`);
      setCustomer(data);
      setShirtMeasures(data.measurements?.shirt || {});
      setPantMeasures(data.measurements?.pant || {});
      setOtherNotes(data.measurements?.others || '');
    } catch (err) {
      console.error('Failed to fetch customer details:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCustomerDetails();
  }, [id]);

  const handleSaveMeasurements = async () => {
    try {
      const payload = {
        measurements: {
          shirt: shirtMeasures,
          pant: pantMeasures,
          others: otherNotes
        }
      };
      const data = await api.put(`/customers/${id}`, payload);
      setCustomer(prev => ({ ...prev, measurements: data.measurements }));
      setIsEditingMeasures(false);
    } catch (err) {
      console.error('Failed to update measurements:', err);
      alert('Error updating measurements.');
    }
  };

  const handleOpenEditModal = () => {
    if (!customer) return;
    setEditName(customer.name || '');
    setEditPhone(customer.phone || '');
    setEditEmail(customer.email || '');
    setEditAddress(customer.address || '');
    setEditError('');
    setIsEditProfileModalOpen(true);
  };

  const handleEditProfileSubmit = async (e) => {
    e.preventDefault();
    if (!editName || !editPhone) {
      setEditError('Name and phone are required.');
      return;
    }
    setEditLoading(true);
    setEditError('');
    try {
      const data = await api.put(`/customers/${id}`, {
        name: editName,
        phone: editPhone,
        email: editEmail,
        address: editAddress,
      });
      setCustomer(prev => ({
        ...prev,
        name: data.name,
        phone: data.phone,
        email: data.email,
        address: data.address
      }));
      setIsEditProfileModalOpen(false);
    } catch (err) {
      setEditError(err.message || 'Failed to update profile.');
    } finally {
      setEditLoading(false);
    }
  };

  const handleDeleteCustomer = async () => {
    setDeleteLoading(true);
    setDeleteError('');
    try {
      await api.delete(`/customers/${id}`);
      navigate('/customers');
    } catch (err) {
      setDeleteError(err.message || 'Failed to delete customer.');
    } finally {
      setDeleteLoading(false);
    }
  };

  if (loading) {
    return <div className="w-full py-12 text-center text-sm text-text-muted">{tf('syncing', 'Syncing...')}</div>;
  }

  if (!customer) {
    return (
      <Card className="flex flex-col items-center justify-center py-12 text-center">
        <h4 className="text-sm font-bold text-text-main">{tf('recordNotFound', 'Record Not Found')}</h4>
        <p className="text-xs text-text-muted mt-1 font-semibold">{tf('customerNotFoundDesc', 'Customer details could not be found.')}</p>
        <button onClick={() => navigate('/customers')} className="btn-tactile mt-4 cursor-pointer">
          <span className="text-white-forced">{tf('backToRegistry', 'Back to Registry')}</span>
        </button>
      </Card>
    );
  }

  const getTabLabel = (tab) => {
    if (tab === 'Overview') return tf('overview', 'Overview');
    if (tab === 'Measurements') return tf('measurements', 'Measurements');
    return tab;
  };

  return (
    <div className="flex flex-col gap-6 select-none max-w-5xl mx-auto text-left">
      <div className="flex items-center justify-between">
        <Link to="/customers" className="flex items-center gap-1.5 text-xs text-text-muted hover:text-text-main font-bold transition-colors">
          <MdArrowBack className="w-4 h-4" />
          <span>{tf('backToCustomers', 'Back to Customers')}</span>
        </Link>
        <div className="flex items-center gap-2">
          <button onClick={handleOpenEditModal} className="px-3.5 py-1.5 bg-bg-secondary hover:bg-bg-card-hover text-text-main border border-border-medium hover:border-color-accent-purple/50 font-bold rounded-xl shadow-lg text-xs cursor-pointer flex items-center gap-1 transition-all">
            <MdEdit className="w-3.5 h-3.5 text-color-accent-purple" />
            <span>{tf('editProfile', 'Edit Profile')}</span>
          </button>
          <button onClick={() => setIsDeleteModalOpen(true)} className="px-3.5 py-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-500 border border-rose-500/20 font-bold rounded-xl shadow-lg text-xs cursor-pointer flex items-center gap-1 transition-all">
            <MdDelete className="w-3.5 h-3.5 text-color-accent-pink" />
            <span>{tf('deleteProfile', 'Delete Profile')}</span>
          </button>
        </div>
      </div>

      <Card className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-2xl bg-color-accent-purple/20 text-color-accent-purple flex items-center justify-center font-black text-2xl shadow-inner">
            {customer.name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase()}
          </div>
          <div>
            <h3 className="text-xl font-bold text-text-main tracking-wide">{customer.name}</h3>
            <div className="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-4 mt-1.5 text-xs text-text-muted">
              <span className="flex items-center gap-1">
                <MdPhone className="w-4 h-4 text-color-accent-purple" /> {customer.phone}
                <button
                  onClick={() => {
                    const cleanPhone = customer.phone.replace(/\D/g, '');
                    const formattedPhone = cleanPhone.length === 10 ? '91' + cleanPhone : cleanPhone;
                    const message = `Hello ${customer.name}, hope you are doing well!`;
                    window.open(`https://wa.me/${formattedPhone}?text=${encodeURIComponent(message)}`, '_blank');
                  }}
                  className="ml-1.5 p-1 bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/20 text-emerald-500 rounded-lg transition-all cursor-pointer flex items-center justify-center"
                  title="WhatsApp"
                >
                  <FaWhatsapp className="w-3.5 h-3.5" />
                </button>
              </span>
              {customer.email && (<span className="flex items-center gap-1"><MdMail className="w-4 h-4 text-color-accent-purple" /> {customer.email}</span>)}
              {customer.address && (<span className="flex items-center gap-1"><MdLocationOn className="w-4 h-4 text-color-accent-purple" /> {customer.address}</span>)}
            </div>
          </div>
        </div>
        <div>
          <span className="px-3.5 py-1.5 text-xs font-black bg-bg-secondary text-color-accent-purple rounded-xl border border-border-subtle uppercase tracking-wider">
            ID: {customer.customerId}
          </span>
        </div>
      </Card>

      <Card className="flex items-center gap-2 p-3">
        {tabs.map((tab) => (
          <button
            key={tab}
            onClick={() => { setActiveTab(tab); setIsEditingMeasures(false); }}
            className={`px-4 py-2 text-xs font-bold rounded-xl border transition-all cursor-pointer
              ${activeTab === tab ? 'delivery-active-tab border-color-accent-purple shadow-md' : 'filter-tab-inactive hover:text-text-main'}`}
          >
            <span>{getTabLabel(tab)}</span>
          </button>
        ))}
      </Card>

      {activeTab === 'Overview' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card className="flex items-center gap-4 py-4 px-6 border-l-4 border-l-purple-500">
            <div className="w-12 h-12 rounded-xl bg-purple-500/10 flex items-center justify-center text-purple-500">
              <MdAssignmentInd className="w-6 h-6" />
            </div>
            <div>
              <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('totalJobs', 'Total Jobs')}</span>
              <h3 className="text-xl font-black text-text-main mt-0.5">{customer.ordersCount || 0}</h3>
            </div>
          </Card>

          <Card className="md:col-span-3 flex flex-col gap-4">
            <h3 className="text-base font-bold text-text-main tracking-wide">{tf('clientSummary', 'Client Summary')}</h3>
            <p className="text-sm text-text-muted leading-relaxed">
              Customer profile record for {customer.name}.
            </p>
            <div className="bg-bg-secondary p-4 rounded-xl border border-border-subtle mt-2 flex flex-col gap-2">
              <span className="text-xs font-bold text-text-main uppercase tracking-wider">{tf('clientProfileContacts', 'Client Contacts')}</span>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs font-semibold text-text-muted mt-1">
                <div>{t('fullName').replace(' *', '')}: <span className="text-text-main">{customer.name}</span></div>
                <div>{tf('contactPhone', 'Contact Phone')}: <span className="text-text-main">{customer.phone}</span></div>
                <div>{t('emailAddress')}: <span className="text-text-main">{customer.email || 'N/A'}</span></div>
                <div>{t('address')}: <span className="text-text-main">{customer.address || 'N/A'}</span></div>
              </div>
            </div>
          </Card>
        </div>
      )}

      {activeTab === 'Measurements' && (
        <Card className="flex flex-col gap-6">
          <div className="flex items-center justify-between border-b border-border-subtle pb-4">
            <div>
              <h3 className="text-base font-bold text-text-main tracking-wide">{tf('anatomicalCard', 'Anatomical Card')}</h3>
              <p className="text-xs text-text-muted mt-0.5">{tf('anatomicalSub', 'Manage sizing settings and specifications')}</p>
            </div>
            {!isEditingMeasures ? (
              <button onClick={() => setIsEditingMeasures(true)} className="btn-tactile-dark flex items-center gap-1.5 cursor-pointer text-xs">
                <MdEdit className="w-4 h-4 text-color-accent-purple" />
                <span>{tf('updateMeasures', 'Update Measurements')}</span>
              </button>
            ) : (
              <button onClick={handleSaveMeasurements} className="btn-tactile flex items-center gap-1.5 cursor-pointer text-xs">
                <MdSave className="w-4 h-4 text-white-forced" />
                <span className="text-white-forced">{tf('saveParameters', 'Save Parameters')}</span>
              </button>
            )}
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-2">
            <div className="flex flex-col gap-4">
              <h4 className="text-sm font-bold text-text-main border-b border-border-subtle pb-2">{tf('shirtParameters', 'Shirt Parameters')}</h4>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                {['neck', 'chest', 'waist', 'hips', 'shoulder', 'sleeves', 'length', 'frontNeck', 'backNeck'].map((field) => (
                  <div key={`shirt-${field}`} className="bg-bg-secondary p-3.5 rounded-xl border border-border-subtle flex flex-col gap-1 items-center">
                    <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf(field, field)}</span>
                    {isEditingMeasures ? (
                      <input type="number" value={shirtMeasures[field] || ''} onChange={(e) => setShirtMeasures({ ...shirtMeasures, [field]: Number(e.target.value) })} className="w-16 bg-bg-input text-center text-text-main border border-border-medium rounded-md py-0.5 outline-none focus:border-color-accent-purple text-sm font-black mt-1" />
                    ) : (
                      <span className="text-base font-black text-text-main">{shirtMeasures[field] ? `${shirtMeasures[field]}"` : '-'}</span>
                    )}
                  </div>
                ))}
              </div>
            </div>
            <div className="flex flex-col gap-4">
              <h4 className="text-sm font-bold text-text-main border-b border-border-subtle pb-2">{tf('pantParameters', 'Pant Parameters')}</h4>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                {['length', 'waist', 'hips', 'inseam', 'thigh', 'rise', 'bottom'].map((field) => (
                  <div key={`pant-${field}`} className="bg-bg-secondary p-3.5 rounded-xl border border-border-subtle flex flex-col gap-1 items-center">
                    <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf(field, field)}</span>
                    {isEditingMeasures ? (
                      <input type="number" value={pantMeasures[field] || ''} onChange={(e) => setPantMeasures({ ...pantMeasures, [field]: Number(e.target.value) })} className="w-16 bg-bg-input text-center text-text-main border border-border-medium rounded-md py-0.5 outline-none focus:border-color-accent-purple text-sm font-black mt-1" />
                    ) : (
                      <span className="text-base font-black text-text-main">{pantMeasures[field] ? `${pantMeasures[field]}"` : '-'}</span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>
          <div className="flex flex-col gap-2 mt-4 text-left">
            <span className="text-xs font-bold text-color-accent-purple flex items-center gap-1 uppercase tracking-wider">
              <MdBookmarkBorder /> {tf('specialSewingNotes', 'Special Sewing Notes')}
            </span>
            {isEditingMeasures ? (
              <textarea value={otherNotes} onChange={(e) => setOtherNotes(e.target.value)} placeholder={tf('specialNotesPlaceholder', 'Write notes here...')} className="w-full bg-bg-input border border-border-medium rounded-xl px-4 py-3 text-sm text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple transition-all font-medium mt-1 min-h-[80px]" />
            ) : (
              <div className="bg-bg-secondary p-4 rounded-xl border border-border-subtle mt-1">
                <p className="text-sm text-text-main opacity-80 italic">{otherNotes ? `"${otherNotes}"` : t('noRecords')}</p>
              </div>
            )}
          </div>
        </Card>
      )}

      {isEditProfileModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[440px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button onClick={() => setIsEditProfileModalOpen(false)} className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer">
              <MdClose className="w-5 h-5" />
            </button>
            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-1"><MdEdit className="text-color-accent-purple w-5 h-5" />{tf('editProfile', 'Edit Profile')}</h3>
            <p className="text-xs text-text-muted mb-5 font-semibold">{tf('editClientProfileSub', 'Update customer contact information details.')}</p>
            <form onSubmit={handleEditProfileSubmit} className="flex flex-col gap-4">
              <div className="flex flex-col gap-1"><label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('fullName')}</label><input type="text" required value={editName} onChange={e => { setEditName(e.target.value); setEditError(''); }} placeholder={t('fullName')} className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50" /></div>
              <div className="flex flex-col gap-1"><label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('phoneNumber', 'Phone Number')}</label><input type="tel" required value={editPhone} onChange={e => { setEditPhone(e.target.value); setEditError(''); }} placeholder={tf('contactPhone', 'Contact Phone')} className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50" /></div>
              <div className="flex flex-col gap-1"><label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('emailAddress')}</label><input type="email" value={editEmail} onChange={e => setEditEmail(e.target.value)} placeholder={t('emailAddress')} className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50" /></div>
              <div className="flex flex-col gap-1"><label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('address')}</label><input type="text" value={editAddress} onChange={e => setEditAddress(e.target.value)} placeholder={t('address')} className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main outline-none focus:border-color-accent-purple text-sm transition-all placeholder:text-text-muted/50" /></div>
              {editError && <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse">{editError}</span>}
              <div className="flex gap-3 mt-2">
                <button type="button" onClick={() => setIsEditProfileModalOpen(false)} className="flex-1 py-2.5 bg-bg-secondary border border-border-medium text-text-main rounded-xl font-bold text-sm hover:bg-bg-card-hover transition-all cursor-pointer">{t('cancel')}</button>
                <button type="submit" disabled={editLoading} className="flex-1 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50">{t('save')}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {isDeleteModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[420px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative text-left">
            <button onClick={() => setIsDeleteModalOpen(false)} className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"><MdClose className="w-5 h-5" /></button>
            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-2"><MdDelete className="text-color-accent-pink w-5 h-5" />{tf('deleteCustomerConfirmTitle', 'Delete Customer Profile')}</h3>
            <p className="text-xs text-text-muted mb-4 font-semibold">{tf('deleteCustomerConfirmDesc', 'Are you sure you want to delete profile for {name}?').replace('{name}', customer.name)}</p>
            {deleteError && <span className="text-xs text-color-accent-pink font-bold text-center block mb-4 animate-pulse">{deleteError}</span>}
            <div className="flex gap-3">
              <button type="button" onClick={() => setIsDeleteModalOpen(false)} className="flex-1 py-2.5 bg-bg-secondary border border-border-medium text-text-main rounded-xl font-bold text-sm hover:bg-bg-card-hover transition-all cursor-pointer">{t('cancel')}</button>
              <button onClick={handleDeleteCustomer} disabled={deleteLoading} className="flex-1 py-2.5 bg-rose-600 hover:bg-rose-700 text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-rose-950/20 transition-all cursor-pointer disabled:opacity-50">{tf('deleteProfile', 'Delete Profile')}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CustomerDetails;
