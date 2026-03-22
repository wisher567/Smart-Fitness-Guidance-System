import { useState, useEffect, useMemo } from 'react';
import { Download, RefreshCcw } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import api from '../services/api';
import DataTable from '../components/ui/DataTable';
import Badge from '../components/ui/Badge';
import SearchInput from '../components/ui/SearchInput';
import { getInitials, getAvatarColor, formatDate, formatCurrency } from '../utils/formatters';

export default function Payments() {
  const [payments, setPayments] = useState([]);
  const [filteredPayments, setFilteredPayments] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchPayments();
  }, []);

  useEffect(() => {
    filterData();
  }, [payments, searchQuery, statusFilter]);

  const fetchPayments = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/admin/payments');
      setPayments(res.data?.payments || []);
    } catch(e) {
      toast.error('Failed to load payments');
    } finally {
      setIsLoading(false);
    }
  };

  const filterData = () => {
    let result = payments;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      result = result.filter(p => (p.memberName || '').toLowerCase().includes(q) || (p.id || '').toLowerCase().includes(q));
    }
    if (statusFilter !== 'all') {
      result = result.filter(p => p.status === statusFilter);
    }
    setFilteredPayments(result);
  };

  // derived metrics
  const totalRevenue = payments.reduce((sum, p) => p.status==='completed' ? sum + p.amount : sum, 0);
  const currentMonth = new Date().toISOString().slice(0, 7);
  const monthRevenue = payments.reduce((sum, p) => p.status==='completed' && p.createdAt?.startsWith(currentMonth) ? sum + p.amount : sum, 0);
  const pendingCount = payments.filter(p => p.status==='pending').length;

  // Chart data
  const monthlyData = useMemo(() => {
    const monthly = {};
    payments.filter(p => p.status === 'completed').forEach(p => {
      const m = p.createdAt?.slice(0, 7) || 'Unknown';
      if (!monthly[m]) monthly[m] = { month: m, revenue: 0 };
      monthly[m].revenue += p.amount;
    });
    return Object.values(monthly).sort((a,b) => a.month.localeCompare(b.month)).slice(-6); // last 6 months
  }, [payments]);

  const downloadInvoice = (payment) => {
    const content = `
FITFUSION GYM - INVOICE
=======================
Invoice: ${payment.id}
Member:  ${payment.memberName || 'Unknown'}
Plan:    ${payment.planName || 'Membership Plan'}
Amount:  ${formatCurrency(payment.amount)}
Date:    ${formatDate(payment.createdAt)}
Status:  ${payment.status.toUpperCase()}
Card:    **** **** **** ${payment.cardLast4 || 'XXXX'}
=======================
Thank you for your membership!`;
    const blob = new Blob([content], { type: 'text/plain' });
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href     = url;
    a.download = `Invoice_${payment.id}.txt`;
    a.click();
  };

  const markPaid = async (paymentId) => {
    if(window.confirm('Mark this payment as completed?')) {
        // mock for now
        toast.success("Payment marked as completed");
    }
  };

  const columns = [
    { key: 'invoice', label: 'Invoice #', render: (p) => <span className="font-mono text-xs text-gray-500">{p.id.slice(0,8).toUpperCase()}</span> },
    { key: 'member', label: 'Member', render: (p) => (
      <div className="flex items-center gap-3">
        <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold text-xs ${getAvatarColor(p.memberName)}`}>
          {getInitials(p.memberName)}
        </div>
        <p className="font-semibold text-gray-900">{p.memberName || 'Unknown'}</p>
      </div>
    )},
    { key: 'plan', label: 'Plan', render: (p) => p.planName || 'Basic' },
    { key: 'amount', label: 'Amount', render: (p) => <span className="font-bold">{formatCurrency(p.amount)}</span> },
    { key: 'status', label: 'Status', render: (p) => <Badge status={p.status} /> },
    { key: 'date', label: 'Date', render: (p) => formatDate(p.createdAt) },
    { key: 'actions', label: '', render: (p) => (
      <div className="flex items-center gap-2">
        <button onClick={() => downloadInvoice(p)} className="text-primary hover:bg-primary/10 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors">
          Invoice
        </button>
        {p.status === 'pending' && (
          <button onClick={() => markPaid(p.id)} className="text-green-600 hover:bg-green-50 border border-green-200 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors">
            Mark Paid
          </button>
        )}
      </div>
    )}
  ];

  return (
    <div className="space-y-6 animate-fade-in-up">
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <h2 className="text-2xl font-bold text-gray-900">Payments & Billing</h2>
          <Badge status="completed" /> 
        </div>
        <div className="flex items-center gap-3">
          <SearchInput value={searchQuery} onChange={(e)=>setSearchQuery(e.target.value)} placeholder="Search member or invoice..." />
          <select value={statusFilter} onChange={(e)=>setStatusFilter(e.target.value)} className="border border-gray-200 rounded-xl text-sm px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary/20">
            <option value="all">All Status</option>
            <option value="completed">Completed</option>
            <option value="pending">Pending</option>
            <option value="failed">Failed</option>
          </select>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-2xl border border-gray-100 p-6 flex items-center justify-between">
            <div>
                <p className="text-gray-500 text-sm mb-1">Total Revenue</p>
                <p className="text-2xl font-bold text-gray-900">{formatCurrency(totalRevenue)}</p>
            </div>
            <div className="w-12 h-12 bg-blue-50 text-blue-500 rounded-full flex items-center justify-center">💰</div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-100 p-6 flex items-center justify-between">
            <div>
                <p className="text-gray-500 text-sm mb-1">This Month Revenue</p>
                <p className="text-2xl font-bold text-gray-900">{formatCurrency(monthRevenue)}</p>
            </div>
            <div className="w-12 h-12 bg-orange-50 text-orange-500 rounded-full flex items-center justify-center">📈</div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-100 p-6 flex items-center justify-between">
            <div>
                <p className="text-gray-500 text-sm mb-1">Pending Payments</p>
                <p className="text-2xl font-bold text-gray-900">{pendingCount}</p>
            </div>
            <div className="w-12 h-12 bg-yellow-50 text-yellow-500 rounded-full flex items-center justify-center">⏳</div>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 p-6 h-[300px]">
        <h3 className="font-bold text-gray-900 mb-4">Monthly Revenue</h3>
        {monthlyData.length > 0 ? (
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={monthlyData} margin={{top: 0, right: 0, left: -20, bottom: 0}}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0"/>
                <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#9ca3af'}} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#9ca3af'}} tickFormatter={v => `LKR ${v/1000}k`} />
                <Tooltip cursor={{fill: 'transparent'}} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}} formatter={(val) => [`LKR ${val.toLocaleString()}`, 'Revenue']} />
                <Bar dataKey="revenue" fill="#E8845C" radius={[4,4,0,0]} />
            </BarChart>
          </ResponsiveContainer>
        ) : (
          <div className="h-full flex items-center justify-center text-gray-400">Not enough data to graph</div>
        )}
      </div>

      <DataTable 
        columns={columns}
        data={filteredPayments}
        loading={isLoading}
        emptyMessage="No payments found matching your filters."
      />

    </div>
  );
}
