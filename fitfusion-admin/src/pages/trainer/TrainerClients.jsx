import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Users, Search, Target, MessageCircle, 
  ChevronRight, Filter, MoreVertical
} from 'lucide-react';
import api from '../../services/api';
import Avatar from '../../components/ui/Avatar';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import LoadingSpinner from '../../components/ui/LoadingSpinner';
import SearchInput from '../../components/ui/SearchInput';

export default function TrainerClients() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [clients, setClients] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    fetchClients();
  }, []);

  const fetchClients = async () => {
    try {
      const res = await api.get('/trainer/clients');
      if (res.data.success) {
        setClients(res.data.clients);
      }
    } catch (err) {
      console.error('Failed to fetch trainer clients:', err);
    } finally {
      setLoading(false);
    }
  };

  const filteredClients = clients.filter(c => 
    c.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.email?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header Section */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-3">
            My Clients
            <span className="bg-[#E8845C]/10 text-[#E8845C] text-xs font-bold px-2 py-1 rounded-lg">
              {clients.length}
            </span>
          </h1>
          <p className="text-gray-500 text-sm mt-1">Manage and track your assigned members' progress.</p>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="flex flex-col md:flex-row gap-4">
        <div className="flex-1 relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-[#E8845C] transition-colors" size={18} />
          <input 
            type="text"
            placeholder="Search by name or email..."
            className="w-full pl-11 pr-4 py-3 bg-white border border-gray-100 rounded-2xl focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 focus:border-[#E8845C] shadow-sm transition-all text-sm"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <Button variant="secondary" className="bg-white border-gray-100 gap-2">
          <Filter size={18} />
          Filters
        </Button>
      </div>

      {/* Clients Grid */}
      {filteredClients.length > 0 ? (
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
          {filteredClients.map((client) => (
            <div key={client.uid} className="bg-white rounded-3xl p-6 shadow-card hover:shadow-cardHover border border-gray-50 transition-all group">
              <div className="flex flex-col h-full">
                {/* Top Section */}
                <div className="flex items-start gap-4 mb-5">
                  <Avatar name={client.name} size="lg" />
                  <div className="flex-1 min-w-0">
                    <div className="flex justify-between items-start">
                      <h3 className="font-bold text-gray-900 text-lg group-hover:text-[#E8845C] transition-colors truncate">
                        {client.name}
                      </h3>
                      <button className="text-gray-300 hover:text-gray-500 p-1">
                        <MoreVertical size={18} />
                      </button>
                    </div>
                    <p className="text-gray-400 text-sm truncate mb-3">{client.email}</p>
                    <div className="flex flex-wrap gap-2">
                      <Badge status={client.status || 'active'} />
                      <Badge status={client.membershipPlanName?.toLowerCase() || 'basic'} />
                    </div>
                  </div>
                </div>

                {/* Stats Section */}
                <div className="grid grid-cols-3 gap-3 mb-6">
                  <div className="bg-gray-50 rounded-2xl p-3 text-center transition-colors group-hover:bg-[#E8845C]/5">
                    <p className="text-xl font-bold text-gray-900">{client.bmi || 'N/A'}</p>
                    <p className="text-[10px] text-gray-400 uppercase font-bold tracking-wider">BMI</p>
                  </div>
                  <div className="bg-gray-50 rounded-2xl p-3 text-center transition-colors group-hover:bg-[#E8845C]/5">
                    <p className="text-xl font-bold text-[#E8845C]">{client.points || 0}</p>
                    <p className="text-[10px] text-gray-400 uppercase font-bold tracking-wider">Points</p>
                  </div>
                  <div className="bg-gray-50 rounded-2xl p-3 text-center transition-colors group-hover:bg-[#E8845C]/5">
                    <p className="text-xl font-bold text-gray-900 truncate px-1">
                      {client.fitnessLevel || 'N/A'}
                    </p>
                    <p className="text-[10px] text-gray-400 uppercase font-bold tracking-wider">Level</p>
                  </div>
                </div>

                {/* Goal Section */}
                <div className="flex items-center gap-2 mb-6 p-3.5 bg-[#E8845C]/5 rounded-2xl border border-[#E8845C]/10">
                  <div className="bg-white p-1.5 rounded-lg shadow-sm">
                    <Target size={14} className="text-[#E8845C]" />
                  </div>
                  <div className="flex-1">
                    <p className="text-[10px] text-[#E8845C]/60 uppercase font-bold tracking-widest">Fitness Goal</p>
                    <p className="text-sm text-gray-800 font-bold capitalize">
                      {client.fitnessGoal?.replace('_', ' ') || 'General Fitness'}
                    </p>
                  </div>
                </div>

                {/* Actions Section */}
                <div className="mt-auto flex gap-3">
                  <button 
                    onClick={() => navigate(`/trainer/clients/${client.uid}`)}
                    className="flex-[2] py-3 bg-[#E8845C] text-white rounded-2xl text-sm font-bold shadow-lg shadow-orange-500/20 hover:bg-[#D4673A] hover:-translate-y-0.5 active:translate-y-0 transition-all flex items-center justify-center gap-2"
                  >
                    View Profile
                    <ChevronRight size={16} />
                  </button>
                  <button 
                    onClick={() => navigate(`/trainer/plans/create?client=${client.uid}`)}
                    className="flex-[1.5] py-3 border border-[#E8845C] text-[#E8845C] rounded-2xl text-sm font-bold hover:bg-[#E8845C] hover:text-white hover:-translate-y-0.5 active:translate-y-0 transition-all"
                  >
                    Create Plan
                  </button>
                  <button 
                    onClick={() => navigate(`/trainer/chat?client=${client.uid}`)}
                    className="p-3 border border-gray-200 text-gray-400 rounded-2xl hover:bg-gray-50 hover:text-[#E8845C] hover:border-[#E8845C]/30 transition-all"
                  >
                    <MessageCircle size={18} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-white rounded-3xl p-20 text-center border-2 border-dashed border-gray-200 flex flex-col items-center justify-center gap-4">
          <div className="w-16 h-16 bg-gray-50 rounded-3xl flex items-center justify-center text-gray-300">
            <Users size={32} />
          </div>
          <div className="max-w-xs">
            <h3 className="text-lg font-bold text-gray-900">No clients found</h3>
            <p className="text-gray-500 text-sm mt-1">
              {searchQuery ? `We couldn't find any results for "${searchQuery}"` : "You don't have any clients assigned to you yet."}
            </p>
          </div>
          {searchQuery && (
            <Button variant="secondary" onClick={() => setSearchQuery('')} className="mt-2">
              Clear Search
            </Button>
          )}
        </div>
      )}
    </div>
  );
}
