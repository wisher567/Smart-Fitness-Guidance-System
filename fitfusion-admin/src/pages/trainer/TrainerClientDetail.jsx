import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { 
  ArrowLeft, MessageCircle, ClipboardList, Target, 
  Activity, Heart, TrendingUp, Calendar, 
  Plus, Save, Trash2, Clock, CheckCircle2, 
  AlertCircle, ChevronRight
} from 'lucide-react';
import { 
  LineChart, Line, XAxis, YAxis, CartesianGrid, 
  Tooltip, ResponsiveContainer, AreaChart, Area 
} from 'recharts';
import api from '../../services/api';
import Avatar from '../../components/ui/Avatar';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import LoadingSpinner from '../../components/ui/LoadingSpinner';
import { format } from 'date-fns';
import { toast } from 'react-hot-toast';

export default function TrainerClientDetail() {
  const { uid } = useParams();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('overview');
  const [loading, setLoading] = useState(true);
  const [clientData, setClientData] = useState(null);
  const [workouts, setWorkouts] = useState([]);
  const [nutrition, setNutrition] = useState(null);
  const [notes, setNotes] = useState([]);
  const [newNote, setNewNote] = useState('');
  const [savingNote, setSavingNote] = useState(false);

  useEffect(() => {
    fetchClientData();
  }, [uid]);

  const fetchClientData = async () => {
    setLoading(true);
    try {
      const [clientRes, workoutsRes, nutritionRes, notesRes] = await Promise.all([
        api.get(`/trainer/clients/${uid}`),
        api.get(`/trainer/clients/${uid}/workouts`),
        api.get(`/trainer/clients/${uid}/nutrition`),
        api.get(`/trainer/clients/${uid}/notes`)
      ]);

      if (clientRes.data.success) setClientData(clientRes.data);
      if (workoutsRes.data.success) setWorkouts(workoutsRes.data.workouts);
      if (nutritionRes.data.success) setNutrition(nutritionRes.data.latestPlan);
      if (notesRes.data.success) setNotes(notesRes.data.notes);
    } catch (err) {
      console.error('Failed to fetch client detail:', err);
      toast.error('Failed to load client information');
    } finally {
      setLoading(false);
    }
  };

  const handleAddNote = async (e) => {
    e.preventDefault();
    if (!newNote.trim()) return;

    setSavingNote(true);
    try {
      const res = await api.post(`/trainer/clients/${uid}/notes`, { note: newNote });
      if (res.data.success) {
        setNotes([res.data.note, ...notes]);
        setNewNote('');
        toast.success('Note added successfully');
      }
    } catch (err) {
      toast.error('Failed to add note');
    } finally {
      setSavingNote(false);
    }
  };

  if (loading) return <LoadingSpinner />;
  if (!clientData) return <div className="p-10 text-center">Client not found</div>;

  const { client, stats } = clientData;

  const tabs = [
    { id: 'overview', label: 'Overview', icon: Activity },
    { id: 'workouts', label: 'Workouts', icon: ClipboardList },
    { id: 'nutrition', label: 'Nutrition', icon: Heart },
    { id: 'notes', label: 'Notes', icon: ClipboardList },
  ];

  return (
    <div className="space-y-6 animate-fade-in pb-10">
      {/* Header */}
      <div className="flex flex-col gap-6">
        <button 
          onClick={() => navigate('/trainer/clients')}
          className="flex items-center gap-2 text-gray-500 hover:text-[#E8845C] transition-colors w-fit"
        >
          <ArrowLeft size={18} />
          <span className="text-sm font-semibold">Back to Clients</span>
        </button>

        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6 bg-white p-6 rounded-3xl shadow-sm border border-gray-50">
          <div className="flex items-center gap-5">
            <Avatar name={client.name} size="xl" />
            <div>
              <div className="flex items-center gap-3 mb-1">
                <h1 className="text-2xl font-extrabold text-gray-900 leading-none">{client.name}</h1>
                <Badge status={client.status || 'active'} />
              </div>
              <p className="text-gray-400 font-medium mb-3">{client.email}</p>
              <div className="flex flex-wrap gap-2">
                <div className="bg-[#E8845C]/10 text-[#E8845C] text-[10px] font-bold px-2 py-1 rounded-lg uppercase tracking-wider">
                  {client.membershipPlanName || 'Basic'} Member
                </div>
                <div className="bg-blue-50 text-blue-600 text-[10px] font-bold px-2 py-1 rounded-lg uppercase tracking-wider">
                  Level: {client.fitnessLevel || 'Beginner'}
                </div>
              </div>
            </div>
          </div>
          
          <div className="flex flex-wrap gap-3">
            <Button 
              variant="outline" 
              className="rounded-2xl gap-2 border-gray-200"
              onClick={() => navigate(`/trainer/chat?client=${uid}`)}
            >
              <MessageCircle size={18} />
              Message Client
            </Button>
            <Button 
              variant="primary" 
              className="rounded-2xl gap-2 shadow-lg shadow-orange-500/20"
              onClick={() => navigate(`/trainer/plans/create?client=${uid}`)}
            >
              <Plus size={18} />
              Assign Workout
            </Button>
          </div>
        </div>
      </div>

      {/* Progress Stats Row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-2xl border border-gray-50 shadow-sm flex flex-col items-center justify-center text-center group">
          <p className="text-gray-400 text-[10px] font-bold uppercase tracking-widest mb-1 group-hover:text-[#E8845C] transition-colors">Workouts Done</p>
          <p className="text-2xl font-extrabold text-gray-900">{stats?.completedWorkouts || 0}</p>
        </div>
        <div className="bg-white p-4 rounded-2xl border border-gray-50 shadow-sm flex flex-col items-center justify-center text-center group">
          <p className="text-gray-400 text-[10px] font-bold uppercase tracking-widest mb-1 group-hover:text-[#E8845C] transition-colors">Calories Burned</p>
          <p className="text-2xl font-extrabold text-gray-900">{stats?.totalCaloriesBurned || 0}</p>
        </div>
        <div className="bg-white p-4 rounded-2xl border border-gray-50 shadow-sm flex flex-col items-center justify-center text-center group">
          <p className="text-gray-400 text-[10px] font-bold uppercase tracking-widest mb-1 group-hover:text-[#E8845C] transition-colors">Current Points</p>
          <p className="text-2xl font-extrabold text-[#E8845C]">{client.points || 0}</p>
        </div>
        <div className="bg-white p-4 rounded-2xl border border-gray-50 shadow-sm flex flex-col items-center justify-center text-center group">
          <p className="text-gray-400 text-[10px] font-bold uppercase tracking-widest mb-1 group-hover:text-[#E8845C] transition-colors">BMI Ratio</p>
          <p className="text-2xl font-extrabold text-gray-900">{client.bmi || 'N/A'}</p>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="flex items-center gap-1 bg-gray-100 p-1.5 rounded-2xl w-fit border border-gray-200 shadow-inner">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-bold transition-all
              ${activeTab === tab.id 
                ? 'bg-white text-[#E8845C] shadow-sm' 
                : 'text-gray-500 hover:bg-gray-200'}`}
          >
            <tab.icon size={16} />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      <div className="min-h-[400px]">
        {activeTab === 'overview' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 animate-slide-up">
            {/* Main Info */}
            <div className="lg:col-span-2 space-y-6">
              <div className="bg-white p-6 rounded-3xl shadow-sm border border-gray-50">
                <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
                  <TrendingUp size={20} className="text-[#E8845C]" />
                  Activity Progress
                </h3>
                <div className="h-[300px] w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={[
                      { name: 'Mon', pts: 400 },
                      { name: 'Tue', pts: 600 },
                      { name: 'Wed', pts: 550 },
                      { name: 'Thu', pts: 800 },
                      { name: 'Fri', pts: 700 },
                      { name: 'Sat', pts: 950 },
                      { name: 'Sun', pts: 1100 },
                    ]}>
                      <defs>
                        <linearGradient id="colorPts" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#E8845C" stopOpacity={0.1}/>
                          <stop offset="95%" stopColor="#E8845C" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
                      <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#94A3B8', fontSize: 12}} dy={10} />
                      <YAxis axisLine={false} tickLine={false} tick={{fill: '#94A3B8', fontSize: 12}} />
                      <Tooltip 
                        contentStyle={{borderRadius: '16px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}}
                        itemStyle={{fontWeight: 'bold', color: '#E8845C'}}
                      />
                      <Area type="monotone" dataKey="pts" stroke="#E8845C" strokeWidth={3} fillOpacity={1} fill="url(#colorPts)" />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="bg-white p-6 rounded-3xl shadow-sm border border-gray-50">
                  <h3 className="font-bold text-gray-900 mb-3">Medical History</h3>
                  <div className="flex flex-wrap gap-2">
                    {client.medicalConditions && client.medicalConditions.length > 0 ? (
                      client.medicalConditions.map((cond, i) => (
                        <div key={i} className="bg-red-50 text-red-500 text-xs font-bold px-3 py-1.5 rounded-xl border border-red-100 italic">
                          {cond}
                        </div>
                      ))
                    ) : (
                      <p className="text-gray-400 text-sm">No medical conditions reported.</p>
                    )}
                  </div>
                </div>
                <div className="bg-white p-6 rounded-3xl shadow-sm border border-gray-50 flex flex-col justify-center">
                   <div className="flex items-center gap-3 mb-4">
                      <div className="bg-[#E8845C]/10 p-2.5 rounded-2xl">
                        <Target size={20} className="text-[#E8845C]" />
                      </div>
                      <div>
                        <p className="text-[10px] text-gray-400 uppercase font-bold tracking-widest">Client Goal</p>
                        <p className="text-gray-900 font-bold capitalize">{client.fitnessGoal?.replace('_', ' ') || 'General Fitness'}</p>
                      </div>
                   </div>
                   <div className="w-full bg-gray-100 h-2.5 rounded-full overflow-hidden">
                      <div className="bg-[#E8845C] h-full w-[65%] rounded-full shadow-lg shadow-orange-500/20"></div>
                   </div>
                   <p className="text-[10px] text-gray-500 mt-2 font-medium text-right italic">65% Progress toward goal</p>
                </div>
              </div>
            </div>

            {/* Side Info */}
            <div className="bg-white p-6 rounded-3xl shadow-sm border border-gray-50 self-start">
              <h3 className="font-bold text-gray-900 mb-6 px-1">Detailed Profile</h3>
              <div className="space-y-5">
                {[
                  { label: 'Age', value: `${client.age || 'N/A'} years` },
                  { label: 'Weight', value: `${client.weight || 'N/A'} kg` },
                  { label: 'Height', value: `${client.height || 'N/A'} cm` },
                  { label: 'Join Date', value: client.createdAt ? format(new Date(client.createdAt), 'MMMM yyyy') : 'N/A' },
                  { label: 'Membership', value: client.membershipPlanName || 'Basic' },
                ].map((item, i) => (
                  <div key={i} className="flex justify-between items-center py-2 border-b border-gray-50 last:border-0 group">
                    <span className="text-sm font-medium text-gray-400 group-hover:text-gray-600 transition-colors">{item.label}</span>
                    <span className="text-sm font-bold text-gray-900">{item.value}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {activeTab === 'workouts' && (
          <div className="space-y-6 animate-slide-up">
            <div className="bg-white rounded-3xl border border-gray-100 overflow-hidden shadow-sm">
              <div className="p-4 bg-gray-50/50 border-b border-gray-100 flex items-center justify-between">
                <h3 className="font-bold text-gray-900 text-sm">Workout History</h3>
                <div className="flex gap-2">
                  <button className="text-[10px] font-bold px-3 py-1 bg-white border border-gray-200 rounded-lg text-gray-500 hover:border-[#E8845C] hover:text-[#E8845C] transition-all">All</button>
                  <button className="text-[10px] font-bold px-3 py-1 bg-[#E8845C] text-white rounded-lg shadow-sm">Assigned by Me</button>
                </div>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left">
                  <thead>
                    <tr className="bg-gray-50/30">
                      <th className="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-widest">Workout</th>
                      <th className="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-widest">Date</th>
                      <th className="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-widest">Status</th>
                      <th className="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-widest">Calories</th>
                      <th className="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-widest">Admin Note</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-50">
                    {workouts.length > 0 ? (
                      workouts.map((w) => (
                        <tr key={w.id} className="hover:bg-gray-50 transition-colors group">
                          <td className="px-6 py-4">
                            <p className="font-bold text-gray-900 group-hover:text-[#E8845C] transition-colors">{w.planName || 'General Workout'}</p>
                            <p className="text-[10px] text-gray-400 font-medium italic">Type: Strength</p>
                          </td>
                          <td className="px-6 py-4 text-sm text-gray-600 font-medium">
                            {format(new Date(w.createdAt), 'MMM d, yyyy')}
                          </td>
                          <td className="px-6 py-4">
                            <Badge status={w.completed ? 'completed' : 'pending'} />
                          </td>
                          <td className="px-6 py-4 text-sm font-bold text-gray-900">
                            {w.plan?.estimatedCalories || 0} kcal
                          </td>
                          <td className="px-6 py-4">
                            <button className="p-2 text-gray-300 hover:text-gray-500">
                              <ChevronRight size={18} />
                            </button>
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan="5" className="px-6 py-10 text-center text-gray-400 italic font-medium">No workout records found.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'nutrition' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 animate-slide-up">
             <div className="lg:col-span-2 space-y-6">
                <div className="bg-white p-8 rounded-3xl shadow-sm border border-gray-50 flex items-center justify-between">
                   <div className="flex items-center gap-6">
                      <div className="w-20 h-20 rounded-full border-8 border-orange-500 border-t-gray-100 flex items-center justify-center -rotate-45">
                         <span className="rotate-45 font-extrabold text-[#E8845C] text-lg">68%</span>
                      </div>
                      <div>
                         <p className="text-[10px] text-gray-400 uppercase font-black tracking-widest">Daily Calorie Intake</p>
                         <p className="text-2xl font-black text-gray-900">{nutrition?.calories || 2400} / 3200 kcal</p>
                         <p className="text-xs text-orange-500 font-bold mt-1">Average: 2,150 kcal</p>
                      </div>
                   </div>
                   <div className="hidden sm:flex flex-col gap-2">
                      <div className="flex items-center gap-2">
                        <div className="w-2 h-2 rounded-full bg-orange-500"></div>
                        <span className="text-[10px] font-bold text-gray-500 uppercase tracking-tighter">Budget Left</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <div className="w-2 h-2 rounded-full bg-gray-200"></div>
                        <span className="text-[10px] font-bold text-gray-500 uppercase tracking-tighter">Consumed</span>
                      </div>
                   </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                   {[
                     { label: 'Proteins', value: nutrition?.protein || 180, target: 200, unit: 'g', color: 'orange' },
                     { label: 'Carbs', value: nutrition?.carbs || 250, target: 300, unit: 'g', color: 'blue' },
                     { label: 'Fats', value: nutrition?.fats || 80, target: 90, unit: 'g', color: 'purple' },
                   ].map((macro, i) => (
                    <div key={i} className="bg-white p-6 rounded-3xl shadow-sm border border-gray-50 flex flex-col justify-center items-center text-center">
                        <p className="text-[10px] text-gray-400 font-bold uppercase tracking-widest mb-3">{macro.label}</p>
                        <p className="text-xl font-black text-gray-900">{macro.value}{macro.unit}</p>
                        <p className="text-[10px] text-gray-400 font-medium mb-4">Target: {macro.target}{macro.unit}</p>
                        <div className="w-full bg-gray-50 h-1.5 rounded-full overflow-hidden">
                          <div className={`h-full rounded-full shadow-lg ${macro.label === 'Proteins' ? 'bg-[#E8845C]' : macro.label === 'Carbs' ? 'bg-blue-500' : 'bg-purple-500'}`} style={{width: `${(macro.value/macro.target)*100}%`}}></div>
                        </div>
                    </div>
                   ))}
                </div>
             </div>

             <div className="space-y-6">
                <div className="bg-white p-6 rounded-3xl shadow-sm border border-gray-50">
                   <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                      <AlertCircle size={18} className="text-[#E8845C]" />
                      Dietary Restrictions
                   </h3>
                   <div className="flex flex-wrap gap-2">
                      <span className="bg-gray-50 text-gray-600 text-xs font-bold px-3 py-1.5 rounded-xl border border-gray-100">Gluten-Free</span>
                      <span className="bg-orange-50 text-[#E8845C] text-xs font-bold px-3 py-1.5 rounded-xl border border-orange-100">High Protein</span>
                   </div>
                </div>

                <div className="bg-gradient-to-br from-[#0F1923] to-[#1a2b3c] p-6 rounded-3xl text-white shadow-xl">
                   <h4 className="font-bold mb-2">AI Diet Insight</h4>
                   <p className="text-xs text-[#64748B] leading-relaxed italic">"Member is consistently hitting protein targets but struggling with carb intake on workout days. Suggesting adjustment..."</p>
                </div>
             </div>
          </div>
        )}

        {activeTab === 'notes' && (
          <div className="space-y-6 animate-slide-up">
            <div className="bg-white p-6 rounded-3xl shadow-sm border border-gray-50 mb-8">
              <h3 className="text-lg font-bold text-gray-900 mb-4">Add Private Trainer Note</h3>
              <form onSubmit={handleAddNote}>
                <textarea 
                  className="w-full p-4 bg-gray-50 border border-gray-100 rounded-2xl focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 focus:border-[#E8845C] transition-all text-sm mb-4 resize-none h-32 font-medium"
                  placeholder="Record your observations about this client's performance, health status, or future goals..."
                  value={newNote}
                  onChange={(e) => setNewNote(e.target.value)}
                />
                <div className="flex justify-end">
                  <Button 
                    type="submit" 
                    variant="primary" 
                    className="rounded-xl px-8 gap-2 shadow-lg shadow-orange-500/20"
                    disabled={!newNote.trim() || savingNote}
                  >
                    {savingNote ? <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div> : <Save size={18} />}
                    Save Daily Note
                  </Button>
                </div>
              </form>
            </div>

            <div className="space-y-4">
              <h3 className="font-bold text-gray-900 px-1">Previous Notes ({notes.length})</h3>
              {notes.length > 0 ? (
                notes.map((note) => (
                  <div key={note.id} className="bg-white p-6 rounded-3xl shadow-sm border border-gray-50 relative group hover:border-[#E8845C]/10 hover:shadow-md transition-all">
                    <div className="flex justify-between items-start mb-4">
                      <div className="flex items-center gap-3">
                         <div className="bg-[#E8845C]/10 p-2 rounded-xl">
                             <Calendar size={14} className="text-[#E8845C]" />
                         </div>
                         <p className="text-xs font-bold text-gray-400 tracking-wider font-mono">
                            {format(new Date(note.createdAt), 'EEEE, MMM do, yyyy')} • {format(new Date(note.createdAt), 'p')}
                         </p>
                      </div>
                      <button className="text-gray-200 hover:text-red-500 transition-colors p-1">
                        <Trash2 size={16} />
                      </button>
                    </div>
                    <p className="text-gray-700 text-sm leading-relaxed font-medium">
                      {note.note}
                    </p>
                  </div>
                ))
              ) : (
                <div className="bg-white rounded-3xl p-16 border-2 border-dashed border-gray-100 text-center flex flex-col items-center justify-center gap-4">
                   <div className="w-12 h-12 bg-gray-50 rounded-2xl flex items-center justify-center text-gray-300">
                     <ClipboardList size={22} />
                   </div>
                   <p className="text-gray-400 text-sm font-medium italic">No session notes recorded for this client yet.</p>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
