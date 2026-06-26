/* src/pages/Delivery.jsx */
import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import Card from '../components/common/Card';
import { api } from '../services/api';
import { formatDate } from '../utils/formatters';
import { MdLocalShipping, MdCheckCircle } from 'react-icons/md';
import { useLanguage } from '../context/LanguageContext';

export const Delivery = () => {
  const [searchParams] = useSearchParams();
  const [deliveries, setDeliveries] = useState([]);
  const [loading, setLoading] = useState(false);
  const { t } = useLanguage();
  const [activeTab, setActiveTab] = useState(() => {
    const tab = searchParams.get('tab');
    return ['Today', 'Late', 'Upcoming', 'Delivered'].includes(tab) ? tab : 'Today';
  });

  const tabs = ['Today', 'Late', 'Upcoming', 'Delivered'];

  // Helper with fallbacks for translations
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const getTabLabel = (tab) => {
    if (tab === 'Today') return tf('today', 'Today');
    if (tab === 'Late') return tf('late', 'Late');
    if (tab === 'Upcoming') return tf('upcoming', 'Upcoming');
    if (tab === 'Delivered') return tf('delivered', 'Delivered');
    if (tab === 'Pending') return tf('pending', 'Pending');
    return tab;
  };

  const fetchDeliveries = async () => {
    setLoading(true);
    try {
      const data = await api.get(`/deliveries?tab=${activeTab}`);
      setDeliveries(data);
    } catch (err) {
      console.error('Failed to fetch deliveries:', err);
    }
    setLoading(false);
  };

  useEffect(() => {
    fetchDeliveries();
  }, [activeTab]);

  const handleMarkDelivered = async (id) => {
    try {
      await api.put(`/deliveries/${id}/deliver`);
      fetchDeliveries();
    } catch (err) {
      console.error('Failed to mark delivered:', err);
    }
  };

  const getTabBadgeColor = (tab) => {
    switch (tab) {
      case 'Today': return 'bg-blue-500 text-white-forced';
      case 'Late': return 'bg-color-accent-pink text-white-forced';
      case 'Upcoming': return 'bg-color-accent-purple text-white-forced';
      case 'Delivered': return 'bg-color-accent-emerald text-white-forced';
      default: return 'bg-border-medium text-text-muted border border-border-subtle';
    }
  };

  return (
    <div className="flex flex-col gap-6 select-none text-left">

      {/* Page Header */}
      <div>
        <h2 className="text-xl font-bold text-text-main tracking-wide">{tf('deliveriesDispatch', 'Deliveries Dispatch')}</h2>
        <p className="text-xs text-text-muted mt-0.5 font-semibold">{tf('deliveriesDispatchSub', 'Log dispatch receipts and pending order delivery queues')}</p>
      </div>

      {/* Tabs Selector Card */}
      <Card className="flex items-center gap-2 p-3">
        {tabs.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 text-xs font-bold rounded-xl border transition-all cursor-pointer flex items-center gap-1.5
              ${activeTab === tab
                ? 'delivery-active-tab border-color-accent-purple shadow-md'
                : 'filter-tab-inactive hover:text-text-main'}`}
          >
            <span>{getTabLabel(tab)}</span>
          </button>
        ))}
      </Card>

      {/* Deliveries Table Card */}
      <div className="bg-bg-secondary rounded-[20px] border border-border-subtle overflow-hidden shadow-card">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-bg-primary/30 border-b border-border-subtle">
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('orderId', 'Order ID')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('customer', 'Customer')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('apparelCategory', 'Apparel Category')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('targetDate', 'Target Date')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider">{tf('status', 'Status')}</th>
                <th className="px-6 py-4 text-xs font-bold text-text-muted uppercase tracking-wider text-right">{tf('actions', 'Actions')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-subtle">
              {loading ? (
                <tr>
                  <td colSpan="6" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('syncingDeliveries', 'Syncing deliveries...')}
                  </td>
                </tr>
              ) : deliveries.length === 0 ? (
                <tr>
                  <td colSpan="6" className="px-6 py-12 text-center text-sm text-text-muted">
                    {tf('noDeliveries', 'No deliveries recorded in this slot.')}
                  </td>
                </tr>
              ) : (
                deliveries.map((del) => (
                  <tr key={del._id} className="hover:bg-bg-hover transition-colors">
                    <td className="px-6 py-4 text-sm font-black text-text-main">{del.orderId}</td>
                    <td className="px-6 py-4 text-sm font-bold text-text-main/90">{del.customerName}</td>
                    <td className="px-6 py-4 text-sm font-bold text-text-muted">{del.apparelType}</td>
                    <td className="px-6 py-4 text-xs font-bold text-text-main">{formatDate(del.deliveryDate)}</td>
                    <td className="px-6 py-4 text-xs">
                      <span style={{ whiteSpace: 'nowrap' }} className={`px-2.5 py-1 rounded-md font-bold uppercase tracking-wider ${getTabBadgeColor(del.status)}`}>
                        {getTabLabel(del.status)}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-right">
                      {del.status === 'Pending' ? (
                        <button
                          onClick={() => handleMarkDelivered(del._id)}
                          style={{ whiteSpace: 'nowrap' }}
                          className="px-3.5 py-1.5 bg-color-accent-emerald text-white-forced rounded-lg text-xs font-extrabold flex items-center gap-1.5 hover:bg-emerald-600 active:scale-95 transition-all shadow-md shadow-emerald-950/20 cursor-pointer ml-auto"
                        >
                          <MdCheckCircle className="w-4 h-4 text-white-forced" />
                          <span>{tf('markDelivered', 'Mark Delivered')}</span>
                        </button>
                      ) : (
                        <span className="text-xs text-text-muted flex items-center gap-1 justify-end">
                          <MdLocalShipping className="w-4 h-4 text-color-accent-emerald" />
                          <span>{tf('dispatchedBy', 'Dispatched by {name}').replace('{name}', del.deliveredBy)}</span>
                        </span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  );
};

export default Delivery;
