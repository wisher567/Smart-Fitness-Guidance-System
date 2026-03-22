import React from 'react';

const EmptyState = ({ icon: Icon, title, description, action }) => (
  <div className="flex flex-col items-center justify-center py-16 
    text-center animate-fade-in">
    <div className="w-16 h-16 bg-gray-50 rounded-2xl flex items-center 
      justify-center mb-4 border border-gray-100">
      <Icon size={28} className="text-gray-300" />
    </div>
    <h3 className="text-gray-700 font-semibold text-base mb-1">{title}</h3>
    <p className="text-gray-400 text-sm max-w-xs">{description}</p>
    {action && <div className="mt-4">{action}</div>}
  </div>
);

export default EmptyState;
