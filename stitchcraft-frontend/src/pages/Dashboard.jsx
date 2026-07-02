/* src/pages/Dashboard.jsx */
import React from 'react';
import StatCard from '../components/specific/StatCard';
import RecentOrders from '../components/specific/RecentOrders';
import Card from '../components/common/Card';
import { GiSewingMachine, GiSewingNeedle } from 'react-icons/gi';
import {
  MdTimer, MdWarning, MdPeople, MdNotificationsActive,
  MdPersonAdd, MdStraighten, MdAdd
} from 'react-icons/md';

// Custom State/Business Logic Hook
import useDashboard from '../features/dashboard/hooks/useDashboard';

// Modular Feature Components
import WeeklyStitchingChart from '../features/dashboard/components/WeeklyStitchingChart';
import PerformanceTracker from '../features/dashboard/components/PerformanceTracker';
import DashboardCalendar from '../features/dashboard/components/DashboardCalendar';
import RemindersPanel from '../features/dashboard/components/RemindersPanel';

export const Dashboard = () => {
  const {
    navigate,
    t,
    settings,
    stats,
    perfTab,
    setPerfTab,
    loading,
    activeDayIdx,
    setActiveDayIdx,
    selectedRange,
    setSelectedRange,
    calendarMonth,
    calendarYear,
    fabOpen,
    setFabOpen,
    updateOrderStatus,
    handlePrevMonth,
    handleNextMonth,
    handlePrevYear,
    handleNextYear,
    handleDayClick,
    filteredOrders,
  } = useDashboard();

  return (
    <div className="flex flex-col gap-6 select-none">
      {settings.showStatsCards && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          <StatCard
            title={t('todayDelivery')}
            value={loading ? '—' : stats.todayDelivery}
            subtitle={t('todayDeliverySub')}
            variant="blue"
            icon={<MdTimer className="w-6 h-6 text-white-forced" />}
            onClick={() => navigate('/deliveries?tab=Today')}
          />
          <StatCard
            title={t('lateDelivery')}
            value={loading ? '—' : stats.lateDelivery}
            subtitle={t('lateDeliverySub')}
            variant="pink"
            icon={<MdWarning className="w-6 h-6 text-white-forced animate-bounce" />}
            onClick={() => navigate('/deliveries?tab=Late')}
          />
          <StatCard
            title={t('incomingOrdersCount')}
            value={loading ? '—' : stats.incomingOrders}
            subtitle={t('incomingOrdersSub')}
            variant="purple"
            icon={<GiSewingMachine className="w-6 h-6 text-white-forced" />}
            onClick={() => navigate('/orders?status=Incoming')}
          />
          <StatCard
            title={t('totalCustomers')}
            value={loading ? '—' : stats.totalCustomers}
            subtitle={t('totalCustomersSub')}
            variant="emerald"
            icon={<MdPeople className="w-6 h-6 text-white-forced" />}
            onClick={() => navigate('/customers')}
          />
        </div>
      )}

      {(() => {
        const showLeftCol = settings.showRecentOrders || settings.showWeeklyStitching || settings.showPerformanceTracking;
        const showRightCol = settings.showCalendar || settings.showReminders;

        if (!showLeftCol && !showRightCol) {
          return (
            <Card className="flex flex-col items-center justify-center py-20 text-center">
              <div className="w-16 h-16 rounded-2xl bg-bg-secondary border border-border-subtle flex items-center justify-center text-text-muted mb-4 shadow-inner">
                <MdNotificationsActive className="w-8 h-8 text-color-accent-purple" />
              </div>
              <h3 className="text-lg font-bold text-text-main">Dashboard is Empty</h3>
              <p className="text-xs text-text-muted max-w-sm mt-1 mb-6 font-semibold">
                All widgets are hidden. Go to Settings to select the graphs and data cards you want to see.
              </p>
              <button
                onClick={() => navigate('/profile')}
                className="px-6 py-2.5 bg-color-accent-purple text-white-forced rounded-xl font-bold text-xs shadow-lg shadow-color-accent-purple/20 hover:opacity-90 active:scale-95 transition-all cursor-pointer"
              >
                Go to Settings
              </button>
            </Card>
          );
        }

        return (
          <div className={`grid grid-cols-1 ${showLeftCol && showRightCol ? 'lg:grid-cols-3' : ''} gap-8`}>
            {showLeftCol && (
              <div className={`${showLeftCol && showRightCol ? 'lg:col-span-2' : 'w-full'} flex flex-col gap-6 text-left`}>
                {settings.showRecentOrders && (
                  <RecentOrders
                    orders={filteredOrders}
                    onUpdateStatus={updateOrderStatus}
                    onEditOrder={(order) => navigate(`/orders/${order._id}/edit`)}
                  />
                )}

                {settings.showWeeklyStitching && (
                  <WeeklyStitchingChart
                    chartData={stats.dailyStitching}
                    activeDayIdx={activeDayIdx}
                    setActiveDayIdx={setActiveDayIdx}
                    t={t}
                  />
                )}

                {settings.showPerformanceTracking && (
                  <PerformanceTracker
                    stats={stats}
                    perfTab={perfTab}
                    setPerfTab={setPerfTab}
                    t={t}
                  />
                )}
              </div>
            )}

            {showRightCol && (
              <div className={`${showLeftCol && showRightCol ? 'lg:col-span-1' : 'w-full'} flex flex-col gap-6 text-left`}>
                {settings.showCalendar && (
                  <DashboardCalendar
                    calendarMonth={calendarMonth}
                    calendarYear={calendarYear}
                    handlePrevMonth={handlePrevMonth}
                    handleNextMonth={handleNextMonth}
                    handlePrevYear={handlePrevYear}
                    handleNextYear={handleNextYear}
                    selectedRange={selectedRange}
                    setSelectedRange={setSelectedRange}
                    handleDayClick={handleDayClick}
                    filteredOrdersCount={filteredOrders.length}
                    t={t}
                  />
                )}

                {settings.showReminders && (
                  <RemindersPanel
                    reminders={stats.reminders}
                    t={t}
                  />
                )}
              </div>
            )}
          </div>
        );
      })()}

      {/* FAB actions */}
      <div className="fixed bottom-8 right-8 z-50 flex flex-col items-end gap-3">
        <div className={`flex flex-col gap-2 items-end transition-all duration-300 ${fabOpen ? 'opacity-100 translate-y-0 pointer-events-auto' : 'opacity-0 translate-y-4 pointer-events-none'
          }`}>
          {[
            { label: t('createOrder'), icon: <GiSewingNeedle className="w-4 h-4" />, to: '/new-order', color: 'bg-color-accent-purple' },
            { label: t('newCustomer'), icon: <MdPersonAdd className="w-4 h-4" />, to: '/customers?action=new', color: 'bg-color-accent-blue' },
            { label: t('addMeasurement'), icon: <MdStraighten className="w-4 h-4" />, to: '/customers', color: 'bg-color-accent-pink' },
          ].map((action) => (
            <button
              key={action.label}
              onClick={() => { setFabOpen(false); navigate(action.to); }}
              className={`flex items-center gap-3 px-4 py-2.5 ${action.color} text-white-forced rounded-2xl font-bold text-sm shadow-xl cursor-pointer hover:opacity-90 active:scale-95 transition-all whitespace-nowrap`}
            >
              {action.icon}
              <span>{action.label}</span>
            </button>
          ))}
        </div>

        <button
          onClick={() => setFabOpen(prev => !prev)}
          className={`w-14 h-14 rounded-2xl flex items-center justify-center shadow-2xl cursor-pointer transition-all duration-300 ${fabOpen
            ? 'bg-rose-500 shadow-rose-500/30 rotate-45'
            : 'bg-color-accent-purple shadow-color-accent-purple/40 hover:scale-110'
            }`}
        >
          <MdAdd className="w-7 h-7 text-white-forced" />
        </button>
      </div>

      {fabOpen && (
        <div
          className="fixed inset-0 z-40"
          onClick={() => setFabOpen(false)}
        />
      )}
    </div>
  );
};

export default Dashboard;
