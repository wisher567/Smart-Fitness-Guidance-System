import React, { useState, useEffect } from 'react';
import { 
  Users, Calendar, ClipboardList, Activity, 
  ChevronRight, Play, Clock, MapPin
} from 'lucide-react';
import api from '../../services/api';
import StatsCard from '../../components/ui/StatsCard';
import Avatar from '../../components/ui/Avatar';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import LoadingSpinner from '../../components/ui/LoadingSpinner';
import { useAuth } from '../../context/AuthContext';
import { format } from 'date-fns';

export default function TrainerDashboard() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const res = await api.get('/trainer/dashboard');
      if (res.data.success) {
        setData(res.data);
      }
    } catch (err) {
      console.error('Failed to fetch trainer dashboard:', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <LoadingSpinner />;

  const { stats, todayClasses, recentClients, recentActivity } = data || {};

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Welcome Section */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 group">
            Welcome back, <span className="text-[#E8845C]">{user?.displayName || 'Trainer'}!</span> 💪
          </h1>
          <p className="text-gray-500 mt-1 font-medium italic">
            {format(new Date(), 'EEEE, MMMM do, yyyy')}
          </p>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 font-primary">
        <StatsCard 
          icon={Users}
          value={stats?.totalClients || 0}
          label="My Clients"
          color="text-blue-600"
          bgColor="bg-blue-50"
        />
        <StatsCard 
          icon={Calendar}
          value={stats?.todayClasses || 0}
          label="Today's Classes"
          color="text-orange-600"
          bgColor="bg-orange-50"
        />
        <StatsCard 
          icon={ClipboardList}
          value={stats?.totalPlans || 0}
          label="Total Plans"
          color="text-green-600"
          bgColor="bg-green-50"
        />
        <StatsCard 
          icon={Activity}
          value={stats?.activeClients || 0}
          label="Active Members"
          color="text-purple-600"
          bgColor="bg-purple-50"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Today's Classes */}
        <div className="lg:col-span-2 space-y-6">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
              <span className="w-1.5 h-6 bg-[#E8845C] rounded-full"></span>
              Today's Classes
            </h2>
            <button className="text-sm font-semibold text-[#E8845C] hover:underline">
              View Calendar
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {todayClasses && todayClasses.length > 0 ? (
              todayClasses.map((c) => (
                <div key={c.id} className="bg-white rounded-2xl p-5 border-l-4 border-orange-500 shadow-card hover:shadow-cardHover transition-all bg-gradient-to-br from-white to-orange-50/15">
                  <div className="flex justify-between items-start mb-4">
                    <h3 className="font-bold text-gray-900 text-lg leading-tight">{c.name}</h3>
                    <Badge status="upcoming" />
                  </div>
                  
                  <div className="space-y-2 mb-4">
                    <div className="flex items-center gap-2 text-sm text-gray-500">
                      <Clock size={16} className="text-[#E8845C]" />
                      <span>{c.dateTime?.slice(11, 16)} • {c.duration || '60 mins'}</span>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-gray-500">
                      <MapPin size={16} className="text-[#E8845C]" />
                      <span>{c.location || 'Studio A'}</span>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-gray-500">
                      <Users size={16} className="text-[#E8845C]" />
                      <span>{c.enrolledMembers?.length || 0} Enrolled Members</span>
                    </div>
                  </div>

                  <Button 
                    fullWidth 
                    variant="primary" 
                    size="sm"
                    className="rounded-xl font-bold tracking-wide"
                  >
                    Start Class
                  </Button>
                </div>
              ))
            ) : (
              <div className="col-span-2 bg-white rounded-2xl p-10 border border-dashed border-gray-200 text-center flex flex-col items-center justify-center gap-3">
                <div className="w-12 h-12 bg-gray-50 rounded-2xl flex items-center justify-center">
                  <Calendar size={24} className="text-gray-300" />
                </div>
                <p className="text-gray-400 font-medium tracking-tight">No classes today. Enjoy your rest day! 😊</p>
              </div>
            )}
          </div>

          {/* Recent Client Activity */}
          <div className="space-y-4 pt-4">
            <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
              <span className="w-1.5 h-6 bg-[#E8845C] rounded-full"></span>
              Recent Client Activity
            </h2>
            <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-sm">
              <div className="divide-y divide-gray-50">
                {recentActivity && recentActivity.length > 0 ? (
                  recentActivity.map((activity) => (
                    <div key={activity.id} className="p-4 hover:bg-gray-50/50 transition-colors flex items-center gap-4">
                      <Avatar name={activity.userName || 'Member'} size="sm" />
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-bold text-gray-900 truncate">
                          {activity.userName || 'Member'} <span className="font-normal text-gray-500">completed</span> {activity.planName || 'Workout'}
                        </p>
                        <p className="text-xs text-gray-400 mt-0.5 flex items-center gap-1">
                          <Activity size={12} className="text-[#E8845C]" />
                          {activity.caloriesBurned || 0} kcal burned • {format(new Date(activity.completedAt), 'p')}
                        </p>
                      </div>
                      <span className="text-[10px] font-bold text-gray-400 bg-gray-50 px-2 py-1 rounded-lg">
                        {format(new Date(activity.completedAt), 'MMM d')}
                      </span>
                    </div>
                  ))
                ) : (
                  <div className="p-10 text-center text-gray-400 flex flex-col items-center gap-2">
                    <Activity size={24} className="text-gray-200" />
                    <p className="text-sm">No recent client activity to show.</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Sidebar: My Clients Overview */}
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
              <span className="w-1.5 h-6 bg-[#E8845C] rounded-full"></span>
              My Clients
            </h2>
            <button className="text-sm font-semibold text-[#E8845C] hover:underline">
              See All
            </button>
          </div>

          <div className="space-y-4">
            {recentClients && recentClients.length > 0 ? (
              recentClients.map((client) => (
                <div key={client.uid} className="bg-white rounded-2xl p-4 shadow-sm border border-gray-50 hover:border-[#E8845C]/30 hover:shadow-md transition-all group">
                  <div className="flex items-center gap-3 mb-3">
                    <Avatar name={client.name} size="md" />
                    <div className="flex-1 min-w-0">
                      <h3 className="text-sm font-bold text-gray-900 truncate group-hover:text-[#E8845C] transition-colors">
                        {client.name}
                      </h3>
                      <p className="text-xs text-gray-400 truncate font-medium">
                        Goal: <span className="text-gray-600 capitalize">{client.fitnessGoal?.replace('_', ' ') || 'General Fitness'}</span>
                      </p>
                    </div>
                    <Badge status={client.status || 'active'} />
                  </div>

                  <div className="flex items-center justify-between px-1">
                    <div className="flex items-center gap-2">
                      <div className="bg-[#E8845C]/10 text-[#E8845C] text-[10px] font-bold px-2 py-0.5 rounded-lg">
                        BMI: {client.bmi || 'N/A'}
                      </div>
                      <div className="bg-blue-50 text-blue-600 text-[10px] font-bold px-2 py-0.5 rounded-lg">
                        {client.points || 0} pts
                      </div>
                    </div>
                    <ChevronRight size={16} className="text-gray-300 group-hover:text-[#E8845C] group-hover:translate-x-0.5 transition-all" />
                  </div>
                </div>
              ))
            ) : (
              <div className="bg-white rounded-2xl p-10 border border-dashed border-gray-200 text-center flex flex-col items-center justify-center gap-3">
                 <Users size={24} className="text-gray-300" />
                 <p className="text-gray-400 text-sm">No clients assigned yet.</p>
              </div>
            )}
          </div>
          
          {/* Quick Actions Card */}
          <div className="bg-[#0F1923] rounded-2xl p-6 text-white overflow-hidden relative group">
            <div className="relative z-10">
              <h3 className="font-bold text-lg mb-2">Need Help?</h3>
              <p className="text-[#64748B] text-xs mb-4 leading-relaxed">Check the trainer guide or reach out to support if you're stuck.</p>
              <button className="bg-white/10 hover:bg-white/20 text-white text-xs font-bold py-2 px-4 rounded-xl transition-all border border-white/5">
                Trainer Guide
              </button>
            </div>
            <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:scale-110 transition-transform">
              <ClipboardList size={80} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
