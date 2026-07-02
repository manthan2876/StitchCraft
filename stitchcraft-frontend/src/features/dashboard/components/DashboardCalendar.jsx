/* src/features/dashboard/components/DashboardCalendar.jsx */
import React from 'react';
import { MdChevronLeft, MdChevronRight, MdClose } from 'react-icons/md';
import Card from '../../../components/common/Card';

export const DashboardCalendar = ({
  calendarMonth,
  calendarYear,
  handlePrevMonth,
  handleNextMonth,
  handlePrevYear,
  handleNextYear,
  selectedRange,
  setSelectedRange,
  handleDayClick,
  filteredOrdersCount,
  t,
}) => {
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

  return (
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
            ? `${filteredOrdersCount} ${t('ordersFound')}`
            : t('calendarApplyRange')}
        </button>
      </div>
    </Card>
  );
};

export default DashboardCalendar;
