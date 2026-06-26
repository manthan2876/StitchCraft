import React from 'react';
import { IoMdClose } from 'react-icons/io';

export const Modal = ({ isOpen, onClose, title, children, className = '' }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/65 backdrop-blur-xs transition-opacity duration-300">
      <div className={`w-full max-w-2xl bg-bg-modal border border-border-medium rounded-[20px] shadow-2xl overflow-hidden transform scale-100 transition-all duration-300 ${className}`}>
        {/* Modal Header */}
        <div className="flex items-center justify-between p-6 border-b border-border-subtle bg-bg-primary">
          <h3 className="text-lg font-bold text-text-main tracking-wide">{title}</h3>
          <button
            onClick={onClose}
            className="p-2 rounded-xl hover:bg-bg-hover text-text-muted hover:text-text-main transition-all duration-200"
          >
            <IoMdClose className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 max-h-[70vh] overflow-y-auto">
          {children}
        </div>
      </div>
    </div>
  );
};

export default Modal;
