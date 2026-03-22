import React, { useState, useEffect } from 'react';
import { 
  Calendar as CalendarIcon, Users, Clock, 
  MapPin, Plus, ChevronRight, Search, Filter 
} from 'lucide-react';
import api from '../../services/api';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import LoadingSpinner from '../../components/ui/LoadingSpinner';
import { format, isToday, isFuture } from 'date-fns';

export default function TrainerClasses() {
  const [loading, setLoading] = useState(true);
  const [classes, setClasses] = useState([]);
  const [filter, setFilter] = useState('all'); // all, today, upcoming

  useEffect(() => {
    fetchClasses();
  }, []);

  const fetchClasses = async () => {
    try {
      const res = await api.get('/trainer/classes');
      if (res.data.success) {
        setClasses(res.data.classes);
      }
    } catch (err) {
      console.error('Failed to fetch trainer classes:', err);
    } finally {
      setLoading(false);
    }
  };

  const filteredClasses = classes.filter(c => {
    const classDate = new Date(c.dateTime);
    if (filter === 'today') return isToday(classDate);
    if (filter === 'upcoming') return isFuture(classDate);
    return true;
  });

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-3">
            My Classes
            <span className="bg-[#E8845C]/10 text-[#E8845C] text-xs font-bold px-2 py-1 rounded-lg">
              {classes.length}
            </span>
          </h1>
          <p className="text-gray-500 text-sm mt-1">View and manage your personal training sessions and group classes.</p>
        </div>
        <Button variant="primary" className="rounded-2xl gap-2 shadow-lg shadow-orange-500/20">
          <Plus size={18} />
          Create New Class
        </Button>
      </div>

      {/* Filters */}
      <div className="flex bg-gray-100 p-1 rounded-2xl border border-gray-200 shadow-inner w-fit">
        {['all', 'today', 'upcoming'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-6 py-1.5 rounded-xl text-xs font-bold capitalize transition-all
              ${filter === f ? 'bg-white text-[#E8845C] shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}
          >
            {f}
          </button>
        ))}
      </div>

      {/* Classes Grid */}
      {filteredClasses.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
          {filteredClasses.map((c) => (
            <div key={c.id} className="bg-white rounded-3xl p-6 shadow-card hover:shadow-cardHover border border-gray-50 transition-all group overflow-hidden relative">
              <div className="flex flex-col h-full relative z-10">
                <div className="flex justify-between items-start mb-5">
                  <div className="bg-[#E8845C]/10 p-2.5 rounded-2xl group-hover:bg-[#E8845C] group-hover:text-white transition-all duration-300">
                    <CalendarIcon size={22} className="transition-colors" />
                  </div>
                  <Badge status={isToday(new Date(c.dateTime)) ? 'today' : 'upcoming'} />
                </div>

                <h3 className="text-lg font-bold text-gray-900 mb-1 group-hover:text-[#E8845C] transition-colors">{c.name}</h3>
                <p className="text-xs text-gray-400 font-medium mb-6 uppercase tracking-widest">{c.type || 'Group Session'}</p>

                <div className="space-y-4 mb-8">
                  <div className="flex items-center gap-3 text-sm font-medium text-gray-600">
                    <div className="w-8 h-8 rounded-xl bg-gray-50 flex items-center justify-center text-[#E8845C]">
                      <Clock size={16} />
                    </div>
                    <div>
                        <p className="text-[10px] text-gray-400 font-bold uppercase tracking-tighter leading-none mb-1">Time & Duration</p>
                        <p>{format(new Date(c.dateTime), 'h:mm a')} • {c.duration || '60 mins'}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 text-sm font-medium text-gray-600">
                    <div className="w-8 h-8 rounded-xl bg-gray-50 flex items-center justify-center text-[#E8845C]">
                      <MapPin size={16} />
                    </div>
                    <div>
                        <p className="text-[10px] text-gray-400 font-bold uppercase tracking-tighter leading-none mb-1">Location</p>
                        <p>{c.location || 'Studio A'}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 text-sm font-medium text-gray-600">
                    <div className="w-8 h-8 rounded-xl bg-gray-50 flex items-center justify-center text-[#E8845C]">
                      <Users size={16} />
                    </div>
                    <div>
                        <p className="text-[10px] text-gray-400 font-bold uppercase tracking-tighter leading-none mb-1">Enrollment</p>
                        <p>{c.enrolledMembers?.length || 0} / {c.capacity || 20} Members</p>
                    </div>
                  </div>
                </div>

                <div className="mt-auto flex gap-3">
                   <Button variant="primary" fullWidth className="rounded-2xl text-xs font-bold py-3 shadow-lg shadow-orange-500/10">
                      Manage Attendance
                   </Button>
                   <button className="p-3 bg-gray-50 text-gray-400 rounded-2xl hover:bg-gray-100 transition-colors">
                      <ChevronRight size={18} />
                   </button>
                </div>
              </div>
              
              {/* Decorative line */}
              <div className="absolute top-0 right-0 w-32 h-32 bg-[#E8845C]/5 rounded-full blur-3xl -mr-16 -mt-16"></div>
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-white rounded-3xl p-24 text-center border-2 border-dashed border-gray-100 flex flex-col items-center justify-center gap-4">
           <div className="w-16 h-16 bg-gray-50 rounded-[2rem] flex items-center justify-center text-gray-200">
              <CalendarIcon size={32} />
           </div>
           <div className="max-w-xs">
              <h3 className="text-lg font-black text-gray-900">No classes scheduled</h3>
              <p className="text-gray-500 text-sm mt-1 font-medium italic">
                {filter === 'all' ? "You don't have any classes recorded in our system." : `No ${filter} classes found for your profile.`}
              </p>
           </div>
           {filter !== 'all' && (
             <Button variant="secondary" onClick={() => setFilter('all')} className="mt-2 text-xs font-bold rounded-xl">
               Show All Classes
             </Button>
           )}
        </div>
      )}
    </div>
  );
}
