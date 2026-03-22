import { useState, useEffect, useCallback } from 'react';
import { Menu, Bell, ChevronRight, ChevronDown } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useLocation, useNavigate } from 'react-router-dom';
import api from '../../services/api';

export default function Header({ onMenuClick }) {
  const { logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const title = location.pathname.split('/')[1];
  const pageTitle = title ? title.charAt(0).toUpperCase() + title.slice(1) : 'Dashboard';

  const [alertCount, setAlertCount] = useState(0);

  const fetchAlerts = useCallback(async () => {
    try {
      const res = await api.get('/admin/trainer-requests');
      setAlertCount(res.data?.stats?.pending || 0);
    } catch { /* silent */ }
  }, []);

  useEffect(() => {
    fetchAlerts();
    const interval = setInterval(fetchAlerts, 15000); // refresh every 15s
    return () => clearInterval(interval);
  }, [fetchAlerts]);

  return (
    <header className="h-16 bg-white/80 backdrop-blur-xl border-b 
      border-[#E2E8F0] sticky top-0 z-30 flex items-center 
      justify-between px-6">
      
      {/* Left: breadcrumb style title */}
      <div className="flex items-center gap-2">
        <button onClick={onMenuClick} className="lg:hidden p-2 rounded-xl hover:bg-gray-100">
          <Menu size={20} className="text-gray-600" />
        </button>
        <div className="flex items-center gap-2">
          <span className="text-gray-400 text-sm hidden sm:inline-block">FitFusion</span>
          <ChevronRight size={14} className="text-gray-300 hidden sm:inline-block" />
          <span className="text-gray-900 font-semibold text-sm">{pageTitle}</span>
        </div>
      </div>

      {/* Right: actions */}
      <div className="flex items-center gap-2">

        {/* Notifications */}
        <div className="relative">
          <button
            onClick={() => navigate('/trainer-requests')}
            className="relative p-2 hover:bg-gray-100 
            rounded-xl transition-colors"
            title={alertCount > 0 ? `${alertCount} pending request(s)` : 'No pending requests'}>
            <Bell size={18} className="text-gray-600" />
            {alertCount > 0 && (
              <span className="absolute -top-0.5 -right-0.5 w-4 h-4 
                bg-red-500 rounded-full text-[10px] text-white 
                flex items-center justify-center font-bold animate-pulse">
                {alertCount > 9 ? '9+' : alertCount}
              </span>
            )}
          </button>
        </div>

        {/* Divider */}
        <div className="w-px h-6 bg-gray-200 mx-1 hidden sm:block" />

        {/* Admin avatar */}
        <button className="flex items-center gap-2 p-1.5 
          hover:bg-gray-50 rounded-xl transition-colors">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-br 
            from-[#E8845C] to-[#D4673A] flex items-center 
            justify-center text-white text-xs font-bold shrink-0">
            AD
          </div>
          <ChevronDown size={14} className="text-gray-400 hidden sm:block" />
        </button>

      </div>
    </header>
  );
}
