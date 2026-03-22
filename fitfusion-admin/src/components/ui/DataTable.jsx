import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

const DataTable = ({ columns, data, loading, emptyMessage }) => (
  <div className="bg-white rounded-2xl border border-[#E2E8F0] shadow-card overflow-hidden">
    
    {/* Table header */}
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead>
          <tr className="border-b border-[#F1F5F9]">
            {columns.map(col => (
              <th key={col.key} className="px-6 py-4 text-left 
                text-xs font-semibold text-[#94A3B8] 
                uppercase tracking-wider bg-[#F8FAFC]
                whitespace-nowrap">
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {loading ? (
            // Skeleton rows
            [...Array(5)].map((_, i) => (
              <tr key={i} className="border-b border-[#F8FAFC] last:border-0 hover:bg-[#F8FAFC]">
                {columns.map((_, j) => (
                  <td key={j} className="px-6 py-4">
                    <div className="h-4 bg-gray-100 rounded animate-pulse"/>
                  </td>
                ))}
              </tr>
            ))
          ) : data.length === 0 ? (
            <tr>
              <td colSpan={columns.length} className="px-6 py-12 text-center text-gray-400">
                {emptyMessage || 'No data found'}
              </td>
            </tr>
          ) : (
            data.map((row, i) => (
              <tr key={i}
                className="border-b border-[#F8FAFC] last:border-0
                  hover:bg-[#F8FAFC] transition-colors duration-150
                  animate-fade-in">
                {columns.map(col => (
                  <td key={col.key} className="px-6 py-4 text-sm 
                    text-gray-700 whitespace-nowrap">
                    {col.render ? col.render(row, i) : row[col.key]}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>

    {/* Pagination */}
    <div className="px-6 py-4 border-t border-[#F1F5F9] bg-[#F8FAFC] flex items-center justify-between">
      <p className="text-sm text-gray-500">
        Showing <span className="font-medium text-gray-700">1-10</span> of{' '}
        <span className="font-medium text-gray-700">{Math.max(data.length, 10)}</span>
      </p>
      <div className="flex items-center gap-1">
        <button className="p-2 rounded-xl hover:bg-white border 
          border-transparent hover:border-gray-200 transition-all
          text-gray-500 disabled:opacity-30">
          <ChevronLeft size={16} />
        </button>
        {[1,2,3].map(n => (
          <button key={n} className={`w-8 h-8 rounded-xl text-sm font-medium
            transition-all ${n === 1 
              ? 'bg-[#E8845C] text-white shadow-button' 
              : 'text-gray-500 hover:bg-white hover:border-gray-200 border border-transparent'
            }`}>
            {n}
          </button>
        ))}
        <button className="p-2 rounded-xl hover:bg-white border 
          border-transparent hover:border-gray-200 transition-all
          text-gray-500">
          <ChevronRight size={16} />
        </button>
      </div>
    </div>
  </div>
);

export default DataTable;
