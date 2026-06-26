import React from 'react';

export const Button = ({
  children,
  variant = 'primary',
  className = '',
  onClick,
  type = 'button',
  disabled = false
}) => {
  let btnClass = 'btn-tactile text-white-forced';

  if (variant === 'secondary') {
    btnClass = 'btn-tactile-secondary';
  } else if (variant === 'dark') {
    btnClass = 'btn-tactile-dark';
  }

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`${btnClass} ${disabled ? 'opacity-50 cursor-not-allowed transform-none!' : ''} ${className}`}
    >
      {children}
    </button>
  );
};

export default Button;
