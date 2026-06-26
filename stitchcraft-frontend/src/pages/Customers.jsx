import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { api } from '../services/api';
import Card from '../components/common/Card';
import { MdSearch, MdPersonAdd, MdClose, MdPeople } from 'react-icons/md';
import { GiSewingNeedle } from 'react-icons/gi';
import { useLanguage } from '../context/LanguageContext';

export const Customers = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const { t } = useLanguage();

  // Add customer modal state
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [newName, setNewName] = useState('');
  const [newPhone, setNewPhone] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [newAddress, setNewAddress] = useState('');
  const [addLoading, setAddLoading] = useState(false);
  const [addError, setAddError] = useState('');

  // Helper with fallbacks for translations
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const fetchCustomers = async (search = '') => {
    setLoading(true);
    try {
      const data = await api.get(`/customers?search=${encodeURIComponent(search)}`);
      setCustomers(data);
    } catch (err) {
      console.error('Failed to fetch customers:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCustomers(searchTerm);
  }, [searchTerm]);

  // Listen for "?action=new" from the Dashboard FAB
  useEffect(() => {
    if (searchParams.get('action') === 'new') {
      setIsAddModalOpen(true);
      setSearchParams({});
    }
  }, [searchParams, setSearchParams]);

  const handleAddCustomer = async (e) => {
    e.preventDefault();
    if (!newName || !newPhone) {
      setAddError('Name and phone are required.');
      return;
    }
    setAddLoading(true);
    setAddError('');
    try {
      const data = await api.post('/customers', {
        name: newName,
        phone: newPhone,
        email: newEmail,
        address: newAddress,
      });
      setCustomers(prev => [data, ...prev]);
      setIsAddModalOpen(false);
      setNewName('');
      setNewPhone('');
      setNewEmail('');
      setNewAddress('');
      navigate(`/customers/${data._id}`);
    } catch (err) {
      setAddError(err.message || 'Failed to create customer.');
    } finally {
      setAddLoading(false);
    }
  };

  const getInitials = (name = '') =>
    name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();

  const avatarColors = [
    'from-violet-600 to-indigo-600',
    'from-pink-600 to-rose-600',
    'from-emerald-600 to-teal-600',
    'from-amber-600 to-orange-600',
    'from-sky-600 to-blue-600',
  ];

  return (
    <div className="flex flex-col gap-6 select-none">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-text-main tracking-wide">{tf('customerRegistry', 'Customer Registry')}</h2>
          <p className="text-xs text-text-muted mt-0.5 font-semibold">
            {tf('customerSub', 'Manage tailoring customer profiles and sizing history')}
          </p>
        </div>
        <button
          onClick={() => { setIsAddModalOpen(true); setAddError(''); }}
          className="btn-tactile flex items-center gap-2 self-start sm:self-auto cursor-pointer"
        >
          <MdPersonAdd className="w-5 h-5 text-white-forced" />
          <span className="text-white-forced">{t('newCustomer')}</span>
        </button>
      </div>

      {/* Search Bar */}
      <Card className="py-3 px-4">
        <div className="relative">
          <MdSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted w-5 h-5" />
          <input
            type="text"
            placeholder={tf('searchCustomerPlaceholder', 'Search by name, phone, or ID...')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-bg-input border border-border-subtle rounded-xl text-sm text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple/50 transition-all"
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

      {/* Customer Grid */}
      {loading ? (
        <div className="text-center py-16 text-sm text-text-muted">{tf('loadingCustomers', 'Loading Client Profiles...')}</div>
      ) : customers.length === 0 ? (
        <Card className="flex flex-col items-center justify-center py-16 text-center gap-4">
          <div className="w-14 h-14 rounded-full bg-bg-hover flex items-center justify-center text-text-muted">
            <MdPeople className="w-7 h-7" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-text-main">{tf('noCustomersFound', 'No customers found')}</h4>
            <p className="text-xs text-text-muted mt-1 font-semibold">
              {searchTerm ? `No results for "${searchTerm}"` : tf('noCustomersDesc', 'Register your first customer details to get started.')}
            </p>
          </div>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
          {customers.map((customer, idx) => (
            <button
              key={customer._id}
              onClick={() => navigate(`/customers/${customer._id}`)}
              className="group bg-bg-secondary border border-border-subtle rounded-[20px] p-5 flex flex-col gap-4 text-left hover:border-color-accent-purple/40 hover:shadow-lg hover:shadow-color-accent-purple/10 active:scale-[0.98] transition-all duration-200 cursor-pointer"
            >
              {/* Avatar + Name */}
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${avatarColors[idx % avatarColors.length]} flex items-center justify-center font-black text-white-forced text-base shadow-lg shrink-0`}>
                  {getInitials(customer.name)}
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-bold text-text-main truncate group-hover:text-color-accent-purple transition-colors">
                    {customer.name}
                  </p>
                  <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider">
                    {customer.customerId || 'CUST-???'}
                  </p>
                </div>
              </div>

              {/* Contact Details */}
              <div className="flex flex-col gap-1.5 text-xs text-text-muted border-t border-border-subtle pt-3">
                <span className="truncate">📞 {customer.phone}</span>
                {customer.email && (
                  <span className="truncate">✉️ {customer.email}</span>
                )}
              </div>

              {/* Orders count badge */}
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider flex items-center gap-1">
                  <GiSewingNeedle className="w-3.5 h-3.5 text-color-accent-purple" />
                  {customer.ordersCount || 0} {tf('orders', 'Orders')}
                </span>
                <span className="text-[10px] font-bold text-color-accent-purple">
                  {tf('viewProfile', 'View Profile')} →
                </span>
              </div>
            </button>
          ))}
        </div>
      )}

      {/* Add Customer Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="w-full max-w-[440px] bg-bg-modal border border-border-medium rounded-[24px] p-6 shadow-2xl relative">
            <button
              onClick={() => setIsAddModalOpen(false)}
              className="absolute right-4 top-4 p-1.5 rounded-lg bg-bg-secondary border border-border-subtle text-text-muted hover:text-text-main cursor-pointer"
            >
              <MdClose className="w-5 h-5" />
            </button>

            <h3 className="text-lg font-black text-text-main flex items-center gap-2 mb-1">
              <MdPersonAdd className="text-color-accent-purple w-5 h-5" />
              {tf('registerNewClient', 'Register New Client')}
            </h3>
            <p className="text-xs text-text-muted mb-5 font-semibold">
              {tf('registerNewClientDesc', 'Create a new customer profile card in the database.')}
            </p>

            <form onSubmit={handleAddCustomer} className="flex flex-col gap-4">
              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('fullName')}</label>
                <input
                  type="text"
                  required
                  value={newName}
                  onChange={e => { setNewName(e.target.value); setAddError(''); }}
                  placeholder={tf('fullName', 'Full Name')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple text-sm transition-all"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{tf('phoneNumber', 'Phone Number')}</label>
                <input
                  type="tel"
                  required
                  value={newPhone}
                  onChange={e => { setNewPhone(e.target.value); setAddError(''); }}
                  placeholder={tf('contactPhone', 'Contact Phone')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple text-sm transition-all"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('emailAddress')}</label>
                <input
                  type="email"
                  value={newEmail}
                  onChange={e => setNewEmail(e.target.value)}
                  placeholder={t('emailAddress')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple text-sm transition-all"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('address')}</label>
                <input
                  type="text"
                  value={newAddress}
                  onChange={e => setNewAddress(e.target.value)}
                  placeholder={t('address')}
                  className="w-full px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple text-sm transition-all"
                />
              </div>

              {addError && (
                <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse">
                  {addError}
                </span>
              )}

              <div className="flex gap-3 mt-2">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="flex-1 py-2.5 btn-tactile-dark font-bold text-sm transition-all cursor-pointer"
                >
                  {t('cancel')}
                </button>
                <button
                  type="submit"
                  disabled={addLoading}
                  className="flex-1 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-sm shadow-lg shadow-color-accent-purple/20 hover:bg-color-accent-purple/90 transition-all cursor-pointer disabled:opacity-50"
                >
                  {addLoading ? t('saving') : tf('createProfile', 'Create Profile')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Customers;
