import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  ClipboardList, Plus, Search, Filter, 
  Calendar, User, Trash2, Edit2, CheckCircle2,
  Clock, Flame, MoreHorizontal
} from 'lucide-react';
import api from '../../services/api';
import Avatar from '../../components/ui/Avatar';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import LoadingSpinner from '../../components/ui/LoadingSpinner';
import { format } from 'date-fns';
import { toast } from 'react-hot-toast';

export default function TrainerWorkoutPlans() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [plans, setPlans] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    fetchPlans();
  }, []);

  const fetchPlans = async () => {
    try {
      const res = await api.get('/trainer/plans');
      if (res.data.success) {
        setPlans(res.data.plans);
      }
    } catch (err) {
      console.error('Failed to fetch trainer plans:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this plan?')) return;
    try {
      const res = await api.delete(`/trainer/plans/${id}`);
      if (res.data.success) {
        setPlans(plans.filter(p => p.id !== id));
        toast.success('Plan deleted successfully');
      }
    } catch (err) {
      toast.error('Failed to delete plan');
    }
  };

  const filteredPlans = plans.filter(p => {
    const matchesSearch = p.planName?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = filter === 'all' || p.status === filter;
    return matchesSearch && matchesFilter;
  });

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-3">
            Workout Plans
            <span className="bg-[#E8845C]/10 text-[#E8845C] text-xs font-bold px-2 py-1 rounded-lg">
              {plans.length}
            </span>
          </h1>
          <p className="text-gray-500 text-sm mt-1">Manage and assign training routines to your clients.</p>
        </div>
        <Button 
          variant="primary" 
          className="rounded-2xl gap-2 shadow-lg shadow-orange-500/20"
          onClick={() => navigate('/trainer/plans/create')}
        >
          <Plus size={18} />
          Create New Plan
        </Button>
      </div>

      {/* Filters & Search */}
      <div className="flex flex-col lg:flex-row gap-4">
        <div className="flex-1 relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
          <input 
            type="text"
            placeholder="Search by plan name..."
            className="w-full pl-11 pr-4 py-3 bg-white border border-gray-100 rounded-2xl focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 focus:border-[#E8845C] shadow-sm transition-all text-sm"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <div className="flex bg-gray-100 p-1 rounded-2xl border border-gray-200 shadow-inner">
          {['all', 'assigned', 'completed', 'draft'].map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-1.5 rounded-xl text-xs font-bold capitalize transition-all
                ${filter === f ? 'bg-white text-[#E8845C] shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {/* Plans Grid */}
      {filteredPlans.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredPlans.map((plan) => (
            <div key={plan.id} className="bg-white rounded-3xl p-6 shadow-card hover:shadow-cardHover border border-gray-50 transition-all group flex flex-col">
              <div className="flex justify-between items-start mb-4">
                <div className="bg-[#E8845C]/10 p-2.5 rounded-2xl">
                  <ClipboardList size={20} className="text-[#E8845C]" />
                </div>
                <Badge status={plan.status || 'draft'} />
              </div>

              <h3 className="text-lg font-bold text-gray-900 group-hover:text-[#E8845C] transition-colors mb-2">
                {plan.planName}
              </h3>
              
              <div className="space-y-3 mb-6 flex-1">
                <div className="flex items-center gap-2">
                  <Avatar name={plan.clientName || 'Unassigned'} size="xs" />
                  <p className="text-xs text-gray-500 font-medium">For: <span className="text-gray-900">{plan.clientName || 'Draft'}</span></p>
                </div>
                <div className="flex gap-4">
                   <div className="flex items-center gap-1.5 text-[10px] font-bold text-gray-400 uppercase tracking-widest">
                      <CheckCircle2 size={12} className="text-[#E8845C]" />
                      {plan.exercises?.length || 0} Exercises
                   </div>
                   <div className="flex items-center gap-1.5 text-[10px] font-bold text-gray-400 uppercase tracking-widest">
                      <Flame size={12} className="text-orange-400" />
                      {plan.exercises?.reduce((s, e) => s + (e.estimatedCalories || 0), 0)} kCal
                   </div>
                </div>
                <div className="flex items-center gap-1.5 text-xs text-gray-400">
                   <Calendar size={12} />
                   <span>Created: {format(new Date(plan.createdAt), 'MMM d, yyyy')}</span>
                </div>
              </div>

              <div className="flex gap-2 pt-4 border-t border-gray-50">
                <button 
                  onClick={() => navigate(`/trainer/plans/edit/${plan.id}`)}
                  className="flex-1 py-2.5 bg-gray-50 text-gray-500 rounded-xl text-xs font-bold hover:bg-[#E8845C]/5 hover:text-[#E8845C] transition-all flex items-center justify-center gap-2"
                >
                  <Edit2 size={14} />
                  Edit
                </button>
                <button 
                  onClick={() => handleDelete(plan.id)}
                  className="p-2.5 bg-gray-50 text-gray-300 rounded-xl hover:bg-red-50 hover:text-red-500 transition-all"
                >
                  <Trash2 size={14} />
                </button>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-white rounded-3xl p-20 text-center border-2 border-dashed border-gray-100 flex flex-col items-center justify-center gap-4">
           <ClipboardList size={32} className="text-gray-200" />
           <p className="text-gray-400 text-sm font-medium italic">No workout plans found.</p>
           <Button variant="primary" onClick={() => navigate('/trainer/plans/create')} size="sm">
              Create One Now
           </Button>
        </div>
      )}
    </div>
  );
}
