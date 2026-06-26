import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useLanguage } from '../context/LanguageContext';
import { api } from '../services/api';
import StatCard from '../components/specific/StatCard';
import RecentOrders from '../components/specific/RecentOrders';
import Card from '../components/common/Card';
import { formatCurrency, formatDate } from '../utils/formatters';
import { GiSewingMachine, GiSewingNeedle } from 'react-icons/gi';
import {
  MdChevronLeft, MdChevronRight, MdPeople, MdNotificationsActive,
  MdTimer, MdWarning, MdArrowForward, MdAdd, MdPersonAdd, MdStraighten, MdClose
} from 'react-icons/md';
import { Link } from 'react-router-dom';

const getLineProperties = (pointA, pointB) => {
  const lengthX = pointB[0] - pointA[0];
  const lengthY = pointB[1] - pointA[1];
  return {
    length: Math.sqrt(Math.pow(lengthX, 2) + Math.pow(lengthY, 2)),
    angle: Math.atan2(lengthY, lengthX)
  };
};

const getControlPoint = (current, previous, next, reverse) => {
  const p = previous || current;
  const n = next || current;
  const smoothing = 0.18;
  const o = getLineProperties(p, n);
  const angle = o.angle + (reverse ? Math.PI : 0);
  const length = o.length * smoothing;
  const x = current[0] + Math.cos(angle) * length;
  const y = current[1] + Math.sin(angle) * length;
  return [x, y];
};

const getBezierCommand = (point, i, a) => {
  const cps = getControlPoint(a[i - 1], a[i - 2], point, false);
  const cpe = getControlPoint(point, a[i - 1], a[i + 1], true);
  return `C ${cps[0]},${cps[1]} ${cpe[0]},${cpe[1]} ${point[0]},${point[1]}`;
};

const getSvgPath = (points) => {
  return points.reduce((acc, point, i, a) => i === 0
    ? `M ${point[0]},${point[1]}`
    : `${acc} ${getBezierCommand(point, i, a)}`
    , '');
};

