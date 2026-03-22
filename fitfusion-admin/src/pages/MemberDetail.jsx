import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Edit, ShieldBan, Activity, Flame, Calendar as CalendarIcon, Utensils, UserCheck, Search, X } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import api from '../services/api';
import Badge from '../components/ui/Badge';
import { getInitials, getAvatarColor, formatDate, formatDateTime, formatCurrency } from '../utils/formatters';
import Modal from '../components/ui/Modal';
import Button from '../components/ui/Button';

export default function MemberDetail() {
  const { uid } = useParams();
  const navigate = useNavigate();
  const [member, setMember] = useState(null);
  const [payments, setPayments] = useState([]);
  const [activeTab, setActiveTab] = useState('overview');
  const [loading, setLoading] = useState(true);
  const [showTrainerModal, setShowTrainerModal] = useState(false);
  const [trainers, setTrainers] = useState([]);
  const [loadingTrainers, setLoadingTrainers] = useState(false);
  const [assigningTrainer, setAssigningTrainer] = useState(false);
  const [trainerSearch, setTrainerSearch] = useState('');

  useEffect(() => {
    const fetchMemberData = async () => {
      try {
        const [memberRes, paymentsRes] = await Promise.all([
          api.get(`/admin/members/${uid}`),
          api.get(`/admin/payments`).catch(() => ({ data: { payments: [] } }))
        ]);
        setMember(memberRes.data.member);
        
        // Filter payments for this member 
        // Note: member might have name instead of uid on payment record depending on backend implementation
        const allPayments = paymentsRes.data?.payments || [];
        const memberPayments = allPayments.filter(p => p.memberName === memberRes.data.member.name || p.uid === uid);
        setPayments(memberPayments);
      } catch (err) {
        toast.error('Failed to load member profile');
        navigate('/members');
      } finally {
        setLoading(false);
      }
    };
    fetchMemberData();
  }, [uid, navigate]);

  if (loading) return (
    <div className="flex h-[60vh] items-center justify-center">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
    </div>
  );

  if (!member) return <div className="p-8 text-center text-gray-500">Member not found</div>;

  // Mock data for workouts/nutrition as it requires further backend relation endpoints
  const mockWorkouts = [
    { id: 1, name: 'Full Body HIIT', date: new Date().toISOString(), duration: 45, calories: 420 },
    { id: 2, name: 'Upper Body Strength', date: new Date(Date.now() - 86400000).toISOString(), duration: 60, calories: 350 },
  ];

  const pointsData = [
    { day: 'Mon', points: 120 }, { day: 'Tue', points: 250 },
    { day: 'Wed', points: 300 }, { day: 'Thu', points: 380 },
    { day: 'Fri', points: 500 }, { day: 'Sat', points: Math.max(500, member.points || 0) },
  ];

  return (
    <div className="space-y-6 animate-fade-in-up max-w-5xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between">
        <button onClick={() => navigate('/members')} className="flex items-center gap-2 text-gray-500 hover:text-gray-900 transition-colors">
          <ArrowLeft size={20} /> Back to Members
        </button>
        <div className="flex items-center gap-3">
          <button 
            onClick={() => {
              setShowTrainerModal(true);
              fetchTrainers();
            }}
            className="flex items-center gap-2 border border-blue-200 bg-blue-50 hover:bg-blue-100 text-blue-600 font-medium px-4 py-2 rounded-xl transition-colors text-sm"
          >
            <UserCheck size={16} /> 
            {member.assignedTrainerId ? 'Change Trainer' : 'Assign Trainer'}
          </button>
          <button className="flex items-center gap-2 border border-gray-200 bg-white hover:bg-gray-50 text-gray-700 font-medium px-4 py-2 rounded-xl transition-colors text-sm">
            <Edit size={16} /> Edit
          </button>
          <button className="flex items-center gap-2 border border-red-200 bg-red-50 hover:bg-red-100 text-red-600 font-medium px-4 py-2 rounded-xl transition-colors text-sm">
            <ShieldBan size={16} /> Suspend
          </button>
        </div>
      </div>

      {/* Main Profile Card */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 flex flex-col md:flex-row gap-8 items-start relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 rounded-full -translate-y-1/2 translate-x-1/2 blur-3xl"></div>
        
        <div className="flex flex-col items-center gap-4 shrink-0 relative z-10">
          <div className={`w-32 h-32 rounded-full flex items-center justify-center text-white font-bold text-4xl shadow-lg border-4 border-white ${getAvatarColor(member.name)}`}>
            {getInitials(member.name)}
          </div>
          <div className="flex flex-col items-center">
            <Badge status={member.status || 'active'} />
            <div className="mt-2"><Badge status={member.membershipPlanName || 'none'} /></div>
          </div>
        </div>

        <div className="flex-1 w-full relative z-10">
          <h2 className="text-3xl font-bold text-gray-900 mb-1">{member.name}</h2>
          <p className="text-gray-500 mb-6">{member.email} • {member.phone || 'No phone'}</p>
          
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
            <div>
              <p className="text-xs text-gray-400 mb-1 uppercase tracking-wider font-semibold">Age</p>
              <p className="font-medium text-gray-900">{member.age || '—'} yrs</p>
            </div>
            <div>
              <p className="text-xs text-gray-400 mb-1 uppercase tracking-wider font-semibold">Weight</p>
              <p className="font-medium text-gray-900">{member.weight || '—'} kg</p>
            </div>
            <div>
              <p className="text-xs text-gray-400 mb-1 uppercase tracking-wider font-semibold">Height</p>
              <p className="font-medium text-gray-900">{member.height || '—'} cm</p>
            </div>
            <div>
              <p className="text-xs text-gray-400 mb-1 uppercase tracking-wider font-semibold">BMI</p>
              <p className="font-medium text-gray-900">{member.bmi || '—'}</p>
            </div>
            
            <div className="sm:col-span-2">
              <p className="text-xs text-gray-400 mb-1 uppercase tracking-wider font-semibold">Fitness Goal</p>
              <p className="font-medium text-gray-900 capitalize">{member.fitnessGoal?.replace('_', ' ') || 'Not set'}</p>
            </div>
            <div className="sm:col-span-2">
              <p className="text-xs text-gray-400 mb-1 uppercase tracking-wider font-semibold">Member Since</p>
              <p className="font-medium text-gray-900">{formatDate(member.createdAt)}</p>
            </div>
          </div>

          <div className="mt-8 pt-6 border-t border-gray-100 flex flex-wrap items-center gap-6">
            <div className="flex items-center gap-3">
              <span className="text-sm font-semibold text-gray-500 uppercase tracking-wider">Total Points:</span>
              <span className="text-2xl font-bold text-primary">{member.points || 0} ✨</span>
            </div>
            {member.trainerName && (
              <div className="flex items-center gap-3 bg-blue-50 px-4 py-2 rounded-2xl border border-blue-100">
                <span className="text-[10px] font-bold text-blue-500 uppercase tracking-widest">Assigned Trainer</span>
                <span className="text-sm font-bold text-blue-700">{member.trainerName}</span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl border border-gray-100 p-5 flex items-center gap-4">
          <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-500 flex items-center justify-center"><Activity size={20} /></div>
          <div><p className="text-xl font-bold text-gray-900">12</p><p className="text-xs text-gray-500">Workouts</p></div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-100 p-5 flex items-center gap-4">
          <div className="w-10 h-10 rounded-xl bg-orange-50 text-orange-500 flex items-center justify-center"><Flame size={20} /></div>
          <div><p className="text-xl font-bold text-gray-900">4,500</p><p className="text-xs text-gray-500">kcal Burned</p></div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-100 p-5 flex items-center gap-4">
          <div className="w-10 h-10 rounded-xl bg-green-50 text-green-500 flex items-center justify-center"><CalendarIcon size={20} /></div>
          <div><p className="text-xl font-bold text-gray-900">3 Days</p><p className="text-xs text-gray-500">Current Streak</p></div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-100 p-5 flex items-center gap-4">
          <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-500 flex items-center justify-center"><Utensils size={20} /></div>
          <div><p className="text-xl font-bold text-gray-900">28</p><p className="text-xs text-gray-500">Meals Logged</p></div>
        </div>
      </div>

      {/* Tabs Menu */}
      <div className="border-b border-gray-200">
        <nav className="flex gap-8">
          {['overview', 'workouts', 'payments', 'nutrition'].map(tab => (
            <button key={tab} onClick={() => setActiveTab(tab)}
              className={`pb-4 px-2 text-sm font-medium capitalize transition-colors duration-200 ${
                activeTab === tab ? 'border-b-2 border-primary text-primary' : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              {tab}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      <div className="py-2">
        {activeTab === 'overview' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 h-[300px]">
              <h3 className="font-bold text-gray-900 mb-4">Progress Journey</h3>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={pointsData} margin={{top: 5, right: 10, left: -20, bottom: 0}}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F0F0F0" />
                  <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{fill: '#9CA3AF', fontSize: 12}} dy={10} />
                  <YAxis axisLine={false} tickLine={false} tick={{fill: '#9CA3AF', fontSize: 12}} />
                  <Tooltip contentStyle={{borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}} />
                  <Line type="monotone" dataKey="points" stroke="#E8845C" strokeWidth={3} dot={{r: 4}} activeDot={{r: 6}} />
                </LineChart>
              </ResponsiveContainer>
            </div>
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
              <h3 className="font-bold text-gray-900 mb-4">Recent Activity</h3>
              <div className="space-y-4">
                <div className="flex gap-4">
                  <div className="w-2 h-2 mt-2 rounded-full bg-primary shrink-0"></div>
                  <div><p className="text-sm font-medium text-gray-900">Completed Full Body HIIT</p><p className="text-xs text-gray-500">Yesterday at 5:30 PM</p></div>
                </div>
                <div className="flex gap-4">
                  <div className="w-2 h-2 mt-2 rounded-full bg-green-500 shrink-0"></div>
                  <div><p className="text-sm font-medium text-gray-900">Logged Breakfast Meal</p><p className="text-xs text-gray-500">2 days ago</p></div>
                </div>
                <div className="flex gap-4">
                  <div className="w-2 h-2 mt-2 rounded-full bg-blue-500 shrink-0"></div>
                  <div><p className="text-sm font-medium text-gray-900">Unlocked Bronze Badge!</p><p className="text-xs text-gray-500">1 week ago</p></div>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'payments' && (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <table className="w-full text-sm text-left">
              <thead className="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider font-medium">
                <tr>
                  <th className="px-6 py-4">Invoice #</th>
                  <th className="px-6 py-4">Amount</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {payments.length === 0 ? (
                  <tr><td colSpan="4" className="text-center py-8 text-gray-400">No payment history</td></tr>
                ) : payments.map(p => (
                  <tr key={p.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 font-mono text-xs text-gray-500">{p.id.slice(0,8).toUpperCase()}</td>
                    <td className="px-6 py-4 font-bold">{formatCurrency(p.amount)}</td>
                    <td className="px-6 py-4"><Badge status={p.status} /></td>
                    <td className="px-6 py-4 text-gray-500">{formatDateTime(p.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {activeTab === 'workouts' && (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <table className="w-full text-sm text-left">
              <thead className="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider font-medium">
                <tr>
                  <th className="px-6 py-4">Exercise</th>
                  <th className="px-6 py-4">Date</th>
                  <th className="px-6 py-4">Duration</th>
                  <th className="px-6 py-4">Calories</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {mockWorkouts.map(w => (
                  <tr key={w.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 font-medium text-gray-900">{w.name}</td>
                    <td className="px-6 py-4 text-gray-500">{formatDateTime(w.date)}</td>
                    <td className="px-6 py-4 text-gray-700">{w.duration} mins</td>
                    <td className="px-6 py-4 font-semibold text-orange-500">{w.calories} kcal</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {activeTab === 'nutrition' && (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 text-center text-gray-500">
            Nutrition data integration coming soon.
          </div>
        )}
      </div>

      {/* Assign Trainer Modal */}
      <Modal 
        isOpen={showTrainerModal} 
        onClose={() => setShowTrainerModal(false)}
        title="Assign Personal Trainer"
      >
        <div className="space-y-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input 
              type="text"
              placeholder="Search trainers..."
              className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/20"
              value={trainerSearch}
              onChange={(e) => setTrainerSearch(e.target.value)}
            />
          </div>

          <div className="max-h-[300px] overflow-y-auto space-y-2 pr-2">
            {loadingTrainers ? (
              <div className="py-10 text-center"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div></div>
            ) : trainers.filter(t => t.name.toLowerCase().includes(trainerSearch.toLowerCase())).length > 0 ? (
              trainers.filter(t => t.name.toLowerCase().includes(trainerSearch.toLowerCase())).map((t) => (
                <button
                  key={t.uid}
                  onClick={() => handleAssignTrainer(t.uid, t.name)}
                  disabled={assigningTrainer}
                  className={`w-full flex items-center justify-between p-4 rounded-2xl border transition-all
                    ${member.assignedTrainerId === t.uid 
                      ? 'bg-blue-50 border-blue-200 ring-2 ring-blue-100' 
                      : 'bg-white border-gray-100 hover:border-primary/30 hover:bg-primary/5'}`}
                >
                  <div className="flex items-center gap-3">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center text-white font-bold text-sm ${getAvatarColor(t.name)}`}>
                      {getInitials(t.name)}
                    </div>
                    <div className="text-left">
                      <p className="font-bold text-gray-900 leading-tight">{t.name}</p>
                      <p className="text-xs text-gray-400 font-semibold uppercase tracking-wider mt-0.5">{t.specialization || 'General Trainer'}</p>
                    </div>
                  </div>
                  {member.assignedTrainerId === t.uid ? (
                    <span className="text-[10px] font-bold text-blue-600 bg-blue-100 px-2 py-1 rounded-lg uppercase tracking-widest">Selected</span>
                  ) : (
                    <UserCheck size={18} className="text-gray-300 group-hover:text-primary" />
                  )}
                </button>
              ))
            ) : (
              <p className="py-10 text-center text-gray-400 italic">No trainers found.</p>
            )}
          </div>
          
          <div className="pt-4 border-t border-gray-100 flex justify-end">
            <button 
              onClick={() => setShowTrainerModal(false)}
              className="px-5 py-2.5 text-gray-500 font-bold hover:bg-gray-50 rounded-xl transition-all"
            >
              Cancel
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );

  async function fetchTrainers() {
    setLoadingTrainers(true);
    try {
      const res = await api.get('/admin/trainers');
      setTrainers(res.data?.trainers || []);
    } catch (err) {
      toast.error('Failed to load trainers list');
    } finally {
      setLoadingTrainers(false);
    }
  }

  async function handleAssignTrainer(trainerId, trainerName) {
    if (member.assignedTrainerId === trainerId) return;
    
    setAssigningTrainer(true);
    try {
      const res = await api.patch(`/admin/members/${uid}`, { assignedTrainerId: trainerId });
      if (res.data.success) {
        setMember({ ...member, assignedTrainerId: trainerId, trainerName });
        toast.success(`Trainer ${trainerName} assigned to ${member.name}`);
        setShowTrainerModal(false);
      }
    } catch (err) {
      toast.error('Failed to assign trainer');
    } finally {
      setAssigningTrainer(false);
    }
  }
}
