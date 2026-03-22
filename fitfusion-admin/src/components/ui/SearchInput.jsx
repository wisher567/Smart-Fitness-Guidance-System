import React from 'react';
import { Search } from 'lucide-react';

const SearchInput = ({ value, onChange, placeholder }) => (
  <div className="relative">
    <Search size={15} className="absolute left-3.5 top-1/2 
      -translate-y-1/2 text-gray-400 pointer-events-none" />
    <input
      type="text"
      value={value}
      onChange={e => onChange(e.target.value)}
      placeholder={placeholder || 'Search...'}
      className="pl-10 pr-4 py-2.5 bg-gray-50 border border-[#E2E8F0]
        rounded-xl text-sm text-gray-700 placeholder-gray-400
        focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 
        focus:border-[#E8845C] focus:bg-white
        transition-all w-64"
    />
  </div>
);

export default SearchInput;
