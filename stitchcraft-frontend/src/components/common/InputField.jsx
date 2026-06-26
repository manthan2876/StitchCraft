import React from 'react';

export const InputField = ({
  label,
  name,
  type = 'text',
  value,
  onChange,
  placeholder,
  error,
  required = false,
  className = '',
  ...props
}) => {
  return (
    <div className={`flex flex-col gap-2 w-full ${className}`}>
      {label && (
        <label className="text-sm font-medium text-text-muted flex gap-1">
          {label}
          {required && <span className="text-color-accent-pink">*</span>}
        </label>
      )}
      <input
        type={type}
        name={name}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        required={required}
        className={`w-full px-4 py-3 bg-bg-input border rounded-xl text-text-main placeholder:text-text-muted/50 outline-none transition-all duration-200
          ${error
            ? 'border-color-accent-pink focus:border-color-accent-pink/80 focus:shadow-[0_0_10px_rgba(255,46,126,0.15)]'
            : 'border-border-medium focus:border-color-accent-purple focus:shadow-[0_0_10px_rgba(122,96,255,0.15)]'
          }`}
        {...props}
      />
      {error && <span className="text-xs text-color-accent-pink font-medium">{error}</span>}
    </div>
  );
};

export default InputField;
