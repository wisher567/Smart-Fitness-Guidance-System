import React from 'react';

const PageHeader = ({ title, subtitle, actions, badge }) => (
  <div className="flex flex-col sm:flex-row sm:items-center 
    justify-between gap-4 mb-6">
    <div>
      <div className="flex items-center gap-3">
        <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
        {badge && (
          <span className="px-2.5 py-1 bg-[#E8845C]/10 text-[#E8845C]
            text-xs font-semibold rounded-xl">
            {badge}
          </span>
        )}
      </div>
      {subtitle && (
        <p className="text-gray-500 text-sm mt-1">{subtitle}</p>
      )}
    </div>
    {actions && (
      <div className="flex items-center gap-2 shrink-0">
        {actions}
      </div>
    )}
  </div>
);

export default PageHeader;
