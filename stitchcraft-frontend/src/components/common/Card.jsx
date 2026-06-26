import React from 'react';

export const Card = ({ children, className = '', glowColor = '', onClick }) => {
  let glowClass = '';
  if (glowColor === 'purple') glowClass = 'glow-purple';
  else if (glowColor === 'pink') glowClass = 'glow-pink';
  else if (glowColor === 'cyan') glowClass = 'glow-cyan';

  const hasCustomBg = className.includes('bg-');
  const hasCustomBorder = className.includes('border-none') || className.includes('border-transparent');

  const defaultBg = hasCustomBg ? '' : 'bg-bg-secondary';
  const defaultBorder = hasCustomBorder ? '' : 'border border-border-subtle hover:border-border-medium';

  return (
    <div
      onClick={onClick}
      className={`${defaultBg} ${defaultBorder} rounded-[20px] p-6 shadow-card transition-all duration-300 ${glowClass} ${onClick ? 'cursor-pointer hover:translate-y-[-2px]' : ''} ${className}`}
    >
      {children}
    </div>
  );
};

export default Card;
