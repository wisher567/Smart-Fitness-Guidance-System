import React from 'react';

const Button = ({ 
  children, variant = 'primary', size = 'md', 
  loading, icon: Icon, onClick, disabled, className 
}) => {
  const variants = {
    primary:   `bg-gradient-to-r from-[#E8845C] to-[#D4673A] 
                text-white shadow-button hover:shadow-lg 
                hover:-translate-y-0.5 active:translate-y-0`,
    secondary: `bg-white border border-[#E2E8F0] text-gray-700 
                hover:bg-gray-50 hover:border-gray-300`,
    danger:    `bg-red-50 border border-red-100 text-red-600 
                hover:bg-red-100`,
    ghost:     `text-gray-600 hover:bg-gray-100`,
    success:   `bg-green-50 border border-green-100 text-green-600 
                hover:bg-green-100`,
  };

  const sizes = {
    sm: 'px-3 py-1.5 text-xs rounded-xl',
    md: 'px-4 py-2.5 text-sm rounded-xl',
    lg: 'px-6 py-3 text-base rounded-2xl',
  };

  return (
    <button
      onClick={onClick}
      disabled={disabled || loading}
      className={`inline-flex items-center justify-center gap-2
        font-semibold transition-all duration-200
        disabled:opacity-50 disabled:cursor-not-allowed
        disabled:transform-none
        ${variants[variant]} ${sizes[size]} ${className}`}>
      {loading ? (
        <div className="w-4 h-4 border-2 border-current/30 
          border-t-current rounded-full animate-spin" />
      ) : Icon ? (
        <Icon size={size === 'lg' ? 18 : 15} />
      ) : null}
      {children}
    </button>
  );
};

export default Button;
