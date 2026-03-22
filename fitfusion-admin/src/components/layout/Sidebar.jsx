import { NavLink } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import {
  LayoutDashboard, Users, CreditCard, Package, Calendar,
  Wrench, UserCheck, BarChart2, Settings, LogOut, MessageSquare
} from 'lucide-react';

const navItems = [
  { icon: LayoutDashboard, label: 'Dashboard', path: '/dashboard' },
  { icon: Users, label: 'Members', path: '/members' },
  { icon: CreditCard, label: 'Payments', path: '/payments' },
  { icon: Package, label: 'Plans', path: '/plans' },
  { icon: Calendar, label: 'Classes', path: '/classes' },
  { icon: Wrench, label: 'Equipment', path: '/equipment' },
  { icon: UserCheck, label: 'Trainers', path: '/trainers' },
  { icon: Users, label: 'Trainer Requests', path: '/trainer-requests' },
  { icon: BarChart2, label: 'Reports', path: '/reports' },
  { icon: MessageSquare, label: 'Messages', path: '/messages' },
  { icon: Settings, label: 'Settings', path: '/settings' },
];

export default function Sidebar({ isOpen, onClose }) {
  const { logout, user } = useAuth();
  return (
    <>
      {isOpen && (
        <div 
          className="lg:hidden fixed inset-0 bg-black/40 backdrop-blur-sm z-40"
          onClick={onClose}
        />
      )}
      <aside className={`fixed inset-y-0 left-0 bg-[#0F1923] w-[260px] text-white
        flex flex-col z-50 transform transition-transform duration-200 ease-in-out
        ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}`}>
        
        {/* Top logo section */}
        <div className="flex items-center gap-3 px-6 py-6 border-b border-white/5">
          <div className="w-10 h-10 rounded-xl bg-white flex items-center justify-center shadow-lg shadow-orange-500/10 p-1">
            <img src="/logo.png" alt="FitFusion" className="w-full h-full object-contain" />
          </div>
          <div>
            <p className="text-white font-bold text-base leading-none">FitFusion</p>
            <p className="text-[#64748B] text-xs mt-0.5">Admin Portal</p>
          </div>
        </div>

        <nav className="flex-1 py-6 overflow-y-auto">
          {/* Navigation section label */}
          <p className="px-6 mb-2 text-[10px] font-semibold text-[#475569] uppercase tracking-widest">
            Main Menu
          </p>

          <div className="space-y-0.5 px-3">
            {navItems.map((item) => (
              <NavLink
                key={item.path}
                to={item.path}
                onClick={() => { if(window.innerWidth < 1024 && onClose) onClose() }}
                className={({ isActive }) => `
                  flex items-center gap-3 px-4 py-2.5 rounded-xl mx-2 mb-1
                  transition-all duration-200 group
                  ${isActive 
                    ? 'bg-gradient-to-r from-[#E8845C] to-[#D4673A] text-white shadow-lg shadow-orange-500/20' 
                    : 'text-[#64748B] hover:bg-white/5 hover:text-white'
                  }
                `}
              >
                {({ isActive }) => (
                  <>
                    <item.icon size={18} className={isActive ? 'text-white' : 
                      'text-[#64748B] group-hover:text-white transition-colors'} />
                    <span className="text-sm font-medium">{item.label}</span>
                    {item.badge && (
                      <span className="ml-auto bg-red-500 text-white text-[10px] 
                        font-bold px-1.5 py-0.5 rounded-full min-w-[18px] 
                        text-center">
                        {item.badge}
                      </span>
                    )}
                  </>
                )}
              </NavLink>
            ))}
          </div>
        </nav>

        {/* Bottom user section */}
        <div className="p-4 border-t border-white/5">
          <div className="flex items-center gap-3 p-3 rounded-xl 
            hover:bg-white/5 cursor-pointer transition-all group">
            <div className="w-8 h-8 rounded-xl bg-gradient-to-br 
              from-[#E8845C] to-[#D4673A] flex items-center 
              justify-center text-white text-xs font-bold shrink-0">
              AD
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-white text-sm font-medium truncate">Admin User</p>
              <p className="text-[#475569] text-xs truncate">{user?.email || 'admin@fitfusion.com'}</p>
            </div>
            <button onClick={logout} className="opacity-0 lg:group-hover:opacity-100
              opacity-100
              transition-opacity p-1.5 hover:bg-white/10 rounded-lg">
              <LogOut size={14} className="text-[#94A3B8]" />
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
