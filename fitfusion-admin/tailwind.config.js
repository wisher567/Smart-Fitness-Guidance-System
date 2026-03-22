/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary:     '#E8845C',
        primaryDark: '#D4673A',
        primaryLight:'#FDF0EB',
        sidebar:     '#0F1923',
        sidebarHover:'#1A2635',
        success:     '#22C55E',
        successLight:'#F0FDF4',
        error:       '#EF4444',
        errorLight:  '#FEF2F2',
        warning:     '#F59E0B',
        warningLight:'#FFFBEB',
        info:        '#3B82F6',
        infoLight:   '#EFF6FF',
        surface:     '#F8FAFC',
        border:      '#E2E8F0',
        muted:       '#94A3B8',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
      boxShadow: {
        card:   '0 1px 3px rgba(0,0,0,0.04), 0 4px 12px rgba(0,0,0,0.04)',
        cardHover: '0 4px 6px rgba(0,0,0,0.06), 0 10px 30px rgba(0,0,0,0.08)',
        modal:  '0 20px 60px rgba(0,0,0,0.15)',
        sidebar:'4px 0 24px rgba(0,0,0,0.12)',
        button: '0 2px 8px rgba(232,132,92,0.35)',
      },
      borderRadius: {
        '2xl': '16px',
        '3xl': '24px',
      },
      animation: {
        'fade-in':    'fadeIn 0.2s ease-out',
        'slide-up':   'slideUp 0.3s ease-out',
        'slide-in':   'slideIn 0.3s ease-out',
        'pulse-soft': 'pulseSoft 2s infinite',
      },
      keyframes: {
        fadeIn:    { from: { opacity: 0 }, to: { opacity: 1 } },
        slideUp:   { from: { opacity: 0, transform: 'translateY(8px)' },
                     to:   { opacity: 1, transform: 'translateY(0)' } },
        slideIn:   { from: { opacity: 0, transform: 'translateX(-8px)' },
                     to:   { opacity: 1, transform: 'translateX(0)' } },
        pulseSoft: { '0%,100%': { opacity: 1 }, '50%': { opacity: 0.6 } },
      },
    },
  },
  plugins: [],
}
