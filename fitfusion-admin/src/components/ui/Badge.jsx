import React from 'react';

const Badge = ({ status, size = 'sm' }) => {
  const variants = {
    active:      { bg: 'bg-green-50',  text: 'text-green-700',  dot: 'bg-green-500'  },
    suspended:   { bg: 'bg-red-50',    text: 'text-red-700',    dot: 'bg-red-500'    },
    cancelled:   { bg: 'bg-gray-100',  text: 'text-gray-600',   dot: 'bg-gray-400'   },
    completed:   { bg: 'bg-green-50',  text: 'text-green-700',  dot: 'bg-green-500'  },
    pending:     { bg: 'bg-amber-50',  text: 'text-amber-700',  dot: 'bg-amber-500'  },
    failed:      { bg: 'bg-red-50',    text: 'text-red-700',    dot: 'bg-red-500'    },
    refunded:    { bg: 'bg-blue-50',   text: 'text-blue-700',   dot: 'bg-blue-500'   },
    open:        { bg: 'bg-red-50',    text: 'text-red-700',    dot: 'bg-red-500'    },
    in_progress: { bg: 'bg-amber-50',  text: 'text-amber-700',  dot: 'bg-amber-500'  },
    resolved:    { bg: 'bg-green-50',  text: 'text-green-700',  dot: 'bg-green-500'  },
    high:        { bg: 'bg-red-50',    text: 'text-red-700',    dot: 'bg-red-500'    },
    medium:      { bg: 'bg-orange-50', text: 'text-orange-700', dot: 'bg-orange-500' },
    low:         { bg: 'bg-yellow-50', text: 'text-yellow-700', dot: 'bg-yellow-500' },
    premium:     { bg: 'bg-orange-50', text: 'text-orange-700', dot: 'bg-orange-500' },
    basic:       { bg: 'bg-gray-100',  text: 'text-gray-600',   dot: 'bg-gray-400'   },
    student:     { bg: 'bg-blue-50',   text: 'text-blue-700',   dot: 'bg-blue-500'   },
  };

  const v = variants[status?.toLowerCase()] || variants.basic;

  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1
      rounded-lg text-xs font-semibold capitalize
      ${v.bg} ${v.text}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${v.dot}`} />
      {status?.replace('_', ' ')}
    </span>
  );
};

export default Badge;
