export const formatCurrency = (amount) =>
  `LKR ${amount?.toLocaleString('en-LK') || '0'}`;

export const formatDate = (dateString) => {
  if (!dateString) return '—';
  return new Date(dateString).toLocaleDateString('en-LK', {
    day: 'numeric', month: 'short', year: 'numeric'
  });
};

export const formatDateTime = (dateString) => {
  if (!dateString) return '—';
  return new Date(dateString).toLocaleString('en-LK', {
    day: 'numeric', month: 'short',
    hour: '2-digit', minute: '2-digit'
  });
};

export const getInitials = (name) => {
  if (!name) return '?';
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0,2);
};

export const getAvatarColor = (name) => {
  const colors = [
    'bg-orange-400', 'bg-blue-400', 'bg-green-400',
    'bg-purple-400', 'bg-pink-400', 'bg-teal-400',
  ];
  const index = (name?.charCodeAt(0) || 0) % colors.length;
  return colors[index];
};
