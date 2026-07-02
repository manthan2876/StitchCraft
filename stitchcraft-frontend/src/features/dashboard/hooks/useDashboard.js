/* src/features/dashboard/hooks/useDashboard.js */
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useLanguage } from '../../../context/LanguageContext';
import { api } from '../../../services/api';

export const useDashboard = () => {
  const navigate = useNavigate();
  const { t } = useLanguage();

  const [settings] = useState(() => {
    const saved = localStorage.getItem('stitchcraft_settings');
    const defaultSettings = {
      showStatsCards: true,
      showRecentOrders: true,
      showWeeklyStitching: true,
      showPerformanceTracking: true,
      showCalendar: true,
      showReminders: true,
    };
    if (!saved) return defaultSettings;
    try {
      const parsed = JSON.parse(saved);
      return { ...defaultSettings, ...parsed };
    } catch (e) {
      return defaultSettings;
    }
  });

  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const [stats, setStats] = useState({
    todayDelivery: 0,
    lateDelivery: 0,
    incomingOrders: 0,
    totalCustomers: 0,
    totalRevenue: 0,
    recentOrders: [],
    reminders: [],
    dailyStitching: [0, 0, 0, 0, 0, 0, 0],
    karigarPerformance: [],
    machinePerformance: []
  });

  const [perfTab, setPerfTab] = useState('Karigars');
  const [loading, setLoading] = useState(true);
  const [activeDayIdx, setActiveDayIdx] = useState(() => {
    const d = new Date().getDay();
    return d === 0 ? 6 : d - 1;
  });

  const [selectedRange, setSelectedRange] = useState({ start: null, end: null });
  const [calendarMonth, setCalendarMonth] = useState(() => {
    const now = new Date();
    return ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'][now.getMonth()];
  });
  const [calendarYear, setCalendarYear] = useState(() => new Date().getFullYear());
  const [fabOpen, setFabOpen] = useState(false);

  const monthsList = React.useMemo(() => [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ], []);

  const fetchStats = async () => {
    try {
      const data = await api.get('/dashboard/stats');
      setStats(data);
    } catch (err) {
      console.error('Failed to fetch dashboard stats:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  const updateOrderStatus = async (orderId, newStatus) => {
    try {
      await api.put(`/orders/${orderId}`, { status: newStatus });
      fetchStats();
    } catch (err) {
      console.error('Failed to update status:', err);
      // Fallback state update locally
      setStats(prev => ({
        ...prev,
        recentOrders: prev.recentOrders.map(o => o._id === orderId ? { ...o, status: newStatus } : o)
      }));
    }
  };

  const handlePrevMonth = () => {
    let idx = monthsList.indexOf(calendarMonth) - 1;
    if (idx < 0) {
      idx = 11;
      setCalendarYear(y => y - 1);
    }
    setCalendarMonth(monthsList[idx]);
    setSelectedRange({ start: null, end: null });
  };

  const handleNextMonth = () => {
    let idx = monthsList.indexOf(calendarMonth) + 1;
    if (idx > 11) {
      idx = 0;
      setCalendarYear(y => y + 1);
    }
    setCalendarMonth(monthsList[idx]);
    setSelectedRange({ start: null, end: null });
  };

  const handlePrevYear = () => {
    setCalendarYear(y => y - 1);
    setSelectedRange({ start: null, end: null });
  };

  const handleNextYear = () => {
    setCalendarYear(y => y + 1);
    setSelectedRange({ start: null, end: null });
  };

  const handleDayClick = (day) => {
    // getDaysInMonth calculation inside helper
    const idx = monthsList.indexOf(calendarMonth);
    const daysInMonth = new Date(calendarYear, idx + 1, 0).getDate();

    if (day < 1 || day > daysInMonth) return;
    if (!selectedRange.start || (selectedRange.start && selectedRange.end)) {
      setSelectedRange({ start: day, end: null });
    } else {
      const end = day;
      const start = selectedRange.start;
      setSelectedRange(end < start ? { start: end, end: start } : { start, end });
    }
  };

  const filteredOrders = React.useMemo(() => {
    if (!selectedRange.start || !selectedRange.end) return stats.recentOrders;
    const mIdx = monthsList.indexOf(calendarMonth);
    const startDate = new Date(calendarYear, mIdx, selectedRange.start);
    const endDate = new Date(calendarYear, mIdx, selectedRange.end, 23, 59, 59);
    return stats.recentOrders.filter(o => {
      const d = new Date(o.deliveryDate);
      return d >= startDate && d <= endDate;
    });
  }, [stats.recentOrders, selectedRange, calendarMonth, calendarYear, monthsList]);

  return {
    navigate,
    t,
    settings,
    tf,
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
  };
};

export default useDashboard;
