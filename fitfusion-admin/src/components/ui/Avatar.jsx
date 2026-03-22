import React from 'react';

const Avatar = ({ name, size = 'md', image }) => {
  const sizes = {
    xs: 'w-6 h-6 text-[10px] rounded-lg',
    sm: 'w-8 h-8 text-xs rounded-xl',
    md: 'w-10 h-10 text-sm rounded-xl',
    lg: 'w-14 h-14 text-lg rounded-2xl',
    xl: 'w-20 h-20 text-2xl rounded-2xl',
  };
  const colors = [
    'from-orange-400 to-red-400',
    'from-blue-400 to-cyan-400',
    'from-green-400 to-teal-400',
    'from-purple-400 to-pink-400',
    'from-yellow-400 to-orange-400',
  ];
  const colorIndex = (name?.charCodeAt(0) || 0) % colors.length;

  const getInitials = (name) => {
    if (!name) return 'U';
    return name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
  };

  if (image) return (
    <img src={image} alt={name}
      className={`${sizes[size]} object-cover`} />
  );

  return (
    <div className={`${sizes[size]} bg-gradient-to-br 
      ${colors[colorIndex]} flex items-center justify-center
      text-white font-bold shrink-0`}>
      {getInitials(name)}
    </div>
  );
};

export default Avatar;
