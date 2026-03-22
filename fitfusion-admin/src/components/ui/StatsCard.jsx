import React from 'react';
import { TrendingUp, TrendingDown } from 'lucide-react';

const StatsCard = ({ icon: Icon, value, label, trend, trendUp, color, bgColor }) => {
  return (
    <div className="bg-white rounded-2xl border border-[#E2E8F0] 
      shadow-card hover:shadow-cardHover transition-all duration-300
      hover:-translate-y-0.5 p-6 animate-slide-up">
      <div className="flex items-start justify-between mb-4">
        <div className={`p-3 rounded-2xl ${bgColor}`}>
          <Icon size={20} className={color} />
        </div>
        {trend && (
          <div className={`flex items-center gap-1 text-xs font-semibold
            px-2 py-1 rounded-xl
            ${trendUp 
              ? 'bg-green-50 text-green-600' 
              : 'bg-red-50 text-red-500'
            }`}>
            {trendUp ? <TrendingUp size={12}/> : <TrendingDown size={12}/>}
            {trend}
          </div>
        )}
      </div>
      <p className="text-3xl font-bold text-gray-900 mb-1">{value}</p>
      <p className="text-gray-500 text-sm">{label}</p>
    </div>
  );
};

export default StatsCard;
