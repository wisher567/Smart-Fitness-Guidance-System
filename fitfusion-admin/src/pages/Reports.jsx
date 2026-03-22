import { useState, useEffect } from 'react';
import { Download, TrendingUp, Users, Calendar } from 'lucide-react';
import { AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { toast } from 'react-hot-toast';
import api from '../services/api';
import { formatCurrency } from '../utils/formatters';

export default function Reports() {
  const [revenueData, setRevenueData] = useState([]);
  const [memberData, setMemberData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState('6M'); // 6M, 1Y, ALL

  useEffect(() => {
    fetchStats();
  }, [dateRange]);

  const fetchStats = async () => {
    setLoading(true);
    try {
      const [revRes, memRes] = await Promise.all([
        api.get('/admin/stats/revenue'),
        api.get('/admin/stats/members')
      ]);
      
      // The API returns monthly totals. 
      // Determine how many months to show based on dateRange
      const limit = dateRange === '6M' ? 6 : dateRange === '1Y' ? 12 : undefined;
      
      let rData = revRes.data?.monthly || [];
      let mData = memRes.data?.monthly || [];
      
      if (limit) {
        rData = rData.slice(-limit);
        mData = mData.slice(-limit);
      }
      
      setRevenueData(rData);
      setMemberData(mData);
    } catch (err) {
      toast.error('Failed to load reports');
    } finally {
      setLoading(false);
    }
  };

  const handleExport = () => {
    toast.success('Report generation started. Check your downloads.');
    // Mapped export logic
    const csv = ['Month,Revenue,New Members'].concat(
      revenueData.map((r, i) => `${r.month},${r.revenue},${memberData[i]?.count || 0}`)
    ).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `fitfusion_report_${new Date().getTime()}.csv`;
    a.click();
  };

  if (loading) return (
    <div className="flex h-[60vh] items-center justify-center">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
    </div>
  );

  const totalRev = revenueData.reduce((sum, item) => sum + item.revenue, 0);
  const totalNewMem = memberData.reduce((sum, item) => sum + item.count, 0);

  return (
    <div className="space-y-6 animate-fade-in-up">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Reports & Analytics</h2>
          <p className="text-gray-500 text-sm mt-1">Detailed breakdown of gym performance</p>
        </div>
        
        <div className="flex items-center gap-3">
          <div className="bg-white border border-gray-200 rounded-xl p-1 flex items-center">
            {['6M', '1Y', 'ALL'].map(range => (
              <button 
                key={range}
                onClick={() => setDateRange(range)}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${dateRange === range ? 'bg-primary text-white' : 'text-gray-500 hover:text-gray-900'}`}
              >
                {range}
              </button>
            ))}
          </div>
          <button onClick={handleExport} className="flex items-center gap-2 border border-gray-200 bg-white hover:bg-gray-50 text-gray-700 font-medium px-4 py-2.5 rounded-xl transition-colors text-sm">
            <Download size={18} /> Export Full Report
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Revenue Report */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col">
          <div className="flex justify-between items-start mb-6">
            <div>
              <h3 className="font-bold text-gray-900 flex items-center gap-2"><TrendingUp size={20} className="text-orange-500"/> Revenue Growth</h3>
              <p className="text-sm text-gray-500 mt-1">Total across selected period</p>
            </div>
            <div className="text-right">
              <p className="text-2xl font-bold text-gray-900">{formatCurrency(totalRev)}</p>
              <p className="text-sm text-green-500 font-medium">+12% vs previous</p>
            </div>
          </div>
          <div className="flex-1 min-h-[300px]">
            {revenueData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={revenueData} margin={{top: 10, right: 10, left: -20, bottom: 0}}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F0F0F0" />
                  <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{fill: '#9CA3AF', fontSize: 12}} dy={10} />
                  <YAxis axisLine={false} tickLine={false} tick={{fill: '#9CA3AF', fontSize: 12}} tickFormatter={v => `LKR ${v/1000}k`} />
                  <Tooltip cursor={{fill: 'transparent'}} contentStyle={{borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}} formatter={(val) => [`LKR ${val.toLocaleString()}`, 'Revenue']} />
                  <Bar dataKey="revenue" fill="#E8845C" radius={[4,4,0,0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-gray-400">Not enough data</div>
            )}
          </div>
        </div>

        {/* Member Growth Report */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col">
          <div className="flex justify-between items-start mb-6">
            <div>
              <h3 className="font-bold text-gray-900 flex items-center gap-2"><Users size={20} className="text-blue-500"/> Member Acquisition</h3>
              <p className="text-sm text-gray-500 mt-1">New members enrolled</p>
            </div>
            <div className="text-right">
              <p className="text-2xl font-bold text-gray-900">{totalNewMem}</p>
              <p className="text-sm text-green-500 font-medium">+5% vs previous</p>
            </div>
          </div>
          <div className="flex-1 min-h-[300px]">
             {memberData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={memberData} margin={{top: 10, right: 10, left: -20, bottom: 0}}>
                  <defs>
                    <linearGradient id="colorMembers" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#3B82F6" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#3B82F6" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F0F0F0" />
                  <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{fill: '#9CA3AF', fontSize: 12}} dy={10} />
                  <YAxis axisLine={false} tickLine={false} tick={{fill: '#9CA3AF', fontSize: 12}} />
                  <Tooltip contentStyle={{borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}} />
                  <Area type="monotone" dataKey="count" stroke="#3B82F6" strokeWidth={3} fillOpacity={1} fill="url(#colorMembers)" />
                </AreaChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-gray-400">Not enough data</div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}
