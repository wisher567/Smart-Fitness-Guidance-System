import { useState, useEffect } from 'react';
import { Users, CreditCard, TrendingUp, AlertTriangle, RefreshCw } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { format } from 'date-fns';
import api from '../services/api';
import StatsCard from '../components/ui/StatsCard';
import Badge from '../components/ui/Badge';
import LoadingSpinner from '../components/ui/LoadingSpinner';
import { formatCurrency, formatDate, getInitials, getAvatarColor } from '../utils/formatters';
import { Link } from 'react-router-dom';

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [recentMembers, setRecentMembers] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [revenueData, setRevenueData] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchDashboardData = async () => {
    setLoading(true);
    try {
      const [statsRes, membersRes, paymentsRes, revenueRes] = await Promise.all([
        api.get('/admin/dashboard').catch(()=>({data:{}})),
        api.get('/admin/members').catch(()=>({data:{}})),
        api.get('/admin/payments').catch(()=>({data:{}})),
        api.get('/admin/stats/revenue').catch(()=>({data:{}}))
      ]);
      
      setStats(statsRes.data?.stats || {
         totalMembers: 0, activeSubscriptions: 0, totalRevenue: 0, openEquipmentAlerts: 0
      });
      setRecentMembers((membersRes.data?.members || []).slice(0, 5));
      setRevenueData(revenueRes.data?.monthly || []);
      
      // Mock equipment alerts
      setAlerts([
        { id: 1, equip: 'Treadmill 4', issue: 'Belt skipping', urgency: 'high', reportedBy: 'John D.' },
        { id: 2, equip: 'Leg Press', issue: 'Squeaking noise', urgency: 'medium', reportedBy: 'Sarah M.' },
      ]);
      
    } catch (error) {
      console.error("Dashboard fetch error:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  if (loading && !stats) return (
    <div className="h-[60vh] flex items-center justify-center">
      <LoadingSpinner text="Loading dashboard..." />
    </div>
  );

  return (
    <div className="p-6 lg:p-8 space-y-6 animate-fade-in">

      {/* Welcome section */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">
            Good morning, Admin! 👋
          </h1>
          <p className="text-gray-500 text-sm mt-1">
            {format(new Date(), 'EEEE, MMMM do yyyy')}
          </p>
        </div>
        <button onClick={fetchDashboardData} className="flex items-center gap-2 px-4 py-2.5 
          bg-white border border-[#E2E8F0] rounded-xl text-sm 
          text-gray-600 hover:bg-gray-50 shadow-card transition-all">
          <RefreshCw size={15} className={loading ? "animate-spin" : ""} />
          Refresh
        </button>
      </div>

      {/* Stats grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <StatsCard
          icon={Users}
          value={stats?.totalMembers || "0"}
          label="Total Members"
          trend="+12 this month"
          trendUp={true}
          bgColor="bg-blue-50"
          color="text-blue-500"
        />
        <StatsCard
          icon={CreditCard}
          value={stats?.activeSubscriptions || "0"}
          label="Active Plans"
          trend="85% of members"
          trendUp={true}
          bgColor="bg-green-50"
          color="text-green-500"
        />
        <StatsCard
          icon={TrendingUp}
          value={formatCurrency(stats?.totalRevenue) || "LKR 0"}
          label="Revenue This Month"
          trend="+8% vs last month"
          trendUp={true}
          bgColor="bg-orange-50"
          color="text-[#E8845C]"
        />
        <StatsCard
          icon={AlertTriangle}
          value={stats?.openEquipmentAlerts || "0"}
          label="Equipment Alerts"
          trend={stats?.openEquipmentAlerts > 0 ? "Needs attention" : "All good"}
          trendUp={stats?.openEquipmentAlerts === 0}
          bgColor="bg-red-50"
          color="text-red-500"
        />
      </div>

      {/* Revenue + Members section */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        
        {/* Revenue chart - takes 2/3 */}
        <div className="xl:col-span-2 bg-white rounded-2xl border 
          border-[#E2E8F0] shadow-card p-6">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="font-bold text-gray-900">Revenue Overview</h3>
              <p className="text-gray-500 text-sm mt-0.5">
                Last 6 months performance
              </p>
            </div>
            <select className="text-sm border border-[#E2E8F0] rounded-xl
              px-3 py-2 bg-gray-50 text-gray-600 focus:outline-none
              focus:border-[#E8845C] cursor-pointer">
              <option>Last 6 months</option>
              <option>Last 12 months</option>
              <option>This year</option>
            </select>
          </div>
          
          <div className="h-[260px]">
          {revenueData.length > 0 ? (
            <ResponsiveContainer width="100%" height={260}>
              <AreaChart data={revenueData} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor="#E8845C" stopOpacity={0.15}/>
                    <stop offset="95%" stopColor="#E8845C" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#94A3B8' }}
                  axisLine={false} tickLine={false} dy={10} />
                <YAxis tick={{ fontSize: 12, fill: '#94A3B8' }}
                  axisLine={false} tickLine={false} dx={-10}
                  tickFormatter={v => `LKR ${(v/1000).toFixed(0)}K`} />
                <Tooltip contentStyle={{ 
                  background: '#fff', border: '1px solid #E2E8F0',
                  borderRadius: '12px', boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
                  fontSize: '13px',
                }} formatter={(value) => [`LKR ${value.toLocaleString()}`, 'Revenue']} />
                <Area type="monotone" dataKey="revenue" stroke="#E8845C"
                  strokeWidth={2.5} fill="url(#colorRevenue)"
                  dot={{ fill: '#E8845C', strokeWidth: 0, r: 4 }}
                  activeDot={{ r: 6, fill: '#E8845C', strokeWidth: 0 }} />
              </AreaChart>
            </ResponsiveContainer>
          ) : (
             <div className="flex h-full items-center justify-center text-gray-400">No revenue data available</div>
          )}
          </div>
        </div>

        {/* Recent members - takes 1/3 */}
        <div className="bg-white rounded-2xl border border-[#E2E8F0] 
          shadow-card p-6">
          <div className="flex items-center justify-between mb-5">
            <h3 className="font-bold text-gray-900">New Members</h3>
            <Link to="/members" className="text-[#E8845C] text-sm 
              font-medium hover:underline">
              See all →
            </Link>
          </div>
          <div className="space-y-4">
            {recentMembers.length === 0 && <p className="text-gray-400 text-center py-4 text-sm">No recent members</p>}
            {recentMembers.map(member => (
              <div key={member.uid} className="flex items-center gap-3">
                <div className={`w-9 h-9 rounded-xl flex items-center
                  justify-center text-white text-sm font-bold shrink-0
                  ${getAvatarColor(member.name)}`}>
                  {getInitials(member.name)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 truncate">
                    {member.name}
                  </p>
                  <p className="text-xs text-gray-400">
                    {formatDate(member.createdAt)}
                  </p>
                </div>
                <Badge status={member.membershipPlanName?.toLowerCase() || 'basic'} />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
