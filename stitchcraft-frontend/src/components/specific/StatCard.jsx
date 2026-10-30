import React from 'react';
import Card from '../common/Card';

export const StatCard = ({
  title,
  value,
  subtitle,
  icon,
  variant = 'dark',
  onClick = null,
}) => {
  let iconWrapperClass = 'text-text-muted bg-bg-hover';

  if (variant === 'purple' || variant === 'blue') {
    iconWrapperClass = 'text-color-accent-purple bg-color-accent-purple/10';
  } else if (variant === 'pink') {
    iconWrapperClass = 'text-color-accent-pink bg-color-accent-pink/10';
  } else if (variant === 'emerald') {
    iconWrapperClass = 'text-color-accent-emerald bg-color-accent-emerald/10';
  }

  const clickableClass = onClick
    ? 'cursor-pointer hover:-translate-y-0.5 hover:shadow-theme-md transition-all duration-200 rounded-2xl overflow-hidden'
    : 'rounded-2xl overflow-hidden';

  return (
    <div onClick={onClick} className={clickableClass}>
      <Card className="bg-bg-secondary border border-border-subtle p-6 transition-all duration-300 relative select-none">
        <div className="flex flex-col">
          {icon && (
            <div className={`w-11 h-11 rounded-full flex items-center justify-center mb-4 ${iconWrapperClass}`}>
              {React.cloneElement(icon, { className: 'w-5 h-5' })}
            </div>
          )}

          <div className="flex flex-col text-left">
            <span className="text-sm font-medium text-text-muted">{title}</span>
            <div className="flex items-baseline gap-1 mt-1.5">
              <span className="text-2xl sm:text-[28px] font-bold text-text-main leading-tight">{value}</span>
            </div>
            {subtitle && (
              <span className="text-xs text-text-muted mt-1">{subtitle}</span>
            )}
          </div>
        </div>

        {onClick && (
          <div className="absolute top-4 right-4">
            <span className="text-text-muted hover:text-text-main text-xs font-semibold">→</span>
          </div>
        )}
      </Card>
    </div>
  );
};

export default StatCard;
