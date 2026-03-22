import React from 'react';
import { X } from 'lucide-react';

const Modal = ({ isOpen, onClose, title, subtitle, children, size = 'md', footer }) => {
  if (!isOpen) return null;
  const sizes = {
    sm: 'max-w-sm', md: 'max-w-lg',
    lg: 'max-w-2xl', xl: 'max-w-4xl'
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center 
      justify-center p-4 animate-fade-in">
      
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose} />

      {/* Modal */}
      <div className={`relative bg-white rounded-3xl shadow-modal 
        w-full ${sizes[size]} max-h-[90vh] flex flex-col
        animate-slide-up border border-[#E2E8F0]`}>
        
        {/* Header */}
        <div className="flex items-start justify-between p-6 
          border-b border-[#F1F5F9]">
          <div>
            <h2 className="text-lg font-bold text-gray-900">{title}</h2>
            {subtitle && (
              <p className="text-sm text-gray-500 mt-0.5">{subtitle}</p>
            )}
          </div>
          <button onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-xl 
              transition-colors text-gray-400 hover:text-gray-600">
            <X size={18} />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-6">
          {children}
        </div>

        {/* Footer */}
        {footer && (
          <div className="p-6 border-t border-[#F1F5F9] 
            bg-[#F8FAFC] rounded-b-3xl flex items-center 
            justify-end gap-3">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
};

export default Modal;
