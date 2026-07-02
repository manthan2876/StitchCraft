/* src/features/dashboard/components/PerformanceTracker.jsx */
import React from 'react';
import { Link } from 'react-router-dom';
import { GiSewingMachine } from 'react-icons/gi';
import Card from '../../../components/common/Card';
import { formatCurrency } from '../../../utils/formatters';

export const PerformanceTracker = ({
  stats,
  perfTab,
  setPerfTab,
  t,
}) => {
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  return (
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
  );
};

export default PerformanceTracker;
