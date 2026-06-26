import React, { useState } from 'react';
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { useLanguage } from '../../context/LanguageContext';
import Sidebar from './Sidebar';
import Topbar from './Topbar';

export const AppLayout = () => {
  const { user, loading } = useAuth();
  const { t } = useLanguage();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  if (loading) {
    return (
      <div className="w-screen h-screen flex flex-col items-center justify-center bg-bg-primary gap-4">
        <div className="w-12 h-12 rounded-full border-4 border-color-accent-purple border-t-transparent animate-spin"></div>
        <span className="text-sm font-semibold text-text-muted">Unlocking Ledger...</span>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  const getPageTitle = () => {
    if (location.pathname === '/dashboard') return t('dashboard');
    if (location.pathname === '/profile') return t('profile');
    if (location.pathname === '/customers') return t('customerRegistry') !== 'customerRegistry' ? t('customerRegistry') : 'Customer Registry';
    if (location.pathname.startsWith('/customers/')) return 'Customer Details';
    if (location.pathname === '/orders') return t('ordersRegistry') !== 'ordersRegistry' ? t('ordersRegistry') : 'Orders Registry';
    if (location.pathname === '/new-order') return t('newOrder') !== 'newOrder' ? t('newOrder') : 'New Order';
    if (location.pathname.includes('/edit') && location.pathname.includes('/orders/')) return t('editOrder') !== 'editOrder' ? t('editOrder') : 'Edit Order';
    if (location.pathname.startsWith('/orders/')) return 'Order Details';
    if (location.pathname === '/invoices') return 'Invoice Registry';
    if (location.pathname.startsWith('/invoices/')) return 'Invoice Details';
    if (location.pathname === '/payments') return t('paymentsLedger') !== 'paymentsLedger' ? t('paymentsLedger') : 'Payments Ledger';
    if (location.pathname === '/ledger') return t('paymentsLedger') !== 'paymentsLedger' ? t('paymentsLedger') : 'Payments Ledger';
    if (location.pathname === '/deliveries') return t('deliveriesDispatch') !== 'deliveriesDispatch' ? t('deliveriesDispatch') : 'Deliveries Dispatch';
    if (location.pathname === '/notifications') return t('notificationsFeed') !== 'notificationsFeed' ? t('notificationsFeed') : 'Notifications Feed';
    if (location.pathname === '/karigars') return t('karigarRegistry') !== 'karigarRegistry' ? t('karigarRegistry') : 'Karigar Registry';
    if (location.pathname === '/machines') return t('machinesRegistry') !== 'machinesRegistry' ? t('machinesRegistry') : 'Machines Registry';
    if (location.pathname === '/inventory') return t('inventoryManager') !== 'inventoryManager' ? t('inventoryManager') : 'Inventory Manager';
    return "Tailor's App ERP";
  };

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-bg-primary relative">
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/60 backdrop-blur-xs z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />

      <div className="flex flex-col flex-1 overflow-hidden">
        <Topbar pageTitle={getPageTitle()} onMenuToggle={() => setSidebarOpen(prev => !prev)} />

        <main className="flex-1 overflow-y-auto p-4 sm:p-8 bg-bg-primary">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default AppLayout;
