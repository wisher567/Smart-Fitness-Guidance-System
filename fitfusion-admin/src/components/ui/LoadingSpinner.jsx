import React from 'react';

const LoadingSpinner = ({ size = 'md', text }) => {
  const sizes = { sm: 'h-4 w-4', md: 'h-8 w-8', lg: 'h-12 w-12' };
  return (
    <div className="flex flex-col items-center justify-center gap-3 
      py-12 animate-fade-in">
      <div className={`${sizes[size]} border-[3px] border-[#E8845C]/20 
        border-t-[#E8845C] rounded-full animate-spin`} />
      {text && <p className="text-gray-400 text-sm">{text}</p>}
    </div>
  );
};

export default LoadingSpinner;
