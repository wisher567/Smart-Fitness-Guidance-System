import { NavLink } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import {
  LayoutDashboard, Users, ClipboardList, Calendar,
  MessageCircle, User, LogOut
} from 'lucide-react';

const navItems = [
  { icon: LayoutDashboard, label: 'Dashboard', path: '/trainer/dashboard' },
  { icon: Users, label: 'My Clients', path: '/trainer/clients' },
  { icon: ClipboardList, label: 'Workout Plans', path: '/trainer/plans' },
  { icon: Calendar, label: 'My Classes', path: '/trainer/classes' },
  { icon: MessageCircle, label: 'Client Chat', path: '/trainer/chat' },
  { icon: User, label: 'My Profile', path: '/trainer/profile' },
];

export default function TrainerSidebar({ isOpen, onClose }) {
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
            <p className="text-[#E8845C]/60 text-[10px] uppercase tracking-widest mt-1">Trainer Portal</p>
          </div>
        </div>

        <nav className="flex-1 py-6 overflow-y-auto">
          <p className="px-6 mb-2 text-[10px] font-semibold text-[#475569] uppercase tracking-widest">
            Trainer Menu
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
              {user?.displayName?.substring(0,2).toUpperCase() || 'TR'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-white text-sm font-medium truncate">{user?.displayName || 'Trainer'}</p>
              <p className="text-[#475569] text-xs truncate">Trainer</p>
            </div>
            <button onClick={logout} className="opacity-0 lg:group-hover:opacity-100
              opacity-100 transition-opacity p-1.5 hover:bg-white/10 rounded-lg">
              <LogOut size={14} className="text-[#94A3B8]" />
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
