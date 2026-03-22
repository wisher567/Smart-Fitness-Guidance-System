import { useState, useEffect } from 'react';
import { Download, MoreVertical, Eye, Edit, ShieldBan, CheckCircle, Trash2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { toast } from 'react-hot-toast';
import api from '../services/api';
import DataTable from '../components/ui/DataTable';
import Badge from '../components/ui/Badge';
import SearchInput from '../components/ui/SearchInput';
import { getInitials, getAvatarColor, formatDate } from '../utils/formatters';

export default function Members() {
  const navigate = useNavigate();
  const [members, setMembers] = useState([]);
  const [filteredMembers, setFilteredMembers] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [planFilter, setPlanFilter] = useState('all');
  const [isLoading, setIsLoading] = useState(true);

  // Pagination states
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  useEffect(() => {
    fetchMembers();
  }, []);

  useEffect(() => {
    filterData();
  }, [members, searchQuery, statusFilter, planFilter]);

  const fetchMembers = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/admin/members');
      setMembers(res.data?.members || []);
    } catch (err) {
      toast.error('Failed to load members');
    } finally {
      setIsLoading(false);
    }
  };

  const filterData = () => {
    let result = members;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      result = result.filter(m => (m.name || '').toLowerCase().includes(q) || (m.email || '').toLowerCase().includes(q));
    }
    if (statusFilter !== 'all') {
      result = result.filter(m => (m.status || 'active') === statusFilter);
    }
    if (planFilter !== 'all') {
      result = result.filter(m => {
        const p = m.membershipPlanName?.toLowerCase();
        if (planFilter === 'none') return !p;
        return p === planFilter;
      });
    }
    setFilteredMembers(result);
    setCurrentPage(1); // Reset page on filter
  };

  const exportCSV = () => {
    const headers = ['Name', 'Email', 'Plan', 'Status', 'BMI', 'Join Date', 'Points'];
    const rows = filteredMembers.map(m => [
      `"${m.name || ''}"`, `"${m.email || ''}"`, `"${m.membershipPlanName || 'None'}"`,
      m.status || 'active', m.bmi || '', formatDate(m.createdAt || m.updatedAt), m.points || 0
    ]);
    const csv = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'fitfusion_members.csv';
    a.click();
    toast.success('Exported to CSV');
  };

  const handleAction = async (action, uid) => {
    if (action === 'view') {
      navigate(`/members/${uid}`);
    } else if (action === 'suspend') {
      if (window.confirm('Suspend this member?')) {
        // Mock API call for now, since we haven't created the status update endpoint yet
        // await api.patch(`/admin/members/${uid}/status`, { status: 'suspended' });
        toast.success('Member suspended');
      }
    } else if (action === 'activate') {
      // await api.patch(`/admin/members/${uid}/status`, { status: 'active' });
      toast.success('Member activated');
    } else if (action === 'delete') {
      if (window.confirm('Are you sure you want to permanently delete this member?')) {
        // await api.delete(`/admin/members/${uid}`);
        toast.success('Member deleted');
      }
    }
  };

  const columns = [
    { key: 'index', label: '#', render: (_, idx) => (currentPage - 1) * itemsPerPage + idx + 1 },
    { key: 'member', label: 'Member', render: (m) => (
      <div className="flex items-center gap-3 cursor-pointer" onClick={() => navigate(`/members/${m.uid}`)}>
        <div className={`w-9 h-9 shrink-0 rounded-full flex items-center justify-center text-white font-bold text-xs ${getAvatarColor(m.name)}`}>
          {getInitials(m.name)}
        </div>
        <div className="overflow-hidden">
          <p className="font-semibold text-gray-900 truncate">{m.name}</p>
          <p className="text-xs text-gray-500 truncate">{m.email}</p>
        </div>
      </div>
    )},
    { key: 'phone', label: 'Phone', render: (m) => m.phone || '—' },
    { key: 'plan', label: 'Plan', render: (m) => <Badge status={m.membershipPlanName || 'none'} /> },
    { key: 'status', label: 'Status', render: (m) => <Badge status={m.status || 'active'} /> },
    { key: 'bmi', label: 'BMI', render: (m) => m.bmi ? <span className="font-mono text-xs bg-gray-100 px-2 py-1 rounded">{m.bmi}</span> : '—' },
    { key: 'joinDate', label: 'Join Date', render: (m) => formatDate(m.createdAt || m.updatedAt) },
    { key: 'points', label: 'Points', render: (m) => <span className="font-semibold text-gray-700">{m.points || 0}</span> },
    { key: 'actions', label: '', render: (m) => (
      <div className="relative group/dropdown">
        <button className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors">
          <MoreVertical size={18} />
        </button>
        <div className="absolute right-0 mt-1 w-48 bg-white border border-gray-100 shadow-lg rounded-xl opacity-0 invisible group-hover/dropdown:opacity-100 group-hover/dropdown:visible transition-all z-10 flex flex-col py-1">
          <button onClick={() => handleAction('view', m.uid)} className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 w-full text-left">
            <Eye size={16} className="text-gray-400" /> View Profile
          </button>
          <button className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 w-full text-left">
            <Edit size={16} className="text-gray-400" /> Edit Details
          </button>
          
          <div className="h-px bg-gray-100 my-1 w-full scale-y-50"></div>
          
          {(m.status === 'suspended') ? (
            <button onClick={() => handleAction('activate', m.uid)} className="flex items-center gap-2 px-4 py-2 text-sm text-green-600 hover:bg-green-50 w-full text-left">
              <CheckCircle size={16} /> Activate
            </button>
          ) : (
            <button onClick={() => handleAction('suspend', m.uid)} className="flex items-center gap-2 px-4 py-2 text-sm text-orange-600 hover:bg-orange-50 w-full text-left">
              <ShieldBan size={16} /> Suspend
            </button>
          )}
          
          <div className="h-px bg-gray-100 my-1 w-full scale-y-50"></div>
          
          <button onClick={() => handleAction('delete', m.uid)} className="flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 w-full text-left">
            <Trash2 size={16} /> Delete
          </button>
        </div>
      </div>
    )}
  ];

  // Pagination slice
  const paginatedData = filteredMembers.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);
  const totalPages = Math.ceil(filteredMembers.length / itemsPerPage);

  return (
    <div className="space-y-6 animate-fade-in-up">
      
      {/* Header Row */}
      <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <h2 className="text-2xl font-bold text-gray-900">Members</h2>
          <span className="bg-primary/10 text-primary font-bold px-3 py-1 rounded-full text-sm">
            {filteredMembers.length}
          </span>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <SearchInput 
            value={searchQuery} 
            onChange={(e) => setSearchQuery(e.target.value)} 
            placeholder="Search name or email..." 
          />
          
          <select 
            value={statusFilter} 
            onChange={(e) => setStatusFilter(e.target.value)}
            className="border border-gray-200 rounded-xl text-sm px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary w-[120px]"
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
            <option value="cancelled">Cancelled</option>
          </select>

          <select 
            value={planFilter} 
            onChange={(e) => setPlanFilter(e.target.value)}
            className="border border-gray-200 rounded-xl text-sm px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary w-[130px]"
          >
            <option value="all">All Plans</option>
            <option value="basic">Basic</option>
            <option value="premium">Premium</option>
            <option value="student">Student</option>
            <option value="none">No Plan</option>
          </select>

          <button 
            onClick={exportCSV}
            className="flex items-center gap-2 border border-gray-200 bg-white hover:bg-gray-50 text-gray-700 font-medium px-4 py-2 rounded-xl transition-colors"
          >
            <Download size={18} />
            <span className="hidden sm:inline">Export CSV</span>
          </button>
        </div>
      </div>

      {/* Main Table */}
      <DataTable 
        columns={columns} 
        data={paginatedData} 
        loading={isLoading} 
        emptyMessage={
          searchQuery || statusFilter !== 'all' || planFilter !== 'all' 
            ? "No members match your combined filters." 
            : "No members found in the system."
        }
      />

      {/* Pagination Controls */}
      {!isLoading && filteredMembers.length > 0 && (
        <div className="flex items-center justify-between text-sm text-gray-500 px-2 mt-4">
          <p>Showing <b>{(currentPage - 1) * itemsPerPage + 1}</b> to <b>{Math.min(currentPage * itemsPerPage, filteredMembers.length)}</b> of <b>{filteredMembers.length}</b> members</p>
          
          <div className="flex items-center gap-2">
            <button 
              disabled={currentPage === 1}
              onClick={() => setCurrentPage(p => p - 1)}
              className="px-4 py-2 border border-gray-200 rounded-xl bg-white hover:bg-gray-50 disabled:opacity-50 disabled:hover:bg-white transition-colors font-medium text-gray-700"
            >
              Previous
            </button>
            <span className="px-4 font-medium text-gray-900">Page {currentPage} of {totalPages}</span>
            <button 
              disabled={currentPage === totalPages}
              onClick={() => setCurrentPage(p => p + 1)}
              className="px-4 py-2 border border-gray-200 rounded-xl bg-white hover:bg-gray-50 disabled:opacity-50 disabled:hover:bg-white transition-colors font-medium text-gray-700"
            >
              Next
            </button>
          </div>
        </div>
      )}

    </div>
  );
}
