/* src/features/dashboard/components/WeeklyStitchingChart.jsx */
import React from 'react';
import Card from '../../../components/common/Card';
import { getSvgPath } from '../../../utils/svgHelpers';
import { formatCurrency } from '../../../utils/formatters';

export const WeeklyStitchingChart = ({
  chartData = [0, 0, 0, 0, 0, 0, 0],
  activeDayIdx,
  setActiveDayIdx,
  t,
}) => {
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
  );
};

export default WeeklyStitchingChart;