export const Dashboard = () => {
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

  const getDaysInMonth = (monthName, year) => {
    const idx = monthsList.indexOf(monthName);
    return new Date(year, idx + 1, 0).getDate();
  };

  const getFirstDayOffset = (monthName, year) => {
    const idx = monthsList.indexOf(monthName);
    return new Date(year, idx, 1).getDay();
  };

  const daysInMonth = getDaysInMonth(calendarMonth, calendarYear);
  const firstDayOffset = getFirstDayOffset(calendarMonth, calendarYear);

  const today = new Date();
  const todayDay = today.getDate();
  const todayMonth = monthsList[today.getMonth()];
  const todayYear = today.getFullYear();
  const isCurrentMonthYear = calendarMonth === todayMonth && calendarYear === todayYear;

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

  useEffect(() => { fetchStats(); }, []);

  const updateOrderStatus = async (orderId, newStatus) => {
    try {
      await api.put(`/orders/${orderId}`, { status: newStatus });
      fetchStats();
    } catch (err) {
      console.error('Failed to update status:', err);
      // Fallback state update locally for Step 1 since orders PUT is not yet implemented
      setStats(prev => ({
        ...prev,
        recentOrders: prev.recentOrders.map(o => o._id === orderId ? { ...o, status: newStatus } : o)
      }));
    }
  };

  const handlePrevMonth = () => {
    let idx = monthsList.indexOf(calendarMonth) - 1;
    if (idx < 0) { idx = 11; setCalendarYear(y => y - 1); }
    setCalendarMonth(monthsList[idx]);
    setSelectedRange({ start: null, end: null });
  };
  const handleNextMonth = () => {
    let idx = monthsList.indexOf(calendarMonth) + 1;
    if (idx > 11) { idx = 0; setCalendarYear(y => y + 1); }
    setCalendarMonth(monthsList[idx]);
    setSelectedRange({ start: null, end: null });
  };
  const handlePrevYear = () => { setCalendarYear(y => y - 1); setSelectedRange({ start: null, end: null }); };
  const handleNextYear = () => { setCalendarYear(y => y + 1); setSelectedRange({ start: null, end: null }); };

  const handleDayClick = (day) => {
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

  const chartData = stats.dailyStitching || [0, 0, 0, 0, 0, 0, 0];
  const maxVal = Math.max(...chartData, 1000);
  const xCoords = [20, 96.7, 173.3, 250, 326.7, 403.3, 480];
  const points = xCoords.map((x, i) => {
    const val = chartData[i] || 0;
    const y = 140 - ((val / maxVal) * 105);
    return [x, y];
  });

  const linePath = getSvgPath(points);
  const fillPath = `${linePath} L 480,160 L 20,160 Z`;
  const activePoint = points[activeDayIdx] || [250, 100];
  const activeVal = chartData[activeDayIdx] || 0;
  const tooltipLeft = activePoint[0];
  const tooltipTop = activePoint[1] - 42;

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
                  <Card className="flex flex-col gap-6">
                    <div>
                      <h3 className="text-lg font-bold text-text-main tracking-wide">{t('weeklyStitching')}</h3>
                      <p className="text-xs text-text-muted mt-0.5">{t('weeklyStitchingSub')}</p>
                    </div>
                    <div className="relative bg-bg-secondary border border-border-subtle rounded-2xl p-4 overflow-hidden">
                      <div
                        className="absolute px-2.5 py-1.5 rounded-xl text-[10px] font-black shadow-xl shadow-color-accent-purple/30 transition-all duration-300 -translate-x-1/2 pointer-events-none select-none z-10 border border-border-medium"
                        style={{
                          left: `${tooltipLeft}px`,
                          top: `${tooltipTop}px`,
                          backgroundColor: '#7a60ff',
                          color: '#ffffff'
                        }}
                      >
                        {formatCurrency(activeVal)}
                      </div>

                      <svg className="w-full h-[160px]" viewBox="0 0 500 160" preserveAspectRatio="none">
                        <defs>
                          <linearGradient id="glowWave" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="0%" stopColor="#7a60ff" stopOpacity="0.45" />
                            <stop offset="100%" stopColor="#7a60ff" stopOpacity="0.0" />
                          </linearGradient>
                        </defs>
                        <line x1="0" y1="40" x2="500" y2="40" stroke="rgba(255,255,255,0.03)" strokeWidth="1" className="chart-grid-line" />
                        <line x1="0" y1="80" x2="500" y2="80" stroke="rgba(255,255,255,0.03)" strokeWidth="1" className="chart-grid-line" />
                        <line x1="0" y1="120" x2="500" y2="120" stroke="rgba(255,255,255,0.03)" strokeWidth="1" className="chart-grid-line" />

                        <path d={fillPath} fill="url(#glowWave)" className="transition-all duration-500 ease-in-out" />
                        <path d={linePath} fill="none" stroke="#7a60ff" strokeWidth="3.5" className="transition-all duration-500 ease-in-out" />

                        <circle
                          cx={activePoint[0]}
                          cy={activePoint[1]}
                          r="5"
                          fill="#7a60ff"
                          stroke="#ffffff"
                          strokeWidth="2.5"
                          className="animate-ping transition-all duration-300"
                          style={{ transformOrigin: `${activePoint[0]}px ${activePoint[1]}px` }}
                        />
                        <circle
                          cx={activePoint[0]}
                          cy={activePoint[1]}
                          r="5"
                          fill="#7a60ff"
                          stroke="#ffffff"
                          strokeWidth="2.5"
                          className="transition-all duration-300"
                        />

                        {points.map((p, idx) => (
                          <rect
                            key={idx}
                            x={p[0] - 38}
                            y="0"
                            width="76"
                            height="160"
                            fill="transparent"
                            className="cursor-pointer"
                            onMouseEnter={() => setActiveDayIdx(idx)}
                          />
                        ))}
                      </svg>
                    </div>

                    <div className="flex justify-between px-2 text-[10px] font-bold text-text-muted/80 uppercase tracking-widest">
                      {['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'].map((key, idx) => (
                        <span
                          key={key}
                          className={`cursor-pointer transition-all duration-200 ${activeDayIdx === idx
                            ? 'text-color-accent-purple font-black scale-110'
                            : 'hover:text-text-main'
                            }`}
                          onMouseEnter={() => setActiveDayIdx(idx)}
                        >
                          {t(key)}
                        </span>
                      ))}
                    </div>
                  </Card>
                )}

                {settings.showPerformanceTracking && (
                  <Card className="flex flex-col gap-6">
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border-subtle pb-3">
                      <div>
                        <h3 className="text-lg font-bold text-text-main tracking-wide">{tf('performanceTracking', 'Performance Tracking')}</h3>
                        <p className="text-xs text-text-muted mt-0.5">{tf('performanceTrackingSub', 'Monitor artisan workloads and machinery utilization')}</p>
                      </div>
                      <div className="flex bg-bg-secondary p-1 rounded-xl border border-border-subtle">
                        <button
                          type="button"
                          onClick={() => setPerfTab('Karigars')}
                          className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-all cursor-pointer ${perfTab === 'Karigars' ? 'bg-color-accent-purple text-white-forced shadow-md' : 'text-text-muted hover:text-text-main'
                            }`}
                        >
                          {tf('karigars', 'Karigars')}
                        </button>
                        <button
                          type="button"
                          onClick={() => setPerfTab('Machines')}
                          className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-all cursor-pointer ${perfTab === 'Machines' ? 'bg-color-accent-purple text-white-forced shadow-md' : 'text-text-muted hover:text-text-main'
                            }`}
                        >
                          {tf('machines', 'Machines')}
                        </button>
                      </div>
                    </div>

                    {perfTab === 'Karigars' ? (
                      <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse">
                          <thead>
                            <tr className="border-b border-border-subtle text-[10px] text-text-muted uppercase tracking-widest font-black">
                              <th className="pb-3 text-left">{tf('artisanName', 'Artisan')}</th>
                              <th className="pb-3 text-center">{tf('activeJobsCount', 'Active Workload')}</th>
                              <th className="pb-3 text-right">{tf('earningsValue', 'Value Generated')}</th>
                              <th className="pb-3 text-right">{tf('timelinessRate', 'On-Time Rate')}</th>
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-border-subtle font-semibold">
                            {!stats.karigarPerformance || stats.karigarPerformance.length === 0 ? (
                              <tr>
                                <td colSpan="4" className="py-6 text-center text-xs text-text-muted font-bold">
                                  {tf('noArtisans', 'No artisan performance metrics found.')}
                                </td>
                              </tr>
                            ) : (
                              stats.karigarPerformance.map((k) => (
                                <tr key={k._id} className="hover:bg-bg-hover/30 transition-colors">
                                  <td className="py-3 text-sm font-semibold text-text-main">
                                    <Link to={`/karigars/${k._id}`} className="text-color-accent-purple hover:underline font-bold">
                                      {k.name}
                                    </Link>
                                    <span className="text-[9px] text-text-muted block font-extrabold mt-0.5 uppercase tracking-wide">
                                      {tf(k.specialization.toLowerCase(), k.specialization)}
                                    </span>
                                  </td>
                                  <td className="py-3 text-center">
                                    <span className={`px-2 py-0.5 rounded text-[10px] font-black ${k.activeCount > 3
                                      ? 'bg-rose-500/10 text-rose-500 border border-rose-500/20'
                                      : k.activeCount > 0
                                        ? 'bg-blue-500/10 text-blue-500 border border-blue-500/20'
                                        : 'bg-gray-500/10 text-gray-500 border border-gray-500/20'
                                      }`}>
                                      {k.activeCount} {t('active')}
                                    </span>
                                  </td>
                                  <td className="py-3 text-sm font-bold text-color-accent-emerald text-right">
                                    {formatCurrency(k.completedValue)}
                                  </td>
                                  <td className="py-3 text-right">
                                    <div className="flex flex-col items-end gap-1">
                                      <span className="text-xs font-black text-text-main">{k.onTimeRate}%</span>
                                      <div className="w-20 bg-bg-hover h-1.5 rounded-full overflow-hidden border border-border-subtle">
                                        <div
                                          style={{ width: `${k.onTimeRate}%` }}
                                          className={`h-full rounded-full ${k.onTimeRate >= 80 ? 'bg-emerald-500' : k.onTimeRate >= 50 ? 'bg-amber-500' : 'bg-rose-500'
                                            }`}
                                        />
                                      </div>
                                    </div>
                                  </td>
                                </tr>
                              ))
                            )}
                          </tbody>
                        </table>
                      </div>
                    ) : (
                      <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse">
                          <thead>
                            <tr className="border-b border-border-subtle text-[10px] text-text-muted uppercase tracking-widest font-black">
                              <th className="pb-3 text-left">{tf('machineNameNum', 'Machine')}</th>
                              <th className="pb-3 text-center">{tf('status', 'Status')}</th>
                              <th className="pb-3 text-center">{tf('activeJobs', 'Active Jobs')}</th>
                              <th className="pb-3 text-right">{tf('totalUsage', 'Total Processed')}</th>
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-border-subtle font-semibold">
                            {!stats.machinePerformance || stats.machinePerformance.length === 0 ? (
                              <tr>
                                <td colSpan="4" className="py-6 text-center text-xs text-text-muted font-bold">
                                  {tf('noMachines', 'No machine performance records found.')}
                                </td>
                              </tr>
                            ) : (
                              stats.machinePerformance.map((m) => (
                                <tr key={m._id} className="hover:bg-bg-hover/30 transition-colors">
                                  <td className="py-3 text-sm font-semibold text-text-main flex items-center gap-2">
                                    <div className="w-8 h-8 rounded-lg bg-bg-hover flex items-center justify-center text-color-accent-purple shrink-0">
                                      <GiSewingMachine className="w-5 h-5 text-color-accent-purple" />
                                    </div>
                                    <div>
                                      <span className="font-bold block text-text-main leading-tight">{m.name}</span>
                                      <span className="text-[9px] text-text-muted font-extrabold uppercase tracking-wider">{tf(m.type.toLowerCase(), m.type)}</span>
                                    </div>
                                  </td>
                                  <td className="py-3 text-center">
                                    <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider ${m.status === 'Working'
                                      ? 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20'
                                      : m.status === 'Maintenance'
                                        ? 'bg-amber-500/10 text-amber-500 border border-amber-500/20'
                                        : 'bg-rose-500/10 text-rose-500 border border-rose-500/20'
                                      }`}>
                                      {tf(m.status.toLowerCase(), m.status)}
                                    </span>
                                  </td>
                                  <td className="py-3 text-center text-xs font-bold text-text-main">
                                    {m.activeCount}
                                  </td>
                                  <td className="py-3 text-sm font-black text-text-main text-right">
                                    {m.totalCount} {t('jobs')}
                                  </td>
                                </tr>
                              ))
                            )}
                          </tbody>
                        </table>
                      </div>
                    )}
                  </Card>
                )}
              </div>
            )}

            {showRightCol && (
              <div className={`${showLeftCol && showRightCol ? 'lg:col-span-1' : 'w-full'} flex flex-col gap-6 text-left`}>
                {settings.showCalendar && (
                  <Card className="flex flex-col gap-3">
                    <div className="flex items-center justify-between border-b border-border-subtle pb-3">
                      <div className="flex items-center gap-1">
                        <button onClick={handlePrevMonth} className="p-1.5 rounded-lg hover:bg-bg-hover text-text-muted hover:text-text-main cursor-pointer transition-colors">
                          <MdChevronLeft className="w-4 h-4" />
                        </button>
                        <span className="text-sm font-bold text-text-main tracking-wide w-[72px] text-center">{t(calendarMonth.toLowerCase())}</span>
                        <button onClick={handleNextMonth} className="p-1.5 rounded-lg hover:bg-bg-hover text-text-muted hover:text-text-main cursor-pointer transition-colors">
                          <MdChevronRight className="w-4 h-4" />
                        </button>
                      </div>
                      <div className="flex items-center gap-1">
                        <button onClick={handlePrevYear} className="p-1.5 rounded-lg hover:bg-bg-hover text-text-muted hover:text-text-main cursor-pointer transition-colors">
                          <MdChevronLeft className="w-4 h-4" />
                        </button>
                        <span className="text-sm font-bold text-text-main tracking-wide w-12 text-center">{calendarYear}</span>
                        <button onClick={handleNextYear} className="p-1.5 rounded-lg hover:bg-bg-hover text-text-muted hover:text-text-main cursor-pointer transition-colors">
                          <MdChevronRight className="w-4 h-4" />
                        </button>
                      </div>
                    </div>

                    {(selectedRange.start || selectedRange.end) && (
                      <div className="flex items-center justify-between text-[10px] font-bold px-1">
                        <span className="text-color-accent-blue uppercase tracking-wider">
                          {selectedRange.start && !selectedRange.end
                            ? t('calendarClickEnd')
                            : `${selectedRange.start} – ${selectedRange.end} ${t(calendarMonth.toLowerCase())}`}
                        </span>
                        <button
                          onClick={() => setSelectedRange({ start: null, end: null })}
                          className="text-text-muted hover:text-text-main cursor-pointer"
                        >
                          <MdClose className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    )}

                    <div className="grid grid-cols-7 text-center text-[10px] font-extrabold text-text-muted uppercase tracking-widest">
                      {['sun_short', 'mon_short', 'tue_short', 'wed_short', 'thu_short', 'fri_short', 'sat_short'].map((key, i) => (
                        <span key={i} className={i === 0 || i === 6 ? 'text-color-accent-pink/70' : ''}>{t(key)}</span>
                      ))}
                    </div>

                    <div className="grid grid-cols-7 gap-y-2 text-center text-xs font-bold mt-2">
                      {[...Array(firstDayOffset)].map((_, i) => (
                        <div key={`e${i}`} />
                      ))}

                      {[...Array(daysInMonth)].map((_, i) => {
                        const day = i + 1;
                        const isStart = selectedRange.start === day;
                        const isEnd = selectedRange.end === day;
                        const isPending = selectedRange.start && !selectedRange.end && day === selectedRange.start;
                        const isToday = isCurrentMonthYear && day === todayDay;
                        const inRange = selectedRange.start && selectedRange.end
                          && day >= selectedRange.start && day <= selectedRange.end;

                        const col = (firstDayOffset + day - 1) % 7;
                        let containerClass = 'relative w-full h-8 flex items-center justify-center cursor-pointer';

                        let stripClass = '';
                        let hasUpBridge = false;
                        let hasStartOutfill = false;
                        let hasEndOutfill = false;
                        if (selectedRange.start && selectedRange.end && selectedRange.start !== selectedRange.end) {
                          if (inRange) {
                            stripClass = 'absolute inset-0 bg-[var(--calendar-range-bg)] z-0';
                            const hasUp = day - 7 >= selectedRange.start;
                            const hasDown = day + 7 <= selectedRange.end;
                            const hasLeft = col > 0 && day - 1 >= selectedRange.start;
                            const hasRight = col < 6 && day + 1 <= selectedRange.end;

                            if (!hasUp && !hasLeft) stripClass += ' rounded-tl-[14px]';
                            if (!hasUp && !hasRight) stripClass += ' rounded-tr-[14px]';
                            if (!hasDown && !hasLeft) stripClass += ' rounded-bl-[14px]';
                            if (!hasDown && !hasRight) stripClass += ' rounded-br-[14px]';

                            if (hasUp) hasUpBridge = true;
                            if (isStart && hasDown && col > 0) hasStartOutfill = true;
                            if (isEnd && hasUp && col < 6) hasEndOutfill = true;
                          }
                        }

                        let circleClass = 'w-8 h-8 flex items-center justify-center rounded-full transition-all duration-150 text-xs z-10 relative';

                        if (isStart || isEnd) {
                          circleClass += ' bg-[#007aff] text-white-forced font-black shadow-lg shadow-[#007aff]/40 scale-105';
                        } else if (isPending) {
                          circleClass += ' bg-[#007aff]/30 text-white-forced font-extrabold ring-2 ring-[#007aff]/50 ring-offset-2 ring-offset-[var(--bg-primary)]';
                        } else if (isToday) {
                          circleClass += ' ring-2 ring-[#7a60ff]/60 text-[#7a60ff] font-extrabold';
                        } else if (inRange) {
                          circleClass += ' calendar-inrange-text font-bold';
                        } else {
                          circleClass += ' text-text-muted hover:bg-bg-hover hover:text-text-main';
                        }

                        return (
                          <div key={day} className={containerClass} onClick={() => handleDayClick(day)}>
                            {stripClass && <div className={stripClass} />}
                            {hasUpBridge && (
                              <div className="absolute bottom-full left-0 w-full h-2 bg-[var(--calendar-range-bg)] z-0" />
                            )}
                            {hasStartOutfill && (
                              <div
                                className="absolute top-full right-full w-4 h-4 z-0 pointer-events-none"
                                style={{ background: 'radial-gradient(circle at top left, transparent 16px, var(--calendar-range-color) 16.5px)' }}
                              />
                            )}
                            {hasEndOutfill && (
                              <div
                                className="absolute bottom-full left-full w-4 h-4 z-0 pointer-events-none"
                                style={{ background: 'radial-gradient(circle at bottom right, transparent 16px, var(--calendar-range-color) 16.5px)' }}
                              />
                            )}
                            <span className={circleClass}>{day}</span>
                          </div>
                        );
                      })}
                    </div>

                    <div className="flex items-center gap-2 mt-1 border-t border-border-subtle pt-3">
                      <button
                        onClick={() => setSelectedRange({ start: null, end: null })}
                        className="flex-1 py-2 rounded-xl bg-bg-hover hover:bg-border-medium text-xs text-text-main font-bold active:scale-95 transition-all cursor-pointer border border-border-subtle"
                      >
                        {t('calendarClear')}
                      </button>
                      <button
                        disabled={!selectedRange.start || !selectedRange.end}
                        className="flex-1 py-2 rounded-xl bg-color-accent-blue text-xs text-white-forced font-bold hover:bg-color-accent-blue/90 active:scale-95 transition-all shadow-md shadow-color-accent-blue/20 cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
                      >
                        {selectedRange.start && selectedRange.end
                          ? `${filteredOrders.length} ${t('ordersFound')}`
                          : t('calendarApplyRange')}
                      </button>
                    </div>
                  </Card>
                )}

                {settings.showReminders && (
                  <Card className="flex flex-col gap-4">
                    <div className="flex items-center justify-between border-b border-border-subtle pb-3">
                      <div>
                        <h3 className="text-base font-bold text-text-main tracking-wide">{t('todayReminders')}</h3>
                        <p className="text-xs text-text-muted mt-0.5">{t('todayRemindersSub')}</p>
                      </div>
                      <MdNotificationsActive className="w-5 h-5 text-color-accent-pink animate-pulse" />
                    </div>

                    <div className="flex flex-col gap-3">
                      {stats.reminders.length === 0 ? (
                        <div className="text-xs text-text-muted text-center py-6">
                          {t('noReminders')}
                        </div>
                      ) : (
                        stats.reminders.map((alert) => (
                          <div
                            key={alert._id}
                            className="p-3 bg-bg-secondary border border-border-subtle rounded-xl flex items-start gap-3 hover:border-border-medium transition-colors"
                          >
                            <div className="w-1.5 h-1.5 rounded-full bg-color-accent-pink shrink-0 mt-1.5" />
                            <div className="flex-1 min-w-0">
                              <p className="text-xs text-text-main font-semibold leading-relaxed text-left">
                                {alert.message}
                              </p>
                              <span className="text-[9px] text-text-muted font-bold block mt-1 uppercase tracking-wider">
                                {formatDate(alert.createdAt)}
                              </span>
                            </div>
                          </div>
                        ))
                      )}
                    </div>

                    <Link
                      to="/notifications"
                      className="mt-2 text-xs font-bold text-color-accent-purple hover:underline flex items-center justify-center gap-1"
                    >
                      <span>{t('viewFeed')}</span>
                      <MdArrowForward className="w-3.5 h-3.5" />
                    </Link>
                  </Card>
                )}
              </div>
            )}
          </div>
        );
      })()}

      {/* FAB actions (Step 1 routes are not active, will hit 404) */}
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
